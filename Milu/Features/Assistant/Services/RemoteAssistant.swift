import Foundation

/// Milu's answers from the local LLM on the app's server (`MiluAPI`), worked from the phone's
/// own data: the model asks for tools (`AssistantTools`), they run here, only their results go
/// back, and it answers from them (user choice 2026-11-12).
///
/// Without the server (no network, the server down) before any tool ran, the keyword assistant
/// on the phone answers instead, so the chat still works offline.
struct RemoteAssistant: AssistantService {
    let api: MiluAPI
    let store: FinanceStore

    /// Rounds of tools before giving up: a question takes one or two.
    private static let maxRounds = 5
    /// The chat so far the model reads: enough for "còn tháng trước?" after a question.
    private static let historyLength = 6

    func reply(to question: String, history: [ChatMessage]) async throws -> AssistantReply {
        var messages: [MiluAPI.ChatMessage] = history.suffix(Self.historyLength).compactMap { message in
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return message.role == .user ? .user(text) : .assistant(text)
        }
        messages.append(.user(question))
        let context = makeContext()
        var action: AssistantReply.Action?
        var ranTools = false

        do {
            for _ in 0..<Self.maxRounds {
                let reply = try await api.chat(messages, tools: AssistantTools.specs, context: context)
                guard !reply.toolCalls.isEmpty else {
                    let text = reply.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    return AssistantReply(text: text.isEmpty ? Self.emptyAnswer(action) : text, action: action)
                }
                messages.append(.assistant(reply.content, calls: reply.toolCalls))
                for call in reply.toolCalls {
                    let output = AssistantTools.named(call.name)?.run(call.arguments, in: store)
                        ?? .failure("Không có công cụ \(call.name)")
                    ranTools = true
                    if let next = output.action { action = next }
                    messages.append(.tool(call.name, result: output.result))
                }
            }
            return AssistantReply(text: Self.emptyAnswer(action), action: action)
        } catch MiluAPI.Failure.unreachable where !ranTools {
            // Offline: the phone's own assistant, which knows the common questions.
            return MockAssistant(store: store).reply(to: question)
        } catch MiluAPI.Failure.busy {
            throw AssistantServiceError.server("bạn đã hỏi nhiều quá trong giờ này")
        } catch where action != nil {
            // A transaction was recorded or picked before the answer failed: its card shows.
            return AssistantReply(text: "Mình làm xong rồi, bạn xem bên dưới nhé:", action: action)
        } catch is CancellationError {
            throw CancellationError()
        } catch MiluAPI.Failure.unreachable {
            throw AssistantServiceError.noConnection
        } catch MiluAPI.Failure.unauthorized {
            throw AssistantServiceError.server("khoá kết nối không hợp lệ")
        } catch {
            throw AssistantServiceError.server("máy chủ trả lời lỗi")
        }
    }

    private static func emptyAnswer(_ action: AssistantReply.Action?) -> String {
        action == nil ? "Mình chưa trả lời được câu này. Bạn hỏi lại theo cách khác nhé." : "Xong rồi, bạn xem bên dưới nhé:"
    }

    /// The day and the names the model may use: categories (groups and their items) and accounts.
    private func makeContext() -> MiluAPI.Context {
        func names(_ kind: TransactionKind) -> [String] {
            store.groups(kind).flatMap { group in [group.name] + store.items(of: group).map(\.name) }
        }
        let profileName = UserDefaults.standard.string(forKey: StorageKey.profileName)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return MiluAPI.Context(
            today: ToolDates.text(.now),
            userName: profileName?.isEmpty == false ? profileName : nil,
            expenseCategories: names(.expense),
            incomeCategories: names(.income),
            accounts: store.accounts.map(\.name)
        )
    }
}
