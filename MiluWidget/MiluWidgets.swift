import SwiftUI
import WidgetKit

/// Milu's widgets (Figma "13 · Milu · Widget", 2026-11-19): "Ghi nhanh" and "Chi tiêu tháng này",
/// on the home and lock screens, and two buttons for Trung tâm điều khiển (iOS 18 and later).
@main
struct MiluWidgets: WidgetBundle {
    var body: some Widget {
        QuickAddWidget()
        MonthSpendingWidget()
        if #available(iOS 18.0, *) {
            AddTransactionControl()
            QuickRecordControl()
        }
    }
}
