import UIKit

/// Handles the `camera` namespace.
///
/// Methods:
/// - `camera.capturePhoto` — Presents UIImagePickerController; returns base64 JPEG.
class CameraHandler: BridgeHandler, ViewControllerConsumer {

    weak var viewController: UIViewController?

    private let cameraService = CameraService()

    // MARK: - BridgeHandler

    func handle(message: BridgeMessage, completion: @escaping (String) -> Void) {
        switch message.method {
        case "capturePhoto":
            handleCapturePhoto(message: message, completion: completion)
        default:
            AppLogger.log(.warning, "CameraHandler: unknown method '\(message.method)'")
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownMethod,
                message: BridgeError.unknownMethod(message.method).message
            ))
        }
    }

    // MARK: - Method Implementations

    private func handleCapturePhoto(message: BridgeMessage, completion: @escaping (String) -> Void) {
        guard let vc = viewController else {
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.handlerError,
                message: "No presentation context available."
            ))
            return
        }

        guard cameraService.isCameraAvailable() else {
            AppLogger.log(.info, "CameraHandler: camera not available on this device")
            let result = PhotoCaptureResult(status: "unavailable", imageBase64: nil, error: "Camera is not available on this device.")
            completion(BridgeResponseBuilder.success(id: message.id, result: result))
            return
        }

        AppLogger.log(.info, "CameraHandler: presenting camera picker")

        cameraService.capturePhoto(from: vc) { [weak self] image, error in
            guard self != nil else { return }

            if let error = error {
                let result = PhotoCaptureResult(status: "failed", imageBase64: nil, error: error.localizedDescription)
                completion(BridgeResponseBuilder.success(id: message.id, result: result))
                return
            }

            guard let image = image else {
                // nil image, nil error means user cancelled
                let result = PhotoCaptureResult(status: "cancelled", imageBase64: nil, error: nil)
                completion(BridgeResponseBuilder.success(id: message.id, result: result))
                return
            }

            guard let base64 = ImageEncoding.toJPEGBase64(image, compressionQuality: 0.8) else {
                AppLogger.log(.error, "CameraHandler: failed to encode image to base64 JPEG")
                let result = PhotoCaptureResult(status: "failed", imageBase64: nil, error: "Image encoding failed.")
                completion(BridgeResponseBuilder.success(id: message.id, result: result))
                return
            }

            AppLogger.log(.info, "CameraHandler: photo captured, base64 length=\(base64.count)")
            let result = PhotoCaptureResult(status: "captured", imageBase64: base64, error: nil)
            completion(BridgeResponseBuilder.success(id: message.id, result: result))
        }
    }
}
