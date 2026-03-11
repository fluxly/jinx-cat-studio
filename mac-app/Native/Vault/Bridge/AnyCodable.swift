import Foundation

/// A type-erased Codable wrapper that can hold any JSON-compatible value.
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable: unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try encodeValue(value, into: &container)
    }

    private func encodeValue(_ val: Any, into container: inout SingleValueEncodingContainer) throws {
        switch val {
        case is NSNull, is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int64 as Int64:
            try container.encode(int64)
        case let double as Double:
            try container.encode(double)
        case let float as Float:
            try container.encode(Double(float))
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        case let codable as AnyCodable:
            try encodeValue(codable.value, into: &container)
        default:
            let description = "AnyCodable: cannot encode \(type(of: val))"
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: description)
            throw EncodingError.invalidValue(val, context)
        }
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) { value = NSNull() }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) { self.value = value }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) { self.value = value }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) { self.value = value }
}

extension AnyCodable: ExpressibleByStringLiteral {
    init(stringLiteral value: String) { self.value = value }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Any...) { value = elements }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, Any)...) {
        value = Dictionary(uniqueKeysWithValues: elements)
    }
}
