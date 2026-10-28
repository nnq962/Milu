//
//  LoansContent.swift
//  Timi
//

import SwiftUI

enum LoanFilter: String, CaseIterable, Identifiable {
    case all, lent, borrowed, settled

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        case .settled: "Đã tất toán"
        }
    }
}

/// "Vay nợ" tab of the Transactions screen.
struct LoansContent: View {
    @Environment(FinanceStore.self) private var store
    @Binding var filter: LoanFilter
    let searchText: String
    let onEdit: (Loan) -> Void

    private func matchesSearch(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }

    private var activeLoans: [Loan] {
        store.loans.filter { !$0.isSettled && matchesSearch($0.name) }
    }

    private var lentLoans: [Loan] { activeLoans.filter { $0.direction == .lent } }
    private var borrowedLoans: [Loan] { activeLoans.filter { $0.direction == .borrowed } }
    private var settledLoans: [Loan] { store.loans.filter { $0.isSettled && matchesSearch($0.name) } }

    /// Credit cards carrying a balance are shown as borrowing.
    private var cardDebts: [Account] {
        store.accounts.filter { $0.type == .credit && $0.balance < 0 && matchesSearch($0.name) }
    }

    var body: some View {
        summaryCard
        ChipRow(options: LoanFilter.allCases, selection: $filter) { $0.title }
        switch filter {
        case .all:
            attentionSection
            lentSection
            borrowedSection
        case .lent:
            lentSection
        case .borrowed:
            borrowedSection
        case .settled:
            settledSection
        }
    }

    // MARK: - Tổng quan

