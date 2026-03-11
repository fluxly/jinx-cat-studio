import Foundation

/// Device capabilities and permission states returned by `device.getCapabilities`.
struct DeviceCapabilities: Encodable {
    /// Whether MFMailComposeViewController.canSendMail() is true.
    let hasMail: Bool

    /// Whether UIImagePickerController.isSourceTypeAvailable(.camera) is true.
    let hasCamera: Bool

    /// Camera authorization status: "authorized", "denied", "notDetermined", "restricted".
    let cameraPermission: String
}
