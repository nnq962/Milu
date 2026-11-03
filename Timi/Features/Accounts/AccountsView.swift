import SwiftUI



struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isChoosingNew = false
    /// "Lưu trữ (n) ›" and "Đã xong (n) ›" open their lists in a sheet, as an account and a goal
    /// open (user choice 2026-11-01).
    @State private var isShowingArchived = false
    @State private var isShowingCompleted = false
    /// Picked in the "Thêm mới" sheet; its form opens once that sheet has gone.
    @State private var pendingNew: NewItem?
    @State private var newItem: NewItem?
    /// Trợ lý AI, from the ✦ on the bar, as on Tổng quan.
    @State private var isShowingAssistant = false

    /// What the + button can add.
    enum NewItem: String, Identifiable, CaseIterable {
        case cash, bank, eWallet, goal

        var id: Self { self }

        var option: SheetOption {
            switch self {
            case .cash: SheetOption(icon: "hugeicons-money-02", title: "Tiền mặt", subtitle: "Ví, két, tiền để ở nhà")
            case .bank: SheetOption(icon: "hugeicons-bank", title: "Tài khoản ngân hàng", subtitle: "Vietcombank, Techcombank, MB…")
            case .eWallet: SheetOption(icon: "hugeicons-smart-phone-01", title: "Ví điện tử", subtitle: "MoMo, ZaloPay, ShopeePay…")
            case .goal: SheetOption(icon: "hugeicons-piggy-bank", title: "Hũ tiết kiệm", subtitle: "Để dành cho một mục tiêu")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // No total at the head any more (user request 2026-11-03): the accounts as rows
                // in one block (fine for any number of them), the goals as jars filling up, three
                // to a row (user pick "C" 2026-11-03). Sections 28 apart, as on every tab.
                VStack(alignment: .leading, spacing: Spacing.section) {
                    paymentSection
                    goalsSection
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            // The plain page colour, as every tab (user reports 2026-11-03).
            .background(Palette.background)
            .foregroundStyle(Palette.label)
            .navigationTitle("Tài khoản")
            .modifier(TabHeading())
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // Plain buttons: the bar draws their glass, which then takes part in push and pop.
                // ✦ before +, as on Tổng quan; the spacer gives each its own glass.
                ToolbarItem(placement: .topBarTrailing) { assistantButton }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { addMenu }
            }
            .fullScreenCover(isPresented: $isShowingAssistant) {
                NavigationStack { AssistantView() }
                    .presentationBackground(Palette.background)
            }
            .sheet(isPresented: $isShowingArchived) { ArchivedAccountsSheet() }
            .sheet(isPresented: $isShowingCompleted) { CompletedGoalsSheet() }
            .sheet(isPresented: $isChoosingNew, onDismiss: {
                newItem = pendingNew
                pendingNew = nil
            }) {
                OptionSheet(title: "Thêm mới", options: NewItem.allCases.map(\.option)) { option in
                    pendingNew = NewItem.allCases.first { $0.option.title == option.title }
                }
            }
            .sheet(item: $newItem) { item in
                switch item {
                case .cash: AddAccountView(type: .cash)
                case .bank: AddAccountView(type: .bank)
                case .eWallet: AddAccountView(type: .eWallet)
                case .goal: GoalEditorView(goal: nil)
                }
            }
        }
    }

    private var assistantButton: some View {
        Button { isShowingAssistant = true } label: {
            TimiIcon("hugeicons-ai-magic", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hỏi Timi")
        .accessibilityHint("Mở trợ lý AI")
    }

    /// A bare + in the bar's glass circle (2026-11-03: the ringed ⊕ made two circles, one in the other).
    private var addMenu: some View {
        Button { isChoosingNew = true } label: {
            TimiIcon("hugeicons-add-01", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Thêm tài khoản hoặc hũ")
    }

    /// Accounts in order: cash → bank → e-wallet.
    private var accounts: [Account] {
        AccountType.paymentTypes.flatMap { store.accounts(of: $0) }
    }

    private var paymentSection: some View {
        let archived = store.archivedAccounts.count
        return HeaderCard(title: "Ví & ngân hàng") {
            // Not "Tài khoản" again under the page title of that name (HIG review 2026-10-30).
            if archived > 0 {
                Button { isShowingArchived = true } label: { HeaderLink(title: "Lưu trữ (\(archived))", opensPage: true) }
                    .headerLinkButton()
                    .accessibilityLabel("Tài khoản đã lưu trữ, \(archived)")
            }
        } content: {
            if accounts.isEmpty {
                EmptyStateCard(icon: "hugeicons-wallet-01", title: "Chưa có tài khoản",
                               message: "Tiền mặt, ngân hàng và ví sẽ hiện ở đây.", picture: "fluent-bank")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        AccountSheetLink(accountID: account.id) { AccountRow(account: account) }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                    }
                }
                .listCard()
            }
        }
    }

    private var goalsSection: some View {
        let completed = store.completedGoals.count
        return HeaderCard(title: "Hũ tiết kiệm") {
            if completed > 0 {
                Button { isShowingCompleted = true } label: { HeaderLink(title: "Đã xong (\(completed))", opensPage: true) }
                    .headerLinkButton()
                    .accessibilityLabel("Hũ đã hoàn thành, \(completed)")
            }
        } content: {
            if store.activeGoals.isEmpty {
                // Every goal may be done already: then the empty card invites the next one.
                EmptyStateCard(icon: "hugeicons-piggy-bank",
                               title: store.completedGoals.isEmpty ? "Chưa có hũ nào" : "Chưa có hũ đang để dành",
                               message: "Các hũ để dành sẽ hiện ở đây.", picture: "fluent-pig")
            } else {
                // Goals as jars filling up, three to a row, two at the largest text sizes (user
                // pick "C" 2026-11-03, after tiles scrolling sideways); a new one comes from the
                // + on the bar (the dashed "+ Hũ mới" tile went, user request 2026-11-03).
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m, alignment: .top),
                                         count: dynamicTypeSize.isAccessibilitySize ? 2 : 3),
                          spacing: Spacing.l) {
                    ForEach(store.activeGoals) { goal in
                        GoalSheetLink(goalID: goal.id) { GoalJarTile(goal: goal) }
                            .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, RowMetrics.horizontal)
                .padding(.top, Spacing.s)
                .padding(.bottom, RowMetrics.horizontal)
            }
        }
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
