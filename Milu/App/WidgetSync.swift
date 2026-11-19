import Combine
import SwiftUI
import UIKit

/// Keeps the widgets' summary (`WidgetShared`) in step with the data: today's and this month's
/// spending, the month's limit, the latest spendings, and whether amounts may show. A small view
/// of its own, so only it is read again as transactions change, not the page it sits on.
struct WidgetSync: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    /// "Khoá bằng Face ID" (`AppLock.isOn`): read here as a stored value, so turning it on or off
    /// updates the widgets at once.
    @AppStorage(StorageKey.appLock) private var lockOn = false
    @State private var today = Calendar.current.startOfDay(for: .now)

    var body: some View {
        Color.clear
            .onChange(of: snapshot, initial: true) { _, snapshot in
                for line in snapshot.recent { if let icon = line.icon { Self.drawIcon(icon) } }
                WidgetShared.write(snapshot)
            }
            // Past midnight: today's figures start again (the widgets turn over by themselves too).
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                today = Calendar.current.startOfDay(for: .now)
            }
    }

    /// Spending as Tổng quan and Báo cáo count it: reported transactions, transfer fees and loan
    /// interest, locked accounts left out (`reportableTransactions`).
    private var snapshot: WidgetSnapshot {
        let calendar = Calendar.current
        let day = DateInterval(start: today, end: calendar.date(byAdding: .day, value: 1, to: today) ?? today)
        let monthItems = store.reportableTransactions(inMonthOf: today)
        // What has happened: a spending planned for later this month is not "recent" yet.
        let recent = monthItems
            .filter { $0.kind == .expense && $0.date <= .now }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { item in
                let icon = IconCatalog.assetName(for: store.categoryIcon(item.categoryID))
                return WidgetSnapshot.Spending(title: store.title(of: item), amount: item.amount,
                                               icon: icon, iconIsTemplate: !IconCatalog.isEmoji(icon))
            }
        return WidgetSnapshot(day: today,
                              spentToday: store.total(.expense, in: day),
                              spentThisMonth: store.total(.expense, of: monthItems),
                              monthlyBudget: monthlyBudget,
                              recent: Array(recent),
                              hidesAmounts: lockOn)
    }

    /// Draws a category icon from the app's images into the shared folder, once.
    private static func drawIcon(_ name: String) {
        guard let url = WidgetShared.iconURL(name), !FileManager.default.fileExists(atPath: url.path()),
              let image = UIImage(named: name) else { return }
        let side: CGFloat = 32
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let png = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).pngData { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? png.write(to: url, options: .atomic)
    }
}
