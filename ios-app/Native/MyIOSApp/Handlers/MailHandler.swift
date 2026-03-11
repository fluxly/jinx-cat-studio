import UIKit

/// Handles the `mail` namespace.
///
/// Methods:
/// - `mail.composeNote` — Opens MFMailComposeViewController for a text note.
/// - `mail.composePhoto` — Opens MFMailComposeViewController with a photo attachment.
class MailHandler: BridgeHandler, ViewControllerConsumer {

    weak var viewController: UIViewController?

    private let mailService = MailComposeService()

    // MARK: - BridgeHandler

    func handle(message: BridgeMessage, completion: @escaping (String) -> Void) {
        switch message.method {
        case "composeNote":
            handleComposeNote(message: message, completion: completion)
        case "composePhoto":
            handleComposePhoto(message: message, completion: completion)
        default:
            AppLogger.log(.warning, "MailHandler: unknown method '\(message.method)'")
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownMethod,
                message: BridgeError.unknownMethod(message.method).message
            ))
        }
    }

    // MARK: - Method Implementations

    private func handleComposeNote(message: BridgeMessage, completion: @escaping (String) -> Void) {
        guard let vc = viewController else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.handlerError,
                message: "No presentation context available."
            ))
            return
        }

        guard mailService.canComposeMail() else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.mailUnavailable,
                message: "Mail services are not configured on this device."
            ))
            return
        }

        let request = MailNoteRequest.from(params: message.params)
        AppLogger.log(.info, "MailHandler: composing note, subject components: category=\(request.category ?? "nil")")

        mailService.composeNote(request: request, from: vc) { [weak self] status in
            guard self != nil else { return }
            let result = MailStatusResult(status: status)
            completion(BridgeResponseBuilder.success(id: message.id, result: result))
        }
    }

    private func handleComposePhoto(message: BridgeMessage, completion: @escaping (String) -> Void) {
        guard let vc = viewController else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.handlerError,
                message: "No presentation context available."
            ))
            return
        }

        guard mailService.canComposeMail() else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.mailUnavailable,
                message: "Mail services are not configured on this device."
            ))
            return
        }

        let request = MailPhotoRequest.from(params: message.params)

        guard request.imageData != nil else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.invalidImage,
                message: "Missing or invalid imageBase64 parameter."
            ))
            return
        }

        AppLogger.log(.info, "MailHandler: composing photo mail")

        mailService.composePhoto(request: request, from: vc) { [weak self] status in
            guard self != nil else { return }
            let result = MailStatusResult(status: status)
            completion(BridgeResponseBuilder.success(id: message.id, result: result))
        }
    }
}

// MARK: - Result DTO

private struct MailStatusResult: Encodable {
    let status: String
}
