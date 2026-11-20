import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview
    /// The form the + opened, picked in its small sheet.
    @State private var adding: AddKind?
    /// The + first asks what to add (user requests 2026-11-16 and 2026-11-17): a transaction, a
    /// loan, or with AI. The same rows on every tab; the form opens once the small sheet has gone.
    @State private var isChoosingAdd = false
    @State private var pendingAdd: AddKind?
    @State private var addContext = AddTransactionContext()
    /// What "Thêm bằng AI" asked to open once it has gone: a form, or the chat.
    @State private var afterQuickRecord: QuickRecordNext?
    /// The chat opened from "Thêm bằng AI" with a question in its field.
    @State private var chatPrefill: ChatPrefill?
    @Environment(AppLock.self) private var appLock
    @Environment(FinanceStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    /// A tapped reminder waiting for the sheet on screen to close (`openFromReminder`).
    @State private var waitingForSheet: Task<Void, Never>?

    private enum AddKind: Identifiable, Hashable {
        case transaction, loan
        /// "Thêm bằng AI": the quick sheet that listens at once (user design 2026-11-17).
        case quickRecord
        /// What Milu cannot record yet, by hand, the amount said already in.
        case transfer(amount: Double?)
        case newLoan(LoanDirection, amount: Double?)
        var id: Self { self }
    }

    struct ChatPrefill: Identifiable {
        let id = UUID()
        let text: String
    }

    /// The rows of the small sheet the + opens, in a set order on every tab.
    private enum AddWay: CaseIterable {
        case transaction, loan, ai

        var option: SheetOption {
            switch self {
            case .transaction:
                SheetOption(icon: IconCatalog.emojiName("📝"), title: "Thêm giao dịch",
                            subtitle: "Chi tiêu, thu nhập, chuyển khoản")
            case .loan:
                SheetOption(icon: IconCatalog.emojiName("🤝"), title: "Thêm khoản vay",
                            subtitle: "Cho vay hoặc đi vay")
            case .ai:
                SheetOption(icon: IconCatalog.emojiName("✨"), title: "Thêm bằng AI",
                            subtitle: "Gõ hoặc nói một câu, Milu ghi giúp")
            }
        }

        /// What the row opens.
        var kind: AddKind {
            switch self {
            case .transaction: .transaction
            case .loan: .loan
            case .ai: .quickRecord
            }
        }
    }

    private func add() {
        isChoosingAdd = true
    }

    private func choose(_ option: SheetOption) {
        pendingAdd = AddWay.allCases.first { $0.option.title == option.title }?.kind
    }

    /// A tapped "Nhắc ghi chi tiêu", or a button on the widget, opens its form once nothing stands
    /// in its way: not under the Face ID lock (its keyboard came up over the lock, audit
    /// 2026-11-15), and not while another sheet is up (it could not open, and the tap was lost):
    /// then as that one closes. Gone with the app to the background.
    private func openFromReminder() {
        guard let action = Reminders.shared.router.pending, !appLock.isLocked else { return }
        let kind: AddKind
        switch action {
        case .addTransaction: kind = .transaction
        case .quickRecord: kind = .quickRecord
        case .overview, .budget, .recurring:
            // A page, not a form: Tổng quan at once, which opens Hạn mức chi tiêu, or a rule's
            // "Ghi", when asked.
            Reminders.shared.router.pending = nil
            selectedTab = .overview
            if action == .budget { Reminders.shared.router.opensBudget = true }
            if action == .recurring { Reminders.shared.router.opensRecurring = true }
            return
        }
        // The form asked for is the sheet up: the tap is answered already (audit round 2,
        // 2026-11-15: waited on, a second, empty form came up once it closed). The loan form is
        // not: it is waited on, as any other sheet.
        if adding == kind || (kind == .transaction && Reminders.shared.router.openAddForms > 0) {
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
        // A transaction (or "Thêm bằng AI"), whatever the + would add on the page behind: left on
        // "Vay nợ", it opened the loan form (audit round 3, 2026-11-16).
        present(kind)
    }

    /// "Thêm bằng AI" in the sheet the app draws (`BottomPanel`) rather than iOS's own: DEBUG
    /// `MILU_QUICK_PANEL=1`, to compare the two on an iPhone (trial 2026-11-19).
    private static var quickRecordInPanel: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["MILU_QUICK_PANEL"] != nil
        #else
        false
        #endif
    }

    /// What + adds, up. "Thêm bằng AI" in the app's own panel: its clear cover comes at once, the
    /// panel sliding in by itself, where iOS would slide the cover up too.
    private func present(_ kind: AddKind?) {
        var transaction = Transaction()
        transaction.disablesAnimations = kind == .quickRecord && Self.quickRecordInPanel
        withTransaction(transaction) { adding = kind }
    }

    /// The forms in iOS's sheet, "Thêm bằng AI" too; in the panel, it has its own
    /// (`quickRecordShown`).
    private var sheetAdding: Binding<AddKind?> {
        Binding(get: { adding == .quickRecord ? nil : adding }, set: { adding = $0 })
    }

    /// "Thêm bằng AI" in iOS's sheet, put up by UIKit (`QuickRecordController.present`).
    private var quickRecordInSheet: Binding<Bool> {
        Binding(get: { adding == .quickRecord && !Self.quickRecordInPanel },
                set: { if !$0, adding == .quickRecord { adding = nil } })
    }

    private var quickRecordShown: Binding<Bool> {
        Binding(get: { adding == .quickRecord && Self.quickRecordInPanel },
                set: { if !$0, adding == .quickRecord { adding = nil } })
    }

    /// The form or the chat "Thêm bằng AI" asked for, once it has gone (one sheet at a time).
    private func openAfterQuickRecord() {
        guard let next = afterQuickRecord else { return }
        afterQuickRecord = nil
        switch next {
        case .form(.transfer(let amount)): adding = .transfer(amount: amount)
        case .form(.loan(let direction, let amount)): adding = .newLoan(direction, amount: amount)
        case .chat(let text): chatPrefill = ChatPrefill(text: text)
        }
    }

    /// The +'s name for VoiceOver and the title of its small sheet.
    private static let addTitle = "Thêm mới"

    /// Picking the + opens the small "how to add" sheet and leaves the current tab where it is.
    /// `InstantTabSwitch` stops the tap before the tab is selected; this is the fallback should it
    /// get through.
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
                Reminders.shared.router.pending = nil
            }
            // The home-screen widget's summary, kept up to date (`WidgetSync`).
            .background { WidgetSync().frame(width: 0, height: 0) }
            #if DEBUG
            // MILU_DEMO: "Thêm bằng AI" opens by itself and runs through its steps
            // (`QuickRecordSheet.runDemo`), for `FrameLog` to measure on an iPhone.
            .task {
                guard ProcessInfo.processInfo.environment["MILU_DEMO"] != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                present(.quickRecord)
            }
            #endif
            .sheet(isPresented: $isChoosingAdd, onDismiss: {
                present(pendingAdd)
                pendingAdd = nil
            }) {
                OptionSheet(title: Self.addTitle, options: AddWay.allCases.map(\.option)) { choose($0) }
            }
            .sheet(item: sheetAdding, onDismiss: openAfterQuickRecord) { kind in
                switch kind {
                case .transaction: AddTransactionView(preferredAccount: addContext.accountID)
                // On the side "Vay nợ" shows, when it is the page behind; "Cho vay" elsewhere.
                case .loan: LoanEditorView(loan: nil,
                                           direction: addContext.addsLoan ? addContext.loanDirection : nil)
                case .quickRecord: EmptyView()
                case .transfer(let amount): AddTransactionView(mode: .transfer, amount: amount)
                case .newLoan(let direction, let amount): LoanEditorView(loan: nil, direction: direction, principal: amount)
                }
            }
            .background {
                QuickRecordPresenter(isPresented: quickRecordInSheet, store: store,
                                     onNext: { afterQuickRecord = $0 }, onDismiss: openAfterQuickRecord)
                    .frame(width: 0, height: 0)
            }
            .presentsPanel(isPresented: quickRecordShown, onDismiss: openAfterQuickRecord) {
                QuickRecordSheet { afterQuickRecord = $0 }
            }
            // The chat, opened from "Thêm bằng AI" with the question in its field, as the pages
            // open it (a cover of its own).
            .fullScreenCover(item: $chatPrefill) { prefill in
                NavigationStack { AssistantView(prefill: prefill.text) }
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
                .tabItem { Label(Self.addTitle, systemImage: "plus.circle.fill") }
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
            // Store: there, by the thumb on every tab, it adds (user choice 2026-10-29) a
            // transaction, a loan or with AI, picked in a small sheet (2026-11-17).
            // The + drawn Regular (user request 2026-11-05: the bar's default read bold); the
            // weight is set in the image itself, as the bar ignores SwiftUI's font weight.
            Tab(value: AppTab.add, role: .search) {
                Color.clear
            } label: {
                Label { Text(Self.addTitle) } icon: { Image(uiImage: Self.regularPlus) }
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
