import SwiftUI

/// The design system's catalogue (after the web's /design "Thư viện UI"): every token and block, live.
/// Opened from Cài đặt → Nhà phát triển. The bar already says "Thư viện UI", so the page has no
/// title of its own (strict review 2026-10-31).
struct DesignSystemView: View {
    enum Part: String, CaseIterable, Identifiable {
        case foundation, headings, buttons, chips, choices, inputs, lists, progress, sheets, empty

        var id: Self { self }

        var title: String {
            switch self {
            case .foundation: "Nền tảng"
            case .headings: "Tiêu đề phần"
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
            case .headings: "Mọi trang dùng SectionHeader, lùi 16 như dòng trong thẻ, cách thẻ 8."
            case .buttons: "Mỗi màn một nút chính. Nút trong nội dung luôn phẳng; kính chỉ trên thanh công cụ và nút + nổi."
            case .chips: "Lọc nhanh, gắn nhãn, báo trạng thái."
            case .choices: "Dòng chọn và ngày mở sheet cho rộng; công tắc là control native."
            case .inputs: "Kiểu iOS: nhãn trái, giá trị phải, các ô chung một thẻ."
            case .lists: "Dòng dữ liệu trên thẻ trắng, icon không nền, › khi chạm được. Tiền ra đỏ có -, tiền vào mực có +."
            case .progress: "Thanh một cỡ \(Int(ProgressBar.height))pt, hạn mức đổi màu theo mức; vòng cho hũ."
            case .sheets: "Sheet chuẩn iOS: ✕ trái, ✓ màu chính bên phải, luôn bấm được."
            case .empty: "Icon trơn, tiêu đề, một câu ngắn nói thứ sẽ hiện ở đây; không nhắc nút."
            }
        }
    }

    /// The part at the top of the page, kept as the page scrolls, so the chip index follows the
    /// reading (re-review 2026-10-31: it only moved when a chip was tapped).
    @State private var visible: Part? = .foundation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Lazy: a part is built only as it scrolls in, so the push from the avatar stays smooth
                // (all at once, with 82 logos, dropped frames during the slide).
                // The parts as far apart as the parts of any page (strict review 2026-10-31: 32).
                LazyVStack(alignment: .leading, spacing: Spacing.section) {
                    ForEach(Part.allCases) { part in
                        partView(part)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
                .keyboardDismissArea()
            }
            // Only watched, never driven: binding the scroll position to a lazy stack made the page
            // snap back as parts were laid out (user report 2026-10-31).
            .onScrollTargetVisibilityChange(idType: Part.self, threshold: 0.2) { parts in
                if let first = parts.first { visible = first }
            }
            .dismissesKeyboardOnTap()
            // The chip index stays under the bar; as a safe-area inset, scrolling to a part stops below it.
            .safeAreaInset(edge: .top, spacing: 0) {
                ChipRow(selection: chosen(proxy), options: Part.allCases) { $0.title }
                    .padding(.horizontal, Spacing.page)
                    .padding(.vertical, Spacing.m)
                    .background(Palette.background)
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle("Thư viện UI")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The chip lit is the part being read; a tap scrolls to that part's top every time, the lit
    /// chip too, after the page has been scrolled within it (re-review 2026-10-31: the scroll ran
    /// from `onChange`, so tapping the lit chip did nothing).
    private func chosen(_ proxy: ScrollViewProxy) -> Binding<Part> {
        Binding {
            visible ?? .foundation
        } set: { part in
            withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(part, anchor: .top) }
            visible = part
        }
    }

    @ViewBuilder
    private func partView(_ part: Part) -> some View {
        switch part {
        case .foundation: FoundationPart()
        case .headings: HeadingsPart()
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
}

#Preview {
    NavigationStack {
        DesignSystemView()
    }
    .environment(\.locale, .vietnam)
    .environment(FinanceStore())
}
