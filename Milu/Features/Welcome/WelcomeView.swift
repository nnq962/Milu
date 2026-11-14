import SwiftUI

/// "Chào mừng", on the very first launch: Bản 05 · Trưng bày sản phẩm (Figma 824:3568, user
/// choice 2026-11-14), its motion as the approved Rive demo (design/rive/milu-welcome-05).
///
/// Four pages, stepped through with the button or swiped: Gặp Milu, Ghi chép, Trợ lý AI, then
/// the name Milu calls the user by and an avatar. Over each, the stage (`WelcomeStage`) shows the
/// app's own pieces on one sky, Than peeking from behind them; below, the page's words.
///
/// Shown once: the app marks it seen when the user finishes or when the phone already holds data
/// (`MiluApp`), and the mark follows the user through iCloud (`CloudSettings`), so a reinstall
/// that brings the data back does not show it again.
struct WelcomeView: View {
    let onFinish: () -> Void

    @AppStorage(StorageKey.profileName) private var savedName = ""
    @AppStorage(StorageKey.profileAvatar) private var savedAvatar = ""
    @State private var page = WelcomePage.meet
    /// Which way the last turn went: the words slide that way.
    @State private var forward = true
    @State private var name = ""
    @State private var avatar = MiluHero.Look.thanThien
    @State private var than = WelcomeThan.shared
    @State private var finishing = false
    /// An avatar was tapped: only then, or with none saved yet, is it saved. Seen again (Cài đặt,
    /// Debug), the page would otherwise put Thân thiện over a face chosen elsewhere.
    @State private var avatarChosen = false
    @FocusState private var nameFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The room the words take under the stage, as Figma's at the default text size: two lines
    /// of title and one of text; on the last page the title, the name and the avatars.
    @ScaledMetric(relativeTo: .body) private var wordsRoom: CGFloat = 122
    @ScaledMetric(relativeTo: .body) private var formRoom: CGFloat = 275

    /// The avatars Milu offers, in Figma's order; Thân thiện chosen to begin with.
    static let avatars: [MiluHero.Look] = [.nguyenBan, .thanThien, .vui, .nhayMat, .toMo]

