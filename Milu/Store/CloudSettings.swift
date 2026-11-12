import Foundation

/// The few settings kept in UserDefaults that follow the user to their other devices and survive
/// a reinstall, through iCloud's key-value store (user request 2026-11-12): the spending limits,
/// the name, the notification choices, the AI allowance (`ai.*`, so deleting the app no longer
/// gives a full week back) and whether Milu AI was ever asked (an onboarding step).
///
/// UserDefaults stays what the screens read (`@AppStorage`); this copies each change up, and what
/// comes down from another device into it. At launch what iCloud holds is copied down first: it
/// already has this device's own last writes, which were copied up as they were made.
/// Per-device choices (appearance, the last account picked, sample data) are not synced.
@MainActor
final class CloudSettings {
    static let keys: Set<String> = [StorageKey.monthlyBudget, StorageKey.categoryBudgets, StorageKey.profileName, StorageKey.profileAvatar,
                                    StorageKey.dailyReminder, StorageKey.dailyReminderMinutes,
                                    StorageKey.budgetAlerts, StorageKey.recurringAlerts, StorageKey.askedAI, BudgetAlertPlan.sentKey,
                                    StorageKey.welcomeSeen]

    static func isSynced(_ key: String) -> Bool { keys.contains(key) || AIQuota.isOwnKey(key) }

    private let defaults: UserDefaults
    private let cloud: KeyValueStore
    /// Called after values from another device were written down (the AI allowance reads again).
    var onChangeFromCloud: () -> Void = {}
    private var observers: [NSObjectProtocol] = []

    init(defaults: UserDefaults = .standard, cloud: KeyValueStore = NSUbiquitousKeyValueStore.default) {
        self.defaults = defaults
        self.cloud = cloud
    }

    /// Copies iCloud's values down, then keeps both in step. Call once, before anything reads them.
    func start() {
        cloud.synchronize()
        pull(keys: nil)
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: defaults,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.push() }
        })
        observers.append(center.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                            object: nil, queue: .main) { [weak self] note in
            let changed = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            MainActor.assumeIsolated {
                self?.pull(keys: changed)
                self?.onChangeFromCloud()
            }
        })
    }

    /// iCloud → this device, for `keys` (all of them when nil). A key iCloud no longer has
    /// (erased on another device) goes here too.
    func pull(keys: [String]?) {
        let names = keys ?? Array(cloud.dictionaryRepresentation.keys)
        for key in names where Self.isSynced(key) {
            let value = cloud.object(forKey: key)
            if !Self.same(value, defaults.object(forKey: key)) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
    }

    /// This device → iCloud: every synced key whose value differs, set or removed.
    func push() {
        let local = defaults.dictionaryRepresentation().keys.filter(Self.isSynced)
        let remote = cloud.dictionaryRepresentation.keys.filter(Self.isSynced)
        for key in Set(local).union(remote) {
            let value = defaults.object(forKey: key)
            guard !Self.same(value, cloud.object(forKey: key)) else { continue }
            if let value { cloud.set(value, forKey: key) } else { cloud.removeObject(forKey: key) }
        }
    }

    private static func same(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil): true
        case let (a?, b?): (a as AnyObject).isEqual(b)
        default: false
        }
    }
}

/// What `CloudSettings` needs of iCloud's key-value store, so tests can use one in memory.
@MainActor
protocol KeyValueStore: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
    var dictionaryRepresentation: [String: Any] { get }
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: KeyValueStore {}
