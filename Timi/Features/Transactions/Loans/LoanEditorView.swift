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
