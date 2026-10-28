//
//  DesignSystemView.swift
//  Timi
//

import SwiftUI

/// The design system's catalogue (after the web's /design "Thư viện UI"): every token and block, live.
/// Opened from the avatar on Tổng quan.
struct DesignSystemView: View {
    enum Part: String, CaseIterable, Identifiable {
        case foundation, buttons, chips, choices, inputs, lists, progress, sheets, empty

        var id: Self { self }

        var title: String {
            switch self {
            case .foundation: "Nền tảng"
            case .buttons: "Nút"
            case .chips: "Chip & Badge"
            case .choices: "Lựa chọn"
            case .inputs: "Ô nhập"
            case .lists: "Danh sách & Thẻ"
            case .progress: "Tiến độ & Biểu đồ"
            case .sheets: "Sheet"
            case .empty: "Trạng thái trống"
            }
        }

        var note: String {
            switch self {
            case .foundation: "Màu, chữ, khoảng cách, bo góc: mọi thứ khác xây trên đây."
            case .buttons: "Liquid Glass của Apple, chỉ đổi màu, cỡ và chữ. Mỗi màn một nút chính."
            case .chips: "Lọc nhanh, gắn nhãn, báo trạng thái."
            case .choices: "Dòng chọn và ngày mở sheet cho rộng; công tắc là control native."
            case .inputs: "Kiểu iOS: nhãn trái, giá trị phải, các ô chung một thẻ."
            case .lists: "Dòng dữ liệu trên thẻ trắng, icon không nền, › khi chạm được."
            case .progress: "Thanh một cỡ 8pt, hạn mức đổi màu theo mức; biểu đồ dùng Swift Charts."
            case .sheets: "Sheet chuẩn iOS (vị trí nút, bo góc, kéo đóng); Timi chỉ đổi màu và nội dung."
            case .empty: "Khi chưa có dữ liệu: icon, một câu, một việc nên làm."
            }
        }
    }

    @State private var part: Part = .foundation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxxl) {
                    header
                    FoundationPart()
                    ButtonsPart()
                    ChipsPart()
                    ChoicesPart()
                    InputsPart()
                    ListsPart()
                    ProgressPart()
                    SheetsPart()
                    EmptyPart()
                }
                .padding(.horizontal, Spacing.page)
                .padding(.bottom, Spacing.xxxl)
            }
            .dismissesKeyboardOnTap()
            // The chip index stays under the bar; as a safe-area inset, scrolling to a part stops below it.
            .safeAreaInset(edge: .top, spacing: 0) {
                ChipRow(options: Part.allCases, selection: $part) { $0.title }
                    .padding(.horizontal, Spacing.page)
                    .padding(.vertical, Spacing.m)
                    .background(Palette.background)
            }
            .onChange(of: part) { _, newPart in
                withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(newPart, anchor: .top) }
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Thư viện UI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Timi · hệ thống thiết kế")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
            Text("Thư viện UI")
                .textRole(.pageTitle)
            Text("\(Part.allCases.count) nhóm thành phần, đều chạm thử được.")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .padding(.top, Spacing.s)
    }
}

// MARK: - Khung catalog

/// One part: title, when to use it, then sample cards.
private struct PartSection<Content: View>: View {
    let part: DesignSystemView.Part
    @ViewBuilder var content: Content

    var body: some View {
        // Spacing: heading → note 4, header → first sample 16, samples 16 apart, parts 32 apart.
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(part.title)
                    .textRole(.heading)
                Text(part.note)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(.horizontal, Spacing.xs)
            content
        }
        .id(part)
    }
}

/// A white card naming the sample inside it in small capitals.
private struct SampleCard<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(label)
                .textRole(.overline)
                .foregroundStyle(Palette.secondaryText)
            content
        }
        .sleekCard()
    }
}

// MARK: - Nền tảng

private struct FoundationPart: View {
    private let colors: [(name: String, hex: String, color: Color)] = [
        ("background", "#FAFAF7", Palette.background),
        ("card", "#FFFFFF", Palette.card),
        ("ink", "#111827", Palette.ink),
        ("secondaryText", "#596171", Palette.secondaryText),
        ("muted", "#F1F1EC", Palette.muted),
        ("border", "#E5E5E0", Palette.border),
        ("input", "#F3F3EF", Palette.input),
        ("lime", "#C6F432", Palette.lime),
        ("incomeTile", "#EEFCBC", Palette.incomeTile),
        ("red", "#DC2626", Palette.red),
        ("green", "#16A34A", Palette.green),
        ("secondarySurface", "#EEF0F3", Palette.secondarySurface),
        ("fill1", "mực 4%", Palette.fill1),
        ("fill2", "mực 6%", Palette.fill2),
        ("fill3", "mực 10%", Palette.fill3),
    ]

