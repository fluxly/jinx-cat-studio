import Foundation

/// Handles the `meta` namespace.
///
/// Methods:
/// - `meta.getOptions` — Returns hardcoded category and tag option lists.
class MetaHandler: BridgeHandler {

    // MARK: - Hardcoded Options

    private static let categories: [String] = [
        "Ideas", "Tasks", "Reference", "Journal",
        "Project", "Personal", "Work", "Other"
    ]

    private static let tagOptions: [String] = [
        "Urgent", "Important", "Someday", "Waiting",
        "Active", "Backlog", "Done", "Other"
    ]

    // MARK: - BridgeHandler

    func handle(message: BridgeMessage, completion: @escaping (String) -> Void) {
        switch message.method {
        case "getOptions":
            handleGetOptions(message: message, completion: completion)
        default:
            AppLogger.log(.warning, "MetaHandler: unknown method '\(message.method)'")
            completion(BridgeResponseBuilder.failure(
                id: message.id,
                code: BridgeErrorCode.unknownMethod,
                message: BridgeError.unknownMethod(message.method).message
            ))
        }
    }

    // MARK: - Method Implementations

    private func handleGetOptions(message: BridgeMessage, completion: @escaping (String) -> Void) {
        let result = MetaOptionsResult(
            categories: MetaHandler.categories,
            tagOptions: MetaHandler.tagOptions
        )
        completion(BridgeResponseBuilder.success(id: message.id, result: result))
    }
}

// MARK: - Result DTO

private struct MetaOptionsResult: Encodable {
    let categories: [String]
    let tagOptions: [String]
}
