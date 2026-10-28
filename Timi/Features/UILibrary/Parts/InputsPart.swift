import SwiftUI

struct InputsPart: View {
    @State private var amount = ""
    @State private var expense = "60.000"
    @State private var iosName = "Vietcombank"
    @State private var iosNumber = ""
    @State private var iosOwner = ""
    @State private var iosNote = ""

    var body: some View {
        PartSection(part: .inputs) {
            FormGroup(title: "Mặc định · FormTextRow",
                      footer: "Nhãn bên trái, giá trị gõ bên phải, các ô chung một thẻ như Danh bạ và Cài đặt của iOS. Ô nhập không kèm icon.") {
                FormTextRow(title: "Tên", text: $iosName, prompt: "Bắt buộc")
                FormDivider(hasIcon: false)
                FormTextRow(title: "Số tài khoản", text: $iosNumber, prompt: "Không bắt buộc", keyboard: .numberPad)
                FormDivider(hasIcon: false)
                FormTextRow(title: "Chủ tài khoản", text: $iosOwner, prompt: "Không bắt buộc")
            }
            FormGroup(title: "Có icon · không khuyên dùng cho ô nhập",
                      footer: "Icon hợp với dòng chọn và dòng mở trang; ở ô nhập nó lặp lại điều nhãn đã nói.") {
                FormTextRow(title: "Ngân hàng", text: $iosName, prompt: "Bắt buộc", icon: "solar-buildings-2-linear")
                FormDivider()
                FormTextRow(title: "Số thẻ", text: $iosNumber, prompt: "•••• 4821", icon: "solar-card-linear",
                            keyboard: .numberPad)
                FormDivider(hasIcon: false)
                FormNoteRow(text: $iosNote, prompt: "Ghi chú")
            }
            SampleCard(label: "Số tiền lớn · TimiAmountField") {
                VStack(spacing: Spacing.xxl) {
                    TimiAmountField(text: $amount)
                    Text("Gõ 3 để thấy gợi ý 3.000đ, 30.000đ, 300.000đ")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    TimiAmountField(text: $expense, kind: .expense, showsSuggestions: false)
                }
            }
        }
    }
}
