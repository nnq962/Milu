import SwiftUI

struct SheetsPart: View {
    @State private var isShowingForm = false
    @State private var isShowingEdit = false
    @State private var isShowingOptions = false
    @State private var isShowingNote = false
    @State private var isShowingConfirm = false
    @State private var picked: String?

    var body: some View {
        PartSection(part: .sheets) {
            SampleCard(label: "Mở thử") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    TimiButton("Sheet form · Thêm tài khoản", role: .secondary, fullWidth: true) { isShowingForm = true }
                    TimiButton("Sheet form · Sửa tài khoản", role: .secondary, fullWidth: true) { isShowingEdit = true }
                    TimiButton("Sheet ngắn · OptionSheet", role: .secondary, fullWidth: true) { isShowingOptions = true }
                    TimiButton("Sheet ngắn có ✓ · SheetHeader", role: .secondary, fullWidth: true) { isShowingConfirm = true }
                    TimiButton("Ghi chú · NoteSheet", role: .secondary, fullWidth: true) { isShowingNote = true }
                    if let picked {
                        Text("Đã chọn: \(picked)")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                }
            }
            // The rule as it stands (strict review 2026-10-31: it still said a black ✓, grey when
            // something was missing).
            SampleCard(label: "Quy tắc") {
                Text("Như Lịch và Danh bạ của iOS: ✕ bên trái để huỷ, ✓ màu chính bên phải để lưu. ✓ luôn bấm được; thiếu thông tin thì dòng đó đỏ và nhóm báo lỗi đỏ. Không có chân sheet. Khi sửa mục đã có, dòng Xoá đỏ nằm cuối form. Sheet ngắn để chọn nhanh, chọn xong tự đóng.")
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
                SheetOption(icon: "hugeicons-money-02", title: "Tiền mặt"),
                SheetOption(icon: "hugeicons-bank", title: "Ngân hàng"),
                SheetOption(icon: "hugeicons-smart-phone-01", title: "Ví điện tử"),
                SheetOption(icon: "hugeicons-piggy-bank", title: "Hũ tiết kiệm", subtitle: "Để dành cho một mục tiêu", accent: true),
            ]) { picked = $0.title }
        }
        .sheet(isPresented: $isShowingNote) {
            NoteSheet(title: "Câu hỏi thường gặp", message: "Sắp có trong app.")
        }
        .sheet(isPresented: $isShowingConfirm) {
            SampleConfirmSheet { picked = $0 }
        }
    }
}

/// A short sheet that confirms with ✓ in its own header (`SheetHeader(onConfirm:)`).
private struct SampleConfirmSheet: View {
    let onDone: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var on = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: "Bộ lọc nhanh") {
                onDone(on ? "Chỉ tiền ra" : "Tất cả")
                dismiss()
            }
            FormGroup {
                FormToggleRow(title: "Chỉ tiền ra", isOn: $on)
            }
        }
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .background(Palette.background)
        .timiFittedSheet()
    }
}

/// What a real form sheet built from the system looks like; editing adds the red delete row.
/// ✓ is always on: with the name missing it turns the row red and says so (`validate:`).
struct SampleFormSheet: View {
    var isEditing = false

    @Environment(\.dismiss) private var dismiss
    @State private var balance = ""
    @State private var name = ""
    @State private var type = "Ngân hàng"
    @State private var locked = false
    @State private var showsErrors = false

    init(isEditing: Bool = false) {
        self.isEditing = isEditing
        if isEditing {
            _balance = State(initialValue: "14.119.000")
            _name = State(initialValue: "Vietcombank")
        }
    }

    private var nameError: String? {
        showsErrors && name.trimmingCharacters(in: .whitespaces).isEmpty ? "Nhập tên tài khoản." : nil
    }

    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return nameError == nil
    }

    var body: some View {
        SheetScaffold(title: isEditing ? "Sửa tài khoản" : "Thêm tài khoản",
                      validate: validate, onConfirm: { dismiss() }) {
            SheetAmountHeader(caption: "Số dư hiện tại", fieldSaysCaption: true) {
                TimiAmountField(text: $balance, label: "Số dư hiện tại")
            }
        } content: {
            FormGroup(title: "Thông tin", error: nameError) {
                FormTextRow(title: "Tên tài khoản", text: $name, prompt: "Bắt buộc", isInvalid: nameError != nil)
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Loại", selection: $type,
                              options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]) { $0 }
            }

            FormGroup(title: "Tuỳ chọn") {
                FormToggleRow(title: "Khoá tài khoản", isOn: $locked)
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
