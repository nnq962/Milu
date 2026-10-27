//
//  ContentView.swift
//  Timi
//
//  Created by Nguyen Ngoc Quyet on 10/25/26.
//

import SwiftUI

enum AppTab: Hashable {
    case overview, accounts, transactions, assistant
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView(selectedTab: $selectedTab)
                .tabItem { Label("Tổng quan", image: selectedTab == .overview ? "solar-home-2-bold" : "solar-home-2-linear") }
                .tag(AppTab.overview)

            AccountsView()
                .tabItem { Label("Tài khoản", image: selectedTab == .accounts ? "solar-card-bold" : "solar-card-linear") }
                .tag(AppTab.accounts)

            TransactionsView()
                .tabItem { Label("Giao dịch", image: selectedTab == .transactions ? "solar-transfer-horizontal-bold" : "solar-transfer-horizontal-linear") }
                .tag(AppTab.transactions)

            AssistantView()
                .tabItem { Label("Trợ lý AI", image: selectedTab == .assistant ? "solar-magic-wand-2-bold" : "solar-magic-wand-2-linear") }
                .tag(AppTab.assistant)
        }
        .tint(.primary)
    }
}

#Preview {
    ContentView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
