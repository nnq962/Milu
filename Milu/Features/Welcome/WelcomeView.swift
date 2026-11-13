import SwiftUI

/// "Chào mừng", on the very first launch (user request 2026-11-12): who Milu is and what it does,
/// in four pages swiped or stepped through, the last asking what Milu should call the user.
///
/// Each page has its own sky (the garden, the lake, the paper plane) and its own face: as the page
/// turns, the sky fades into the next and Milu takes the new face and a word (`MiluHero`, so a tap
/// still makes it react). Only the words slide, in a paged `TabView`.
///
/// Shown once: the app marks it seen when the user finishes or when the phone already holds data
/// (`AppRoot`), and the mark follows the user through iCloud (`CloudSettings`), so a reinstall
/// that brings the data back does not show it again.
struct WelcomeView: View {
    let onFinish: () -> Void

    @AppStorage(StorageKey.profileName) private var savedName = ""
    @State private var page = 0
    @State private var name = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Page {
        let look: MiluHero.Look
        /// What Milu says as it rises.
        let greeting: String
        let sky: SkyHeader.Sky
        let title: String
        let body: String
    }

    /// Every line says what the app does today.
    static let pages: [Page] = [
        Page(look: .vui, greeting: "Gâu gâu!", sky: .garden,
             title: "Chào bạn, mình là Milu!",
             body: "Người bạn nhỏ giúp bạn ghi chép thu chi mỗi ngày, nhẹ tênh mà vẫn rõ ràng."),
        Page(look: .toMo, greeting: "Hôm nay tiêu gì đó?", sky: .pond,
             title: "Ghi một chạm, rõ từng đồng",
             body: "Ghi chi tiêu trong vài giây. Milu tự cộng số dư, chia theo hạng mục và vẽ báo cáo cho bạn."),
        Page(look: .nhayMat, greeting: "Hỏi mình nè!", sky: .plane,
             title: "Hỏi Milu điều gì cũng được",
             body: "“Tháng này ăn uống hết bao nhiêu?” Hỏi bằng chữ hay giọng nói, Milu trả lời từ chính số liệu của bạn."),
        Page(look: .meMan, greeting: "Bí mật nha!", sky: .garden,
             title: "Dữ liệu là của riêng bạn",
             body: "Lưu trên máy và trong iCloud của chính bạn. Không cần tạo tài khoản, không quảng cáo."),
    ]

    private var isLast: Bool { page == Self.pages.count - 1 }
    private var current: Page { Self.pages[page] }

    /// The drawings' reference width, and Milu's faces (350 × 220, the foot on the edge at 202).
    private static let referenceWidth: CGFloat = 402
    private static let faceSize = CGSize(width: 320, height: 140)
    private static let faceEdge: CGFloat = 135

    var body: some View {
        GeometryReader { proxy in
            let top = proxy.safeAreaInsets.top
            // Half the screen for the sky; less once the keyboard is up, so the field stays in view.
            let sceneHeight = max(proxy.size.height * 0.56, 180)
            VStack(spacing: 0) {
                scene(width: proxy.size.width, height: sceneHeight + top, top: top)
                content(bottom: proxy.safeAreaInsets.bottom)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.label)
        .sensoryFeedback(.selection, trigger: page)
        .onAppear { name = savedName }
    }

    // MARK: - Cảnh

    /// The page's sky, fading into the next as the page turns, and Milu on its edge.
    private func scene(width: CGFloat, height: CGFloat, top: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                current.sky.top
                Image(current.sky.image)
                    .resizable()
                    .frame(width: width, height: width * current.sky.height / Self.referenceWidth)
                    // The drawing's top fades into the sky's colour above it: here the sky stands
                    // far taller than the drawing, and the open sky's (240 tall) met it in a line.
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [current.sky.top, current.sky.top.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: width * 0.2)
                    }
            }
            .id(page)
            .transition(.opacity)

            milu(width: width)
        }
        .frame(width: width, height: height)
        // Milu below the edge is behind the page, as on the tabs' heads.
        .clipped()
        .overlay(alignment: .topTrailing) { skipButton(top: top) }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.45), value: page)
        .accessibilityHidden(true)
    }

    /// Milu in the middle, its foot on the edge; a new page swaps its face and its word (no
    /// movement until the Rive characters, user request 2026-11-13).
    private func milu(width: CGFloat) -> some View {
        let faceWidth = min(width * 0.71, 320)
        let faceHeight = faceWidth * Self.faceSize.height / Self.faceSize.width
        let below = faceHeight * (Self.faceSize.height - Self.faceEdge) / Self.faceSize.height
        return MiluHero(look: current.look, greeting: current.greeting, bubbleSide: .aboveRight)
            .frame(width: faceWidth, height: faceHeight)
            .offset(y: below)
            .id(page)
            .transition(.identity)
    }

    @ViewBuilder private func skipButton(top: CGFloat) -> some View {
        if !isLast {
            Button("Bỏ qua") {
                withAnimation(.smooth(duration: 0.4)) { page = Self.pages.count - 1 }
            }
            .textRole(.bodyStrong)
            .foregroundStyle(current.sky.ink)
            .padding(.horizontal, Spacing.page)
            .padding(.vertical, Spacing.s)
            .contentShape(Rectangle())
            .padding(.top, top + Spacing.xs)
            .transition(.opacity)
            .accessibilityHint("Tới trang cuối")
        }
    }

    // MARK: - Lời

    private func content(bottom: CGFloat) -> some View {
        VStack(spacing: Spacing.l) {
            TabView(selection: $page) {
                ForEach(Self.pages.indices, id: \.self) { index in
                    words(Self.pages[index], isLast: index == Self.pages.count - 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            dots
            MiluButton(role: .primary, fullWidth: true, action: next) {
                Text(isLast ? "Bắt đầu cùng Milu" : "Tiếp tục")
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, Spacing.page)
        }
        .padding(.bottom, bottom > 0 ? Spacing.s : Spacing.l)
    }

    private func words(_ page: Page, isLast: Bool) -> some View {
        GeometryReader { room in
        ScrollView {
            VStack(spacing: Spacing.m) {
                Text(page.title)
                    .textRole(.pageTitle)
                    .foregroundStyle(Palette.label)
                    .accessibilityAddTraits(.isHeader)
                Text(page.body)
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
                if isLast {
                    nameField
                        .padding(.top, Spacing.s)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.page)
            .padding(.vertical, Spacing.l)
            // In the middle of the room between the sky and the dots, a little high; from the
            // top when the words outgrow it (large text), where they scroll.
            .frame(minHeight: room.size.height * 0.9, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The name Milu calls the user by (Cài đặt's card, the assistant); may be left empty.
    private var nameField: some View {
        FormGroup {
            FormTextRow(title: "Tên của bạn", text: $name, prompt: "Không bắt buộc",
                        maxLength: ProfileNameSheet.maxLength)
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(next)
        }
        .multilineTextAlignment(.leading)
    }

    /// Where the user is: the page in view a longer dash, as on "Làm quen với Milu".
    private var dots: some View {
        HStack(spacing: Spacing.xs + 2) {
            ForEach(Self.pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Palette.primary : Palette.progressTrack)
                    .frame(width: index == page ? 18 : 6, height: 6)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: page)
        .accessibilityElement()
        .accessibilityLabel("Trang \(page + 1) trên \(Self.pages.count)")
    }

    // MARK: - Đi tiếp

    private func next() {
        guard isLast else {
            withAnimation(.smooth(duration: 0.4)) { page += 1 }
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { savedName = trimmed }
        Haptics.milestone()
        onFinish()
    }
}

#Preview {
    WelcomeView {}
}
