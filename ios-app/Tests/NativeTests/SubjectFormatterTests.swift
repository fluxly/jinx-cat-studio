import XCTest
@testable import MyIOSApp

final class SubjectFormatterTests: XCTestCase {

    // MARK: - All Fields Present

    func test_allFields_joinsWithColonSeparator() {
        let result = SubjectFormatter.format(
            category:     "Ideas",
            tagPrimary:   "Urgent",
            tagSecondary: "Active",
            tagTertiary:  "Done",
            subject:      "My Note"
        )
        XCTAssertEqual(result, "Ideas: Urgent: Active: Done: My Note")
    }

    // MARK: - Partial Fields

    func test_categoryAndSubjectOnly_skipsEmptyTags() {
        let result = SubjectFormatter.format(
            category:     "Work",
            tagPrimary:   "",
            tagSecondary: "",
            tagTertiary:  "",
            subject:      "Q4 Plan"
        )
        XCTAssertEqual(result, "Work: Q4 Plan")
    }

    func test_categoryAndTagPrimaryAndSubject() {
        let result = SubjectFormatter.format(
            category:     "Ideas",
            tagPrimary:   "Urgent",
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      "Notes"
        )
        XCTAssertEqual(result, "Ideas: Urgent: Notes")
    }

    func test_categoryAndTagPrimaryOnly_noSubject() {
        let result = SubjectFormatter.format(
            category:     "Tasks",
            tagPrimary:   "Important",
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "Tasks: Important")
    }

    func test_tagSecondaryPresent_tagPrimaryMissing_preservesOrder() {
        // tagPrimary is empty, so result skips it but keeps tagSecondary
        let result = SubjectFormatter.format(
            category:     "Project",
            tagPrimary:   "",
            tagSecondary: "Waiting",
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "Project: Waiting")
    }

    func test_onlyTagTertiary() {
        let result = SubjectFormatter.format(
            category:     nil,
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  "Done",
            subject:      nil
        )
        XCTAssertEqual(result, "Done")
    }

    // MARK: - Subject Only

    func test_subjectOnly_returnsSubject() {
        let result = SubjectFormatter.format(
            category:     nil,
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      "My Standalone Note"
        )
        XCTAssertEqual(result, "My Standalone Note")
    }

    // MARK: - All Empty / Nil

    func test_allNil_returnsEmptyString() {
        let result = SubjectFormatter.format(
            category:     nil,
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "")
    }

    func test_allEmptyStrings_returnsEmptyString() {
        let result = SubjectFormatter.format(
            category:     "",
            tagPrimary:   "",
            tagSecondary: "",
            tagTertiary:  "",
            subject:      ""
        )
        XCTAssertEqual(result, "")
    }

    // MARK: - Whitespace Trimming

    func test_valuesWithLeadingTrailingWhitespace_areTrimmed() {
        let result = SubjectFormatter.format(
            category:     "  Ideas  ",
            tagPrimary:   "\tUrgent\n",
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      "  My Note  "
        )
        XCTAssertEqual(result, "Ideas: Urgent: My Note")
    }

    func test_whitespaceOnlyValues_areDropped() {
        let result = SubjectFormatter.format(
            category:     "Work",
            tagPrimary:   "   ",
            tagSecondary: "\t",
            tagTertiary:  "\n",
            subject:      "Report"
        )
        XCTAssertEqual(result, "Work: Report")
    }

    func test_singleWhitespaceValue_isDropped() {
        let result = SubjectFormatter.format(
            category:     " ",
            tagPrimary:   "Urgent",
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "Urgent")
    }

    // MARK: - Single Field

    func test_singleCategoryField() {
        let result = SubjectFormatter.format(
            category:     "Journal",
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "Journal")
    }

    func test_singleTagPrimaryField() {
        let result = SubjectFormatter.format(
            category:     nil,
            tagPrimary:   "Someday",
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        XCTAssertEqual(result, "Someday")
    }

    // MARK: - Order Preservation

    func test_orderIsPreserved_categoryBeforeTags() {
        // Even if tags come before subject, the order must be C > TP > TS > TT > S
        let result = SubjectFormatter.format(
            category:     "A",
            tagPrimary:   "B",
            tagSecondary: "C",
            tagTertiary:  "D",
            subject:      "E"
        )
        XCTAssertEqual(result, "A: B: C: D: E")
    }

    func test_noSeparatorAtStartOrEnd() {
        let result = SubjectFormatter.format(
            category:     "Ideas",
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      nil
        )
        // Should not start or end with ": "
        XCTAssertFalse(result.hasPrefix(": "))
        XCTAssertFalse(result.hasSuffix(": "))
        XCTAssertEqual(result, "Ideas")
    }

    // MARK: - Edge Cases

    func test_valueContainingColon_isNotDoubled() {
        // Values that themselves contain ":" should be included as-is
        let result = SubjectFormatter.format(
            category:     "Work: Notes",
            tagPrimary:   nil,
            tagSecondary: nil,
            tagTertiary:  nil,
            subject:      "Follow-up"
        )
        XCTAssertEqual(result, "Work: Notes: Follow-up")
    }

    func test_allFiveFields_twoEmpty_outputsCorrectly() {
        let result = SubjectFormatter.format(
            category:     "Personal",
            tagPrimary:   nil,
            tagSecondary: "Waiting",
            tagTertiary:  nil,
            subject:      "Doctor Appointment"
        )
        XCTAssertEqual(result, "Personal: Waiting: Doctor Appointment")
    }
}
