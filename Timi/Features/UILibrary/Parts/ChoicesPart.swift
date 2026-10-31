import SwiftUI

struct ChoicesPart: View {
    @State private var segment: TransactionSegment = .flows
    @State private var accountType = "Ngân hàng"
    @State private var reminders = true
    @State private var locked = false
    @State private var date = Date.now
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var month = Date.now

    var body: some View {
        PartSection(part: .choices) {
            // Its words grow with the text size, unlike the bare segmented Picker.
            SampleCard(label: "Segmented · ScaledSegmentedPicker") {
                ScaledSegmentedPicker(title: "Loại", selection: $segment,
                                      options: TransactionSegment.allCases) { $0.title }
                    .controlSize(.large)
            }

            // Every row of a group has an icon, or none has.
            FormGroup(title: "Dòng có icon") {
                FormPickerRow(title: "Loại tài khoản", icon: "hugeicons-wallet-01", selection: $accountType,
                              options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]) { $0 }
                FormDivider()
                FormToggleRow(title: "Nhắc hạn thanh toán", subtitle: "Trước 1 ngày", icon: "hugeicons-notification-01", isOn: $reminders)
                FormDivider()
                FormToggleRow(title: "Khoá tài khoản", icon: "hugeicons-square-lock-02", isOn: $locked)
                FormDivider()
                NavigationLink {
                    Text("Trang được mở")
                        .textRole(.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Palette.background)
                } label: {
                    NavigationRowContent(title: "Hạng mục", icon: "hugeicons-tag-01", value: "12", spokenValue: "12 hạng mục")
                }
                .buttonStyle(.row)
                FormDivider()
                FormNavigationRow(title: "Câu hỏi thường gặp", icon: "hugeicons-help-circle") {}
                FormDivider()
                FormActionRow(title: "Lưu trữ tài khoản", icon: "hugeicons-archive-02") {}
                FormDivider()
                FormDestructiveRow(title: "Xoá tài khoản", question: "Xoá tài khoản?", message: "Không thể hoàn tác.") {}
            }

            // The day and the time on one row, one sheet for both; a day alone (a deadline) on its own.
            FormGroup(title: "Ngày giờ · FormDateTimeRow, FormDateRow") {
                FormDateTimeRow(title: "Thời gian", date: $date, latest: .now)
                FormDivider(hasIcon: false)
                FormDateRow(title: "Hạn trả", date: $deadline)
            }

            // A row that opens a picker sheet: label, grey value, ›.
            FormGroup(title: "Giá trị · FormValueRowContent") {
                Button {} label: {
                    FormValueRowContent(title: "Ngân hàng", icon: nil, value: "Vietcombank",
                                   valueIcon: "Institutions/vietcombank")
                }
                .buttonStyle(.row)
            }

            // The month: a flat capsule on a page, plain words ⌄ beside a heading.
            SampleCard(label: "Tháng · MonthMenu (viên / compact)") {
                HStack {
                    MonthMenu(month: $month)
                    Spacer(minLength: Spacing.s)
                    MonthMenu(month: $month, compact: true)
                }
            }
        }
    }
}
