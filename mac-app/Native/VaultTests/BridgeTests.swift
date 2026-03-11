import XCTest
@testable import Vault

final class BridgeTests: XCTestCase {

    // MARK: - AnyCodable Tests

    func testAnyCodableEncodeString() throws {
        let value = AnyCodable("hello")
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? String, "hello")
    }

    func testAnyCodableEncodeInt() throws {
        let value = AnyCodable(42)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func testAnyCodableEncodeBool() throws {
        let value = AnyCodable(true)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Bool, true)
    }

    func testAnyCodableEncodeArray() throws {
        let value = AnyCodable([1, 2, 3] as [Any])
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "[1,2,3]")
    }

    func testAnyCodableEncodeDictionary() throws {
        let value = AnyCodable(["key": "value"] as [String: Any])
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        XCTAssertEqual(decoded["key"]?.value as? String, "value")
    }

    func testAnyCodableEncodeNull() throws {
        let value = AnyCodable(NSNull())
        let data = try JSONEncoder().encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "null")
    }

    // MARK: - BridgeMessage Decoding

    func testBridgeMessageDecoding() throws {
        let json = """
        {
            "id": "test-id-123",
            "namespace": "documents",
            "method": "list",
            "params": {}
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        XCTAssertEqual(message.id, "test-id-123")
        XCTAssertEqual(message.namespace, "documents")
        XCTAssertEqual(message.method, "list")
        XCTAssertTrue(message.params.isEmpty)
    }

    func testBridgeMessageWithParams() throws {
        let json = """
        {
            "id": "abc",
            "namespace": "documents",
            "method": "get",
            "params": {"id": "doc-123"}
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        XCTAssertEqual(message.params["id"]?.value as? String, "doc-123")
    }

    // MARK: - BridgeResponse Encoding

    func testBridgeResponseSuccessEncoding() throws {
        let response = BridgeResponse.success(id: "test-id", data: ["title": "Hello"] as Any)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["id"] as? String, "test-id")
        XCTAssertEqual(json?["success"] as? Bool, true)
        XCTAssertNil(json?["error"])
    }

    func testBridgeResponseFailureEncoding() throws {
        let error = BridgeErrorPayload(code: "NOT_FOUND", message: "Document not found")
        let response = BridgeResponse.failure(id: "test-id", error: error)
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["id"] as? String, "test-id")
        XCTAssertEqual(json?["success"] as? Bool, false)
        let errPayload = json?["error"] as? [String: Any]
        XCTAssertEqual(errPayload?["code"] as? String, "NOT_FOUND")
        XCTAssertEqual(errPayload?["message"] as? String, "Document not found")
    }

    // MARK: - BridgeError

    func testBridgeErrorCodes() {
        let err = BridgeError.notFound("test")
        XCTAssertEqual(err.code, .notFound)
        XCTAssertEqual(err.code.rawValue, "NOT_FOUND")

        let err2 = BridgeError.invalidParams("bad param")
        XCTAssertEqual(err2.code, .invalidParams)

        let err3 = BridgeError.internalError("oops")
        XCTAssertEqual(err3.code, .internalError)
    }

    // MARK: - BridgeRouter

    func testBridgeRouterUnknownNamespace() throws {
        let db = try SQLiteManager(inMemory: true)
        let docRepo = DocumentRepository(db: db)
        let assetRepo = AssetRepository(db: db)
        let tagRepo = TagRepository(db: db)
        let catRepo = CategoryRepository(db: db)

        let docService = DocumentService(repo: docRepo, tagRepo: tagRepo, categoryRepo: catRepo)
        let assetService = AssetService(repo: assetRepo, tagRepo: tagRepo, categoryRepo: catRepo)
        let tagService = TagService(repo: tagRepo)
        let catService = CategoryService(repo: catRepo)
        let searchService = SearchService(db: db)

        let tagsHandler = TagsHandler(service: tagService)
        let router = BridgeRouter(
            documentsHandler: DocumentsHandler(service: docService),
            assetsHandler: AssetsHandler(service: assetService, webView: FakeWebView()),
            tagsHandler: tagsHandler,
            categoriesHandler: CategoriesHandler(service: catService),
            searchHandler: SearchHandler(service: searchService)
        )

        let message = BridgeMessage(id: "test", namespace: "unknown", method: "list")
        let expectation = self.expectation(description: "Router responds with unknown namespace error")

        router.route(message: message) { response in
            XCTAssertFalse(response.success)
            XCTAssertEqual(response.error?.code, BridgeErrorCode.unknownNamespace.rawValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
}

// MARK: - Test helpers

import WebKit

/// A minimal WKWebView subclass for testing (doesn't actually render)
private class FakeWebView: WKWebView {
    init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }
    required init?(coder: NSCoder) { fatalError() }
}
