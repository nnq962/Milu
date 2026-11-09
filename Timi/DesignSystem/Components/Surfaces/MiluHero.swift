import SwiftUI

/// Milu, the app's one dog, alive on a tab's head (trial, user request 2026-11-09: "sinh động như
/// Duolingo", but kept as the mountain-shaped head of before, Figma 493:1384). With no arms or
/// legs, it moves only as a mountain can: it rises from behind the sky's edge the first time the
/// tab opens, leans now and then with its foot kept on the edge, breathes up taller, and answers a
/// tap with another face, a hop upward and a few words.
///
/// Every face is one 350 × 220 drawing with the head in the same place (Figma "Milu · Xuất cho
/// app"), so a swap never moves it. Nothing moves with Reduce Motion but the swap.
struct MiluHero: View {
    /// Milu's faces, as named in `MiluArt` ("milu-vui-mung").
    enum Look: String, CaseIterable {
        case macDinh = "mac-dinh", toMo = "to-mo", vuiMung = "vui-mung", ngacNhien = "ngac-nhien"
        case buonNgu = "buon-ngu", cuoiTitMat = "cuoi-tit-mat", nhayMat = "nhay-mat"
        case yeuThuong = "yeu-thuong", loLang = "lo-lang", buon, ngaiNgung = "ngai-ngung"

        var image: String { "milu-\(rawValue)" }
    }

    /// The face the page gives it: how things are going.
    let look: Look
    /// Said once in a bubble when the tab first opens; nil for none.
    var greeting: String?
    /// Whether it has room to talk: only where no title sits left of it (Tổng quan); elsewhere a
    /// tap brings the face and the sparkles only.
    var talks = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A tap's face and words, for a moment.
    @State private var reaction: Reaction?
    @State private var taps = 0
    @State private var bubble: String?
    /// Below the edge until the tab first opens.
    @State private var hasRisen = false
    @State private var lean: CGFloat = 0
    @State private var breath: CGFloat = 1
    @State private var bursts: [Burst] = []

    private struct Reaction {
        let look: Look
        let words: String
    }

    /// What a tap brings, in turn.
    private static let reactions: [Reaction] = [
        Reaction(look: .vuiMung, words: "Gâu gâu!"),
        Reaction(look: .cuoiTitMat, words: "Nhột quá à!"),
        Reaction(look: .nhayMat, words: "Hì, thấy rồi nha"),
        Reaction(look: .yeuThuong, words: "Milu thương bạn!"),
        Reaction(look: .ngacNhien, words: "Ơ, gì thế?"),
    ]

    private var shown: Look { reaction?.look ?? look }

