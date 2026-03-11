import Foundation

/// Handles the `device` namespace.
///
/// Methods:
/// - `device.getCapabilities` — Returns device feature flags and permission states.
class DeviceHandler: BridgeHandler {

    private let capabilityService = CapabilityService()

    // MARK: - BridgeHandler

    func handle(message: BridgeMessage, completion: @escaping (String) -> Void) {
        switch message.method {
        case "getCapabilities":
            handleGetCapabilities(message: message, completion: completion)
        default:
            AppLogger.log(.warning, "DeviceHandler: unknown method '\(message.method)'")
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownMethod,
                message: BridgeError.unknownMethod(message.method).message
            ))
        }
    }

    // MARK: - Method Implementations

    private func handleGetCapabilities(message: BridgeMessage, completion: @escaping (String) -> Void) {
        let capabilities = capabilityService.getCapabilities()
        AppLogger.log(.info, "DeviceHandler: capabilities — hasMail=\(capabilities.hasMail), hasCamera=\(capabilities.hasCamera), cameraPermission=\(capabilities.cameraPermission)")
        completion(BridgeResponseBuilder.success(id: message.id, result: capabilities))
    }
}
