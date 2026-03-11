import Foundation

struct DocumentSummaryDTO: Encodable {
    let id: String
    let title: String
    let bodySnippet: String
    let createdAt: String
    let updatedAt: String
    let tags: [TagDTO]
    let categories: [CategoryDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, tags, categories
        case bodySnippet = "body_snippet"
    }
}

struct DocumentDetailDTO: Encodable {
    let id: String
    let title: String
    let body: String
    let createdAt: String
    let updatedAt: String
    let tags: [TagDTO]
    let categories: [CategoryDTO]
    let assets: [AssetSummaryDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, body, createdAt, updatedAt, tags, categories, assets
    }
}
