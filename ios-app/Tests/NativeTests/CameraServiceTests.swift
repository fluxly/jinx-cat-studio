import XCTest
@testable import MyIOSApp

final class CameraServiceTests: XCTestCase {

    // MARK: - PhotoCaptureResult Encoding

    func test_photoCaptureResult_captured_encodesCorrectly() throws {
        let result = PhotoCaptureResult(status: "captured", imageBase64: "abc123", error: nil)
        let data = try JSONEncoder().encode(result)
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(dict["status"] as? String, "captured")
        XCTAssertEqual(dict["imageBase64"] as? String, "abc123")
        XCTAssertTrue(dict["error"] is NSNull || dict["error"] == nil)
    }

    func test_photoCaptureResult_cancelled_encodesCorrectly() throws {
        let result = PhotoCaptureResult(status: "cancelled", imageBase64: nil, error: nil)
        let data = try JSONEncoder().encode(result)
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(dict["status"] as? String, "cancelled")
        XCTAssertTrue(dict["imageBase64"] is NSNull || dict["imageBase64"] == nil)
    }

    func test_photoCaptureResult_failed_includesErrorMessage() throws {
        let result = PhotoCaptureResult(status: "failed", imageBase64: nil, error: "Encoding failed.")
        let data = try JSONEncoder().encode(result)
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(dict["status"] as? String, "failed")
        XCTAssertEqual(dict["error"] as? String, "Encoding failed.")
    }

    func test_photoCaptureResult_unavailable_encodesCorrectly() throws {
        let result = PhotoCaptureResult(status: "unavailable", imageBase64: nil, error: "Camera not available.")
        let data = try JSONEncoder().encode(result)
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(dict["status"] as? String, "unavailable")
        XCTAssertEqual(dict["error"] as? String, "Camera not available.")
    }

    func test_photoCaptureResult_jsonRoundTrip_preservesAllFields() throws {
        let result = PhotoCaptureResult(status: "captured", imageBase64: "base64data==", error: nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        let jsonString = try XCTUnwrap(String(data: data, encoding: .utf8))

        // Verify it deserializes back correctly
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(dict["status"] as? String, "captured")
        XCTAssertEqual(dict["imageBase64"] as? String, "base64data==")
        XCTAssertFalse(jsonString.isEmpty)
    }

    // MARK: - ImageEncoding Base64 Round-Trip

    func test_imageEncoding_toBase64_producesNonEmptyString() {
        // Create a minimal 1x1 pixel image programmatically
        let image = makeTestImage(size: CGSize(width: 1, height: 1), color: .red)
        let base64 = ImageEncoding.toJPEGBase64(image, compressionQuality: 0.8)
        XCTAssertNotNil(base64)
        XCTAssertFalse(base64?.isEmpty ?? true)
    }

    func test_imageEncoding_roundTrip_preservesImage() throws {
        let size = CGSize(width: 20, height: 20)
        let original = makeTestImage(size: size, color: .blue)

        let base64 = try XCTUnwrap(ImageEncoding.toJPEGBase64(original, compressionQuality: 0.9))
        let decoded = try XCTUnwrap(ImageEncoding.fromBase64(base64))

        // JPEG is lossy so pixel values change, but dimensions should be preserved
        XCTAssertEqual(decoded.size.width, size.width, accuracy: 1.0)
        XCTAssertEqual(decoded.size.height, size.height, accuracy: 1.0)
    }

    func test_imageEncoding_toJPEGData_producesNonEmptyData() {
        let image = makeTestImage(size: CGSize(width: 10, height: 10), color: .green)
        let data = ImageEncoding.toJPEGData(image, compressionQuality: 0.5)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 0)
    }

    func test_imageEncoding_fromInvalidBase64_returnsNil() {
        let result = ImageEncoding.fromBase64("this is not valid base64 image data !!!")
        XCTAssertNil(result)
    }

    func test_imageEncoding_stripsDataURIPrefix() throws {
        let image = makeTestImage(size: CGSize(width: 5, height: 5), color: .black)
        let base64 = try XCTUnwrap(ImageEncoding.toJPEGBase64(image))
        let dataURI = "data:image/jpeg;base64,\(base64)"

        // fromBase64 should handle the data URI prefix
        let decoded = ImageEncoding.fromBase64(dataURI)
        XCTAssertNotNil(decoded)
    }

    func test_imageEncoding_toBase64_highCompression_smallerThanLow() throws {
        let image = makeTestImage(size: CGSize(width: 100, height: 100), color: .purple)

        let highCompression = try XCTUnwrap(ImageEncoding.toJPEGBase64(image, compressionQuality: 0.1))
        let lowCompression  = try XCTUnwrap(ImageEncoding.toJPEGBase64(image, compressionQuality: 1.0))

        XCTAssertLessThan(highCompression.count, lowCompression.count,
                          "Higher JPEG compression should produce smaller base64 output")
    }

    // MARK: - CameraService Availability

    func test_cameraService_isAvailableMethod_returnsExpectedType() {
        let service = CameraService()
        // In test environment (Simulator), this will be false; on device it may be true.
        // We just verify the method exists and returns a Bool without crashing.
        let available = service.isCameraAvailable()
        XCTAssertNotNil(available)
    }

    // MARK: - Helpers

    /// Creates a solid-color UIImage of the given size for testing.
    private func makeTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
