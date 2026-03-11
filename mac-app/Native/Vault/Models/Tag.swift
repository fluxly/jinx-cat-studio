import Foundation

struct Tag {
    let id: String
    var name: String
    var color: String
    let createdAt: String

    init(id: String = UUID().uuidString,
         name: String,
         color: String = "#808080",
         createdAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}
