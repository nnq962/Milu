import SwiftUI

struct ChoicesPart: View {
    @State private var segment: TransactionSegment = .flows
    @State private var accountType = "Ngân hàng"
    @State private var reminders = true
    @State private var excluded = false
    @State private var date = Date.now

    var body: some View {
        PartSection(part: .choices) {
            SampleCard(label: "Segmented · native") {
                Picker("Loại", selection: $segment) {
                    ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
            FormGroup(title: "Dòng trong form",
                      footer: "Loại tài khoản, Ngày và Giờ mở sheet chọn; Hạng mục mở màn khác.") {
                FormPickerRow(title: "Loại tài khoản", icon: "hugeicons-wallet-01", selection: $accountType,
                              options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]) { $0 }
                FormDivider()
                FormDateRow(title: "Ngày", icon: "hugeicons-calendar-03", date: $date)
                FormDivider()
                FormTimeRow(title: "Giờ", icon: "hugeicons-clock-01", date: $date)
                FormDivider()
                FormToggleRow(title: "Nhắc hạn thanh toán", subtitle: "Trước 1 ngày", icon: "hugeicons-notification-01", isOn: $reminders)
                FormDivider()
                FormToggleRow(title: "Không tính vào báo cáo", icon: "hugeicons-chart-increase", isOn: $excluded)
                FormDivider()
                FormNavigationRow(title: "Hạng mục", icon: "hugeicons-shopping-bag-01", value: "Mua sắm") {}
            }
        }
    }
}