    private var summaryCard: some View {
        let net = store.totalLent - store.totalDebt
        let lenders = store.loans.filter { $0.direction == .lent && !$0.isSettled }.count
        let debts = store.accounts.filter { $0.type == .credit && $0.balance < 0 }.count
            + store.loans.filter { $0.direction == .borrowed && !$0.isSettled }.count
        return VStack(alignment: .leading, spacing: 4) {
            Text("Tổng cho vay trừ nợ")
                .font(Typography.font(.caption, size: 12, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16, relativeTo: .caption)
            Text(net.vnd)
                .font(Typography.font(.largeTitle, size: 34, weight: .heavy))
                .designLineHeight(42.5, relativeTo: .largeTitle)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            Text(net < 0 ? "Đang ở mức âm: bạn nợ nhiều hơn số đang cho vay"
                 : net > 0 ? "Đang ở mức dương: số đang cho vay nhiều hơn số bạn nợ"
                 : "Số đang cho vay bằng số bạn đang nợ")
                .font(Typography.font(.caption2, size: 11))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
            HStack(spacing: 12) {
                summaryTile("Đang cho vay", amount: store.totalLent.vndCompact, detail: "\(lenders) người",
                            color: Palette.ink, background: Palette.incomeTile)
                summaryTile("Đang nợ", amount: store.totalDebt.vndCompact, detail: "\(debts) khoản",
                            color: Palette.red, background: Palette.muted)
            }
            .padding(.top, 12)
        }
        .sleekCard()
    }

    private func summaryTile(_ title: String, amount: String, detail: String, color: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.font(.caption2, size: 11, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
            Text(amount)
                .font(Typography.font(.callout, size: 16, weight: .bold))
                .foregroundStyle(color)
                .designLineHeight(24, relativeTo: .callout)
                .monospacedDigit()
            Text(detail)
                .font(Typography.font(.caption2, size: 11))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: background)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cần chú ý

    @ViewBuilder
    private var attentionSection: some View {
        let reminders = store.paymentReminders
            .filter { matchesSearch($0.title) || matchesSearch($0.detail) }
            .sorted { $0.dueDate < $1.dueDate }
        if !reminders.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Cần chú ý") {
                    Text("\(reminders.count) sắp đến hạn")
                        .font(Typography.font(.caption2, size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Palette.muted, in: Capsule())
                }
                ForEach(reminders) { reminder in
                    HStack(spacing: 12) {
                        switch reminder.avatar {
                        case .initials(let name): InitialsAvatar(name: name)
                        case .icon(let icon): IconCircle(icon: icon)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(reminder.title)
                                .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                                .designLineHeight(20, relativeTo: .subheadline)
                                .lineLimit(1)
                            Text(reminder.detail)
                                .font(Typography.font(.caption2, size: 11))
                                .foregroundStyle(Palette.secondaryText)
                                .designLineHeight(16.5, relativeTo: .caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vnd)")
                                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                                .foregroundStyle(reminder.isIncome ? Palette.ink : Palette.red)
                                .designLineHeight(20, relativeTo: .subheadline)
                                .monospacedDigit()
                            Text("Hạn \(reminder.dueDate.dayMonth)")
                                .font(Typography.font(.caption2, size: 11))
                                .foregroundStyle(Palette.secondaryText)
                                .designLineHeight(16.5, relativeTo: .caption2)
                        }
                    }
                    .padding(17)
                    // Bordered, shadowless card; the 1pt border sits inside like CSS.
                    .background {
                        RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
                            .fill(Palette.card)
                            .strokeBorder(Palette.border, lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Cho vay / Đi vay / Đã tất toán

    private var lentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cho vay") { remainingLabel(lentLoans.reduce(0) { $0 + $1.outstanding }) }
            if lentLoans.isEmpty {
                EmptyStateCard(icon: "solar-hand-money-linear", title: "Chưa có khoản cho vay",
                               message: "Nhấn + để ghi lại số tiền bạn cho người khác vay.")
            }
            ForEach(lentLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var borrowedSection: some View {
        let total = cardDebts.reduce(0) { $0 - $1.balance } + borrowedLoans.reduce(0) { $0 + $1.outstanding }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Đi vay") { remainingLabel(total) }
            if cardDebts.isEmpty && borrowedLoans.isEmpty {
                EmptyStateCard(icon: "solar-card-linear", title: "Chưa có khoản đi vay",
                               message: "Dư nợ thẻ tín dụng và các khoản bạn vay sẽ hiện ở đây.")
            }
            ForEach(cardDebts) { card in
                NavigationLink(value: card.id) { CreditCardDebtCard(card: card) }
                    .buttonStyle(.plain)
            }
            ForEach(borrowedLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Đã tất toán")
            if settledLoans.isEmpty {
                EmptyStateCard(icon: "solar-check-read-linear", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ được lưu ở đây.")
            }
            ForEach(settledLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func remainingLabel(_ amount: Double) -> some View {
        Text("Còn \(amount.vndCompact)")
            .font(Typography.font(.caption2, size: 11, weight: .semibold))
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
    }
}

/// Loan card: who, due date, principal and repayment progress.
private struct LoanCard: View {
    let loan: Loan

    var body: some View {
        let borrowed = loan.direction == .borrowed
        DebtCardLayout(
            avatar: { InitialsAvatar(name: loan.name) },
            title: loan.name,
            subtitle: loan.isSettled ? "\(loan.direction.title) · Đã tất toán" : loan.dueDate?.dueDescription ?? "Không có hạn trả",
            amount: loan.principal.vndCompact,
            amountColor: borrowed ? Palette.red : Palette.ink,
            progress: loan.paidRatio,
            progressColor: borrowed ? Palette.red : Palette.lime,
            leading: loan.isSettled ? "Đã trả đủ" : loan.paidRatio > 0 ? "Đã trả \(loan.paidRatio.percentText)" : "Chưa trả",
            trailing: "Còn \(loan.outstanding.vndCompact)"
        )
        .accessibilityHint("Sửa khoản vay")
    }
}

/// A credit card balance shown as borrowing; progress is the share of the limit in use.
private struct CreditCardDebtCard: View {
    let card: Account

    var body: some View {
        let debt = -card.balance
        let limit = card.creditLimit ?? 0
        let used = limit > 0 ? debt / limit : 0
        DebtCardLayout(
            avatar: { IconCircle(icon: card.type.icon) },
            title: card.name,
            subtitle: card.paymentDueDate?.dueDescription ?? card.detail,
            amount: debt.vndCompact,
            amountColor: Palette.red,
            progress: used,
            progressColor: Palette.red,
            leading: limit > 0 ? "Đã dùng \(used.percentText) hạn mức" : "Chưa đặt hạn mức",
            trailing: limit > 0 ? "Còn hạn mức \(max(limit - debt, 0).vndCompact)" : ""
        )
    }
}

private struct DebtCardLayout<Avatar: View>: View {
    @ViewBuilder let avatar: Avatar
    let title: String
    let subtitle: String
    let amount: String
    let amountColor: Color
    let progress: Double
    let progressColor: Color
    let leading: String
    let trailing: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                avatar
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                        .designLineHeight(20, relativeTo: .subheadline)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(Typography.font(.caption2, size: 11))
                        .foregroundStyle(Palette.secondaryText)
                        .designLineHeight(16.5, relativeTo: .caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(amount)
                    .font(Typography.font(.subheadline, size: 14, weight: .bold))
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
            }
            ProgressBar(value: progress, color: progressColor)
                .padding(.top, 16)
            HStack {
                Text(leading)
                Spacer()
                Text(trailing)
            }
            .font(Typography.font(.caption2, size: 11, weight: .medium))
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            .designLineHeight(16.5, relativeTo: .caption2)
            .padding(.top, 8)
        }
        .sleekCard(padding: 16)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Form

/// Creates a loan when `loan` is nil, otherwise edits, settles or deletes it.
struct LoanEditorView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: Loan?
    @State private var direction: LoanDirection
    @State private var name: String
    @State private var principalText: String
    @State private var outstandingText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isConfirmingDelete = false

    init(loan: Loan?) {
        original = loan
        _direction = State(initialValue: loan?.direction ?? .lent)
        _name = State(initialValue: loan?.name ?? "")
        _principalText = State(initialValue: loan.map { String(Int($0.principal)).groupedVNDInput } ?? "")
        _outstandingText = State(initialValue: loan.map { String(Int($0.outstanding)).groupedVNDInput } ?? "")
        _hasDueDate = State(initialValue: loan?.dueDate != nil || loan == nil)
        _dueDate = State(initialValue: loan?.dueDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var principal: Double { principalText.vndInputAmount }
    /// Empty "còn lại" means nothing has been repaid yet.
    private var outstanding: Double { outstandingText.isEmpty ? principal : outstandingText.vndInputAmount }
    private var canSave: Bool { !trimmedName.isEmpty && principal > 0 && outstanding <= principal }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại khoản vay", selection: $direction) {
                        ForEach(LoanDirection.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    TextField(direction == .lent ? "Người vay (VD: Minh Trần)" : "Người cho vay (VD: Ngân hàng VCB)", text: $name)
                    Toggle("Có hạn trả", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Hạn trả", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Số tiền gốc") {
                    AmountField(text: $principalText)
                }

                Section {
                    AmountField(text: $outstandingText)
                } header: {
                    Text(direction == .lent ? "Còn phải thu" : "Còn phải trả")
                } footer: {
                    if outstanding > principal {
                        Text("Số còn lại không được lớn hơn số tiền gốc.")
                            .foregroundStyle(Palette.red)
                    } else {
                        Text("Để trống nếu chưa \(direction == .lent ? "thu" : "trả") đồng nào.")
                    }
                }

                if let original {
                    Section {
                        if !original.isSettled {
                            Button("Đánh dấu đã tất toán") { outstandingText = "0" }
                        }
                        Button("Xoá khoản vay", role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .navigationTitle(original == nil ? "Thêm khoản vay" : "Sửa khoản vay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Xoá khoản vay “\(trimmedName)”?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Xoá khoản vay", role: .destructive) {
                    if let original { store.delete(original) }
                    dismiss()
                }
            } message: {
                Text("Khoản này sẽ không còn được tính vào cho vay hoặc nợ.")
            }
        }
    }

    private func save() {
        guard canSave else { return }
        var loan = original ?? Loan(name: trimmedName, direction: direction, principal: 0, outstanding: 0, dueDate: nil)
        loan.name = trimmedName
        loan.direction = direction
        loan.principal = principal
        loan.outstanding = outstanding
        loan.dueDate = hasDueDate ? dueDate : nil
        store.save(loan)
        dismiss()
    }
}

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
