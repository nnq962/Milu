import SwiftUI

/// Milu, the app's one dog, on a tab's head: the page's face, a greeting once, and another face
/// and a few words on a tap. Still for now: the rise, the leans, the breaths, the hop and the
/// sparkles went (user request 2026-11-13); the Rive characters will bring the movement back.
///
/// Every face is one 320 × 140 drawing with the head in the same place (the 20 faces of
/// 2026-11-13, output/02-expressions), so a swap never moves it. A swap is at once.
struct MiluHero: View {
    /// Milu's faces, as named in `MiluArt` ("milu-vui-mung").
    enum Look: String, CaseIterable {
        case nguyenBan = "nguyen-ban", thanThien = "than-thien", toMo = "to-mo", vui
        case boiRoi = "boi-roi", nhayMat = "nhay-mat", cuoiBanhNoc = "cuoi-banh-noc", meMan = "me-man"
        case nguongNgung = "nguong-ngung", buonThiu = "buon-thiu", tuiThan = "tui-than", khocOa = "khoc-oa"
        case gianDoi = "gian-doi", hotHoang = "hot-hoang", buonNgu = "buon-ngu", nguKho = "ngu-kho"
        case sutSit = "sut-sit", dungHinh = "dung-hinh", ngaoNgo = "ngao-ngo", chongMat = "chong-mat"

        /// The faces of before 2026-11-13, as a saved avatar may still name them.
        init?(legacy raw: String) {
            let old: [String: Look] = [
                "mac-dinh": .nguyenBan, "vui-mung": .vui, "ngac-nhien": .hotHoang,
                "cuoi-tit-mat": .cuoiBanhNoc, "yeu-thuong": .meMan, "lo-lang": .boiRoi,
                "buon": .buonThiu, "ngai-ngung": .nguongNgung,
            ]
            guard let look = Look(rawValue: raw) ?? old[raw] else { return nil }
            self = look
        }

        var image: String { "milu-\(rawValue)" }
    }

    /// The face the page gives it: how things are going.
    let look: Look
    /// Said once in a bubble when the tab first opens; nil for none.
    var greeting: String?
    /// Whether it has room to talk: only where no title sits left of it (Tổng quan); elsewhere a
    /// tap brings the face and the sparkles only.
    var talks = true
    /// Where its words go: left of its peak where it stands on the right of a head (the tabs), or
    /// above it on the right where it stands in the middle (the welcome, 2026-11-12: on the left
    /// a longer word ran off the screen).
    var bubbleSide: BubbleSide = .leftOfPeak

    enum BubbleSide { case leftOfPeak, aboveRight }

    /// A tap's face and words, for a moment.
    @State private var reaction: Reaction?
    @State private var taps = 0
    @State private var bubble: String?
    /// The greeting is said once, the first time the tab opens.
    @State private var hasGreeted = false

    private struct Reaction {
        let look: Look
        let words: String
    }

    /// What a tap brings, in turn.
    private static let reactions: [Reaction] = [
        Reaction(look: .vui, words: "Gâu gâu!"),
        Reaction(look: .cuoiBanhNoc, words: "Nhột quá à!"),
        Reaction(look: .nhayMat, words: "Hì, thấy rồi nha"),
        Reaction(look: .meMan, words: "Milu thương bạn!"),
        Reaction(look: .ngaoNgo, words: "Ơ, gì thế?"),
    ]

    private var shown: Look { reaction?.look ?? look }

    var body: some View {
        Image(shown.image)
            .resizable()
            .scaledToFit()
            .transaction { $0.animation = nil }
            .overlay(alignment: .topLeading) { bubbleLayer }
            .contentShape(Rectangle())
            .onTapGesture(perform: react)
            .task { await greet() }
            .task(id: taps) { await settle() }
    }

    // MARK: - Lời nói

    @ViewBuilder private var bubbleLayer: some View {
        if talks, let bubble {
            switch bubbleSide {
            case .leftOfPeak:
                SpeechBubble(text: bubble)
                    .fixedSize()
                    // Left of the peak, above the slope, its tail toward Milu's face: its lower right
                    // corner 54 in and 54 down from the drawing's corner (the same place on the
                    // screen as with the 350 × 220 faces before 2026-11-13).
                    .frame(width: 0, height: 0, alignment: .bottomTrailing)
                    .offset(x: 54, y: 54)
                    .transition(.opacity)
                    .id(bubble)
                    .allowsHitTesting(false)
            case .aboveRight:
                // Its lower left corner just right of the peak, a little above the ears, the tail
                // down toward the head; placed by share of the drawing, whatever its size.
                GeometryReader { proxy in
                    SpeechBubble(text: bubble, tailLeading: true)
                        .fixedSize()
                        .frame(width: 0, height: 0, alignment: .bottomLeading)
                        .position(x: proxy.size.width * 0.63, y: proxy.size.height * -0.075)
                }
                .transition(.opacity)
                .id(bubble)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Chạm

    private func react() {
        Haptics.selection()
        let next = Self.reactions[taps % Self.reactions.count]
        taps += 1
        withAnimation(.easeOut(duration: 0.2)) {
            reaction = next
            bubble = talks ? next.words : nil
        }
    }

    /// Back to the page's face a little after the last tap.
    private func settle() async {
        guard taps > 0 else { return }
        try? await Task.sleep(for: .seconds(2.6))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            reaction = nil
            bubble = nil
        }
    }

    /// The greeting, once, for a few seconds.
    private func greet() async {
        guard !hasGreeted else { return }
        hasGreeted = true
        guard talks, let greeting, reaction == nil else { return }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeOut(duration: 0.2)) { bubble = greeting }
        try? await Task.sleep(for: .seconds(3.5))
        if reaction == nil {
            withAnimation(.easeInOut(duration: 0.25)) { bubble = nil }
        }
    }
}

/// Milu's words: a white card with a tail toward its head, below it on the right (or the left).
private struct SpeechBubble: View {
    let text: String
    var tailLeading = false

    var body: some View {
        Text(text)
            .font(Typography.font(.footnote, size: 13, weight: .bold))
            .foregroundStyle(Palette.label)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                BubbleShape(tailLeading: tailLeading)
                    .fill(Palette.surface)
                    .shadow(color: Palette.label.opacity(0.12), radius: 6, y: 2)
            }
    }
}

private struct BubbleShape: Shape {
    var tailLeading = false

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: min(rect.height / 2, 14), style: .continuous)
        // The tail at the lower right (or left, mirrored), pointing down toward the peak.
        var tail = Path()
        let x = rect.maxX - 22
        tail.move(to: CGPoint(x: x - 7, y: rect.maxY - 1))
        tail.addQuadCurve(to: CGPoint(x: x + 6, y: rect.maxY + 8), control: CGPoint(x: x + 1, y: rect.maxY + 4))
        tail.addQuadCurve(to: CGPoint(x: x + 5, y: rect.maxY - 1), control: CGPoint(x: x + 4, y: rect.maxY + 2))
        tail.closeSubpath()
        if tailLeading {
            tail = tail.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0))
        }
        path.addPath(tail)
        return path
    }
}
