import MessageUI
import SwiftUI

/// iOS's mail form inside the app, to one address with a subject (review 2026-11-09: opening the
/// Mail app did nothing useful when it had no account). Show it only when
/// `MFMailComposeViewController.canSendMail()`; otherwise offer the address to copy.
struct MailComposer: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.setToRecipients([recipient])
        mail.setSubject(subject)
        mail.mailComposeDelegate = context.coordinator
        return mail
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
