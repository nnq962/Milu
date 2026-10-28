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
                .preferredColorScheme(.light)
                .scrollIndicators(.hidden, axes: .vertical)
                .environment(store)
                .modelContainer(container)
                .environment(\.locale, .vietnam)
        }
    }
}
