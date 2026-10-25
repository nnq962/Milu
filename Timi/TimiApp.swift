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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(\.locale, .vietnam)
        }
    }
}
