import SwiftUI

struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var isChoosingNew = false
    /// Picked in the "Thêm mới" sheet; its form opens once that sheet has gone.
    @State private var pendingNew: NewItem?
    @State private var newItem: NewItem?
    @State private var editingGoal: SavingsGoal?
    @State private var deletingAccount: Account?

    /// What the + button can add.
    enum NewItem: String, Identifiable, CaseIterable {
        case cash, bank, eWallet, goal

        var id: Self { self }

        var option: SheetOption {
            switch self {
            case .cash: SheetOption(icon: "solar-banknote-2-linear", title: "Tiền mặt", subtitle: "Ví, két, tiền để ở nhà")
            case .bank: SheetOption(icon: "solar-buildings-2-linear", title: "Tài khoản ngân hàng", subtitle: "Vietcombank, Techcombank, MB…")
            case .eWallet: SheetOption(icon: "solar-smartphone-linear", title: "Ví điện tử", subtitle: "MoMo, ZaloPay, ShopeePay…")
            case .goal: SheetOption(icon: "mdi-piggy-bank", title: "Hũ tiết kiệm", subtitle: "Để dành cho một mục tiêu")
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
            .sheet(item: $editingGoal) { goal in GoalEditorView(goal: goal) }
            .confirmationDialog("Xoá tài khoản “\(deletingAccount?.name ?? "")”?",
                                isPresented: Binding { deletingAccount != nil } set: { if !$0 { deletingAccount = nil } },
                                titleVisibility: .visible, presenting: deletingAccount) { account in
                Button("Xoá tài khoản", role: .destructive) {
                    Haptics.warning()
                    store.delete(account)
                }
            } message: { account in
                Text(Self.deleteMessage(transactionCount: store.accountTransactions(account).count))
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
            SolarIcon("solar-add-circle-linear", size: 20)
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
            Text("Gồm \(store.paymentAccounts.filter { !$0.excluded }.count) tài khoản và \(store.savingsGoals.count) hũ")
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
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tài khoản thanh toán")
            if accounts.isEmpty {
                EmptyStateCard(icon: "solar-wallet-linear", title: "Chưa có tài khoản",
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
                        .contextMenu {
                            Button(role: .destructive) { deletingAccount = account } label: {
                                Label("Xoá tài khoản", systemImage: "trash")
                            }
                        }
                        // Sleek draws the hairline absolutely, so it adds no row height.
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .cardSurface(color: Palette.card, elevated: true)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Hũ tiết kiệm")
            if store.savingsGoals.isEmpty {
                EmptyStateCard(icon: "mdi-piggy-bank", title: "Chưa có hũ nào",
                               message: "Để dành cho chuyến đi, chiếc xe hay quỹ dự phòng, mỗi mục tiêu một hũ.")
            } else {
                goalGrid
            }
        }
    }

    private var goalGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible(), spacing: Spacing.m)],
                  spacing: Spacing.m) {
            ForEach(store.savingsGoals) { goal in
                Button { editingGoal = goal } label: { GoalTile(goal: goal) }
                    .buttonStyle(.card)
            }
        }
    }
}


extension AccountsView {
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