    var body: some View {
        Image(shown.image)
            .resizable()
            .scaledToFit()
            // A face swaps at once: a cross-fade showed the sky through both (user 2026-11-05).
            .transaction { $0.animation = nil }
            .modifier(Lean(amount: lean))
            .scaleEffect(x: 2 - breath, y: breath, anchor: .bottom)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: taps) { content, stretch in
                // A hop as a mountain can: squashed down, then up tall, its foot on the edge.
                content.scaleEffect(x: 1 + (1 - stretch) * 0.6, y: stretch, anchor: .bottom)
            } keyframes: { _ in
                let size: CGFloat = reduceMotion ? 0 : 1
                SpringKeyframe(1 - 0.1 * size, duration: 0.09)
                SpringKeyframe(1 + 0.1 * size, duration: 0.16)
                SpringKeyframe(1, duration: 0.45, spring: .bouncy)
            }
            // Rises from behind the edge (the head masks everything below it).
            .visualEffect { content, proxy in
                content.offset(y: hasRisen ? 0 : proxy.size.height)
            }
            .overlay(alignment: .top) { burstLayer }
            .overlay(alignment: .topLeading) { bubbleLayer }
            .contentShape(Rectangle())
            .onTapGesture(perform: react)
            .task { await live() }
            .task(id: taps) { await settle() }
    }

    // MARK: - Lời nói

    @ViewBuilder private var bubbleLayer: some View {
        if talks, let bubble {
            SpeechBubble(text: bubble)
                .fixedSize()
                // Left of the peak, above the slope, its tail toward Milu's face: its lower right
                // corner 40 in and 74 down from the drawing's corner.
                .frame(width: 0, height: 0, alignment: .bottomTrailing)
                .offset(x: 40, y: 74)
                .transition(reduceMotion ? .opacity
                            : .scale(scale: 0.6, anchor: .topLeading).combined(with: .opacity))
                .id(bubble)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Tim và lấp lánh

    private struct Burst: Identifiable {
        let id = UUID()
        let symbol: String
        let color: Color
        let x: CGFloat
        let rise: CGFloat
        let delay: Double
    }

    private var burstLayer: some View {
        ZStack {
            ForEach(bursts) { burst in
                BurstMark(burst: burst)
            }
        }
        .offset(y: 10)
        .allowsHitTesting(false)
    }

    private struct BurstMark: View {
        let burst: Burst
        @State private var flown = false

        var body: some View {
            Image(systemName: burst.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(burst.color)
                .offset(x: burst.x * (flown ? 1.4 : 0.4), y: flown ? -burst.rise : 0)
                .scaleEffect(flown ? 1 : 0.3)
                .opacity(flown ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.1).delay(burst.delay)) { flown = true }
                }
        }
    }

    // MARK: - Cử động

    private func react() {
        Haptics.selection()
        let next = Self.reactions[taps % Self.reactions.count]
        taps += 1
        withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
            reaction = next
            bubble = next.words
        }
        guard !reduceMotion else { return }
        let hearts = next.look == .yeuThuong
        bursts = (0..<(hearts ? 4 : 3)).map { index in
            Burst(symbol: hearts ? "heart.fill" : "sparkle",
                  color: hearts ? Palette.apricot : Palette.deep,
                  x: CGFloat(index - 1) * 22 + .random(in: -6...6),
                  rise: .random(in: 34...52),
                  delay: Double(index) * 0.06)
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
        bursts = []
    }

    /// While the tab is on screen: rise once, greet, then now and then a lean or a breath. A few
    /// animations a minute, not a running clock: the page above it scrolls at full speed.
    private func live() async {
        if !hasRisen {
            if reduceMotion {
                hasRisen = true
            } else {
                try? await Task.sleep(for: .seconds(0.25))
                withAnimation(.spring(duration: 0.7, bounce: 0.38)) { hasRisen = true }
            }
            if talks, let greeting, reaction == nil {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.spring(duration: 0.35, bounce: 0.3)) { bubble = greeting }
                try? await Task.sleep(for: .seconds(3.5))
                if reaction == nil {
                    withAnimation(.easeInOut(duration: 0.25)) { bubble = nil }
                }
            }
        }
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(.random(in: 3.5...6.5)))
            guard !Task.isCancelled else { return }
            if Bool.random() {
                withAnimation(.spring(duration: 0.6, bounce: 0.35)) { lean = Bool.random() ? 0.12 : -0.12 }
                try? await Task.sleep(for: .seconds(1.1))
                withAnimation(.spring(duration: 0.8, bounce: 0.3)) { lean = 0 }
            } else {
                withAnimation(.easeInOut(duration: 0.9)) { breath = 1.035 }
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.easeInOut(duration: 1.1)) { breath = 1 }
            }
        }
    }
}

/// A lean with the foot kept still: each line of the drawing slides sideways by how high it is, so
/// the peak tilts and the base stays flat on the sky's edge (a turn would lift one corner of it).
private struct Lean: GeometryEffect {
    var amount: CGFloat

    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(a: 1, b: 0, c: amount, d: 1, tx: -amount * size.height, ty: 0))
    }
}

/// Milu's words: a white card with a tail toward its head, below it on the right.
private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.font(.footnote, size: 13, weight: .bold))
            .foregroundStyle(Palette.label)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                BubbleShape()
                    .fill(Palette.surface)
                    .shadow(color: Palette.label.opacity(0.12), radius: 6, y: 2)
            }
    }
}

private struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: min(rect.height / 2, 14), style: .continuous)
        // The tail at the lower right, pointing down toward the peak.
        let x = rect.maxX - 22
        path.move(to: CGPoint(x: x - 7, y: rect.maxY - 1))
        path.addQuadCurve(to: CGPoint(x: x + 6, y: rect.maxY + 8), control: CGPoint(x: x + 1, y: rect.maxY + 4))
        path.addQuadCurve(to: CGPoint(x: x + 5, y: rect.maxY - 1), control: CGPoint(x: x + 4, y: rect.maxY + 2))
        path.closeSubpath()
        return path
    }
}
