import Foundation

// MARK: - MailNoteRequest

/// Parameters for composing a plain-text email note.
struct MailNoteRequest {
    let category: String?
    let tagPrimary: String?
    let tagSecondary: String?
    let tagTertiary: String?
    let subject: String?
    let body: String?

    /// Constructs a MailNoteRequest from bridge params.
    /// All fields are optional; missing or non-string values are treated as nil.
    static func from(params: [String: Any]?) -> MailNoteRequest {
        guard let p = params else {
            return MailNoteRequest(
                category: nil, tagPrimary: nil, tagSecondary: nil,
                tagTertiary: nil, subject: nil, body: nil
            )
        }

        return MailNoteRequest(
            category:     p["category"]     as? String,
            tagPrimary:   p["tagPrimary"]   as? String,
            tagSecondary: p["tagSecondary"] as? String,
            tagTertiary:  p["tagTertiary"]  as? String,
            subject:      p["subject"]      as? String,
            body:         p["body"]         as? String
        )
    }
}

// MARK: - MailPhotoRequest

/// Parameters for composing a photo email.
struct MailPhotoRequest {
    let category: String?
    let tagPrimary: String?
    let tagSecondary: String?
    let tagTertiary: String?
    let subject: String?
    /// Decoded JPEG data from the base64 imageBase64 param.
    let imageData: Data?

    /// Constructs a MailPhotoRequest from bridge params.
    /// Decodes `imageBase64` from base64 to Data; sets imageData to nil if decoding fails.
    static func from(params: [String: Any]?) -> MailPhotoRequest {
        guard let p = params else {
            return MailPhotoRequest(
                category: nil, tagPrimary: nil, tagSecondary: nil,
                tagTertiary: nil, subject: nil, imageData: nil
            )
        }

        // Decode the base64 image string
        var imageData: Data?
        if let base64String = p["imageBase64"] as? String, !base64String.isEmpty {
            // Strip data URI prefix if present (e.g., "data:image/jpeg;base64,...")
            let cleanBase64: String
            if let commaIndex = base64String.firstIndex(of: ",") {
                cleanBase64 = String(base64String[base64String.index(after: commaIndex)...])
            } else {
                cleanBase64 = base64String
            }
            imageData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters)
            if imageData == nil {
                AppLogger.log(.warning, "MailPhotoRequest: failed to decode imageBase64 (length=\(cleanBase64.count))")
            }
        }

        return MailPhotoRequest(
            category:     p["category"]     as? String,
            tagPrimary:   p["tagPrimary"]   as? String,
            tagSecondary: p["tagSecondary"] as? String,
            tagTertiary:  p["tagTertiary"]  as? String,
            subject:      p["subject"]      as? String,
            imageData:    imageData
        )
    }
}