    var body: some View {
        GeometryReader { proxy in
            let scale = stageScale(in: proxy.size)
            VStack(spacing: 0) {
                navigation
                WelcomeStage(page: page, than: than, avatarFace: WelcomeThan.Face(avatar), scale: scale,
                             finishing: finishing)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.selection()
                        than.hop()
                    }
                words
                    .padding(.top, 28 * min(scale, 1))
                Spacer(minLength: Spacing.l)
                footer
            }
            .padding(.bottom, Spacing.m)
            // The whole page takes the swipe, its empty room too, not only the words.
            .contentShape(Rectangle())
        }
        // The keyboard covers the page's lower part rather than squeezing the stage: the field
        // stays where it is, above it (iPhone 16 Pro, SE).
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.label)
        .simultaneousGesture(swipe)
        .sensoryFeedback(.selection, trigger: page)
        .onAppear {
            #if DEBUG
            // `-welcomePage 2` opens on a page, for checking one (0 to 3).
            if UserDefaults.standard.object(forKey: "welcomePage") != nil,
               let start = WelcomePage(rawValue: UserDefaults.standard.integer(forKey: "welcomePage")) {
                page = start
            }
            #endif
            name = savedName
            if case .milu(let look) = ProfileAvatar(raw: savedAvatar), Self.avatars.contains(look) { avatar = look }
        }
    }

    /// Figma's stage is 370 × 404 on a 402-point screen; smaller screens and larger text get a
    /// smaller one, the same on every page so it does not jump as the pages turn.
    private func stageScale(in size: CGSize) -> CGFloat {
        let fixed: CGFloat = 46 + 28 + Spacing.l + 6 + 20 + ControlHeight.regular + 14 + 19 + Spacing.m
        let byWidth = (size.width - 32) / WelcomeStage.size.width
        let byPages = (size.height - fixed - wordsRoom) / WelcomeStage.size.height
        let byProfile = (size.height - fixed - formRoom) / WelcomeStage.profileHeight
        return max(min(byWidth, byPages, byProfile), 0.5)
    }

    // MARK: - Trên

    /// "Bỏ qua" on the first three pages, to the name; "Quay lại" on the last, to the chat.
    private var navigation: some View {
        ZStack {
            if page == .profile {
                navButton("Quay lại", hint: "Về trang trước") { go(to: .assistant) }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            } else {
                navButton("Bỏ qua", hint: "Tới trang cuối") { go(to: .profile) }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
            }
        }
        .frame(height: 46, alignment: .top)
        .padding(.horizontal, Spacing.l)
    }

    private func navButton(_ title: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .textRole(.button)
                .foregroundStyle(Palette.primary)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: ControlHeight.regular)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(y: -1)
        .allowsHitTesting(!finishing)
        .accessibilityHint(hint)
    }

    // MARK: - Lời

    private var words: some View {
        ZStack(alignment: .top) {
            Group {
                switch page {
                case .meet: copy("Chào bạn,\nmình là Milu!", "Bạn cứ vi vu, chi thu có Milu.")
                case .record: copy("Ghi một chạm,\nrõ từng đồng.", "Số dư, hạng mục, báo cáo, Milu tự lo.")
                case .assistant: copy("Cứ nói,\nMilu lo phần còn lại.", "Ghi, sửa hay hỏi số liệu bằng lời.")
                case .profile:
                    WelcomeProfileForm(name: $name, avatar: $avatar, focused: $nameFocused) {
                        avatarChosen = true
                        than.hop()
                    }
                }
            }
            .id(page)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(x: reduceMotion ? 0 : (forward ? 12 : -12)))
                    // On the last page, once the stage has closed up over it: sooner, the title
                    // came in over the stage still shrinking.
                    .animation(.easeOut(duration: 0.3).delay(page == .profile ? 0.3 : 0.12)),
                removal: .opacity.combined(with: .offset(x: reduceMotion ? 0 : (forward ? -12 : 12)))
                    .animation(.easeOut(duration: 0.14))))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xxl)
    }

    private func copy(_ title: String, _ body: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .textRole(.hero)
                .foregroundStyle(Palette.label)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Dưới

    private var footer: some View {
        VStack(spacing: 0) {
            progress
            MiluButton(role: .primary, fullWidth: true, action: next) {
                Text(buttonTitle)
                    .contentTransition(.opacity)
            }
            // Not `disabled`: greyed, the button flashed as the welcome went (2026-11-14).
            .allowsHitTesting(!finishing)
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, 20)
            ZStack {
                foot
                    .id(page)
                    .transition(.opacity)
            }
            .frame(height: 19)
            .padding(.top, 14)
        }
    }

    private var buttonTitle: String {
        switch page {
        case .meet: "Làm quen với Milu"
        case .record, .assistant: "Tiếp tục"
        case .profile: "Vào Milu"
        }
    }

    /// The quiet line under the button: no account, the free questions, changed later.
    @ViewBuilder private var foot: some View {
        Group {
            switch page {
            case .meet: Text("Không cần tạo tài khoản")
            case .record: Color.clear
            case .assistant:
                HStack(spacing: Spacing.xs) {
                    Image(IconCatalog.emojiName("✨"))
                        .resizable()
                        .frame(width: 13, height: 13)
                        .accessibilityHidden(true)
                    Text("Miễn phí 10 lượt/tuần · Pro nhiều hơn")
                }
            case .profile: Text("Đổi lại bất cứ lúc nào trong Cài đặt")
            }
        }
        .textRole(.caption)
        .foregroundStyle(Palette.tertiaryLabel)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// Where the user is: the page in view a longer dash.
    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(WelcomePage.allCases, id: \.self) { item in
                Capsule()
                    .fill(item == page ? Palette.primary : Palette.controlBorder)
                    .frame(width: item == page ? 28 : 8, height: 6)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: page)
        .accessibilityElement()
        .accessibilityLabel("Trang \(page.rawValue + 1) trên \(WelcomePage.allCases.count)")
    }

    // MARK: - Đi tiếp

    /// Left to the next page, right to the one before; never past the last, which finishes only
    /// with its button.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let width = value.translation.width
                guard abs(width) > 60, abs(width) > abs(value.translation.height) * 1.5, !finishing else { return }
                if width < 0, let next = WelcomePage(rawValue: page.rawValue + 1) {
                    go(to: next)
                } else if width > 0, let previous = WelcomePage(rawValue: page.rawValue - 1) {
                    go(to: previous)
                }
            }
    }

    private func go(to target: WelcomePage) {
        guard target != page else { return }
        forward = target.rawValue > page.rawValue
        nameFocused = false
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.4)) { page = target }
    }

    private func next() {
        if let next = WelcomePage(rawValue: page.rawValue + 1) {
            go(to: next)
        } else {
            finish()
        }
    }

    /// The name (may stay empty) and the avatar are saved; Than is happy, then the app opens.
    private func finish() {
        guard !finishing else { return }
        finishing = true
        nameFocused = false
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { savedName = trimmed }
        if avatarChosen || savedAvatar.isEmpty { savedAvatar = ProfileAvatar.milu(avatar).raw }
        than.hop()
        Haptics.milestone()
        // A beat for Than's hop, then the app builds Tổng quan under this page and fades it.
        Task { @MainActor in
            if !reduceMotion { try? await Task.sleep(for: .seconds(0.35)) }
            onFinish()
        }
    }
}

