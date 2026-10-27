//
//  TimiApp.swift
//  Timi
//
//  Created by Nguyen Ngoc Quyet on 10/25/26.
//

import SwiftUI

@main
struct TimiApp: App {
    @State private var store = FinanceStore()

    init() {
        Typography.configureNativeAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(Typography.body)
                .preferredColorScheme(.light)
                .scrollIndicators(.hidden, axes: .vertical)
                .environment(store)
                .environment(\.locale, .vietnam)
        }
    }
}
