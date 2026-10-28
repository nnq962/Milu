import SwiftUI

/// Loan card: who, due date, principal and repayment progress.
struct LoanCard: View {
    let loan: Loan

    var body: some View {
        let borrowed = loan.direction == .borrowed
        DebtCardLayout(
            avatar: { InitialsAvatar(name: loan.name) },
            title: loan.name,
            subtitle: loan.isSettled ? "\(loan.direction.title) · Đã tất toán" : loan.dueDate?.dueDescription ?? "Không có hạn trả",
            amount: loan.principal.vndCompact,
            amountColor: borrowed ? Palette.red : Palette.ink,
            progress: loan.paidRatio,
            progressColor: borrowed ? Palette.red : Palette.primary,
            leading: loan.isSettled ? "Đã trả đủ" : loan.paidRatio > 0 ? "Đã trả \(loan.paidRatio.percentText)" : "Chưa trả",
            trailing: "Còn \(loan.outstanding.vndCompact)"
        )
        .accessibilityHint("Sửa khoản vay")
    }
}

/// A credit card balance shown as borrowing; progress is the share of the limit in use.
struct CreditCardDebtCard: View {
    let card: Account

    var body: some View {
        let debt = -card.balance
        let limit = card.creditLimit ?? 0
        let used = limit > 0 ? debt / limit : 0
        DebtCardLayout(
            avatar: {
                if let institution = card.institution {
                    InstitutionLogo(image: institution.logoImage, size: 44)
                } else {
                    IconCircle(icon: card.type.icon)
                }
            },
            title: card.name,
            subtitle: card.paymentDueDate?.dueDescription ?? card.detail,
            amount: debt.vndCompact,
            amountColor: Palette.red,
            progress: used,
            progressColor: Palette.red,
            leading: limit > 0 ? "Đã dùng \(used.percentText) hạn mức" : "Chưa đặt hạn mức",
            trailing: limit > 0 ? "Còn hạn mức \(max(limit - debt, 0).vndCompact)" : ""
        )
    }
}

struct DebtCardLayout<Avatar: View>: View {
    @ViewBuilder let avatar: Avatar
    let title: String
    let subtitle: String
    let amount: String
    let amountColor: Color
    let progress: Double
    let progressColor: Color
    let leading: String
    let trailing: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                avatar
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .textRole(.body)
                        .lineLimit(1)
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(amount)
                    .textRole(.amount)
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
            }
            ProgressBar(value: progress, color: progressColor)
                .padding(.top, 16)
            HStack {
                Text(leading)
                Spacer()
                Text(trailing)
            }
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            .padding(.top, 8)
        }
        .sleekCard(padding: 16)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