    private let radii: [(name: String, value: CGFloat)] = [
        ("extraLarge", CardCorners.extraLarge), ("sheet", CardCorners.sheet), ("large", CardCorners.large),
        ("inset", CardCorners.inset), ("flow", CardCorners.flow), ("field", CardCorners.field),
        ("icon", CardCorners.icon), ("calendarDay", CardCorners.calendarDay),
    ]

    var body: some View {
        PartSection(part: .foundation) {
            SampleCard(label: "Màu · Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3), spacing: Spacing.l) {
                    ForEach(colors, id: \.name) { item in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous)
                                .fill(item.color)
                                .frame(height: 48)
                                .overlay {
                                    RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous)
                                        .strokeBorder(Palette.border, lineWidth: 1)
                                }
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.8)
                            Text(item.hex).textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Chữ · Manrope · .textRole") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    ForEach(TextRole.allCases) { role in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(role.isNumeric ? "14.119.000đ" : role.name)
                                .textRole(role)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(role.name) · \(role.size.formatted())pt · \(weightName(role.weight))")
                                .textRole(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Khoảng cách · Spacing") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(Spacing.scale, id: \.name) { step in
                        HStack(spacing: Spacing.m) {
                            Text(step.name).textRole(.captionStrong).frame(width: 40, alignment: .leading)
                            Capsule().fill(Palette.primary).frame(width: step.value * 4, height: 8)
                            Text("\(Int(step.value))").textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                    Text("Lề màn \(Int(Spacing.page)) · giữa các phần \(Int(Spacing.section)) · đệm thẻ \(Int(Spacing.card))")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.top, Spacing.xs)
                }
            }

            SampleCard(label: "Bo góc · CardCorners (continuous)") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 4), spacing: Spacing.l) {
                    ForEach(radii, id: \.name) { item in
                        VStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: item.value, style: .continuous)
                                .fill(Palette.muted)
                                .frame(height: 64)
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.7)
                            Text("\(Int(item.value))").textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Chiều cao điều khiển") {
                Text("Nút lớn 56 · thường 44 · nhỏ 36 · ô nhập 44 · dòng 52 · nút nổi 56. Không thứ gì bấm được thấp hơn 44, trừ chip trong nội dung.")
                    .textRole(.body)
            }
        }
    }

    private func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .heavy: "ExtraBold"
        case .bold: "Bold"
        case .semibold: "SemiBold"
        case .medium: "Medium"
        default: "Regular"
        }
    }
}

// MARK: - Nút

private struct ButtonsPart: View {
    @State private var isPressedSample = false

    var body: some View {
        PartSection(part: .buttons) {
            SampleCard(label: "Vai trò · TimiButton") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(TimiButtonRole.allCases) { role in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            TimiButton(role.name, role: role, fullWidth: true) {}
                            Text(role.usage).textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Cỡ · 36 / 44 / 56") {
                HStack(spacing: Spacing.s) {
                    TimiButton("Nhỏ", role: .primary, size: .small) {}
                    TimiButton("Thường", role: .primary) {}
                    TimiButton("Lớn", role: .primary, size: .large) {}
                }
            }

            SampleCard(label: "Có icon · tắt") {
                VStack(spacing: Spacing.m) {
                    TimiButton("Thêm giao dịch", icon: "solar-add-linear", role: .primary, fullWidth: true) {}
                    TimiButton("Chưa bấm được", role: .primary, fullWidth: true) {}
                        .disabled(true)
                }
            }

            SampleCard(label: "Nút tròn trên thanh · nút nổi") {
                HStack(spacing: Spacing.l) {
                    Button {} label: {
                        SolarIcon("solar-bell-linear", size: 20).frame(width: 28, height: 28)
                    }
                    .tint(Palette.ink)
                    .nativeCircleButton(diameter: 44)
                    Button {} label: {
                        SolarIcon("solar-magnifer-linear", size: 20).frame(width: 28, height: 28)
                    }
                    .tint(Palette.ink)
                    .nativeCircleButton(diameter: 44)
                    Spacer()
                    Button {} label: {
                        SolarIcon("material-symbols-add-rounded", size: 26).foregroundStyle(.white)
                    }
                    .nativeFloatingButton(diameter: ControlHeight.floating, tint: Palette.primary)
                }
            }
        }
    }
}

// MARK: - Chip & Badge

private struct ChipsPart: View {
    @State private var filter: TransactionFilter = .all

