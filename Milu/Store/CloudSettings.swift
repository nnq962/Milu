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
    /// The synced keys this device held when it last exchanged with iCloud. One gone from the
    /// device since was erased here, and is erased in iCloud too; one only iCloud has has not come
    /// down yet and is left alone (audit 2026-11-15: taken for erased here, a reinstall's first
    /// sync erased every setting in iCloud, on every device).
    private var exchangedKeys: Set<String> = []
    /// Inside `pull`: its writes come from iCloud, they are not changes to send back up (audit
    /// 2026-11-15: each write pushed the keys not yet written, old or missing, back up mid-loop).
    private var isPulling = false

    init(defaults: UserDefaults = .standard, cloud: KeyValueStore = NSUbiquitousKeyValueStore.default) {
        self.defaults = defaults
        self.cloud = cloud
        exchangedKeys = localKeys()
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
        isPulling = true
        defer {
            isPulling = false
            exchangedKeys = localKeys()
        }
        let names = keys ?? Array(cloud.dictionaryRepresentation.keys)
        for key in names where Self.isSynced(key) {
            let value = cloud.object(forKey: key)
            if !Self.same(value, defaults.object(forKey: key)) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
    }

    /// This device → iCloud: every synced key whose value differs, and every one erased here since
    /// the last exchange.
    func push() {
        guard !isPulling else { return }
        let local = localKeys()
        for key in local {
            let value = defaults.object(forKey: key)
            if !Self.same(value, cloud.object(forKey: key)) { cloud.set(value, forKey: key) }
        }
        for key in exchangedKeys.subtracting(local) where cloud.object(forKey: key) != nil {
            cloud.removeObject(forKey: key)
        }
        exchangedKeys = local
    }

    private func localKeys() -> Set<String> {
        Set(defaults.dictionaryRepresentation().keys.filter(Self.isSynced))
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
