import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        // Hugeicons free has no filled style: a tab keeps its outline icon when selected and the
        // tab bar's own highlight marks it.
        TabView(selection: $selectedTab) {
            OverviewView(selectedTab: $selectedTab)
                .tabItem { Label("Tổng quan", image: "hugeicons-home-01") }
                .tag(AppTab.overview)

            AccountsView()
                .tabItem { Label("Tài khoản", image: "hugeicons-credit-card") }
                .tag(AppTab.accounts)

            TransactionsView()
                .tabItem { Label("Giao dịch", image: "hugeicons-arrow-data-transfer-horizontal") }
                .tag(AppTab.transactions)

            AssistantView()
                .tabItem { Label("Trợ lý AI", image: "hugeicons-ai-magic") }
                .tag(AppTab.assistant)
        }
        .tint(.primary)
        .background { InstantTabSwitch().frame(width: 0, height: 0) }
    }
}

#Preview {
    ContentView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
