import SwiftUI

struct SheetsPart: View {
    @State private var isShowingForm = false
    @State private var isShowingEdit = false
    @State private var isShowingOptions = false
    @State private var picked: String?

    var body: some View {
        PartSection(part: .sheets) {
            SampleCard(label: "Mở thử") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    TimiButton("Sheet form · Thêm tài khoản", role: .secondary, fullWidth: true) { isShowingForm = true }
                    TimiButton("Sheet form · Sửa tài khoản", role: .secondary, fullWidth: true) { isShowingEdit = true }
                    TimiButton("Sheet ngắn · Thêm mới", role: .secondary, fullWidth: true) { isShowingOptions = true }
                    if let picked {
                        Text("Đã chọn: \(picked)")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            SampleCard(label: "Quy tắc") {
                Text("Như Lịch và Danh bạ của iOS: ✕ bên trái để huỷ, ✓ đen bên phải để lưu (xám khi chưa đủ thông tin). Không có chân sheet. Khi sửa mục đã có, dòng Xoá đỏ nằm cuối form. Sheet ngắn để chọn nhanh, chọn xong tự đóng.")
                    .textRole(.body)
            }
        }
        .sheet(isPresented: $isShowingForm) {
            SampleFormSheet().timiSheetStyle()
        }
        .sheet(isPresented: $isShowingEdit) {
            SampleFormSheet(isEditing: true).timiSheetStyle()
        }
        .sheet(isPresented: $isShowingOptions) {
            OptionSheet(title: "Thêm mới", options: [
                SheetOption(icon: "solar-banknote-2-linear", title: "Tiền mặt"),
                SheetOption(icon: "solar-buildings-2-linear", title: "Ngân hàng"),
                SheetOption(icon: "solar-smartphone-linear", title: "Ví điện tử"),
                SheetOption(icon: "mdi-piggy-bank", title: "Hũ tiết kiệm", subtitle: "Để dành cho một mục tiêu", accent: true),
            ]) { picked = $0.title }
        }
    }
}

/// What a real form sheet built from the system looks like; editing adds the red delete row.
struct SampleFormSheet: View {
    var isEditing = false

    @Environment(\.dismiss) private var dismiss
    @State private var balance = ""
    @State private var name = ""
    @State private var type = "Ngân hàng"
    @State private var excluded = false

    init(isEditing: Bool = false) {
        self.isEditing = isEditing
        if isEditing {
            _balance = State(initialValue: "14.119.000")
            _name = State(initialValue: "Vietcombank")
        }
    }

    var body: some View {
        SheetScaffold(title: isEditing ? "Sửa tài khoản" : "Thêm tài khoản",
                      canConfirm: !name.trimmingCharacters(in: .whitespaces).isEmpty,
                      onConfirm: { dismiss() }) {
            VStack(spacing: Spacing.xs) {
                Text("Số dư hiện tại")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $balance)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            FormGroup {
                FormTextRow(title: "Tên tài khoản", text: $name, prompt: "Bắt buộc")
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Loại", selection: $type,
                              options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]) { $0 }
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Không tính vào báo cáo", isOn: $excluded)
            }

            if isEditing {
                FormGroup {
                    FormDestructiveRow(title: "Xoá tài khoản", question: "Xoá tài khoản “\(name)”?",
                                       message: "Giao dịch của tài khoản này cũng bị xoá.") { dismiss() }
                }
            }
        }
    }
}
