import Foundation

/// Encode an Encodable value to Any (JSON-compatible dictionary/array)
func encodeToAny<T: Encodable>(_ value: T) throws -> Any {
    let data = try JSONEncoder().encode(value)
    return try JSONSerialization.jsonObject(with: data, options: [])
}
