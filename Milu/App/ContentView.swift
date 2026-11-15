import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview
    /// What the + opened: a transaction, or a loan on "Vay nợ" (`AddTransactionContext.addsLoan`),
    /// fixed as it opens so the form does not change under the user.
    @State private var adding: AddKind?
    @State private var addContext = AddTransactionContext()
    @Environment(AppLock.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase
    /// A tapped reminder waiting for the sheet on screen to close (`openFromReminder`).
    @State private var waitingForSheet: Task<Void, Never>?

    private enum AddKind: Identifiable {
        case transaction, loan
        var id: Self { self }
    }

    private func add() {
        adding = addContext.addsLoan ? .loan : .transaction
    }

    /// A tapped "Nhắc ghi chi tiêu" opens the add form once nothing stands in its way: not under
    /// the Face ID lock (its keyboard came up over the lock, audit 2026-11-15), and not while
    /// another sheet is up (it could not open, and the tap was lost): then as that one closes.
    /// Gone with the app to the background.
    private func openFromReminder() {
        guard Reminders.shared.router.pending == .addTransaction, !appLock.isLocked else { return }
        // The add form is the sheet up: the reminder is answered already (audit round 2,
        // 2026-11-15: waited on, a second, empty form came up once it closed).
        if adding != nil {
            Reminders.shared.router.pending = nil
            return
        }
        if Presentation.isShowingSheet {
            guard waitingForSheet == nil else { return }
            waitingForSheet = Task {
                while !Task.isCancelled, Presentation.isShowingSheet {
                    try? await Task.sleep(for: .milliseconds(400))
                }
                waitingForSheet = nil
                if !Task.isCancelled { openFromReminder() }
            }
            return
        }
        Reminders.shared.router.pending = nil
        if adding == nil { add() }
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
            }
            .environment(addContext)
            // The first steps pay as the user does them, on whichever tab (user choice 2026-11-08).
            .modifier(OnboardingRewards())
            .notificationScheduling()
            // A tapped "Nhắc ghi chi tiêu" opens the add form (`Reminders`).
            .onChange(of: Reminders.shared.router.pending, initial: true) { openFromReminder() }
            .onChange(of: appLock.isLocked) { _, locked in if !locked { openFromReminder() } }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background else { return }
                waitingForSheet?.cancel()
                waitingForSheet = nil
                if Reminders.shared.router.pending == .addTransaction { Reminders.shared.router.pending = nil }
            }
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
            TabPage(tab: .overview) { OverviewView() }.equatable()
                .tabItem { tabLabel("Tổng quan", symbol: "house", tab: .overview) }
                .tag(AppTab.overview)
            TabPage(tab: .accounts) { AccountsView() }.equatable()
                .tabItem { tabLabel("Tài khoản", symbol: "creditcard", tab: .accounts) }
                .tag(AppTab.accounts)
            TabPage(tab: .transactions) { TransactionsView() }.equatable()
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
                TabPage(tab: .overview) { OverviewView() }.equatable()
            } label: { tabLabel("Tổng quan", symbol: "house", tab: .overview) }
            Tab(value: AppTab.accounts) {
                TabPage(tab: .accounts) { AccountsView() }.equatable()
            } label: { tabLabel("Tài khoản", symbol: "creditcard", tab: .accounts) }
            Tab(value: AppTab.transactions) {
                TabPage(tab: .transactions) { TransactionsView() }.equatable()
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

/// A tab's page, the same page as long as it is the same tab. `ContentView` redraws on every tab
/// change (the chosen tab's icon is filled), which rebuilt the page's struct; SwiftUI could not
/// tell it was unchanged and re-ran the whole page, a second of work on Giao dịch per switch (user
/// report 2026-11-08: the tab bar lagged). Equal by tab, so only the page's own state redraws it.
private struct TabPage<Content: View>: View, Equatable {
    let tab: AppTab
    @ViewBuilder let content: () -> Content

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.tab == rhs.tab }

    var body: some View { content() }
}

/// What is on screen over the app's pages.
@MainActor
enum Presentation {
    /// A sheet (or any view controller) is presented over the app's pages. The lock's window
    /// presents nothing (`LockWindowInstaller`).
    static var isShowingSheet: Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .contains { !$0.isHidden && $0.rootViewController?.presentedViewController != nil }
    }
}

#Preview {
    ContentView()
        .environment(AppLock())
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(CloudSyncMonitor())
        .environment(AssistantChats(saving: false))
        .environment(\.locale, .vietnam)
}