/// The last page's words: what Milu calls the user (may be left empty) and an avatar, each
/// coming in a beat after the title.
private struct WelcomeProfileForm: View {
    @Binding var name: String
    @Binding var avatar: MiluHero.Look
    var focused: FocusState<Bool>.Binding
    let onChoose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fieldShown = false
    @State private var avatarsShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Milu gọi bạn là gì?")
                .textRole(.hero)
                .foregroundStyle(Palette.label)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            field
                .padding(.top, Spacing.l)
                .offset(y: fieldShown ? 0 : 14)
                .opacity(fieldShown ? 1 : 0)
            avatars
                .padding(.top, Spacing.l)
                .offset(y: avatarsShown ? 0 : 14)
                .opacity(avatarsShown ? 1 : 0)
        }
        .task {
            if reduceMotion {
                fieldShown = true
                avatarsShown = true
                return
            }
            try? await Task.sleep(for: .seconds(0.18))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { fieldShown = true }
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { avatarsShown = true }
        }
    }

    private var field: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Tên của bạn · Không bắt buộc")
                .textRole(.button)
                .foregroundStyle(Palette.label)
            TextField("Tên của bạn", text: $name,
                      prompt: Text("Tên hoặc biệt danh").foregroundStyle(Palette.tertiaryLabel))
                .textRole(.body)
                .foregroundStyle(Palette.label)
                // A name as typed: autocorrect "fixed" Vietnamese names (review 2026-11-09).
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused(focused)
                .onSubmit { focused.wrappedValue = false }
                .onChange(of: name) { _, new in
                    if new.count > ProfileNameSheet.maxLength { name = String(new.prefix(ProfileNameSheet.maxLength)) }
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous)
                        .strokeBorder(focused.wrappedValue ? Palette.primary : Palette.tertiaryLabel, lineWidth: 1)
                }
                .contentShape(Rectangle())
                .onTapGesture { focused.wrappedValue = true }
        }
    }

    private var avatars: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chọn avatar")
                .textRole(.button)
                .foregroundStyle(Palette.label)
            HStack(spacing: 0) {
                ForEach(WelcomeView.avatars, id: \.self) { look in
                    if look != WelcomeView.avatars.first { Spacer(minLength: 0) }
                    choice(look)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: avatar)
    }

    private func choice(_ look: MiluHero.Look) -> some View {
        let selected = avatar == look
        return Button {
            guard avatar != look else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) { avatar = look }
            onChoose()
        } label: {
            ProfileAvatarView(avatar: .milu(look), size: 56)
                .padding(3)
                .overlay {
                    Circle()
                        .strokeBorder(Palette.primary, lineWidth: 2.5)
                        .scaleEffect(selected ? 1 : 0.86)
                        .opacity(selected ? 1 : 0)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Avatar Milu")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    WelcomeView {}
}