    var body: some View {
        PartSection(part: .chips) {
            SampleCard(label: "Chip lọc · ChipRow") {
                ChipRow(options: TransactionFilter.allCases, selection: $filter) { $0.title }
            }
            SampleCard(label: "Badge · StatusBadge") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        ForEach(BadgeTone.allCases.prefix(3)) { StatusBadge(text: $0.name, tone: $0) }
                    }
                    HStack(spacing: Spacing.s) {
                        ForEach(BadgeTone.allCases.suffix(2)) { StatusBadge(text: $0.name, tone: $0) }
                    }
                    StatusBadge(text: "2 sắp đến hạn", showsDot: false)
                }
            }
        }
    }
}

// MARK: - Lựa chọn

private struct ChoicesPart: View {
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

// MARK: - Ô nhập

private struct InputsPart: View {
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

// MARK: - Danh sách & Thẻ

private struct ListsPart: View {
    var body: some View {
        PartSection(part: .lists) {
            VStack(spacing: 0) {
                ListRow(icon: "solar-banknote-2-linear", title: "Ví tiền mặt", subtitle: "Cập nhật hôm nay", amount: 2_350_000)
                ListRow(icon: "solar-cup-hot-linear", title: "Cà phê buổi sáng", subtitle: "Ăn uống · 08:30",
                        amount: 45_000, amountTone: .signedExpense)
                    .overlay(alignment: .top) { RowDivider() }
                ListRow(icon: "solar-wallet-money-linear", title: "Lương tháng 10", subtitle: "Thu nhập · 09:00",
                        amount: 25_000_000, amountTone: .signedIncome)
                    .overlay(alignment: .top) { RowDivider() }
            }
            .cardSurface(color: Palette.card, elevated: true)

            SampleCard(label: "Số tiền · MoneyText") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    MoneyText(amount: 192_090_000, size: .display)
                    MoneyText(amount: 14_119_000, size: .large)
                    HStack(spacing: Spacing.l) {
                        MoneyText(amount: 500_000, tone: .signedIncome)
                        MoneyText(amount: 60_000, tone: .signedExpense)
                        MoneyText(amount: -6_430_000, tone: .negativeRed, compact: true)
                    }
                }
            }

            SampleCard(label: "Avatar · icon tròn") {
                HStack(spacing: Spacing.m) {
                    InitialsAvatar(name: "Minh")
                    InitialsAvatar(name: "Hùng")
                    IconCircle(icon: "solar-card-linear")
                    AssistantAvatar()
                }
            }
        }
    }
}

// MARK: - Tiến độ

private struct ProgressPart: View {
    var body: some View {
        PartSection(part: .progress) {
            SampleCard(label: "Chi theo ngày · Swift Charts") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    DailySpendingChart(month: .now, totals: Self.sampleTotals)
                    Text("Nhấn giữ rồi kéo trên cột để xem số tiền từng ngày (như app Sức khoẻ); hôm nay màu chanh.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            SampleCard(label: "Tiến độ · mặc định đen") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    progressSample("Hũ tiết kiệm · 70%", value: 0.7, color: Palette.primary)
                    progressSample("Khoản cho vay đã thu · 40%", value: 0.4, color: Palette.primary)
                }
            }
            SampleCard(label: "Hạn mức · đổi màu theo mức") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    progressSample("Còn thoải mái · 47%", value: 0.47, color: ProgressBar.budgetColor(0.47))
                    progressSample("Sắp chạm hạn mức · 86%", value: 0.86, color: ProgressBar.budgetColor(0.86))
                    progressSample("Vượt hạn mức · 126%", value: 1.26, color: ProgressBar.budgetColor(1.26))
                    Text("Xanh dưới 80% · cam từ 80% · đỏ khi chạm hoặc vượt 100%.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
    }

    /// A month of made-up spending, up to today.
    private static let sampleTotals: [Int: Double] = {
        let today = Calendar.current.component(.day, from: .now)
        let pattern: [Double] = [120, 45, 0, 310, 85, 60, 0, 540, 95, 150, 30, 0, 260, 75]
        return Dictionary(uniqueKeysWithValues: (1...today).map { ($0, pattern[$0 % pattern.count] * 1_000) })
    }()

    private func progressSample(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title).textRole(.label)
            ProgressBar(value: value, color: color)
        }
    }
}

// MARK: - Sheet

private struct SheetsPart: View {
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
private struct SampleFormSheet: View {
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
                      canConfirm: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
            dismiss()
        } content: {
            VStack(spacing: Spacing.xs) {
                Text("Số dư hiện tại")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $balance)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)

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

// MARK: - Trạng thái trống

private struct EmptyPart: View {
    var body: some View {
        PartSection(part: .empty) {
            EmptyStateCard(icon: "solar-inbox-linear", title: "Chưa có giao dịch",
                           message: "Thêm giao dịch đầu tiên để bắt đầu theo dõi.")
        }
    }
}

#Preview {
    NavigationStack {
        DesignSystemView()
    }
    .environment(\.locale, .vietnam)
    .font(Typography.body)
}
