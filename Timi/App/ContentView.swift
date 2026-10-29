import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview
    @State private var isAddingTransaction = false
    @State private var addContext = AddTransactionContext()

    /// Picking the + opens the add sheet and leaves the current tab where it is. `InstantTabSwitch`
    /// stops the tap before the tab is selected; this is the fallback should it get through.
    private var tabSelection: Binding<AppTab> {
        Binding { selectedTab } set: { tab in
            if tab == .add { isAddingTransaction = true } else { selectedTab = tab }
        }
    }

    var body: some View {
        // Hugeicons free has no filled style: a tab keeps its outline icon when selected and the
        // tab bar's own highlight marks it.
        tabs
            .tint(.primary)
            .background {
                InstantTabSwitch { isAddingTransaction = true }.frame(width: 0, height: 0)
            }
            .environment(addContext)
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView(preferredAccount: addContext.accountID)
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: tabSelection) {
                Tab("Tổng quan", image: "hugeicons-home-01", value: AppTab.overview) {
                    OverviewView(selectedTab: $selectedTab)
                }
                Tab("Tài khoản", image: "hugeicons-credit-card", value: AppTab.accounts) {
                    AccountsView()
                }
                Tab("Giao dịch", image: "hugeicons-arrow-data-transfer-horizontal", value: AppTab.transactions) {
                    TransactionsView()
                }
                Tab("Trợ lý AI", image: "hugeicons-ai-magic", value: AppTab.assistant) {
                    AssistantView()
                }
                // On iOS 26 a search-role tab sits apart in its own circle beside the bar, as Search
                // does in App Store: there, by the thumb on every tab, it adds a transaction
                // (user choice 2026-10-29). Earlier iOS shows it as a fifth tab.
                Tab("Thêm giao dịch", image: "hugeicons-add-01", value: AppTab.add, role: .search) {
                    Color.clear
                }
            }
        } else {
            TabView(selection: tabSelection) {
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
                Color.clear
                    .tabItem { Label("Thêm", image: "hugeicons-add-01") }
                    .tag(AppTab.add)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
