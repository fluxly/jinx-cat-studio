import UIKit

/// Presents UIImagePickerController with .camera source type and returns the captured image.
class CameraService: NSObject {

    // MARK: - Private State

    private var completion: ((UIImage?, Error?) -> Void)?

    // MARK: - Availability

    /// Returns true if camera hardware is available on this device.
    func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - Capture

    /// Presents the camera picker modally.
    /// - Parameters:
    ///   - viewController: The presenting view controller.
    ///   - completion: Called on the main thread with either the captured UIImage or an Error.
    ///                 Both being nil indicates the user cancelled.
    func capturePhoto(
        from viewController: UIViewController,
        completion: @escaping (UIImage?, Error?) -> Void
    ) {
        guard isCameraAvailable() else {
            AppLogger.log(.warning, "CameraService: camera source type not available")
            completion(nil, CameraServiceError.cameraUnavailable)
            return
        }

        self.completion = completion

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo

        AppLogger.log(.info, "CameraService: presenting UIImagePickerController")

        DispatchQueue.main.async {
            viewController.present(picker, animated: true)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension CameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let capturedImage = info[.originalImage] as? UIImage
        AppLogger.log(.info, "CameraService: image picked — size=\(capturedImage?.size ?? .zero)")

        picker.dismiss(animated: true) { [weak self] in
            self?.completion?(capturedImage, nil)
            self?.completion = nil
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        AppLogger.log(.info, "CameraService: user cancelled picker")

        picker.dismiss(animated: true) { [weak self] in
            // Pass nil, nil to signal cancellation
            self?.completion?(nil, nil)
            self?.completion = nil
        }
    }
}

// MARK: - CameraServiceError

enum CameraServiceError: Error, LocalizedError {
    case cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device."
        }
    }
}
