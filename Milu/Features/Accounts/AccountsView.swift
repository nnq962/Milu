import SwiftUI



struct AccountsView: View {
    @Environment(FinanceStore.self) private var store
    /// Than in Rive on the head (2026-11-13).
    private let than = MiluRiveCharacter.accounts
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isChoosingNew = false
    /// "Lưu trữ (n) ›" and "Đã xong (n) ›" open their lists in a sheet, as an account and a goal
    /// open (user choice 2026-11-01).
    @State private var isShowingArchived = false
    @State private var isShowingCompleted = false
    /// Both lists at once, when there are archived wallets and closed goals.
    @State private var isShowingArchiveAndDone = false
    /// Picked in the "Thêm mới" sheet; its form opens once that sheet has gone.
    @State private var pendingNew: NewItem?
    @State private var newItem: NewItem?
    /// Trợ lý AI, from the ✦ on the bar, as on Tổng quan.
    @State private var isShowingAssistant = false
    @State private var isShowingSettings = false

    /// What the + button can add.
    enum NewItem: String, Identifiable, CaseIterable {
        case cash, bank, eWallet, goal

        var id: Self { self }

        var option: SheetOption {
            switch self {
            case .cash: SheetOption(icon: IconCatalog.emojiName("💵"), title: "Tiền mặt", subtitle: "Ví, két, tiền để ở nhà")
            case .bank: SheetOption(icon: IconCatalog.emojiName("🏦"), title: "Tài khoản ngân hàng", subtitle: "Vietcombank, Techcombank, MB…")
            case .eWallet: SheetOption(icon: IconCatalog.emojiName("📱"), title: "Ví điện tử", subtitle: "MoMo, ZaloPay, ShopeePay…")
            case .goal: SheetOption(icon: IconCatalog.emojiName("🫙"), title: "Hũ tiết kiệm", subtitle: "Để dành cho một mục tiêu")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Milu's Sổ ví (Figma 79:1330, 54:789, 54:920): the sky with Milu and "Sổ ví của
                // bạn", then "Ví & ngân hàng" as rows in one card and "Hũ tiết kiệm" as glass jars,
                // three to a row; each part an empty card until it has something. Parts 28
                // apart, 24 under the sky.
                VStack(alignment: .leading, spacing: 0) {
                    SkyHeader(overline: "Milu giữ ví", title: "Sổ ví của bạn", milu: miluLook,
                              rive: (than, .accounts(store)),
                              sky: .pond)
                    VStack(alignment: .leading, spacing: Spacing.section) {
                        paymentSection
                        goalsSection
                        archiveRow
                    }
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.xxl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .onScrollMoved { than.nudge() }
            .pageBackground()
            .foregroundStyle(Palette.label)
            // No title on the bar: Q on the left opens Cài đặt; no wordmark (user request
            // 2026-11-07). The title stays for VoiceOver and the back button.
            .modifier(HiddenTitleBar(title: "Tài khoản", leadingCircles: 1, trailingCircles: 2,
                                     trailingWidth: AssistantBarButton.width + Spacing.s + ControlHeight.regular) {
                // An empty slot, not EmptyView: with nothing there, iOS shows the title.
                Color.clear.frame(height: 1).accessibilityHidden(true)
            })
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // Plain buttons: the bar draws their glass, which then takes part in push and pop.
                // ✦ before +, as on Tổng quan; the spacer gives each its own glass.
                ToolbarItem(placement: .topBarLeading) { ProfileBarButton { isShowingSettings = true } }
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
            .sheet(isPresented: $isShowingSettings) { SettingsView() }
            .sheet(isPresented: $isShowingArchived) { ArchivedAccountsSheet() }
            .sheet(isPresented: $isShowingCompleted) { CompletedGoalsSheet() }
            .sheet(isPresented: $isShowingArchiveAndDone) { ArchiveAndDoneSheet() }
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
        AssistantBarButton { isShowingAssistant = true }
    }

    /// A bare + in the bar's glass circle: opens the choice of what to add (Milu: the + of the
    /// Tài khoản bar adds a wallet or a goal; the + by the tab bar records a transaction).
    private var addMenu: some View {
        Button { isChoosingNew = true } label: {
            BarSymbol("plus")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.deep)
        .accessibilityLabel("Thêm ví hoặc hũ")
        // A bar keeps its size at every text size; a long press shows the glyph large instead (HIG).
        .accessibilityShowsLargeContentViewer {
            Label("Thêm ví hoặc hũ", systemImage: "plus")
        }
    }

    /// How far the page has come, read from what is on it, so Milu looks the same every time the
    /// tab opens (user request 2026-11-05: happy only for a moment after the first wallet, then
    /// back at rest on the next visit): curious with no wallet, happy with wallets but no jar yet,
    /// at rest once there are both.
    private enum Mood { case curious, happy, atRest }

    private var mood: Mood {
        if accounts.isEmpty { return .curious }
        return store.activeGoals.isEmpty ? .happy : .atRest
    }

    private var miluLook: MiluHero.Look {
        switch mood {
        case .curious: .toMo
        case .happy: .vui
        case .atRest: .nguyenBan
        }
    }

    /// Accounts in order: cash → bank → e-wallet.
    private var accounts: [Account] {
        AccountType.paymentTypes.flatMap { store.accounts(of: $0) }
    }

    private var paymentSection: some View {
        PageSection(title: "Ví & ngân hàng") {
            if accounts.isEmpty {
                EmptyNoteCard(emoji: "👝", title: "Chưa có tài khoản",
                              message: "Số dư ví và tài khoản của bạn sẽ hiện ở đây.")
                    .transition(.emptySwap)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        AccountSheetLink(accountID: account.id) { WalletRow(account: account) }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { LedgerDivider() } }
                    }
                }
                .cardSurface(radius: CardCorners.card)
                .transition(.emptySwap)
            }
        }
    }

