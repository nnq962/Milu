import SwiftUI

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

    private var outstandingFooter: String {
        outstanding > principal
            ? "Số còn lại không được lớn hơn số tiền gốc."
            : "Để trống nếu chưa \(direction == .lent ? "thu" : "trả") đồng nào."
    }

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm khoản vay" : "Sửa khoản vay",
                      canConfirm: canSave, onConfirm: save) {
            Picker("Loại khoản vay", selection: $direction) {
                ForEach(LoanDirection.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            VStack(spacing: Spacing.xs) {
                Text("Số tiền gốc")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $principalText, focusesOnAppear: original == nil)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
        } content: {
            FormGroup(title: "Thông tin", footer: outstandingFooter) {
                FormTextRow(title: direction == .lent ? "Người vay" : "Người cho vay", text: $name,
                            prompt: direction == .lent ? "Minh Trần" : "Ngân hàng VCB")
                FormDivider(hasIcon: false)
                FormAmountRow(title: direction == .lent ? "Còn phải thu" : "Còn phải trả", text: $outstandingText)
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Có hạn trả", isOn: $hasDueDate)
                if hasDueDate {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Hạn trả", date: $dueDate)
                }
            }

            if let original {
                FormGroup {
                    if !original.isSettled {
                        Button {
                            outstandingText = "0"
                        } label: {
                            Text("Đánh dấu đã tất toán")
                                .textRole(.body)
                                .foregroundStyle(Palette.ink)
                                .formRowFrame()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.row)
                        FormDivider(hasIcon: false)
                    }
                    FormDestructiveRow(title: "Xoá khoản vay", question: "Xoá khoản vay “\(original.name)”?",
                                       message: "Khoản này sẽ không còn được tính vào cho vay hoặc nợ.") {
                        store.delete(original)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
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
