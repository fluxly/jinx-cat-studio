import Foundation

/// Constructs email subject lines from structured metadata.
///
/// Algorithm:
/// 1. Collect optional values in order: category, tagPrimary, tagSecondary, tagTertiary, subject
/// 2. Trim whitespace from each value
/// 3. Discard nil, empty, and whitespace-only values
/// 4. Join remaining values with ": "
///
/// Examples:
/// - category="Ideas", tagPrimary="Urgent", subject="Notes" → "Ideas: Urgent: Notes"
/// - category="Work", subject="Q4 Plan" → "Work: Q4 Plan"
/// - all nil/empty → ""
/// - subject="My Note" only → "My Note"
struct SubjectFormatter {

    /// Formats a subject line from the provided metadata components.
    /// - Parameters:
    ///   - category: Optional category string.
    ///   - tagPrimary: Optional primary tag string.
    ///   - tagSecondary: Optional secondary tag string.
    ///   - tagTertiary: Optional tertiary tag string.
    ///   - subject: Optional subject string.
    /// - Returns: A formatted subject string, or empty string if all inputs are blank.
    static func format(
        category: String?,
        tagPrimary: String?,
        tagSecondary: String?,
        tagTertiary: String?,
        subject: String?
    ) -> String {
        let components: [String?] = [category, tagPrimary, tagSecondary, tagTertiary, subject]

        let filtered = components.compactMap { value -> String? in
            guard let v = value else { return nil }
            let trimmed = v.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return filtered.joined(separator: ": ")
    }
}
