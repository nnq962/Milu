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
                FormPickerRow(title: "Loại tài khoản", icon: "solar-wallet-linear", selection: $accountType,
                              options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]) { $0 }
                FormDivider()
                FormDateRow(title: "Ngày", icon: "solar-calendar-linear", date: $date)
                FormDivider()
                FormTimeRow(title: "Giờ", icon: "solar-clock-circle-linear", date: $date)
                FormDivider()
                FormToggleRow(title: "Nhắc hạn thanh toán", subtitle: "Trước 1 ngày", icon: "solar-bell-linear", isOn: $reminders)
                FormDivider()
                FormToggleRow(title: "Không tính vào báo cáo", icon: "solar-graph-up-linear", isOn: $excluded)
                FormDivider()
                FormNavigationRow(title: "Hạng mục", icon: "solar-bag-3-linear", value: "Mua sắm") {}
            }
        }
    }
}