    private var goalsSection: some View {
        let completed = store.completedGoals.count
        // Three jars to a row up to Large, one a row from XL (saved and target no longer fit a
        // third of the page). Two a row from XL to AX2 left an odd jar alone beside a gap, as
        // the wallets' two-column grid did on 2026-10-30 (review 2026-11-06).
        let columns = dynamicTypeSize >= GoalJar.oneColumnFrom ? 1 : 3
        return PageSection(title: "Hũ tiết kiệm") {
            if store.activeGoals.isEmpty {
                // Every goal may be done already: then the empty card says none is on its way.
                EmptyNoteCard(emoji: "🫙",
                              title: completed == 0 ? "Chưa có hũ tiết kiệm" : "Chưa có hũ đang góp",
                              message: "Mỗi hũ giúp bạn để dành cho một mục tiêu.")
                    .transition(.emptySwap)
            } else {
                // Jars three to a row, 10 apart; one a row from XL
                // (Milu: a grid goes to fewer columns when names or figures no longer fit).
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: WalletRow.gap, alignment: .top),
                                         count: columns),
                          spacing: WalletRow.gap) {
                    ForEach(Array(store.activeGoals.enumerated()), id: \.element.id) { index, goal in
                        GoalSheetLink(goalID: goal.id) {
                            GoalJar(goal: goal, water: Palette.jarWater(at: index))
                        }
                        .buttonStyle(.card)
                    }
                }
                .transition(.emptySwap)
            }
        }
    }

    /// The way in to what is put away, after the goals, one row for both (Milu "Tài khoản / Lối
    /// vào lưu trữ và hoàn thành", Figma 137:1741, 2026-11-05): hidden when both are empty; with
    /// one kind only, its name and count, opening its list straight away; with both, "Lưu trữ &
    /// hoàn thành" and the counts under it, opening both lists in one sheet.
    @ViewBuilder
    private var archiveRow: some View {
        let archived = store.archivedAccounts.count
        let completed = store.completedGoals.count
        if archived > 0 || completed > 0 {
            Button {
                if archived > 0 && completed > 0 { isShowingArchiveAndDone = true }
                else if archived > 0 { isShowingArchived = true }
                else { isShowingCompleted = true }
            } label: {
                if archived > 0 && completed > 0 {
                    ArchiveEntryRow(title: "Lưu trữ & hoàn thành",
                                    detail: "\(archived) tài khoản · \(completed) hũ")
                } else if archived > 0 {
                    ArchiveEntryRow(title: "Tài khoản đã lưu trữ", count: archived, unit: "tài khoản")
                } else {
                    ArchiveEntryRow(title: "Hũ đã hoàn thành", count: completed, unit: "hũ")
                }
            }
            .buttonStyle(.card)
        }
    }
}

