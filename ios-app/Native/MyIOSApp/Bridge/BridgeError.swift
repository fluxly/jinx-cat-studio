import Foundation

// MARK: - Error Codes (constants)

enum BridgeErrorCode {
    static let invalidRequest    = "invalid_request"
    static let unknownNamespace  = "unknown_namespace"
    static let unknownMethod     = "unknown_method"
    static let handlerError      = "handler_error"
    static let mailUnavailable   = "mail_unavailable"
    static let invalidParams     = "invalid_params"
    static let invalidImage      = "invalid_image"
    static let cameraUnavailable = "camera_unavailable"
    static let captureFailed     = "capture_failed"
    static let encodingFailed    = "encoding_failed"
}

// MARK: - BridgeError

/// Typed errors produced during bridge message processing.
enum BridgeError: Error {
    /// The incoming JSON could not be parsed or is missing required fields.
    case invalidRequest(String)

    /// No handler is registered for the given namespace.
    case unknownNamespace(String)

    /// The handler does not recognise the method name.
    case unknownMethod(String)

    /// A handler-level error occurred during execution.
    case handlerError(String)

    // MARK: - Derived Properties

    /// Machine-readable error code for inclusion in the bridge response.
    var code: String {
        switch self {
        case .invalidRequest:   return BridgeErrorCode.invalidRequest
        case .unknownNamespace: return BridgeErrorCode.unknownNamespace
        case .unknownMethod:    return BridgeErrorCode.unknownMethod
        case .handlerError:     return BridgeErrorCode.handlerError
        }
    }

    /// Human-readable description for the `message` field in the error response.
    var message: String {
        switch self {
        case .invalidRequest(let detail):
            return "Invalid request: \(detail)"
        case .unknownNamespace(let ns):
            return "No handler registered for namespace '\(ns)'."
        case .unknownMethod(let method):
            return "Unknown method '\(method)'."
        case .handlerError(let detail):
            return "Handler error: \(detail)"
        }
    }
}
