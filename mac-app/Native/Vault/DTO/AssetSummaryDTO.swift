import Foundation

struct AssetSummaryDTO: Encodable {
    let id: String
    let filename: String
    let originalFilename: String
    let mimeType: String
    let fileSize: Int64
    let sha256: String
    let createdAt: String
    let updatedAt: String
    let tags: [TagDTO]
    let categories: [CategoryDTO]

    enum CodingKeys: String, CodingKey {
        case id, filename, mimeType, fileSize, sha256, createdAt, updatedAt, tags, categories
        case originalFilename = "original_filename"
    }
}
