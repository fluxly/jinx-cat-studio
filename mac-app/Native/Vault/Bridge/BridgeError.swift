import Foundation

enum BridgeErrorCode: String, Codable {
    case notFound = "NOT_FOUND"
    case invalidParams = "INVALID_PARAMS"
    case internalError = "INTERNAL_ERROR"
    case unknownNamespace = "UNKNOWN_NAMESPACE"
    case unknownMethod = "UNKNOWN_METHOD"
    case ioError = "IO_ERROR"
    case encodingError = "ENCODING_ERROR"
    case userCancelled = "USER_CANCELLED"
}

struct BridgeError: Error {
    let code: BridgeErrorCode
    let message: String

    init(_ code: BridgeErrorCode, _ message: String) {
        self.code = code
        self.message = message
    }

    static func notFound(_ message: String) -> BridgeError {
        BridgeError(.notFound, message)
    }

    static func invalidParams(_ message: String) -> BridgeError {
        BridgeError(.invalidParams, message)
    }

    static func internalError(_ message: String) -> BridgeError {
        BridgeError(.internalError, message)
    }

    static func unknownMethod(_ method: String, namespace: String) -> BridgeError {
        BridgeError(.unknownMethod, "Unknown method '\(method)' in namespace '\(namespace)'")
    }

    static func ioError(_ message: String) -> BridgeError {
        BridgeError(.ioError, message)
    }
}

/// Codable payload sent in bridge responses
struct BridgeErrorPayload: Encodable {
    let code: String
    let message: String

    init(code: String, message: String) {
        self.code = code
        self.message = message
    }

    init(from error: BridgeError) {
        self.code = error.code.rawValue
        self.message = error.message
    }
}
