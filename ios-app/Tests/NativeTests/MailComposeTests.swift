import XCTest
@testable import MyIOSApp

final class MailComposeTests: XCTestCase {

    // MARK: - MailNoteRequest Parsing

    func test_mailNoteRequest_parsesAllFields() {
        let params: [String: Any] = [
            "category":     "Ideas",
            "tagPrimary":   "Urgent",
            "tagSecondary": "Active",
            "tagTertiary":  "Done",
            "subject":      "My Subject",
            "body":         "Body text here."
        ]

        let request = MailNoteRequest.from(params: params)

        XCTAssertEqual(request.category,     "Ideas")
        XCTAssertEqual(request.tagPrimary,   "Urgent")
        XCTAssertEqual(request.tagSecondary, "Active")
        XCTAssertEqual(request.tagTertiary,  "Done")
        XCTAssertEqual(request.subject,      "My Subject")
        XCTAssertEqual(request.body,         "Body text here.")
    }

    func test_mailNoteRequest_nilParamsYieldsAllNil() {
        let request = MailNoteRequest.from(params: nil)

        XCTAssertNil(request.category)
        XCTAssertNil(request.tagPrimary)
        XCTAssertNil(request.tagSecondary)
        XCTAssertNil(request.tagTertiary)
        XCTAssertNil(request.subject)
        XCTAssertNil(request.body)
    }

    func test_mailNoteRequest_emptyParamsYieldsAllNil() {
        let request = MailNoteRequest.from(params: [:])

        XCTAssertNil(request.category)
        XCTAssertNil(request.tagPrimary)
        XCTAssertNil(request.body)
    }

    func test_mailNoteRequest_partialParams() {
        let params: [String: Any] = [
            "category": "Work",
            "subject":  "Weekly Sync"
        ]

        let request = MailNoteRequest.from(params: params)

        XCTAssertEqual(request.category, "Work")
        XCTAssertNil(request.tagPrimary)
        XCTAssertNil(request.tagSecondary)
        XCTAssertNil(request.tagTertiary)
        XCTAssertEqual(request.subject, "Weekly Sync")
        XCTAssertNil(request.body)
    }

    func test_mailNoteRequest_ignoresNonStringValues() {
        let params: [String: Any] = [
            "category": 42,         // wrong type
            "subject":  "Valid",
            "body":     true        // wrong type
        ]

        let request = MailNoteRequest.from(params: params)

        // Non-string values are treated as nil
        XCTAssertNil(request.category)
        XCTAssertEqual(request.subject, "Valid")
        XCTAssertNil(request.body)
    }

    // MARK: - MailPhotoRequest Parsing

    func test_mailPhotoRequest_parsesBase64Image() {
        // Create a tiny valid base64-encoded PNG (1x1 red pixel)
        // Using a simple known-good JPEG base64 fragment (won't be a valid image but tests decode path)
        let sampleBase64 = Data("SampleImageData".utf8).base64EncodedString()

        let params: [String: Any] = [
            "category":    "Work",
            "subject":     "Photo",
            "imageBase64": sampleBase64
        ]

        let request = MailPhotoRequest.from(params: params)

        XCTAssertEqual(request.category, "Work")
        XCTAssertEqual(request.subject, "Photo")
        // imageData should be non-nil since we provided valid base64
        XCTAssertNotNil(request.imageData)
    }

    func test_mailPhotoRequest_missingImageBase64_yieldsNilImageData() {
        let params: [String: Any] = [
            "category": "Work"
        ]

        let request = MailPhotoRequest.from(params: params)

        XCTAssertNil(request.imageData)
    }

    func test_mailPhotoRequest_emptyImageBase64_yieldsNilImageData() {
        let params: [String: Any] = [
            "imageBase64": ""
        ]

        let request = MailPhotoRequest.from(params: params)

        XCTAssertNil(request.imageData)
    }

    func test_mailPhotoRequest_stripsDataURIPrefix() {
        let rawData = Data("SampleImageData".utf8)
        let base64 = rawData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"

        let params: [String: Any] = [
            "imageBase64": dataURI
        ]

        let request = MailPhotoRequest.from(params: params)

        // Should strip the data URI prefix and decode correctly
        XCTAssertNotNil(request.imageData)
        XCTAssertEqual(request.imageData, rawData)
    }

    func test_mailPhotoRequest_nilParams_yieldsAllNil() {
        let request = MailPhotoRequest.from(params: nil)

        XCTAssertNil(request.category)
        XCTAssertNil(request.subject)
        XCTAssertNil(request.imageData)
    }

    // MARK: - Subject Construction via SubjectFormatter

    func test_subjectConstruction_fromNoteRequest() {
        let params: [String: Any] = [
            "category":   "Ideas",
            "tagPrimary": "Urgent",
            "subject":    "Big Idea"
        ]
        let request = MailNoteRequest.from(params: params)

        let subject = SubjectFormatter.format(
            category:     request.category,
            tagPrimary:   request.tagPrimary,
            tagSecondary: request.tagSecondary,
            tagTertiary:  request.tagTertiary,
            subject:      request.subject
        )

        XCTAssertEqual(subject, "Ideas: Urgent: Big Idea")
    }

    func test_subjectConstruction_allParamsMissing_emptySubject() {
        let request = MailNoteRequest.from(params: nil)

        let subject = SubjectFormatter.format(
            category:     request.category,
            tagPrimary:   request.tagPrimary,
            tagSecondary: request.tagSecondary,
            tagTertiary:  request.tagTertiary,
            subject:      request.subject
        )

        XCTAssertEqual(subject, "")
    }

    func test_subjectConstruction_fromPhotoRequest() {
        let sampleBase64 = Data("img".utf8).base64EncodedString()
        let params: [String: Any] = [
            "category":    "Work",
            "tagPrimary":  "Active",
            "subject":     "Site Photo",
            "imageBase64": sampleBase64
        ]
        let request = MailPhotoRequest.from(params: params)

        let subject = SubjectFormatter.format(
            category:     request.category,
            tagPrimary:   request.tagPrimary,
            tagSecondary: request.tagSecondary,
            tagTertiary:  request.tagTertiary,
            subject:      request.subject
        )

        XCTAssertEqual(subject, "Work: Active: Site Photo")
    }

    // MARK: - MailComposeService.recipientEmail

    func test_recipientEmail_isHardcoded() {
        XCTAssertEqual(MailComposeService.recipientEmail, "fluxama@gmail.com")
    }
}
