import Foundation
import Observation
import StoreKit

/// Milu Pro bought through the App Store (StoreKit 2): two auto-renewing plans in one group, by
/// the month (49.000đ) and by the year (399.000đ), no trial and no lifetime (user choices
/// 2026-11-12). The App Store is the truth: what is owned is read from the current entitlements
/// on launch, after every purchase and whenever Apple says it changed (a renewal, a refund, a
/// plan bought on another device or with an offer code). The last answer is kept in UserDefaults
/// so `MiluPlan.isPro` is right before StoreKit answers, and off-line.
@MainActor
@Observable
final class ProStore {
    static let shared = ProStore()

    enum Plan: String, CaseIterable, Identifiable {
        case yearly = "com.quyetnguyen.milu.app.pro.yearly"
        case monthly = "com.quyetnguyen.milu.app.pro.monthly"

        var id: Self { self }

        var title: String {
            switch self {
            case .yearly: "Gói năm"
            case .monthly: "Gói tháng"
            }
        }
    }

    /// The plans as the App Store sells them, with their prices in the user's currency; empty
    /// until they load (or with no connection).
    private(set) var products: [Plan: Product] = [:]
    private(set) var isLoading = false
    /// Owned now, from the App Store.
    private(set) var isPro = UserDefaults.standard.bool(forKey: StorageKey.proActive)
    /// The plan owned, when there is one.
    private(set) var ownedPlan: Plan?
    /// What went wrong buying, in the user's words.
    var failure: String?
    /// Owned through the made-up purchase of a Debug build, not the App Store.
    private(set) var isMockOwned = false
    /// When the plan owned ends unless it renews.
    private(set) var expiresAt: Date?
    /// Whether it renews then: false once cancelled, when it stays until `expiresAt` and goes.
    private(set) var renews = true

    #if DEBUG
    /// Debug builds with no plan from the App Store (not set up in App Store Connect yet, or run
    /// outside Xcode's `Milu.storekit`): made-up prices, and a purchase that only says yes, so the
    /// page can be tried on the iPhone (user request 2026-11-12). Never in a Release build.
    private static let mockPrices: [Plan: Decimal] = [.monthly: 49_000, .yearly: 399_000]
    var isMocking: Bool { products.isEmpty && !isLoading }
    #else
    var isMocking: Bool { false }
    #endif

    @ObservationIgnored private var updates: Task<Void, Never>?
    /// Asks again as the plan ends: a plan running out is no change Apple reports, so a cancelled
    /// plan stayed Pro until the app was opened again (user report 2026-11-13).
    @ObservationIgnored private var expiryCheck: Task<Void, Never>?

    private init() {}

    /// From launch: the entitlements now, then every change Apple reports.
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let found = (try? await Product.products(for: Plan.allCases.map(\.rawValue))) ?? []
        products = Dictionary(uniqueKeysWithValues: found.compactMap { product in
            Plan(rawValue: product.id).map { ($0, product) }
        })
    }

    /// Buys `plan`; true when it went through. A cancel is not a failure.
    @discardableResult
    func buy(_ plan: Plan) async -> Bool {
        failure = nil
        guard let product = products[plan] else {
            #if DEBUG
            if isMocking {
                try? await Task.sleep(for: .seconds(0.8))
                UserDefaults.standard.set(plan.rawValue, forKey: StorageKey.debugMockPlan)
                await refresh()
                return true
            }
            #endif
            failure = "Chưa tải được gói. Kiểm tra kết nối mạng rồi thử lại."
            return false
        }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refresh()
                return true
            case .success(.unverified):
                failure = "Apple chưa xác nhận được giao dịch này."
            case .pending:
                // Ask to Buy, a bank's check: it comes through `Transaction.updates` later.
                failure = "Giao dịch đang chờ duyệt. Milu Pro sẽ bật khi được duyệt."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            failure = "Không mua được lúc này. Bạn thử lại sau nhé."
        }
        return false
    }

    /// "Khôi phục giao dịch mua": asks the App Store again for what this Apple ID owns.
    func restore() async {
        failure = nil
        try? await AppStore.sync()
        await refresh()
        if !isPro { failure = "Apple ID này chưa có gói Milu Pro nào." }
    }

    /// What is owned now.
    func refresh() async {
        var owned: Plan?
        var ends: Date?
        var renewing = true
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement, transaction.revocationDate == nil,
                  let plan = Plan(rawValue: transaction.productID) else { continue }
            // Lapsed already, though still listed a moment: not owned.
            if let end = transaction.expirationDate, end <= .now { continue }
            owned = plan
            ends = transaction.expirationDate
            if case .verified(let renewal)? = await transaction.subscriptionStatus?.renewalInfo {
                renewing = renewal.willAutoRenew
            }
        }
        // Each set only when it changed: asked again every time the app comes back, a same value
        // set anew still redrew every view that reads it.
        if expiresAt != ends { expiresAt = ends }
        if renews != renewing { renews = renewing }
        scheduleExpiryCheck()
        var mock = false
        #if DEBUG
        if owned == nil, let raw = UserDefaults.standard.string(forKey: StorageKey.debugMockPlan) {
            owned = Plan(rawValue: raw)
            mock = owned != nil
        }
        #endif
        if isMockOwned != mock { isMockOwned = mock }
        if ownedPlan != owned { ownedPlan = owned }
        if isPro != (owned != nil) { isPro = owned != nil }
        UserDefaults.standard.set(isPro, forKey: StorageKey.proActive)
    }

    /// A second after the plan owned ends, asks the App Store again: renewed, still Pro; lapsed
    /// (cancelled, a failed payment), back to free on the spot.
    private func scheduleExpiryCheck() {
        expiryCheck?.cancel()
        guard let expiresAt else { return }
        let wait = max(expiresAt.timeIntervalSinceNow, 0) + 1
        expiryCheck = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    #if DEBUG
    /// Ends the made-up plan, as if it had lapsed.
    func cancelMock() async {
        UserDefaults.standard.removeObject(forKey: StorageKey.debugMockPlan)
        await refresh()
    }
    #endif

    // MARK: Lời

    /// The price, from the App Store, or made up in a Debug build that has none.
    private func amount(_ plan: Plan) -> Decimal? {
        if let product = products[plan] { return product.price }
        #if DEBUG
        if isMocking { return Self.mockPrices[plan] }
        #endif
        return nil
    }

    /// Đồng as the rest of Milu writes it, "399.000đ" (user request 2026-11-12: Apple's
    /// "399.000 ₫" did not match); another currency as the App Store writes it.
    private func format(_ value: Decimal) -> String {
        if let style = products.values.first?.priceFormatStyle, style.currencyCode != "VND" {
            return value.formatted(style)
        }
        return NSDecimalNumber(decimal: value).doubleValue.vnd
    }

    /// "399.000đ", or nil until it loads.
    func price(_ plan: Plan) -> String? { amount(plan).map(format) }

    /// The year's price by the month, "33.250đ/tháng", to set beside the monthly plan.
    func yearlyPerMonth() -> String? {
        guard let year = amount(.yearly) else { return nil }
        return format(year / 12) + "/tháng"
    }

    /// How much the year saves against twelve months, "Giảm 32%" (short: it sits in the half-width
    /// plan card beside its radio).
    func yearlySaving() -> String? {
        guard let year = amount(.yearly), let month = amount(.monthly), month > 0 else { return nil }
        let saving = 1 - (year as NSDecimalNumber).doubleValue / ((month as NSDecimalNumber).doubleValue * 12)
        guard saving > 0.01 else { return nil }
        return "Giảm \(Int((saving * 100).rounded()))%"
    }
}
