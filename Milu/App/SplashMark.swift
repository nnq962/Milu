import SwiftUI

/// What shows as Milu opens (Figma 774:941, "C2 · Vườn nhà Milu · Xanh", 2026-11-14): "Milu" and
/// its line over a blue morning sky (night blue in dark), the garden with the pink tree below,
/// and Than sticking out its tongue at the foot. Drawn on the 402 × 874 frame of the design and
/// scaled to fill the screen, so every iPhone shows the same picture.
///
/// iOS shows the sky and the garden at once (`milu-launch-garden` filling
/// `LaunchScreen.storyboard`, in the same place); then the hold screen greets: the words fade in
/// and Than pops up from the foot ("Một nhịp chào", the design's note), and the first page fades
/// in over it.
struct SplashScene<Accessory: View>: View {
    private static var size: CGSize { SplashCaption.frame }

    /// False for the first frame, the launch picture's: then the greeting plays.
    var greeted = true
    /// How far the words move down, in the design's points, on a screen shorter than the design
    /// (iPhone SE): the scene stands on the screen's foot there, and its top, with the words,
    /// would sit under the status bar.
    var wordsDrop: CGFloat = 0
    /// The line under "Milu"; the lock says it is locked there.
    var caption = SplashCaption.tagline
    /// Under the words, in the sky: the lock's button.
    @ViewBuilder var accessory: Accessory

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The sky and the garden, one picture from the design (iOS's launch picture too).
            Image("milu-launch-garden")
                .resizable()
                .frame(width: Self.size.width, height: Self.size.height)
                .accessibilityHidden(true)
            // Figma's 8 between the lines; SwiftUI's Nunito lines are taller, so none is added.
            VStack(spacing: 0) {
                Text("Milu")
                    .font(Typography.fixedFont(size: 100, weight: .black))
                    .tracking(-2.5)
                    .foregroundStyle(Palette.deep)
                Text(caption)
                    .font(Typography.fixedFont(size: 17, weight: .medium))
                    .foregroundStyle(Palette.secondaryLabel)
                    .lineLimit(1)
                accessory
                    .padding(.top, Spacing.xl)
            }
            .frame(width: 354)
            .offset(x: 24, y: 204 - Self.titleLead + wordsDrop + (greeted ? 0 : 10))
            .opacity(greeted ? 1 : 0)
            // Than at the foot, as large as the design has it, its cut edge on the screen's;
            // before the greeting, below the screen.
            Image(MiluHero.Look.nguyenBan.image)
                .resizable()
                .scaledToFit()
                .frame(width: 632)
                .accessibilityHidden(true)
                .offset(x: -100.34, y: greeted ? 597.73 : Self.size.height + 8)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .clipped()
    }

    /// Figma sets the title on a 115 line; SwiftUI's Nunito line is a little taller, with the
    /// letters lower in it. This keeps the letters where the design draws them.
    private static var titleLead: CGFloat { 12 }
}

extension SplashScene where Accessory == EmptyView {
    init(greeted: Bool = true, caption: String = SplashCaption.tagline) {
        self.init(greeted: greeted, wordsDrop: 0, caption: caption) { EmptyView() }
    }
}

enum SplashCaption {
    static let tagline = "Bạn cứ vi vu, chi thu có Milu."
    /// The design's frame, which the scene is drawn on and scaled from.
    static let frame = CGSize(width: 402, height: 874)
}

/// The hold screen: the scene filling the screen and standing on its foot, as iOS's launch
/// picture does (`LaunchScreen.storyboard`), greeting as it appears. On its foot, not centred: on
/// a screen shorter than the design (iPhone SE) centring cut Than off at the nose (2026-11-14);
/// only plain sky goes off the top. Still (`greets` false), the same scene is the app switcher's picture and the lock
/// (`PrivacyCover`, `LockScreen`): one look for opening, away and locked (user choice 2026-11-14).
struct SplashScreen<Accessory: View>: View {
    var greets = true
    var caption = SplashCaption.tagline
    @ViewBuilder var accessory: Accessory

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var greeted = false

    /// The highest the words' line may start, from the screen's top: under the status bar.
    private static var wordsLowest: CGFloat { 72 }

    var body: some View {
        GeometryReader { proxy in
            let design = SplashCaption.frame
            let scale = max(proxy.size.width / design.width, proxy.size.height / design.height)
            // How much of the scene's top goes off the screen, in screen points.
            let cut = design.height * scale - proxy.size.height
            // The words' top kept clear of the status bar.
            let wordsTop = 204 * scale - cut
            let drop = max(Self.wordsLowest - wordsTop, 0) / scale
            SplashScene(greeted: greeted || !greets, wordsDrop: drop, caption: caption) { accessory }
                .scaleEffect(scale, anchor: .bottom)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        // Always the morning look, in the three places alike (user choice 2026-11-14): iOS's
        // launch picture is that one even in dark mode, and the lock and the app switcher's
        // picture now match it whatever Milu's "Giao diện" says.
        .environment(\.colorScheme, .light)
        // The sky's top colour behind, as the launch picture has (`milu-launch-sky`).
        .background(Color("milu-launch-sky"))
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .task {
            guard greets else { return }
            // Than glides up and settles in place as the words fade in: no bounce, which lifted
            // it past its place and showed the empty foot below it (user report 2026-11-14).
            // With Reduce Motion all is there at once, nothing moving.
            if reduceMotion {
                greeted = true
            } else {
                withAnimation(.spring(duration: 0.6, bounce: 0)) { greeted = true }
            }
        }
    }
}

/// iOS's launch picture drawn again: the sky and the garden, no words, no Than, placed as
/// `SplashScreen` places its scene. Over a new user's welcome as it opens, fading off it (user
/// request 2026-11-14), as the splash takes over from the same picture for everyone else.
struct LaunchPicture: View {
    var body: some View {
        GeometryReader { proxy in
            let design = SplashCaption.frame
            let scale = max(proxy.size.width / design.width, proxy.size.height / design.height)
            SplashScene(greeted: false)
                .scaleEffect(scale, anchor: .bottom)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .environment(\.colorScheme, .light)
        .background(Color("milu-launch-sky"))
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

extension SplashScreen where Accessory == EmptyView {
    init(greets: Bool = true) {
        self.init(greets: greets) { EmptyView() }
    }
}

#Preview {
    SplashScreen()
}
