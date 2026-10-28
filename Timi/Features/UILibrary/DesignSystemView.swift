import SwiftUI

/// The design system's catalogue (after the web's /design "Thư viện UI"): every token and block, live.
/// Opened from Cài đặt → Nhà phát triển.
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
                // Lazy: a part is built only as it scrolls in, so the push from the avatar stays smooth
                // (all nine at once, with 82 logos and a chart, dropped frames during the slide).
                LazyVStack(alignment: .leading, spacing: Spacing.xxxl) {
                    header
                    ForEach(Part.allCases) { part in
                        partView(part)
                    }
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

    @ViewBuilder
    private func partView(_ part: Part) -> some View {
        switch part {
        case .foundation: FoundationPart()
        case .buttons: ButtonsPart()
        case .chips: ChipsPart()
        case .choices: ChoicesPart()
        case .inputs: InputsPart()
        case .lists: ListsPart()
        case .progress: ProgressPart()
        case .sheets: SheetsPart()
        case .empty: EmptyPart()
        }
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

#Preview {
    NavigationStack {
        DesignSystemView()
    }
    .environment(\.locale, .vietnam)
    .font(Typography.body)
}
