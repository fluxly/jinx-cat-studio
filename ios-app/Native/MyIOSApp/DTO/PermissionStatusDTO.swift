import Foundation

/// Current permission states returned by `permissions.getStatus`.
struct PermissionStatusResult: Encodable {
    /// Camera authorization status: "authorized", "denied", "notDetermined", "restricted".
    let camera: String

    /// Mail availability: "available" or "unavailable".
    let mail: String
}
