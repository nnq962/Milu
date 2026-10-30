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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The layout being tried (`AccountsLayoutTrialRow`, Cài đặt → Nhà phát triển).
    @AppStorage(StorageKey.accountsLayout) private var layout = AccountsLayout.both
    /// Logos, icons and goal rings, growing with the text.
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 36

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
                // The total large on the page, the accounts as rows in one white block (fine for any
                // number of them), the goals as rings two to a row (user choice 2026-10-30).
                VStack(alignment: .leading, spacing: Spacing.xxxl) {
                    if layout.showsBalanceCard { BalanceCard() } else { totalHeader }
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
                if #unavailable(iOS 26.0) {
                    ToolbarItem(placement: .principal) { HiddenToolbarTitle() }
                    ToolbarItem(placement: .topBarLeading) { heading }
                }
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

    /// "Tổng số dư" large on the page: the total, how it moved this month, and how much is locked
    /// away.
    private var totalHeader: some View {
        // Money set aside: what is owed on a locked account is not "khoá" money.
        let lockedMoney = store.lockedPaymentAccounts.reduce(0) { $0 + max($1.balance, 0) }
        // Money in less money out on counted accounts since the 1st; moves between them, and
        // into goals, leave it as it was.
        let change = store.netWorthChange(since: DateInterval.month(of: .now).start)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tổng số dư")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
            Text(store.paymentBalance.vnd)
                .textRole(.display)
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            HStack(spacing: Spacing.m) {
                if change != 0 {
                    Text("\(change > 0 ? "↑" : "↓") \(abs(change).vndCompact) trong tháng này")
                        .textRole(.captionStrong)
                        .monospacedDigit()
                        .foregroundStyle(change > 0 ? Palette.green : Palette.red)
                }
                if lockedMoney > 0 {
                    HStack(spacing: Spacing.xs) {
                        TimiIcon("hugeicons-square-lock-02", size: 14)
                        Text("Đã khoá \(lockedMoney.vndCompact)")
                    }
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Accounts in order: cash → bank → e-wallet.
    private var accounts: [Account] {
        AccountType.paymentTypes.flatMap { store.accounts(of: $0) }
    }

    private var paymentSection: some View {
        let archived = store.archivedAccounts.count
        return VStack(alignment: .leading, spacing: Spacing.l) {
            // Not "Tài khoản" again under the page title of that name (HIG review 2026-10-30).
            sectionHeading("Ví & ngân hàng") {
                if archived > 0 {
                    NavigationLink(value: ArchivedAccountsRoute()) { quietLink("Lưu trữ (\(archived))") }
                        .accessibilityLabel("Tài khoản đã lưu trữ, \(archived)")
                }
            }
            if accounts.isEmpty {
                EmptyStateCard(icon: "hugeicons-wallet-01", title: "Chưa có tài khoản",
                               message: "Thêm tiền mặt, tài khoản ngân hàng hoặc ví để theo dõi số dư.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account.id) { accountRow(account) }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { rowDivider } }
                    }
                }
                .listCard()
            }
        }
    }

    /// The hairline between rows, from where the names start.
    private var rowDivider: some View {
        Palette.border.frame(height: 1)
            .padding(.leading, RowMetrics.horizontal + iconSize + Spacing.m)
    }

    /// An account in the white block: its logo or icon, the name, the balance in short form, ›.
    /// At the accessibility text sizes the balance goes under the name, which one row cut short.
    private func accountRow(_ account: Account) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.m))
        return HStack(spacing: Spacing.m) {
            // Every icon on the same white tile as the bank logos, so the column lines up (HIG
            // review 2026-10-30: the bare cash glyph sat apart from the tiled logos).
            AccountIconTile(name: account.iconName, size: iconSize)
                .overlay(alignment: .bottomTrailing) {
                    if account.isLocked { LockBadge().offset(x: 5, y: 5) }
                }
            layout {
                Text(account.name)
                    .textRole(.label)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                Text("\(account.balance < 0 ? "-" : "")\(abs(account.balance).vndCompact)")
                    .textRole(.label)
                    .monospacedDigit()
                    .foregroundStyle(account.isLocked ? Palette.secondaryText : account.balance < 0 ? Palette.red : Palette.ink)
            }
            // Stacked, the words take the row's width so every row starts at the same edge.
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            TimiIcon("hugeicons-arrow-right-01", size: 14)
                .foregroundStyle(Palette.secondary)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.s)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(account.name), \(account.balance.vnd)\(account.isLocked ? ", đã khoá" : "")")
    }

    private var goalsSection: some View {
        let completed = store.completedGoals.count
        return VStack(alignment: .leading, spacing: Spacing.l) {
            sectionHeading("Hũ tiết kiệm") {
                if completed > 0 {
                    NavigationLink(value: CompletedGoalsRoute()) { quietLink("Đã xong (\(completed))") }
                        .accessibilityLabel("Hũ đã hoàn thành, \(completed)")
                }
            }
            if store.activeGoals.isEmpty {
                // Every goal may be done already: then the empty card invites the next one.
                EmptyStateCard(icon: "hugeicons-piggy-bank",
                               title: store.completedGoals.isEmpty ? "Chưa có hũ nào" : "Chưa có hũ đang để dành",
                               message: "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.")
            } else if layout.showsGoalCarousel {
                // Kiểu B: tiles scrolling sideways, then "+ Hũ mới". Reaches to the screen's edges so
                // the next tile shows it can scroll.
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
            } else {
                // Rows in a white block like the accounts: one way of showing things on the page.
                VStack(spacing: 0) {
                    ForEach(Array(store.activeGoals.enumerated()), id: \.element.id) { index, goal in
                        // Tapping opens the goal (deposit, withdraw, history); editing is in its toolbar.
                        NavigationLink(value: GoalRoute(id: goal.id)) { GoalRow(goal: goal) }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { rowDivider } }
                    }
                }
                .listCard()
            }
        }
    }

    private func sectionHeading<Trailing: View>(_ title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textRole(.title)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            trailing()
        }
    }

    /// Small moss words with a chevron at the end of a heading: what is kept out of the way.
    private func quietLink(_ title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
            TimiIcon("hugeicons-arrow-right-01", size: 12)
        }
        .textRole(.captionStrong)
        .foregroundStyle(Palette.primary)
        .frame(minHeight: ControlHeight.regular)
        .contentShape(Rectangle())
        .padding(.vertical, -10)
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}

/// An account's icon on the same white tile as the bank and wallet logos (`InstitutionLogo`):
/// logos as they are, a glyph centred on the tile.
private struct AccountIconTile: View {
    let name: String
    let size: CGFloat

    var body: some View {
        if name.hasPrefix("Institutions/") {
            InstitutionLogo(image: name, size: size)
        } else {
            TimiIcon(name, size: size * 0.5)
                .foregroundStyle(Palette.ink)
                .frame(width: size, height: size)
                .background(Palette.card)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .strokeBorder(Palette.border, lineWidth: 0.5)
                }
                .accessibilityHidden(true)
        }
    }
}
