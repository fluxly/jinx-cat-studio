import AVFoundation
import MessageUI

/// Handles the `permissions` namespace.
///
/// Methods:
/// - `permissions.getStatus` — Returns current permission states for camera and mail.
class PermissionsHandler: BridgeHandler {

    // MARK: - BridgeHandler

    func handle(message: BridgeMessage, completion: @escaping (String) -> Void) {
        switch message.method {
        case "getStatus":
            handleGetStatus(message: message, completion: completion)
        default:
            AppLogger.log(.warning, "PermissionsHandler: unknown method '\(message.method)'")
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownMethod,
                message: BridgeError.unknownMethod(message.method).message
            ))
        }
    }

    // MARK: - Method Implementations

    private func handleGetStatus(message: BridgeMessage, completion: @escaping (String) -> Void) {
        let cameraStatus = cameraPermissionString()
        let mailStatus = MFMailComposeViewController.canSendMail() ? "available" : "unavailable"

        let result = PermissionStatusResult(camera: cameraStatus, mail: mailStatus)
        AppLogger.log(.info, "PermissionsHandler: camera=\(cameraStatus), mail=\(mailStatus)")
        completion(BridgeResponseBuilder.success(id: message.id, result: result))
    }

    // MARK: - Private Helpers

    private func cameraPermissionString() -> String {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:                return "authorized"
        case .denied:                    return "denied"
        case .notDetermined:             return "notDetermined"
        case .restricted:                return "restricted"
        @unknown default:                return "notDetermined"
        }
    }
}
