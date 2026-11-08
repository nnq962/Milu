import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview
    /// What the + opened: a transaction, or a loan on "Vay nợ" (`AddTransactionContext.addsLoan`),
    /// fixed as it opens so the form does not change under the user.
    @State private var adding: AddKind?
    @State private var addContext = AddTransactionContext()

    private enum AddKind: Identifiable {
        case transaction, loan
        var id: Self { self }
    }

    private func add() {
        adding = addContext.addsLoan ? .loan : .transaction
    }

    /// The +'s name for VoiceOver, as what it adds on the screen behind it.
    private var addTitle: String { addContext.addsLoan ? "Thêm khoản vay" : "Thêm giao dịch" }

    /// Picking the + opens the add sheet and leaves the current tab where it is. `InstantTabSwitch`
    /// stops the tap before the tab is selected; this is the fallback should it get through.
    private var tabSelection: Binding<AppTab> {
        Binding { selectedTab } set: { tab in
            if tab == .add { add() } else { selectedTab = tab }
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
                InstantTabSwitch { add() }.frame(width: 0, height: 0)
                // The saved "Giao diện", before the first frame shows.
                SavedAppearanceSetter().frame(width: 0, height: 0)
            }
            .environment(addContext)
            // The first steps pay as the user does them, on whichever tab (user choice 2026-11-08).
            .modifier(OnboardingRewards())
            .sheet(item: $adding) { kind in
                switch kind {
                case .transaction: AddTransactionView(preferredAccount: addContext.accountID)
                case .loan: LoanEditorView(loan: nil)
                }
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
                .tabItem { Label(addTitle, systemImage: "plus.circle.fill") }
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
            // Store: there, by the thumb on every tab, it adds a transaction (user choice 2026-10-29),
            // a loan on "Vay nợ".
            // The + drawn Regular (user request 2026-11-05: the bar's default read bold); the
            // weight is set in the image itself, as the bar ignores SwiftUI's font weight.
            Tab(value: AppTab.add, role: .search) {
                Color.clear
            } label: {
                Label { Text(addTitle) } icon: { Image(uiImage: Self.regularPlus) }
            }
        }
    }

    private static let regularPlus = UIImage(systemName: "plus",
                                             withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        ?? UIImage()

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
