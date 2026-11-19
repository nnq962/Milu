import AppIntents
import SwiftUI
import WidgetKit

/// Milu's buttons for Trung tâm điều khiển (iOS 18 and later, Figma board 1): the same two ways
/// in as "Ghi nhanh", through the same intent. People can also put them on the Action button or
/// in the lock screen's two bottom corners. A control shows an SF Symbol, not the app's own icons.
@available(iOS 18.0, *)
struct AddTransactionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "MiluAddTransactionControl") {
            ControlWidgetButton(action: OpenMiluIntent(.add)) {
                Label("Thêm giao dịch", systemImage: "plus")
            }
        }
        .displayName("Thêm giao dịch")
        .description("Mở Milu ở màn Thêm giao dịch.")
    }
}

@available(iOS 18.0, *)
struct QuickRecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "MiluQuickRecordControl") {
            ControlWidgetButton(action: OpenMiluIntent(.ai)) {
                Label("Nói với Milu", systemImage: "mic.fill")
            }
        }
        .displayName("Nói với Milu")
        .description("Mở Thêm bằng AI, Milu nghe luôn.")
    }
}
