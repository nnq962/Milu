import SwiftUI

/// The assistant's mark: ✨, the Fluent Flat sparkle of "Hỏi Milu", on a mist disc, a row
/// picture's 32 (final icon review 2026-11-05: a line ✦ beside a coloured ✨ on the bar).
struct AssistantAvatar: View {
    @ScaledMetric(relativeTo: .body) private var size = IconSize.rowArtwork

    var body: some View {
        let disc = RowMetrics.capped(size, base: IconSize.rowArtwork)
        Image(IconCatalog.emojiName("✨"))
            .resizable()
            .scaledToFit()
            .frame(width: disc * 0.6, height: disc * 0.6)
            .frame(width: disc, height: disc)
            .background(Palette.surfaceMuted, in: Circle())
            .accessibilityHidden(true)
    }
}

/// The avatar and the name over each of Milu's messages: who speaks, without an avatar column
/// that would take the bubble's width.
struct AssistantSender: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            AssistantAvatar()
            Text("Milu")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .accessibilityHidden(true)
    }
}

/// Milu writing: three dots rising in turn inside the answer's own bubble, so nothing jumps when
/// the answer comes.
struct TypingIndicator: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            AssistantSender()
            TypingDots()
                .frame(height: ControlHeight.small / 2 + Spacing.xs)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background { Bubble.assistantShape }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel("Milu đang trả lời")
    }
}

/// The three dots rising in turn, alone, as the chat's typing bubble draws them.
struct TypingDots: View {
    var color: Color = Palette.secondaryLabel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var dot: CGFloat = 7

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dot, height: dot)
                    .phaseAnimator([false, true]) { content, up in
                        content
                            .offset(y: reduceMotion ? 0 : (up ? -dot / 2 : dot / 4))
                            .opacity(up ? 1 : 0.4)
                    } animation: { _ in
                        .easeInOut(duration: 0.45).delay(Double(index) * 0.15)
                    }
            }
        }
    }
}

// MARK: - Đang chuyển thành chữ (user choice 2026-11-17, "Ô nhập sáng lên")

/// What was said, on its way to words, said where the words will come: "Đang chuyển thành chữ"
/// in the blue, the light passing over it, and the three dots, in the field lit up (the chat's,
/// `ChatViewController`; the quick sheet's, `QuickRecordSheet`). User feedback 2026-11-17: "Milu
/// đang hiểu ý bạn…", grey in the field, went unseen; a bubble waiting over the field made the
/// question fly to the wrong place, the bar shrinking under it as it flew.
struct TranscribingStatus: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            ShimmerText(text: "Đang chuyển thành chữ", base: Palette.primary.opacity(0.45), shine: Palette.primary)
            TypingDots(color: Palette.primary)
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milu đang chuyển giọng nói thành chữ")
    }
}

// MARK: - Đang nghĩ (user design 2026-11-15, Figma "12 · Milu · Trợ lý AI")

/// Milu thinking, as Claude and ChatGPT show it: no bubble, no avatar, no name. "Đang nghĩ…" with
/// a light passing over it, and under it a line for each thing Milu does on the phone as it does
/// it (`AssistantProgress`), a spinner turning into ✓.
struct ThinkingIndicator: View {
    let progress: AssistantProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ShimmerText(text: "Đang nghĩ…")
            if !progress.steps.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s + 2) {
                    ForEach(progress.steps) { step in
                        ThinkingStepRow(step: step)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: -6)),
                                                    removal: .opacity))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.gentle(.spring(duration: 0.3, bounce: 0)), value: progress.steps.count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((["Milu đang nghĩ"] + progress.steps.map(\.running)).joined(separator: ", "))
    }
}

/// Words with a band of light passing over them from left to right, once every 1.6 s: the grey
/// words, and over them the same words in the label colour seen only through the band. Under
/// Reduce Motion, the grey words alone.
struct ShimmerText: View {
    let text: String
    var role: TextRole = .body
    /// The words' colour, and theirs under the passing light.
    var base: Color = Palette.tertiaryLabel
    var shine: Color = Palette.label
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        Text(text)
            .textRole(role)
            .foregroundStyle(base)
            .overlay {
                if !reduceMotion {
                    Text(text)
                        .textRole(role)
                        .foregroundStyle(shine)
                        .mask {
                            GeometryReader { proxy in
                                let band = max(proxy.size.width * 0.55, 48)
                                LinearGradient(colors: [.clear, .black, .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: band)
                                    .offset(x: -band + phase * (proxy.size.width + band))
                            }
                        }
                        .accessibilityHidden(true)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                phase = 0
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { phase = 1 }
            }
    }
}

/// One step while Milu thinks: a spinner while it runs, ✓ once done. The tools run in a moment;
/// the spinner is kept a little, so the step reads as done rather than blinking past.
private struct ThinkingStepRow: View {
    let step: ThinkingStep
    @State private var done = false

