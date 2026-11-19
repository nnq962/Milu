import AppIntents
import Foundation
import WidgetKit

/// What the home-screen widgets show, left by the app in the folder it shares with them (an App
/// Group). The widgets never open the "Milu" store: they read this small summary only. Compiled
/// into the app and the widgets (`MiluWidget`), so both read it the same way; the amounts are
/// worded in the widget, so a new day or month turns its figures over with no app running.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// The day the figures are for (its start).
    var day: Date
    /// Today's spending, as Tổng quan counts it.
    var spentToday: Double
    /// This month's spending, as Tổng quan and Hạn mức chi tiêu count it.
    var spentThisMonth: Double
    /// "Hạn mức tháng" (`StorageKey.monthlyBudget`); 0 when none is set.
    var monthlyBudget: Double
    /// This month's three latest spendings, newest first.
    var recent: [Spending]
    /// "Khoá bằng Face ID" is on: amounts stay off the home screen, where anyone can see them.
    var hidesAmounts: Bool

    /// One line of "Gần đây".
    struct Spending: Codable, Equatable, Sendable {
        /// Its category ("Ăn trưa"), as the app names it.
        var title: String
        var amount: Double
        /// Its icon's image in the shared folder (`WidgetShared.iconURL`); nil when it has none.
        var icon: String?
        /// A one-colour line icon, tinted like text; an emoji keeps its colours.
        var iconIsTemplate: Bool
    }

    /// What was spent on `date`: nothing yet on a day after the one written.
    func spentToday(on date: Date, calendar: Calendar = .current) -> Double {
        calendar.isDate(day, inSameDayAs: date) ? spentToday : 0
    }

    /// The same for the month of `date`.
    func spentThisMonth(on date: Date, calendar: Calendar = .current) -> Double {
        calendar.isDate(day, equalTo: date, toGranularity: .month) ? spentThisMonth : 0
    }

    /// "Gần đây" in the month of `date`: last month's lines are not this month's.
    func recent(on date: Date, calendar: Calendar = .current) -> [Spending] {
        calendar.isDate(day, equalTo: date, toGranularity: .month) ? recent : []
    }
}

/// The widgets' side of the app: their summary, and the links they open the app with.
nonisolated enum WidgetShared {
    /// "Ghi nhanh".
    static let quickAddKind = "MiluQuickAdd"
    /// "Chi tiêu tháng này".
    static let monthKind = "MiluMonthSpending"

    /// Where a widget asks the app to go.
    enum Link: String {
        /// "Thêm": the add form (Thêm giao dịch).
        case add
        /// "Nói với Milu": "Thêm bằng AI", listening at once.
        case ai
        /// Tổng quan.
        case overview
        /// "Hạn mức chi tiêu", where a limit is set.
        case budget

        var url: URL { URL(string: "milu://\(rawValue)")! }

        init?(_ url: URL) {
            guard url.scheme == "milu", let host = url.host(), let link = Link(rawValue: host) else { return nil }
            self = link
        }
    }

    /// Set by the app at launch: goes where a widget button asked (`OpenMiluIntent`).
    @MainActor static var onOpen: (@MainActor (Link) -> Void)?

    private static let snapshotKey = "widget.snapshot.v2"

    /// The shared folder's name, in Info.plist (`MiluAppGroup`, set per build: Milu Dev has its
    /// own). Nil if the build has none, when the widgets simply show no amounts.
    private static var appGroupID: String? {
        Bundle.main.object(forInfoDictionaryKey: "MiluAppGroup") as? String
    }

    private static var defaults: UserDefaults? { appGroupID.flatMap(UserDefaults.init(suiteName:)) }

    /// A category icon's image, drawn by the app into the shared folder: the widgets cannot read
    /// the app's own images.
    static func iconURL(_ name: String) -> URL? {
        guard let appGroupID,
              let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else { return nil }
        return folder.appending(path: "WidgetIcons", directoryHint: .isDirectory).appending(path: name + ".png")
    }

    static func read() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Leaves `snapshot` for the widgets and has iOS draw them again, only when it changed: iOS
    /// gives a widget a limited number of redraws a day.
    static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults, read() != snapshot, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// A tap on a widget's button: opens Milu where it names. iOS brings the app to the front and
/// runs this there (`openAppWhenRun`), where `WidgetShared.onOpen` takes it on. Not
/// `OpenURLIntent`: it opens web links only, and did nothing with milu:// (simulator test
/// 2026-11-19).
struct OpenMiluIntent: AppIntent {
    static let title: LocalizedStringResource = "Mở Milu"
    static let isDiscoverable = false
    static let openAppWhenRun = true

    @Parameter(title: "Màn hình") var screen: String

    init() {
        screen = WidgetShared.Link.add.rawValue
    }

    init(_ link: WidgetShared.Link) {
        screen = link.rawValue
    }

    func perform() async throws -> some IntentResult {
        if let link = WidgetShared.Link(rawValue: screen) {
            await MainActor.run { WidgetShared.onOpen?(link) }
        }
        return .result()
    }
}
