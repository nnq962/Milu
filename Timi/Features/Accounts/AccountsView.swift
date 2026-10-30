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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                VStack(alignment: .leading, spacing: Spacing.section) {
                    totalCard
                    paymentSection
                    goalsSection
                    moreEntries
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            // The title names the back button of pushed screens; the leading heading is the visible title.
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { HiddenToolbarTitle() }
                if #available(iOS 26.0, *) {
                    // Sleek: the heading sits on the same row as the + button.
                    ToolbarItem(placement: .topBarLeading) { heading }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) {
                        addMenu.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { heading }
                    ToolbarItem(placement: .topBarTrailing) { addMenu }
                }
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

    private var heading: some View {
        Text("Tài khoản")
            .textRole(.pageTitle)
            .foregroundStyle(Palette.ink)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
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

    /// "Tổng số dư" (style 1, user choice 2026-10-28): the total, a quiet line of what it holds,
    /// and, when some accounts are locked, a badge with how much is left out.
    private var totalCard: some View {
        let locked = store.lockedPaymentAccounts
        return SummaryCard(label: "Tổng số dư", amount: store.paymentBalance) {
            Text(Self.holdings(accounts: store.paymentAccounts.count - locked.count, goals: store.activeGoals.count,
                               locked: locked.count))
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .padding(.top, Spacing.xs)
            // Money set aside: what is owed on a locked account is not "khoá" money.
            let lockedMoney = locked.reduce(0) { $0 + max($1.balance, 0) }
            if lockedMoney > 0 {
                StatusBadge(text: "Đã khoá \(lockedMoney.vnd)",
                            icon: "hugeicons-square-lock-02")
                    .padding(.top, Spacing.m)
            }
        }
    }

    private var paymentSection: some View {
        // Each account is its own row, ordered cash → bank → e-wallet.
        let accounts = AccountType.paymentTypes.flatMap { store.accounts(of: $0) }
        return VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Tài khoản thanh toán")
            if accounts.isEmpty {
                EmptyStateCard(icon: "hugeicons-wallet-01", title: "Chưa có tài khoản",
                               message: "Thêm tiền mặt, tài khoản ngân hàng hoặc ví để theo dõi số dư.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account.id) {
                            ListRow(icon: account.iconName, title: account.name,
                                    subtitle: account.isLocked ? "Đã khoá" : nil,
                                    amount: account.balance, isLocked: account.isLocked)
                        }
                        .buttonStyle(.row)
                        // Sleek draws the hairline absolutely, so it adds no row height.
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Hũ tiết kiệm")
            if store.activeGoals.isEmpty {
                // Every goal may be done already: then the empty card invites the next one.
                EmptyStateCard(icon: "hugeicons-piggy-bank",
                               title: store.completedGoals.isEmpty ? "Chưa có hũ nào" : "Chưa có hũ đang để dành",
                               message: "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.")
            } else {
                goalCarousel
            }
        }
    }

    /// Rows into what is kept but out of the way: closed goals and archived accounts (user choice
    /// 2026-10-28 / 2026-10-29), each shown only when there is something in it.
    @ViewBuilder
    private var moreEntries: some View {
        let completed = store.completedGoals.count
        let archived = store.archivedAccounts.count
        if completed > 0 || archived > 0 {
            VStack(spacing: 0) {
                if completed > 0 {
                    NavigationLink(value: CompletedGoalsRoute()) {
                        NavigationRowLabel(title: "Hũ đã hoàn thành", icon: "hugeicons-checkmark-badge-01",
                                           value: "\(completed)", spokenValue: "\(completed) hũ")
                    }
                    .buttonStyle(.row)
                }
                if archived > 0 {
                    NavigationLink(value: ArchivedAccountsRoute()) {
                        NavigationRowLabel(title: "Tài khoản đã lưu trữ", icon: "hugeicons-archive-02",
                                           value: "\(archived)", spokenValue: "\(archived) tài khoản")
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if completed > 0 { FormDivider() } }
                }
            }
            .listCard()
        }
    }

    /// Goals side by side, scrolling sideways and settling on a card; each card is three fifths of
    /// the page so the next one peeks in. The cards run past the page margin while scrolling.
    private var goalCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.m) {
                ForEach(store.activeGoals) { goal in
                    // Tapping opens the goal (deposit, withdraw, history); editing is in its toolbar.
                    NavigationLink(value: GoalRoute(id: goal.id)) { GoalCard(goal: goal) }
                        .buttonStyle(.card)
                        // Full width at the largest text sizes, so nothing on the card is cut off.
                        .containerRelativeFrame(.horizontal, count: 5, span: dynamicTypeSize.isAccessibilitySize ? 5 : 3,
                                                spacing: Spacing.m)
                }
            }
            .scrollTargetLayout()
            // Room for the cards' shadow inside the scroll view.
            .padding(.vertical, Spacing.s)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
        .padding(.vertical, -Spacing.s)
    }
}

extension AccountsView {
    /// "3 tài khoản · 1 hũ", leaving out what there is none of.
    /// Nothing counted but some locked: "1 tài khoản đang khoá", not "Chưa có tài khoản nào".
    static func holdings(accounts: Int, goals: Int, locked: Int = 0) -> String {
        switch (accounts, goals) {
        case (0, 0): locked > 0 ? "\(locked) tài khoản đang khoá" : "Chưa có tài khoản nào"
        case (_, 0): "\(accounts) tài khoản"
        case (0, _): "\(goals) hũ"
        default: "\(accounts) tài khoản · \(goals) hũ"
        }
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