/// One row on the page, a card of its own: 🗂️, the name of what it opens and
/// either the counts of both kinds under it or one count at its end, then ›. 68 tall with the
/// line under, 52 with one count (Figma 137:1708, 137:1719).
private struct ArchiveEntryRow: View {
    let title: String
    var detail: String? = nil
    var count: Int? = nil
    /// What `count` counts, for VoiceOver: "2 tài khoản", not a bare "2".
    var unit: String = ""

    @ScaledMetric(relativeTo: .body) private var column = WalletRow.logo
    /// With its second line, 68 tall (Figma 137:1741).
    private static let twoLineHeight: CGFloat = 68

    var body: some View {
        // The columns of the wallet rows above (`WalletRow`): the mark in a 32 column 12 in, the
        // words 10 after it, the › 14 from the edge (HIG review 2026-11-05: at Figma's 3 and 5
        // the box and › stood out of line with the rows above).
        // One line: on the words' baseline, the picture on their middle (review 2026-11-07).
        HStack(alignment: detail == nil ? .firstTextBaseline : .center, spacing: WalletRow.gap) {
            // 🗂️ in its own colours (user request 2026-11-05, in place of Figma's line box).
            // Grows with the text no further than 1.6 times (HIG review 2026-11-05: free, it
            // reached ~60 at AX5 and took a third of the row).
            Image(IconCatalog.emojiName("🗂️"))
                .resizable()
                .scaledToFit()
                // 32, the wallets' mark exactly (user request 2026-11-05: one icon size down the page).
                .frame(width: RowMetrics.capped(column, base: WalletRow.logo),
                       height: RowMetrics.capped(column, base: WalletRow.logo))
                .accessibilityHidden(true)
                .centeredOnTextLine()
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // A row's name, as the wallets' above it (`LedgerRow`, review 2026-11-07).
                Text(title)
                    .textRole(.bodyStrong)
                    .foregroundStyle(Palette.label)
                if let detail {
                    Text(detail)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let count {
                Text("\(count)")
                    .textRole(.captionStrong)
                    .monospacedDigit()
                    .foregroundStyle(Palette.secondaryLabel)
            }
            RowChevron()
        }
        .padding(.leading, Spacing.m)
        .padding(.trailing, WalletRow.trailing)
        .padding(.vertical, Spacing.m)
        .frame(minHeight: detail == nil ? RowMetrics.minHeight : Self.twoLineHeight)
        // A card of its own, as the wallets' (user request 2026-11-05: an option with an
        // outline, no hairline over it).
        .cardSurface(radius: CardCorners.card)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, detail ?? count.map { "\($0) \(unit)" }].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Mở danh sách")
        .accessibilityAddTraits(.isButton)
    }
}

/// Both lists put away in one sheet when there are archived wallets and closed goals: the two
/// lists one after the other, each under its name (Figma 136:1665). Each row slides its own page
/// over the list, ‹ back to it.
struct ArchiveAndDoneSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // A list whose last item went back (restored, reopened) goes with its heading, not
            // left as a heading over an empty card (review 2026-11-06); with both gone the sheet
            // closes. The page of every sheet (`SheetPage`, review 2026-11-07).
            SheetPage(title: "Lưu trữ & hoàn thành", showsClose: true, canEdit: false, onEdit: {}) {
                if !store.archivedAccounts.isEmpty {
                    ArchivedAccountsList(title: "Tài khoản đã lưu trữ")
                }
                if !store.completedGoals.isEmpty {
                    CompletedGoalsList(title: "Hũ đã hoàn thành")
                }
            }
            .onChange(of: store.archivedAccounts.isEmpty && store.completedGoals.isEmpty) { _, empty in
                if empty { dismiss() }
            }
        }
        // Half height first, as short lists usually are; drag up for the rest (HIG: size a sheet
        // to its content; at full height two rows sat on an empty page, review 2026-11-05).
        .miluSheetStyle([.medium, .large])
    }
}

#Preview {
    AccountsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
