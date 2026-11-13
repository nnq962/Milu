import SwiftUI

/// What shows as Milu opens (user choice 2026-11-13: "Cún + chữ Milu", as MoMo has its own): the
/// friendly face peeking over the word, in the middle of the page's colour. iOS shows a still
/// picture of it at once (`LaunchMark` in the asset catalogue, `UILaunchScreen` in the build
/// settings), then the app's hold screen draws the same in place while the first page gets ready,
/// so the two meet with no jump, and the page fades in over it.
///
/// `LaunchMark` is this view drawn to a picture (`SplashMarkRenderTests`): change it here, then
/// draw it again, or the two no longer match.
struct SplashMark: View {
    /// The face's width; the word is set to it.
    static let faceWidth: CGFloat = 168
    static let wordSize: CGFloat = 46
    /// The word's line starts above its letters; this much of that room goes.
    static let overlap: CGFloat = -10

    var body: some View {
        // The word close under the face, so Milu peeks over it rather than floating above.
        VStack(spacing: Self.overlap) {
            Image(MiluHero.Look.thanThien.image)
                .resizable()
                .scaledToFit()
                .frame(width: Self.faceWidth)
            Text("Milu")
                .font(Typography.font(.largeTitle, size: Self.wordSize, weight: .heavy))
                .foregroundStyle(Palette.deep)
                .fixedSize()
        }
        // The still picture iOS shows cannot follow the text size, so neither does this.
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milu")
    }
}

/// The hold screen: the page's colour edge to edge, the mark in the very middle of the screen,
/// where iOS put the still one.
struct SplashScreen: View {
    var body: some View {
        Palette.background
            .ignoresSafeArea()
            .overlay { SplashMark() }
            .ignoresSafeArea()
    }
}

#Preview {
    SplashScreen()
}
