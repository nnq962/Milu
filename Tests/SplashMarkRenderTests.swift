import SwiftUI
import Testing
@testable import Milu

/// Draws `SplashMark` to the pictures of `LaunchMark` (light and dark, @3x). Not a check: run it
/// on its own after changing the mark, with MILU_LAUNCH_OUT set to a folder, then put the two
/// pictures in the asset catalogue.
@MainActor
struct SplashMarkRenderTests {
    @Test func drawLaunchMark() throws {
        guard let folder = ProcessInfo.processInfo.environment["MILU_LAUNCH_OUT"] else { return }
        for (scheme, name) in [(ColorScheme.light, "launch-mark"), (.dark, "launch-mark-dark")] {
            let renderer = ImageRenderer(content: SplashMark().environment(\.colorScheme, scheme))
            renderer.scale = 3
            let data = try #require(renderer.uiImage?.pngData())
            try data.write(to: URL(fileURLWithPath: folder).appending(path: "\(name)@3x.png"))
        }
    }
}
