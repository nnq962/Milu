import Foundation

/// Where Milu's answers come from. The chat asks this and nothing else, so a real AI (an API)
/// takes the mock's place here without the chat changing (user request 2026-11-11: the API
/// first, the effects after).
///
/// To plug an API in: write a type that conforms (send `history` and `question`, turn the reply
/// into an `AssistantReply`), and return it from `AssistantServices.make(store:)`.
protocol AssistantService {
    /// Milu's answer to `question`. `history` is the chat so far, oldest first, without it.
    func reply(to question: String, history: [ChatMessage]) async throws -> AssistantReply
}

enum AssistantServices {
    /// The service the chat uses: the local LLM on the app's server when `MiluAPI.plist` says
    /// where it is (user choice 2026-11-12), the keyword assistant on the phone otherwise.
    @MainActor
    static func make(store: FinanceStore) -> any AssistantService {
        if let api = MiluAPI.shared { return RemoteAssistant(api: api, store: store) }
        return MockAssistant(store: store)
    }
}

/// What can go wrong asking for an answer, in words for the chat.
enum AssistantServiceError: LocalizedError {
    case noConnection
    case server(String)

    var errorDescription: String? {
        switch self {
        case .noConnection: "Không kết nối được. Bạn kiểm tra mạng rồi thử lại nhé."
        case .server(let detail): "Milu chưa trả lời được (\(detail)). Bạn thử lại sau nhé."
        }
    }
}
