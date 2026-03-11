import Foundation

struct Category {
    let id: String
    var name: String
    var parentId: String?
    let createdAt: String

    init(id: String = UUID().uuidString,
         name: String,
         parentId: String? = nil,
         createdAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.createdAt = createdAt
    }
}
