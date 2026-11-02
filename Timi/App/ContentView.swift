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
        // SF Symbols, filled for the chosen tab (user request 2026-10-30: solid tab icons) and
        // outlined for the others, which in solid ink outweighed it (UI review 2026-10-30); iOS
        // ignores a grey for tabs not chosen. Hugeicons free has no filled style.
        tabs
            // The chosen tab in the primary colour.
            .tint(Palette.primary)
            .background {
                InstantTabSwitch { isAddingTransaction = true }.frame(width: 0, height: 0)
                // The saved "Giao diện", before the first frame shows.
                SavedAppearanceSetter().frame(width: 0, height: 0)
            }
            .environment(addContext)
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView(preferredAccount: addContext.accountID)
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            modernTabs
        } else {
            legacyTabs
        }
    }

    /// Before iOS 18: the same three tabs and a fourth "+" tab at the end (no search-role circle
    /// apart from the bar); picking it opens the add sheet through `tabSelection`.
    private var legacyTabs: some View {
        TabView(selection: tabSelection) {
            OverviewView()
                .tabItem { tabLabel("Tổng quan", symbol: "house", tab: .overview) }
                .tag(AppTab.overview)
            AccountsView()
                .tabItem { tabLabel("Tài khoản", symbol: "creditcard", tab: .accounts) }
                .tag(AppTab.accounts)
            TransactionsView()
                .tabItem { tabLabel("Giao dịch", symbol: "list.bullet.rectangle", tab: .transactions) }
                .tag(AppTab.transactions)
            Color.clear
                .tabItem { Label("Thêm giao dịch", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)
        }
    }

    @available(iOS 18.0, *)
    private var modernTabs: some View {
        TabView(selection: tabSelection) {
            Tab(value: AppTab.overview) {
                OverviewView()
            } label: { tabLabel("Tổng quan", symbol: "house", tab: .overview) }
            Tab(value: AppTab.accounts) {
                AccountsView()
            } label: { tabLabel("Tài khoản", symbol: "creditcard", tab: .accounts) }
            Tab(value: AppTab.transactions) {
                TransactionsView()
            } label: { tabLabel("Giao dịch", symbol: "list.bullet.rectangle", tab: .transactions) }
            // A search-role tab sits apart in its own circle beside the bar, as Search does in App
            // Store: there, by the thumb on every tab, it adds a transaction (user choice 2026-10-29).
            Tab("Thêm giao dịch", systemImage: "plus", value: AppTab.add, role: .search) {
                Color.clear
            }
        }
    }

    private func tabLabel(_ title: String, symbol: String, tab: AppTab) -> some View {
        Label(title, systemImage: selectedTab == tab ? "\(symbol).fill" : symbol)
            .environment(\.symbolVariants, selectedTab == tab ? .fill : .none)
    }
}

#Preview {
    ContentView()
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(AssistantChats())
        .environment(\.locale, .vietnam)
}
