import SwiftUI

/// Pushes a goal's screen; its own type so it does not clash with `Account.ID` (both UUIDs).
struct GoalRoute: Hashable {
    let id: SavingsGoal.ID
}

/// Pushes the list of goals that reached their target.
struct CompletedGoalsRoute: Hashable {}

/// Pushes the list of archived accounts.
struct ArchivedAccountsRoute: Hashable {}

struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var isChoosingNew = false
    /// Picked in the "Thêm mới" sheet; its form opens once that sheet has gone.
    @State private var pendingNew: NewItem?
    @State private var newItem: NewItem?

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
                // The total in a card with a bar of where the money is, the accounts as rows in one
                // white block (fine for any number of them), the goals as tiles scrolling sideways
                // (user choice 2026-10-30, "A + B" of the layouts tried). Sections 28 apart, as on
                // every tab.
                VStack(alignment: .leading, spacing: Spacing.section) {
                    BalanceCard()
                    paymentSection
                    goalsSection
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Tài khoản")
            .modifier(TabHeading())
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // A plain button: the bar draws its glass, which then takes part in push and pop.
                ToolbarItem(placement: .topBarTrailing) { addMenu }
            }
            .navigationDestination(for: Account.ID.self) { accountID in
                AccountDetailView(accountID: accountID)
            }
            .navigationDestination(for: GoalRoute.self) { route in
                GoalDetailView(goalID: route.id)
            }
            .navigationDestination(for: CompletedGoalsRoute.self) { _ in
                CompletedGoalsView()
            }
            .navigationDestination(for: ArchivedAccountsRoute.self) { _ in
                ArchivedAccountsView()
            }
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

    private var addMenu: some View {
        Button { isChoosingNew = true } label: {
            TimiIcon("hugeicons-add-circle", size: RowMetrics.toolbarGlyph)
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
        return VStack(alignment: .leading, spacing: Spacing.headerGap) {
            // Not "Tài khoản" again under the page title of that name (HIG review 2026-10-30).
            SectionHeader(title: "Ví & ngân hàng") {
                if archived > 0 {
                    NavigationLink(value: ArchivedAccountsRoute()) { HeaderCapsuleLabel(title: "Lưu trữ (\(archived))", opensPage: true) }
                        .headerCapsuleGlass()
                        .accessibilityLabel("Tài khoản đã lưu trữ, \(archived)")
                }
            }
            if accounts.isEmpty {
                EmptyStateCard(icon: "hugeicons-wallet-01", title: "Chưa có tài khoản",
                               message: "Tiền mặt, ngân hàng và ví sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account.id) { AccountRow(account: account) }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { AccountRowDivider() } }
                    }
                }
                .listCard()
            }
        }
    }

    private var goalsSection: some View {
        let completed = store.completedGoals.count
        return VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Hũ tiết kiệm") {
                if completed > 0 {
                    NavigationLink(value: CompletedGoalsRoute()) { HeaderCapsuleLabel(title: "Đã xong (\(completed))", opensPage: true) }
                        .headerCapsuleGlass()
                        .accessibilityLabel("Hũ đã hoàn thành, \(completed)")
                }
            }
            if store.activeGoals.isEmpty {
                // Every goal may be done already: then the empty card invites the next one.
                EmptyStateCard(icon: "hugeicons-piggy-bank",
                               title: store.completedGoals.isEmpty ? "Chưa có hũ nào" : "Chưa có hũ đang để dành",
                               message: "Các hũ để dành sẽ hiện ở đây.")
            } else {
                // Tiles scrolling sideways, then "+ Hũ mới". Reaches to the screen's edges so the
                // next tile shows it can scroll.
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: Spacing.m) {
                        ForEach(store.activeGoals) { goal in
                            NavigationLink(value: GoalRoute(id: goal.id)) { GoalCarouselTile(goal: goal) }
                                .buttonStyle(.card)
                        }
                        Button { newItem = .goal } label: { NewGoalTile() }
                            .buttonStyle(.card)
                            .accessibilityLabel("Thêm hũ tiết kiệm")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.page)
                    .padding(.vertical, Spacing.xs)
                }
                .scrollIndicators(.hidden)
                // Let the tiles' soft shadow show past the row's edges instead of being cut off.
                .scrollClipDisabled()
                .padding(.horizontal, -Spacing.page)
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
