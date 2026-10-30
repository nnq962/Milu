import SwiftUI

/// A tab's own title (Tài khoản, Giao dịch), or a pushed page's with a line under it (Trợ lý AI),
/// drawn by iOS 26: large at the leading edge, shrinking to the middle of the bar as the page
/// scrolls, and sliding with the back button. A heading set in a toolbar item instead turned into a glass rectangle as a page
/// went back (user report 2026-10-30). Earlier iOS keeps the inline bar; the page sets its heading
/// as a leading item.
struct TabHeading: ViewModifier {
    /// A small line under the title, as on Trợ lý AI.
    var subtitle: String? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS's own soft scroll-edge effect, as on Tổng quan: one top edge on every tab (user
            // request 2026-10-30, after a hard one here only).
            if let subtitle {
                content.toolbarTitleDisplayMode(.inlineLarge).navigationSubtitle(subtitle)
            } else {
                content.toolbarTitleDisplayMode(.inlineLarge)
            }
        } else {
            content.navigationBarTitleDisplayMode(.inline)
        }
    }
}

