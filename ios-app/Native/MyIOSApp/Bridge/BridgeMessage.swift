import Foundation

/// Represents an inbound message from the JavaScript bridge client.
///
/// The JSON envelope format is:
/// ```json
/// { "id": "req-001", "namespace": "mail", "method": "composeNote", "params": { ... } }
/// ```
///
/// Params are stored as `[String: Any]?` because parameter values vary in type
/// across namespaces (strings, numbers, booleans). Using JSONSerialization avoids
/// the complexity of a fully generic Codable implementation.
struct BridgeMessage {
    let id: String
    let namespace: String
    let method: String
    let params: [String: Any]?

    // MARK: - Parsing

    /// Parses a raw JSON string into a BridgeMessage.
    /// Returns nil and populates the error description if parsing fails.
    static func parse(from jsonString: String) -> Result<BridgeMessage, BridgeParseError> {
        guard let data = jsonString.data(using: .utf8) else {
            return .failure(BridgeParseError(description: "Could not encode JSON string to UTF-8 data"))
        }

        let raw: Any
        do {
            raw = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return .failure(BridgeParseError(description: "JSON parse error: \(error.localizedDescription)"))
        }

        guard let dict = raw as? [String: Any] else {
            return .failure(BridgeParseError(description: "Root JSON value is not an object"))
        }

        guard let id = dict["id"] as? String, !id.isEmpty else {
            return .failure(BridgeParseError(description: "Missing or empty 'id' field"))
        }

        guard let namespace = dict["namespace"] as? String, !namespace.isEmpty else {
            return .failure(BridgeParseError(description: "Missing or empty 'namespace' field"))
        }

        guard let method = dict["method"] as? String, !method.isEmpty else {
            return .failure(BridgeParseError(description: "Missing or empty 'method' field"))
        }

        let params = dict["params"] as? [String: Any]

        return .success(BridgeMessage(id: id, namespace: namespace, method: method, params: params))
    }
}

/// Describes a failure to parse a BridgeMessage from raw JSON.
struct BridgeParseError: Error {
    let description: String
}
