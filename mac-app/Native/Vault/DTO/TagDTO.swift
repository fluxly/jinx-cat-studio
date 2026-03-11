import Foundation

struct TagDTO: Encodable {
    let id: String
    let name: String
    let color: String
    let createdAt: String

    init(from tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.color = tag.color
        self.createdAt = tag.createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, color, createdAt
    }
}
