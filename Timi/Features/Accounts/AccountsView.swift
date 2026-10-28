import SwiftUI

/// Pushes a goal's screen; its own type so it does not clash with `Account.ID` (both UUIDs).
struct GoalRoute: Hashable {
    let id: SavingsGoal.ID
}

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
                VStack(alignment: .leading, spacing: 20) {
                    totalCard
                    paymentSection
                    goalsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            // The title names the back button of pushed screens; the leading heading is the visible title.
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
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
            TimiIcon("hugeicons-add-circle", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Thêm tài khoản hoặc hũ")
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tổng số dư")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            Text(store.paymentBalance.vnd)
                .textRole(.display)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            Text(Self.summary(accounts: store.paymentAccounts.filter { !$0.excluded }.count,
                              goals: store.savingsGoals.count))
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .sleekCard(radius: CardCorners.extraLarge)
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
                                    subtitle: account.excluded ? "Không tính vào báo cáo" : nil,
                                    amount: account.balance)
                        }
                        .buttonStyle(.row)
                        // Sleek draws the hairline absolutely, so it adds no row height.
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .cardSurface(color: Palette.card, elevated: true)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Hũ tiết kiệm")
            if store.savingsGoals.isEmpty {
                EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa có hũ nào",
                               message: "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.")
            } else {
                goalCarousel
            }
        }
    }

    /// Goals side by side, scrolling sideways and settling on a card; each card is three fifths of
    /// the page so the next one peeks in. The cards run past the page margin while scrolling.
    private var goalCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.m) {
                ForEach(store.savingsGoals) { goal in
                    // Tapping opens the goal (deposit, withdraw, history); editing is in its toolbar.
                    NavigationLink(value: GoalRoute(id: goal.id)) { GoalCard(goal: goal) }
                        .buttonStyle(.card)
                        .containerRelativeFrame(.horizontal, count: 5, span: 3, spacing: Spacing.m)
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
    /// The line under Tổng số dư: only what exists is named.
    static func summary(accounts: Int, goals: Int) -> String {
        switch (accounts, goals) {
        case (0, 0): "Chưa có tài khoản nào"
        case (_, 0): "Gồm \(accounts) tài khoản"
        case (0, _): "Gồm \(goals) hũ tiết kiệm"
        default: "Gồm \(accounts) tài khoản và \(goals) hũ"
        }
    }

    /// What deleting an account also removes, said before it happens.
    static func deleteMessage(transactionCount: Int) -> String {
        transactionCount > 0
            ? "\(transactionCount) giao dịch của tài khoản này cũng bị xoá. Không thể hoàn tác."
            : "Không thể hoàn tác."
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
