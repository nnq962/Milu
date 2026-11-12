import Foundation
import Testing
@testable import Milu

/// The tools the assistant's model is offered (`AssistantTools`), and what the server's
/// evaluation (milu-server/eval) reads of them.
@MainActor
struct AssistantToolsTests {
    @Test func toolNamesAreUniqueAndSnakeCase() {
        let names = AssistantTools.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { $0.wholeMatch(of: /[a-z]+(_[a-z]+)*/) != nil })
    }

    @Test func everyToolHasAnObjectSchema() {
        for tool in AssistantTools.all {
            #expect(tool.parameters["type"] == "object", "\(tool.name)")
        }
    }

    /// With TEST_RUNNER_MILU_EXPORT=<path> set for `xcodebuild test`, writes the tools and the
    /// context the app sends (sample data, on 2026-11-12) for the server's evaluation.
    @Test func exportsWhatTheServerSees() throws {
        let store = FinanceStore()
        let day = ToolDates.day("2026-11-12") ?? .now
        let context = RemoteAssistant.context(for: store, on: day)
        #expect(!context.expenseCategories.isEmpty)
        guard let path = ProcessInfo.processInfo.environment["MILU_EXPORT"] else { return }
        struct Export: Encodable { var tools: [MiluAPI.ToolSpec]; var context: MiluAPI.Context }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(Export(tools: AssistantTools.specs, context: context))
            .write(to: URL(fileURLWithPath: path))
    }
}
