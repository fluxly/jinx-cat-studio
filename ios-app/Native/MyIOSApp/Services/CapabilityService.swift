import UIKit
import MessageUI
import AVFoundation

/// Queries device feature availability and permission states.
class CapabilityService {

    /// Returns a snapshot of current device capabilities.
    func getCapabilities() -> DeviceCapabilities {
        let hasMail = MFMailComposeViewController.canSendMail()
        let hasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
        let cameraPermission = cameraPermissionString()

        return DeviceCapabilities(
            hasMail: hasMail,
            hasCamera: hasCamera,
            cameraPermission: cameraPermission
        )
    }

    // MARK: - Private Helpers

    private func cameraPermissionString() -> String {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:        return "authorized"
        case .denied:            return "denied"
        case .notDetermined:     return "notDetermined"
        case .restricted:        return "restricted"
        @unknown default:        return "notDetermined"
        }
    }
}
