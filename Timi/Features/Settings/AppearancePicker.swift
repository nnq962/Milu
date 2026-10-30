import SwiftUI

/// Cài đặt → Giao diện picked in place (user request 2026-10-29), like iOS Màn hình & Độ sáng:
/// three small phone screens (Theo hệ thống half light half dark, Sáng, Tối), the name and a round
/// tick below. The screens keep their own colours whatever look the app is in.
struct AppearancePicker: View {
    @Binding var selection: AppAppearance

    var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(AppAppearance.allCases) { option in
                tile(option)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.l)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func tile(_ option: AppAppearance) -> some View {
        let isChosen = option == selection
        return Button {
            withAnimation(.snappy(duration: 0.2)) { selection = option }
        } label: {
            VStack(spacing: Spacing.s) {
                screen(option)
                    .frame(width: 64, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isChosen ? Palette.ink : Palette.border, lineWidth: isChosen ? 2 : 1)
                    }
                Text(option.shortTitle)
                    .textRole(.captionStrong)
                    .foregroundStyle(isChosen ? Palette.ink : Palette.secondaryText)
                ZStack {
                    Circle().strokeBorder(Palette.border, lineWidth: 1.5)
                    if isChosen {
                        Circle().fill(Palette.primary)
                        TimiIcon("hugeicons-tick-02", size: 12).foregroundStyle(Palette.onPrimary)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        // No press dimming: `.plain` greys the little screens while the finger is down; the border,
        // the tick and the haptic already answer the tap.
        .buttonStyle(StillButtonStyle())
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isChosen ? [.isSelected, .isButton] : .isButton)
    }

    @ViewBuilder
    private func screen(_ option: AppAppearance) -> some View {
        switch option {
        case .light: MiniScreen(dark: false)
        case .dark: MiniScreen(dark: true)
        case .system:
            HStack(spacing: 0) {
                MiniScreen(dark: false).frame(width: 32, alignment: .leading).clipped()
                MiniScreen(dark: true).frame(width: 32, alignment: .trailing).clipped()
            }
        }
    }
}

/// A tiny Tổng quan: page, a lime header and two cards, in fixed light or dark colours.
private struct MiniScreen: View {
    let dark: Bool

    var body: some View {
        let page = dark ? Color.black : Color(red: 0.98, green: 0.98, blue: 0.97)
        let card = dark ? Color(white: 0.11) : .white
        let line = dark ? Color(white: 0.3) : Color(white: 0.85)
        VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(line).frame(width: 26, height: 4)
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(card)
                .frame(height: 30)
                .overlay(alignment: .topLeading) {
                    Capsule().fill(Palette.lime).frame(width: 20, height: 4).padding(6)
                }
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(card).frame(height: 22)
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(card).frame(height: 22)
        }
        .padding(7)
        .frame(width: 64, height: 104, alignment: .top)
        .background(page)
    }
}

/// A button that does not change while pressed.
private struct StillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
