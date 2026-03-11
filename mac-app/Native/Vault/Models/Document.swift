import Foundation

struct Document {
    let id: String
    var title: String
    var body: String
    let createdAt: String
    var updatedAt: String

    init(id: String = UUID().uuidString,
         title: String = "",
         body: String = "",
         createdAt: String = ISO8601DateFormatter().string(from: Date()),
         updatedAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
