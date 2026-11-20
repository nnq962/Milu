import Foundation

/// The app's server (`~/apps/milu-server` on the home server, https://milu-api.nnqlab.dev): the
/// local LLM and speech to text
/// (user choice 2026-11-12: local models only, the data stays on the phone). Its address and key
/// come from `MiluAPI.plist` beside the app's code, kept out of git; without it the assistant
/// answers on its own (`MockAssistant`) and dictation uses the iPhone's recognizer.
nonisolated struct MiluAPI: Sendable {
    let baseURL: URL
    let apiKey: String

    /// From `MiluAPI.plist`: `BaseURL` and `APIKey`.
    static let shared: MiluAPI? = {
        guard let url = Bundle.main.url(forResource: "MiluAPI", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let base = plist["BaseURL"].flatMap(URL.init(string:)),
              let key = plist["APIKey"], !key.isEmpty else { return nil }
        return MiluAPI(baseURL: base, apiKey: key)
    }()

    enum Failure: Error, Equatable {
        /// The phone has no internet (Wi-Fi and mobile data off, or no signal).
        case offline
        /// The phone is online but the server did not answer: down, or too slow.
        case unreachable
        /// The key was refused.
        case unauthorized
        /// Too many requests this hour.
        case busy
        /// The connection dropped mid-way: the app went to the background, say, not no internet.
        case interrupted
        case server(Int)
    }

    // MARK: Chat

    struct ChatMessage: Codable, Sendable {
        var role: String
        var content: String
        var toolCalls: [ToolCall]? = nil
        var toolName: String? = nil

        static func user(_ text: String) -> Self { .init(role: "user", content: text) }
        static func assistant(_ text: String, calls: [ToolCall]? = nil) -> Self {
            .init(role: "assistant", content: text, toolCalls: calls)
        }
        static func tool(_ name: String, result: JSONValue) -> Self {
            .init(role: "tool", content: result.jsonString, toolName: name)
        }
    }

    struct ToolCall: Codable, Sendable {
        var id: String
        var name: String
        var arguments: JSONValue
    }

    struct ToolSpec: Codable, Sendable {
        var name: String
        var description: String
        var parameters: JSONValue
    }

    /// What the model knows of the phone: the day, and the names it may use.
    struct Context: Codable, Sendable {
        var today: String
        var userName: String?
        var expenseCategories: [String]
        var incomeCategories: [String]
        var accounts: [String]
        /// What this build's assistant can write besides transactions, whether or not its tool is
        /// sent this time ("add_account"): the server says so when asked what Milu does, without
        /// the tool's room in the prompt (2026-11-20).
        var assistant: [String]? = nil
    }

    struct Reply: Decodable, Sendable {
        var content: String
        var toolCalls: [ToolCall]
    }

    /// One turn of the model: words, or tools it wants run.
    ///
    /// `onWords`: the answer's words so far, as the model writes them, each time more come (user
    /// choice 2026-11-20, "Trả lời dần từng chữ"). The server sends them only for an answer
    /// written from the tools' results; any other comes whole, and `onWords` is not called.
    func chat(_ messages: [ChatMessage], tools: [ToolSpec], context: Context,
              onWords: ((String) -> Void)? = nil) async throws -> Reply {
        struct Body: Encodable {
            var messages: [ChatMessage]; var tools: [ToolSpec]; var context: Context; var stream: Bool?
        }
        struct Answer: Decodable { var message: Reply }
        var request = request("v1/chat", timeout: 45)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(messages: messages, tools: tools, context: context,
                                                         stream: onWords == nil ? nil : true))
        guard let onWords else {
            let data = try await send(request)
            return try JSONDecoder().decode(Answer.self, from: data).message
        }
        let lines = try await sendForLines(request)
        var events = ChatEvents()
        do {
            for try await line in lines {
                switch try events.read(line) {
                case .words(let words): onWords(words)
                case .reply(let reply): return reply
                case nil: continue
                }
            }
        } catch let failure as Failure {
            throw failure
        } catch {
            throw Self.failure(for: error)
        }
        // Cut off before the last event.
        throw Failure.interrupted
    }

    /// The server's events for a chat that streams (`chat(onWords:)`), one line at a time:
    /// `data: {"delta": …}` for words as they come, `data: {"message": …}` for the turn whole,
    /// `data: {"error": …, "status": …}` for a failure on the way.
    struct ChatEvents {
        /// The words so far.
        private(set) var words = ""

        enum Event {
            case words(String)
            case reply(Reply)
        }

        mutating func read(_ line: String) throws -> Event? {
            guard line.hasPrefix("data:") else { return nil }
            struct Data: Decodable { var delta: String?; var message: Reply?; var status: Int? }
            let json = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard let data = try? JSONDecoder().decode(Data.self, from: Foundation.Data(json.utf8)) else { return nil }
            if let message = data.message { return .reply(message) }
            if let status = data.status {
                throw [502, 503, 504].contains(status) ? Failure.unreachable : Failure.server(status)
            }
            guard let delta = data.delta, !delta.isEmpty else { return nil }
            words += delta
            return .words(words)
        }
    }

    // MARK: Speech

    /// RFC 3986's unreserved characters, the only ones left as they are in a header.
    private static let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    /// The words in a recording (M4A), favouring `names` (accounts, banks, wallets).
    func transcribe(_ audio: Data, names: [String], timeout: TimeInterval) async throws -> String {
        struct Answer: Decodable { var text: String }
        var request = request("v1/transcribe", timeout: timeout)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        // ASCII only, the rest percent-encoded as UTF-8: `.alphanumerics` let "ề" and "ặ" through
        // raw, which a header may not carry (audit round 4, 2026-11-16).
        let hotwords = names.compactMap { $0.addingPercentEncoding(withAllowedCharacters: Self.unreserved) }
        request.setValue(hotwords.joined(separator: "/"), forHTTPHeaderField: "X-Hotwords")
        request.httpBody = audio
        let data = try await send(request)
        return try JSONDecoder().decode(Answer.self, from: data).text
    }

    // MARK: Requests

    /// What URLSession says when the phone itself has no internet.
    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff,
    ]

    private func request(_ path: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path), timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw Self.failure(for: error)
        }
        try Self.check(response)
        return data
    }

    /// The body's lines as they come, once the status says it is an answer.
    private func sendForLines(_ request: URLRequest) async throws -> AsyncLineSequence<URLSession.AsyncBytes> {
        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch {
            throw Self.failure(for: error)
        }
        try Self.check(response)
        return bytes.lines
    }

    /// A request's error as the app tells it.
    private static func failure(for error: Error) -> Error {
        switch error {
        case is CancellationError: return CancellationError()
        case let error as URLError where error.code == .cancelled: return CancellationError()
        case let error as URLError where offlineCodes.contains(error.code): return Failure.offline
        // Lost mid-way, mostly by Milu going to the background while it waited: the phone is
        // online (audit round 4, 2026-11-16: it was told to turn on Wi-Fi).
        case let error as URLError where error.code == .networkConnectionLost: return Failure.interrupted
        default: return Failure.unreachable
        }
    }

    private static func check(_ response: URLResponse) throws {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: return
        case 401: throw Failure.unauthorized
        case 429: throw Failure.busy
        case 502, 503, 504: throw Failure.unreachable
        default: throw Failure.server(status)
        }
    }
}

