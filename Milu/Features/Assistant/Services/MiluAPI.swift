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
        /// No answer: no network, the server down or too slow. The app carries on without it.
        case unreachable
        /// The key was refused.
        case unauthorized
        /// Too many requests this hour.
        case busy
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
    }

    struct Reply: Decodable, Sendable {
        var content: String
        var toolCalls: [ToolCall]
    }

    /// One turn of the model: words, or tools it wants run.
    func chat(_ messages: [ChatMessage], tools: [ToolSpec], context: Context) async throws -> Reply {
        struct Body: Encodable { var messages: [ChatMessage]; var tools: [ToolSpec]; var context: Context }
        struct Answer: Decodable { var message: Reply }
        var request = request("v1/chat", timeout: 45)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(messages: messages, tools: tools, context: context))
        let data = try await send(request)
        return try JSONDecoder().decode(Answer.self, from: data).message
    }

    // MARK: Speech

    /// The words in a recording (M4A), favouring `names` (accounts, banks, wallets).
    func transcribe(_ audio: Data, names: [String], timeout: TimeInterval) async throws -> String {
        struct Answer: Decodable { var text: String }
        var request = request("v1/transcribe", timeout: timeout)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let hotwords = names.compactMap { $0.addingPercentEncoding(withAllowedCharacters: .alphanumerics) }
        request.setValue(hotwords.joined(separator: "/"), forHTTPHeaderField: "X-Hotwords")
        request.httpBody = audio
        let data = try await send(request)
        return try JSONDecoder().decode(Answer.self, from: data).text
    }

    // MARK: Requests

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
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw Failure.unreachable
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: return data
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
        case .number(let value): value.rounded() == value ? String(Int(value)) : String(value)
        default: nil
        }
    }

    /// A number, or a string holding one ("60.000", "60000").
    var number: Double? {
        switch self {
        case .number(let value): value
        case .string(let value):
            Double(value.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces))
        default: nil
        }
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
