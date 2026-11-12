#if DEBUG
import Foundation

/// Debug only (`-demoRecurring`): recurring rules in the states that are slow to reach by hand,
/// for trying "Giao dịch định kỳ" on the Simulator. Made once; their fixed ids keep a relaunch
/// from making them again.
extension FinanceStore {
    private static let demoIDs = (rent: UUID(uuidString: "00000000-0000-4000-8000-00000000D001")!,
                                  netflix: UUID(uuidString: "00000000-0000-4000-8000-00000000D002")!,
                                  salary: UUID(uuidString: "00000000-0000-4000-8000-00000000D003")!,
                                  oldWallet: UUID(uuidString: "00000000-0000-4000-8000-00000000D004")!)

    func seedRecurringDemo(now: Date = .now) {
        guard recurringRule(id: Self.demoIDs.rent) == nil, let wallet = usableAccounts.first else { return }
        let calendar = Calendar.current
        func monthsAgo(_ months: Int, day: Int? = nil) -> Date {
            let date = calendar.date(byAdding: .month, value: -months, to: now) ?? now
            guard let day else { return date }
            return calendar.date(bySetting: .day, value: day, of: date) ?? date
        }

        // An account archived since a rule that records by itself was set on it.
        let oldWallet = Account(id: Self.demoIDs.oldWallet, name: "Ví cũ", type: .cash, balance: 2_000_000,
                                openedAt: monthsAgo(12))
        add(oldWallet)
        if let added = account(id: oldWallet.id) { archive(added) }

        // Asks first, three months not handled: "Tới hạn … · thêm 2 lần chờ ghi".
        save(RecurringRule(id: Self.demoIDs.rent, kind: .expense, amount: 6_000_000, categoryID: "housing.rent",
                           accountID: wallet.id, note: "Tiền nhà", frequency: .monthly, interval: 1,
                           startDate: monthsAgo(3), lastHandled: nil))
        // Records by itself, on the archived account, four months waiting: "Cần chọn tài khoản".
        save(RecurringRule(id: Self.demoIDs.netflix, kind: .expense, amount: 260_000,
                           categoryID: "entertainment.movies", accountID: oldWallet.id, note: "Netflix",
                           frequency: .monthly, interval: 1, startDate: monthsAgo(4), autoRecords: true,
                           lastHandled: calendar.startOfDay(for: monthsAgo(4))))
        // Income in three days: in "Sắp tới", nothing to record yet.
        let inThreeDays = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        save(RecurringRule(id: Self.demoIDs.salary, kind: .income, amount: 25_000_000, categoryID: "salary.main",
                           accountID: wallet.id, note: "Lương", frequency: .monthly, interval: 1,
                           startDate: calendar.date(byAdding: .month, value: -1, to: inThreeDays) ?? inThreeDays,
                           lastHandled: calendar.startOfDay(for: calendar.date(byAdding: .month, value: -1, to: inThreeDays) ?? now)))
    }
}
#endif
