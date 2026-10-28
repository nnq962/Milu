import Foundation

// Translation between the database rows (TimiSchemaV1) and the value types the screens use.
// Screens still work in `Double`; money is rounded to whole đồng at this boundary.

extension Int64 {
    /// Whole đồng from an amount the screens hold as `Double`.
    init(dong amount: Double) {
        self = amount.isFinite ? Int64(amount.rounded()) : 0
    }
}

extension Double {
    init(dong amount: Int64) {
        self = Double(amount)
    }
}

// MARK: - Tài khoản

extension Account {
    init(_ record: AccountRecord) {
        self.init(
            id: record.id,
            name: record.name,
            type: AccountType(rawValue: record.type) ?? .cash,
            balance: Double(dong: record.balance),
            detail: record.detail,
            creditLimit: record.creditLimit.map { Double(dong: $0) },
            paymentDueDate: record.paymentDueDate,
            institutionID: record.institutionID,
            openedAt: record.createdAt,
            excluded: record.excluded
        )
    }
}

extension AccountRecord {
    func apply(_ account: Account) {
        name = account.name
        type = account.type.rawValue
        institutionID = account.institutionID
        detail = account.detail
        balance = Int64(dong: account.balance)
        creditLimit = account.creditLimit.map { Int64(dong: $0) }
        paymentDueDate = account.paymentDueDate
        // V1 has no separate opened date: the row's createdAt holds the date the user picked.
        createdAt = account.openedAt
        excluded = account.excluded
        updatedAt = .now
    }
}

// MARK: - Hũ tiết kiệm (an account of type "savings")

extension SavingsGoal {
    static let accountType = "savings"

    init(_ record: AccountRecord) {
        self.init(
            id: record.id,
            name: record.name,
            icon: GoalIcon(rawValue: record.goalIcon ?? "") ?? .piggyBank,
            saved: Double(dong: record.balance),
            target: Double(dong: record.goalTarget ?? 0)
        )
    }
}

extension AccountRecord {
    func apply(_ goal: SavingsGoal) {
        name = goal.name
        type = SavingsGoal.accountType
        institutionID = nil
        balance = Int64(dong: goal.saved)
        goalTarget = Int64(dong: goal.target)
        goalIcon = goal.icon.rawValue
        updatedAt = .now
    }
}

// MARK: - Hạng mục

extension CategoryRecord {
    convenience init(_ category: TransactionCategory, sortOrder: Int) {
        self.init(id: category.rawValue, kind: category.kind.rawValue, name: category.title,
                  icon: category.icon, isBuiltIn: true, sortOrder: sortOrder)
    }
}

// MARK: - Giao dịch

extension FinanceTransaction {
    /// Nil for a row the screens cannot show yet (a transfer, or one without an account).
    init?(_ record: TransactionRecord) {
        guard record.kind != "transfer", let accountID = record.accountID else { return nil }
        let fallback: TransactionCategory = record.kind == TransactionKind.income.rawValue ? .otherIncome : .otherExpense
        self.init(
            id: record.id,
            title: record.title,
            amount: Double(dong: record.amount),
            category: record.categoryID.flatMap(TransactionCategory.init(rawValue:)) ?? fallback,
            accountID: accountID,
            date: record.occurredAt,
            note: record.note
        )
    }
}

extension TransactionRecord {
    func apply(_ transaction: FinanceTransaction) {
        kind = transaction.kind.rawValue
        amount = Int64(dong: transaction.amount)
        accountID = transaction.accountID
        fromAccountID = nil
        toAccountID = nil
        categoryID = transaction.category.rawValue
        title = transaction.title
        note = transaction.note
        occurredAt = transaction.date
        updatedAt = .now
    }
}

// MARK: - Vay nợ

extension Loan {
    init(_ record: LoanRecord) {
        self.init(
            id: record.id,
            name: record.counterparty,
            direction: LoanDirection(rawValue: record.direction) ?? .lent,
            principal: Double(dong: record.principal),
            outstanding: Double(dong: record.outstanding),
            dueDate: record.dueDate
        )
    }
}

extension LoanRecord {
    func apply(_ loan: Loan) {
        direction = loan.direction.rawValue
        counterparty = loan.name
        principal = Int64(dong: loan.principal)
        outstanding = Int64(dong: loan.outstanding)
        dueDate = loan.dueDate
        settledAt = loan.isSettled ? (settledAt ?? .now) : nil
        updatedAt = .now
    }
}

// MARK: - Lịch thanh toán

extension PaymentReminder {
    init(_ record: ReminderRecord) {
        self.init(
            id: record.id,
            title: record.title,
            amount: Double(dong: record.amount),
            isIncome: record.isIncome,
            dueDate: record.dueDate,
            detail: record.detail,
            avatar: record.avatarKind == "initials" ? .initials(record.avatarValue) : .icon(record.avatarValue)
        )
    }
}

extension ReminderRecord {
    func apply(_ reminder: PaymentReminder) {
        title = reminder.title
        amount = Int64(dong: reminder.amount)
        isIncome = reminder.isIncome
        dueDate = reminder.dueDate
        detail = reminder.detail
        switch reminder.avatar {
        case .initials(let letters):
            avatarKind = "initials"
            avatarValue = letters
        case .icon(let name):
            avatarKind = "icon"
            avatarValue = name
        }
        updatedAt = .now
    }
}
