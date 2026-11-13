import CloudKit
import CoreData
import Foundation
import Network
import Observation

/// What the iCloud sync is doing, for the screens (user request 2026-11-12: opening the app said
/// nothing about syncing). It listens to the sync's own events (setup, import, export) and asks
/// iCloud whether the iPhone is signed in.
///
/// - `isReceiving`: data is coming down from iCloud (at launch, or sent by another device), which
///   the floating "Đang đồng bộ" pill shows. Sending up after each change is not shown: it would
///   flash after every transaction.
/// - `lastSynced`: the last time a sync step succeeded, kept across launches.
/// - `problem`: why the last step failed, in the user's words; cleared by the next success.
/// - `isOffline`: the iPhone has no network. Said at once (user report 2026-11-13: with no
///   network the sync still looked busy for a long while, until iCloud gave up on its own).
@MainActor
@Observable
final class CloudSyncMonitor {
    enum AccountState: Equatable {
        case checking, available, signedOut, restricted, unavailable
    }

    private(set) var account: AccountState = .checking
    private(set) var isReceiving = false
    private(set) var lastSynced: Date?
    private(set) var problem: String?
    private(set) var isOffline = false

    @ObservationIgnored private var receiving: Set<UUID> = []
    /// Data came down since the screens last read the database (`takeNewData`).
    @ObservationIgnored private var hasNewData = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var network: NWPathMonitor?
    @ObservationIgnored private let defaults: UserDefaults
    private static let lastSyncedKey = "sync.lastSynced"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastSynced = defaults.object(forKey: Self.lastSyncedKey) as? Date
    }

    /// Starts listening; the app calls it once.
    func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification,
                                            object: nil, queue: .main) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            let update = EventUpdate(event)
            MainActor.assumeIsolated { self?.handle(update) }
        })
        observers.append(center.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkAccount() }
        })
        watchNetwork()
        checkAccount()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demoSyncPill") { playDemoRestore() }
        #endif
    }

    #if DEBUG
    /// A restore as it comes on an iPhone (rounds with short gaps between), to watch the pill on the
    /// Simulator, which has no iCloud: launch with `-demoSyncPill`.
    private func playDemoRestore() {
        if ProcessInfo.processInfo.arguments.contains("-demoBusyMainThread") {
            // As busy as a real restore, and worse: the main thread stalls 70 ms every 300 ms.
            Task {
                for _ in 0..<45 {
                    try? await Task.sleep(for: .milliseconds(300))
                    usleep(70_000)
                }
            }
        }
        Task {
            for (busy, gap) in [(2.5, 0.6), (1.5, 0.4), (1.0, 0.0)] {
                let id = UUID()
                handle(.init(id: id, isImport: true, ended: false))
                try? await Task.sleep(for: .seconds(busy))
                handle(.init(id: id, isImport: true, ended: true))
                try? await Task.sleep(for: .seconds(gap))
            }
        }
    }
    #endif

    /// The network as iOS sees it, as it changes. With none, nothing shows as coming down: a
    /// round iCloud starts then only waits, and ends whenever it gives up.
    private func watchNetwork() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let offline = path.status != .satisfied
            Task { @MainActor in self.setOffline(offline) }
        }
        monitor.start(queue: DispatchQueue(label: "milu.sync.network"))
        network = monitor
    }

    func setOffline(_ offline: Bool) {
        guard offline != isOffline else { return }
        isOffline = offline
        if offline {
            receiving.removeAll()
            if isReceiving { isReceiving = false }
        }
    }

    func checkAccount() {
        Task {
            let status = try? await CKContainer(identifier: FinanceDatabase.cloudContainerID).accountStatus()
            account = switch status {
            case .available: .available
            case .noAccount: .signedOut
            case .restricted: .restricted
            default: .unavailable
            }
        }
    }

    /// What one sync event says, copied off the notification.
    struct EventUpdate {
        let id: UUID
        let isImport: Bool
        let isSetup: Bool
        let ended: Bool
        let succeeded: Bool
        let error: Error?

        init(_ event: NSPersistentCloudKitContainer.Event) {
            id = event.identifier
            isImport = event.type == .import
            isSetup = event.type == .setup
            ended = event.endDate != nil
            succeeded = event.succeeded
            error = event.error
        }

        init(id: UUID = UUID(), isImport: Bool, isSetup: Bool = false, ended: Bool, succeeded: Bool = true, error: Error? = nil) {
            self.id = id
            self.isImport = isImport
            self.isSetup = isSetup
            self.ended = ended
            self.succeeded = succeeded
            self.error = error
        }
    }

    func handle(_ update: EventUpdate) {
        let shows = update.isImport || update.isSetup
        if !update.ended {
            if shows, !isOffline { receiving.insert(update.id) }
        } else {
            receiving.remove(update.id)
            if update.isImport, update.succeeded { hasNewData = true }
            if update.succeeded {
                problem = nil
                let now = Date.now
                lastSynced = now
                defaults.set(now, forKey: Self.lastSyncedKey)
            } else if let error = update.error {
                problem = Self.describe(error)
            }
        }
        let receivingNow = !receiving.isEmpty
        if receivingNow != isReceiving { isReceiving = receivingNow }
    }

    /// Whether data came down since the last call: the app reads the database again once the sync
    /// has gone quiet, and only then. Reading it on every change notice (sending up included) took
    /// 15–30 ms on the main thread each time and made the pill stutter (iPhone 2026-11-12: a 63 ms
    /// hitch while it moved).
    func takeNewData() -> Bool {
        defer { hasNewData = false }
        return hasNewData
    }

    /// A failed step in the user's words. A signed-out iPhone is not a problem: the account state says it.
    static func describe(_ error: Error) -> String? {
        let ckError = (error as? CKError) ?? ((error as NSError).userInfo[NSUnderlyingErrorKey] as? CKError)
        switch ckError?.code {
        case .notAuthenticated: return nil
        case .quotaExceeded: return "iCloud đã đầy, dữ liệu mới chưa được sao lưu"
        case .networkUnavailable, .networkFailure: return "Không có mạng, sẽ đồng bộ khi có mạng lại"
        case .serviceUnavailable, .requestRateLimited, .zoneBusy: return "iCloud đang bận, Milu sẽ thử lại"
        default:
            if (error as NSError).code == 134400 { return nil } // No iCloud account (CoreData).
            return "Chưa đồng bộ được, Milu sẽ thử lại"
        }
    }
}
