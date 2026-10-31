//
//  TimiApp.swift
//  Timi
//
//  Created by Nguyen Ngoc Quyet on 10/25/26.
//

import SwiftData
import SwiftUI

@main
struct TimiApp: App {
    private let container: ModelContainer
    @State private var store: FinanceStore
    @State private var quota = AIQuota()
    @State private var chats = AssistantChats()

    init() {
        Typography.configureNativeAppearance()
        let container = FinanceDatabase.makeContainer()
        self.container = container
        _store = State(initialValue: FinanceStore(database: FinanceDatabase(context: container.mainContext)))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // The body role (16 SemiBold), so a Text with no role still matches the scale
                // (strict review 2026-10-31: 17 Regular sat outside it).
                .font(TextRole.body.font)
                .scrollIndicators(.hidden, axes: .vertical)
                .environment(store)
                .environment(quota)
                .environment(chats)
                .modelContainer(container)
                .environment(\.locale, .vietnam)
        }
    }
}