/// Any JSON: a tool's arguments as the model wrote them, its parameters' schema, its result.
nonisolated enum JSONValue: Codable, Hashable, Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByBooleanLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(stringLiteral value: String) { self = .string(value) }
    init(integerLiteral value: Int) { self = .number(Double(value)) }
    init(booleanLiteral value: Bool) { self = .bool(value) }
    init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
    init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    subscript(key: String) -> JSONValue? {
        if case .object(let object) = self { return object[key] }
        return nil
    }

    /// A string, or a number written as one ("60000").
    var string: String? {
        switch self {
        case .string(let value): value.trimmingCharacters(in: .whitespacesAndNewlines)
        // `Int(exactly:)`: a number too large for an Int (1e20), or NaN, stopped the app (audit
        // round 3, 2026-11-16).
        case .number(let value): Int(exactly: value).map(String.init) ?? String(value)
        default: nil
        }
    }

    /// A number, or a string holding one ("60.000", "60,000", "60000", "35000.0", "1,5"). Dots or
    /// commas are thousands only in groups of three; otherwise a decimal point (audit round 4,
    /// 2026-11-16: "35000.0" read as 350.000đ).
    var number: Double? {
        switch self {
        case .number(let value): value
        case .string(let value):
            Self.number(in: value.trimmingCharacters(in: .whitespaces))
        default: nil
        }
    }

    static func number(in text: String) -> Double? {
        if text.wholeMatch(of: /\d{1,3}(\.\d{3})+/) != nil { return Double(text.replacingOccurrences(of: ".", with: "")) }
        if text.wholeMatch(of: /\d{1,3}(,\d{3})+/) != nil { return Double(text.replacingOccurrences(of: ",", with: "")) }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }

    /// Strings, from an array or one string alone.
    var strings: [String] {
        switch self {
        case .array(let items): items.compactMap(\.string).filter { !$0.isEmpty }
        case .string(let value): value.isEmpty ? [] : [value]
        default: []
        }
    }

    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? "null"
    }
}