    var body: some View {
        ThoughtStepLabel(text: done ? step.done : step.running, done: done)
            .task {
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(Motion.gentle(.spring(duration: 0.3, bounce: 0.3))) { done = true }
            }
    }
}

/// A step's line: ✓ and its words in the secondary colour once done; a spinner and the label
/// colour while it runs.
struct ThoughtStepLabel: View {
    let text: String
    let done: Bool
    @ScaledMetric(relativeTo: .caption) private var mark: CGFloat = 16

    var body: some View {
        HStack(spacing: Spacing.s + 2) {
            ZStack {
                StepSpinner()
                    .opacity(done ? 0 : 1)
                    .scaleEffect(done ? 0.4 : 1)
                Image(systemName: "checkmark")
                    .font(.system(size: mark * 0.72, weight: .bold))
                    .foregroundStyle(Palette.positive)
                    .opacity(done ? 1 : 0)
                    .scaleEffect(done ? 1 : 0.4)
            }
            .frame(width: mark, height: mark)
            .accessibilityHidden(true)
            Text(text)
                .textRole(.caption)
                .foregroundStyle(done ? Palette.secondaryLabel : Palette.label)
                .contentTransition(.opacity)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A small arc turning, the step still running.
private struct StepSpinner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turned = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(Palette.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .padding(2)
            .rotationEffect(.degrees(turned ? 360 : 0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) { turned = true }
            }
    }
}

/// The line over an answer, "Đã nghĩ 4 giây · 2 bước ›": tapped, the steps open under it (and
/// close again), as Claude's "Thought for 4s".
///
/// Nothing animates while the row changes its height: an animation running in that moment, even
/// a fade, had iOS resize the chat's cell on its curve with the row centred in it, and the answer
/// dipped and came back up (user report 2026-11-15). `MessageRow` runs it: the row's height
/// changes at once, and only what is drawn moves (the steps' fade, the chevron, the words under
/// the steps sliding by the steps' height, measured here before they open).
struct ThoughtLine: View {
    let thought: ChatMessage.Thought
    /// The steps are laid out under the line.
    let expanded: Bool
    /// The steps are drawn (fading in or out while they are laid out).
    let stepsShown: Bool
    let toggle: () -> Void
    /// How much room the steps take once open, line gap included.
    let stepsRoom: (CGFloat) -> Void

    private static let gap = Spacing.s + 2

    var body: some View {
        let words = "Đã nghĩ \(thought.seconds) giây" + (thought.steps.isEmpty ? "" : " · \(thought.steps.count) bước")
        VStack(alignment: .leading, spacing: Self.gap) {
            if thought.steps.isEmpty {
                Text(words)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            } else {
                Button {
                    Haptics.selection()
                    toggle()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(words)
                        Image(systemName: "chevron.right")
                            .font(.system(size: IconSize.chevron - 2, weight: .semibold))
                            .rotationEffect(.degrees(stepsShown ? 90 : 0))
                    }
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    // 44 to tap, without the line taking 44 of the page.
                    .padding(.vertical, Spacing.m)
                    .padding(.trailing, Spacing.l)
                    .contentShape(Rectangle())
                    .padding(.vertical, -Spacing.m)
                    .padding(.trailing, -Spacing.l)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Đã nghĩ \(thought.seconds) giây, \(thought.steps.count) bước")
                .accessibilityHint(expanded ? "Ẩn các bước" : "Xem các bước")
                if expanded {
                    ThoughtSteps(steps: thought.steps)
                        .opacity(stepsShown ? 1 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The steps measured unseen, at the line's width, so their room is known before they open.
        .background(alignment: .topLeading) {
            if !thought.steps.isEmpty {
                ThoughtSteps(steps: thought.steps)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stepsRoom($0 + Self.gap) }
                    .accessibilityHidden(true)
            }
        }
    }
}

/// An answer's steps, each ✓ and its words.
private struct ThoughtSteps: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s + 2) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                ThoughtStepLabel(text: step, done: true)
            }
        }
    }
}

enum ChatMotion {
    /// Runs `change` once the chat's cell has taken a row's new height, a few frames on: an
    /// animation begun in the same moment animated the cell's height too (see `ThoughtLine`).
    static func afterResize(_ change: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { change() }
    }
}
