import UIKit
import MessageUI

/// Presents MFMailComposeViewController for composing text notes or photo emails.
///
/// The recipient is hardcoded to `fluxama@gmail.com`.
/// Subject lines are constructed by `SubjectFormatter`.
class MailComposeService: NSObject {

    // MARK: - Constants

    static let recipientEmail = "fluxama@gmail.com"

    // MARK: - Private State

    /// Holds the completion closure across the async presentation/dismissal lifecycle.
    private var completion: ((String) -> Void)?

    // MARK: - Availability

    /// Returns true if MFMailComposeViewController can be presented on this device.
    func canComposeMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }

    // MARK: - Compose Note

    /// Presents MFMailComposeViewController for a plain-text note.
    /// - Parameters:
    ///   - request: Metadata and body for the note.
    ///   - viewController: The presenting view controller.
    ///   - completion: Called with status string: "sent" | "saved" | "cancelled" | "failed".
    func composeNote(
        request: MailNoteRequest,
        from viewController: UIViewController,
        completion: @escaping (String) -> Void
    ) {
        guard canComposeMail() else {
            AppLogger.log(.warning, "MailComposeService: canSendMail() is false")
            completion("failed")
            return
        }

        self.completion = completion

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([MailComposeService.recipientEmail])

        let subject = SubjectFormatter.format(
            category: request.category,
            tagPrimary: request.tagPrimary,
            tagSecondary: request.tagSecondary,
            tagTertiary: request.tagTertiary,
            subject: request.subject
        )

        if !subject.isEmpty {
            composer.setSubject(subject)
        }

        if let body = request.body, !body.isEmpty {
            composer.setMessageBody(body, isHTML: false)
        }

        AppLogger.log(.info, "MailComposeService: presenting note composer, subject='\(subject)'")

        DispatchQueue.main.async {
            viewController.present(composer, animated: true)
        }
    }

    // MARK: - Compose Photo

    /// Presents MFMailComposeViewController with a JPEG photo attachment.
    /// - Parameters:
    ///   - request: Metadata and image data for the photo email.
    ///   - viewController: The presenting view controller.
    ///   - completion: Called with status string: "sent" | "saved" | "cancelled" | "failed".
    func composePhoto(
        request: MailPhotoRequest,
        from viewController: UIViewController,
        completion: @escaping (String) -> Void
    ) {
        guard canComposeMail() else {
            AppLogger.log(.warning, "MailComposeService: canSendMail() is false")
            completion("failed")
            return
        }

        guard let imageData = request.imageData else {
            AppLogger.log(.error, "MailComposeService: composePhoto called without valid imageData")
            completion("failed")
            return
        }

        self.completion = completion

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([MailComposeService.recipientEmail])

        let subject = SubjectFormatter.format(
            category: request.category,
            tagPrimary: request.tagPrimary,
            tagSecondary: request.tagSecondary,
            tagTertiary: request.tagTertiary,
            subject: request.subject
        )

        if !subject.isEmpty {
            composer.setSubject(subject)
        }

        // Generate a filename from the subject or fallback
        let filename = subject.isEmpty ? "photo.jpg" : "\(subject).jpg"
        composer.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: filename)

        AppLogger.log(.info, "MailComposeService: presenting photo composer, subject='\(subject)', attachment size=\(imageData.count) bytes")

        DispatchQueue.main.async {
            viewController.present(composer, animated: true)
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MailComposeService: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        let status: String
        switch result {
        case .sent:         status = "sent"
        case .saved:        status = "saved"
        case .cancelled:    status = "cancelled"
        case .failed:       status = "failed"
        @unknown default:   status = "failed"
        }

        if let error = error {
            AppLogger.log(.error, "MailComposeService: finished with error: \(error.localizedDescription)")
        } else {
            AppLogger.log(.info, "MailComposeService: finished with status='\(status)'")
        }

        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(status)
            self?.completion = nil
        }
    }
}
