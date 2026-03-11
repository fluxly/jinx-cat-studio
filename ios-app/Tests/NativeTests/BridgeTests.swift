import XCTest
@testable import MyIOSApp

final class BridgeTests: XCTestCase {

    // MARK: - BridgeMessage Parsing

    func test_validRequest_parsesCorrectly() {
        let json = """
        {"id":"req-001","namespace":"mail","method":"composeNote","params":{"subject":"Test"}}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success(let message):
            XCTAssertEqual(message.id, "req-001")
            XCTAssertEqual(message.namespace, "mail")
            XCTAssertEqual(message.method, "composeNote")
            XCTAssertEqual(message.params?["subject"] as? String, "Test")
        case .failure(let error):
            XCTFail("Expected success but got parse error: \(error.description)")
        }
    }

    func test_requestWithoutParams_parsesCorrectly() {
        let json = """
        {"id":"req-002","namespace":"meta","method":"getOptions"}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success(let message):
            XCTAssertEqual(message.id, "req-002")
            XCTAssertNil(message.params)
        case .failure(let error):
            XCTFail("Expected success but got: \(error.description)")
        }
    }

    func test_missingIdField_returnsParseError() {
        let json = """
        {"namespace":"mail","method":"composeNote"}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertTrue(error.description.lowercased().contains("id"),
                          "Error should mention missing 'id' field, got: \(error.description)")
        }
    }

    func test_missingNamespaceField_returnsParseError() {
        let json = """
        {"id":"req-003","method":"composeNote"}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertTrue(error.description.lowercased().contains("namespace"),
                          "Error should mention 'namespace', got: \(error.description)")
        }
    }

    func test_missingMethodField_returnsParseError() {
        let json = """
        {"id":"req-004","namespace":"mail"}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertTrue(error.description.lowercased().contains("method"),
                          "Error should mention 'method', got: \(error.description)")
        }
    }

    func test_emptyIdString_returnsParseError() {
        let json = """
        {"id":"","namespace":"mail","method":"composeNote"}
        """
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure for empty id")
        case .failure:
            break // expected
        }
    }

    func test_invalidJSON_returnsParseError() {
        let json = "not valid json {"
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure for invalid JSON")
        case .failure(let error):
            XCTAssertFalse(error.description.isEmpty)
        }
    }

    func test_jsonArrayRoot_returnsParseError() {
        let json = "[{\"id\":\"req-001\",\"namespace\":\"meta\",\"method\":\"getOptions\"}]"
        let result = BridgeMessage.parse(from: json)

        switch result {
        case .success:
            XCTFail("Expected failure for array root")
        case .failure(let error):
            XCTAssertFalse(error.description.isEmpty)
        }
    }

    // MARK: - BridgeRouter Routing

    func test_unknownNamespace_returnsErrorResponse() {
        let router = BridgeRouter()
        let json = """
        {"id":"req-010","namespace":"unknown","method":"foo"}
        """

        let expectation = expectation(description: "completion called")
        router.route(rawJSON: json) { responseJSON in
            let response = self.parseResponse(responseJSON)
            XCTAssertEqual(response["id"] as? String, "req-010")
            XCTAssertEqual(response["ok"] as? Bool, false)
            let error = response["error"] as? [String: Any]
            XCTAssertEqual(error?["code"] as? String, BridgeErrorCode.unknownNamespace)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_unknownMethod_returnsErrorResponse() {
        let router = BridgeRouter()
        router.register(namespace: "meta", handler: MetaHandler())

        let json = """
        {"id":"req-011","namespace":"meta","method":"nonExistentMethod"}
        """

        let expectation = expectation(description: "completion called")
        router.route(rawJSON: json) { responseJSON in
            let response = self.parseResponse(responseJSON)
            XCTAssertEqual(response["id"] as? String, "req-011")
            XCTAssertEqual(response["ok"] as? Bool, false)
            let error = response["error"] as? [String: Any]
            XCTAssertEqual(error?["code"] as? String, BridgeErrorCode.unknownMethod)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_invalidJSON_returnsErrorWithUnknownId() {
        let router = BridgeRouter()
        let json = "invalid json"

        let expectation = expectation(description: "completion called")
        router.route(rawJSON: json) { responseJSON in
            let response = self.parseResponse(responseJSON)
            XCTAssertEqual(response["ok"] as? Bool, false)
            let error = response["error"] as? [String: Any]
            XCTAssertEqual(error?["code"] as? String, BridgeErrorCode.invalidRequest)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_validMetaRequest_returnsSuccessResponse() {
        let router = BridgeRouter()
        router.register(namespace: "meta", handler: MetaHandler())

        let json = """
        {"id":"req-020","namespace":"meta","method":"getOptions"}
        """

        let expectation = expectation(description: "completion called")
        router.route(rawJSON: json) { responseJSON in
            let response = self.parseResponse(responseJSON)
            XCTAssertEqual(response["id"] as? String, "req-020")
            XCTAssertEqual(response["ok"] as? Bool, true)
            XCTAssertNotNil(response["result"])
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - BridgeResponseBuilder

    func test_successResponseFormat() {
        struct TestResult: Encodable { let value: String }
        let json = BridgeResponseBuilder.success(id: "req-100", result: TestResult(value: "hello"))

        let response = parseResponse(json)
        XCTAssertEqual(response["id"] as? String, "req-100")
        XCTAssertEqual(response["ok"] as? Bool, true)
        let result = response["result"] as? [String: Any]
        XCTAssertEqual(result?["value"] as? String, "hello")
        XCTAssertNil(response["error"])
    }

    func test_failureResponseFormat() {
        let json = BridgeResponseBuilder.failure(id: "req-200", code: "some_error", message: "Something went wrong")

        let response = parseResponse(json)
        XCTAssertEqual(response["id"] as? String, "req-200")
        XCTAssertEqual(response["ok"] as? Bool, false)
        let error = response["error"] as? [String: Any]
        XCTAssertEqual(error?["code"] as? String, "some_error")
        XCTAssertEqual(error?["message"] as? String, "Something went wrong")
        XCTAssertNil(response["result"])
    }

    func test_responseContainsOkField() {
        let successJSON = BridgeResponseBuilder.success(id: "x", result: EmptyResult())
        let failureJSON = BridgeResponseBuilder.failure(id: "y", code: "err", message: "msg")

        let success = parseResponse(successJSON)
        let failure = parseResponse(failureJSON)

        XCTAssertNotNil(success["ok"])
        XCTAssertNotNil(failure["ok"])
    }

    // MARK: - Helpers

    private func parseResponse(_ json: String) -> [String: Any] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse response JSON: \(json)")
            return [:]
        }
        return dict
    }
}

// Minimal encodable for test helper
private struct EmptyResult: Encodable {}
