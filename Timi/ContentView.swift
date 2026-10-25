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
                .tabItem { Label("Tổng quan", systemImage: "chart.pie.fill") }
                .tag(AppTab.overview)

            AccountsView()
                .tabItem { Label("Tài khoản", systemImage: "creditcard.fill") }
                .tag(AppTab.accounts)

            TransactionsView()
                .tabItem { Label("Giao dịch", systemImage: "arrow.left.arrow.right") }
                .tag(AppTab.transactions)

            AssistantView()
                .tabItem { Label("Trợ lý AI", systemImage: "sparkles") }
                .tag(AppTab.assistant)
        }
    }
}

#Preview {
    ContentView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
