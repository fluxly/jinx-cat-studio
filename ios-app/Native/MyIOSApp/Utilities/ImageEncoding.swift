import UIKit

/// Utilities for encoding and decoding UIImages.
struct ImageEncoding {

    // MARK: - Encode

    /// Encodes a UIImage as a JPEG and returns a base64 string.
    /// - Parameters:
    ///   - image: The source UIImage.
    ///   - compressionQuality: JPEG quality from 0.0 (most compressed) to 1.0 (least compressed). Default 0.8.
    /// - Returns: A base64-encoded JPEG string, or nil if encoding fails.
    static func toJPEGBase64(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        guard let data = toJPEGData(image, compressionQuality: compressionQuality) else {
            AppLogger.log(.warning, "ImageEncoding.toJPEGBase64: JPEG encoding returned nil")
            return nil
        }
        return data.base64EncodedString()
    }

    /// Encodes a UIImage as JPEG Data.
    /// - Parameters:
    ///   - image: The source UIImage.
    ///   - compressionQuality: JPEG quality from 0.0 to 1.0. Default 0.8.
    /// - Returns: JPEG-encoded Data, or nil if encoding fails.
    static func toJPEGData(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> Data? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            AppLogger.log(.warning, "ImageEncoding.toJPEGData: UIImage.jpegData returned nil")
            return nil
        }
        AppLogger.log(.debug, "ImageEncoding.toJPEGData: encoded \(data.count) bytes at quality=\(compressionQuality)")
        return data
    }

    // MARK: - Decode

    /// Decodes a base64-encoded string into a UIImage.
    /// Handles optional data URI prefix (e.g., "data:image/jpeg;base64,...").
    /// - Parameter base64: The base64 string to decode.
    /// - Returns: A UIImage, or nil if decoding fails.
    static func fromBase64(_ base64: String) -> UIImage? {
        // Strip data URI prefix if present
        let cleanBase64: String
        if let commaIndex = base64.firstIndex(of: ",") {
            cleanBase64 = String(base64[base64.index(after: commaIndex)...])
        } else {
            cleanBase64 = base64
        }

        guard let data = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters) else {
            AppLogger.log(.warning, "ImageEncoding.fromBase64: base64 decode failed")
            return nil
        }

        guard let image = UIImage(data: data) else {
            AppLogger.log(.warning, "ImageEncoding.fromBase64: UIImage(data:) returned nil")
            return nil
        }

        AppLogger.log(.debug, "ImageEncoding.fromBase64: decoded image size=\(image.size)")
        return image
    }
}
