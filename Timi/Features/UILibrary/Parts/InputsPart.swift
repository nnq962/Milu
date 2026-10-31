import SwiftUI

struct InputsPart: View {
    @State private var amount = ""
    @State private var expense = "60.000"
    @State private var iosName = "Vietcombank"
    @State private var iosNumber = ""
    @State private var iosOwner = ""
    @State private var iosNote = ""
    @State private var showsError = false
    @State private var errorName = ""
    @State private var search = ""
    @FocusState private var isSearching: Bool

    var body: some View {
        PartSection(part: .inputs) {
            // No footers: in the app a footer carries only a computed figure or an error.
            FormGroup(title: "Mặc định · FormTextRow") {
                FormTextRow(title: "Tên", text: $iosName, prompt: "Bắt buộc")
                FormDivider(hasIcon: false)
                FormTextRow(title: "Số tài khoản", text: $iosNumber, prompt: "Không bắt buộc", keyboard: .numberPad)
                FormDivider(hasIcon: false)
                FormTextRow(title: "Chủ tài khoản", text: $iosOwner, prompt: "Không bắt buộc")
            }
            // No "with icon" sample: a text field never has one (re-review 2026-10-31).
            FormGroup(title: "Ghi chú · FormNoteRow") {
                FormNoteRow(text: $iosNote, prompt: "Ghi chú")
            }
            // ✓ stays on; tapping it with a field missing turns the row red and says what to fix.
            FormGroup(title: "Báo lỗi · error, isInvalid", error: showsError ? "Nhập tên." : nil) {
                FormTextRow(title: "Tên", text: $errorName, prompt: "Bắt buộc", isInvalid: showsError)
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Hiện lỗi", isOn: $showsError.animation(.smooth(duration: 0.3)))
            }
            // Read-only rows of a detail sheet: words grey, money always a MoneyText.
            FormGroup(title: "Chỉ xem · FormInfoRow, FormAmountInfoRow") {
                FormInfoRow(title: "Tài khoản", value: "Vietcombank", valueIcon: "Institutions/vietcombank")
                FormDivider(hasIcon: false)
                FormAmountInfoRow(title: "Tiền gốc", amount: 5_000_000)
                FormDivider(hasIcon: false)
                FormAmountInfoRow(title: "Phí chuyển", amount: 5_000, tone: .signedExpense)
            }
            SampleCard(label: "Tìm kiếm · SearchField") {
                SearchField(prompt: "Tìm giao dịch", text: $search, isFocused: $isSearching)
            }
            SampleCard(label: "Số tiền lớn · TimiAmountField") {
                VStack(spacing: Spacing.xxl) {
                    TimiAmountField(text: $amount)
                    TimiAmountField(text: $expense, kind: .expense, showsSuggestions: false)
                }
            }
        }
    }
}
