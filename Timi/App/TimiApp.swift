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
    @AppStorage(StorageKey.appearance) private var appearance = AppAppearance.system.rawValue

    init() {
        Typography.configureNativeAppearance()
        let container = FinanceDatabase.makeContainer()
        self.container = container
        _store = State(initialValue: FinanceStore(database: FinanceDatabase(context: container.mainContext)))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(Typography.body)
                // By the phone, or what Cài đặt → Giao diện says (user request 2026-10-29). Set on
                // the window, not with preferredColorScheme, so a sheet already open (Cài đặt
                // itself) changes too, and "Theo hệ thống" goes back to the phone's look.
                .onChange(of: appearance, initial: true) {
                    (AppAppearance(rawValue: appearance) ?? .system).apply()
                }
                .scrollIndicators(.hidden, axes: .vertical)
                .environment(store)
                .environment(quota)
                .modelContainer(container)
                .environment(\.locale, .vietnam)
        }
    }
}
