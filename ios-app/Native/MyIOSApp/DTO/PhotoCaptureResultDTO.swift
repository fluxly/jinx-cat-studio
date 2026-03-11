import Foundation

/// Result returned to the web layer after a camera capture attempt.
struct PhotoCaptureResult: Encodable {
    /// Capture outcome: "captured", "cancelled", "failed", "unavailable"
    let status: String

    /// Base64-encoded JPEG image string. Only present when status == "captured".
    let imageBase64: String?

    /// Human-readable error description. Only present when status == "failed".
    let error: String?
}
