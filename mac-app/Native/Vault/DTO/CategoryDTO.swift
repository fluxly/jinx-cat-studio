import Foundation

struct CategoryDTO: Encodable {
    let id: String
    let name: String
    let parentId: String?
    let createdAt: String

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.parentId = category.parentId
        self.createdAt = category.createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, createdAt
        case parentId = "parent_id"
    }
}
