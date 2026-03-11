import Foundation

final class DocumentService {
    private let repo: DocumentRepository
    private let assetRepo: AssetRepository
    private let tagRepo: TagRepository
    private let categoryRepo: CategoryRepository

    init(repo: DocumentRepository, tagRepo: TagRepository, categoryRepo: CategoryRepository) {
        self.repo = repo
        // AssetRepository shares the same SQLiteManager instance
        self.assetRepo = AssetRepository(db: repo.db)
        self.tagRepo = tagRepo
        self.categoryRepo = categoryRepo
    }

    func listDocuments() throws -> [DocumentSummaryDTO] {
        let documents = try repo.findAll()
        return try documents.map { doc in
            let tags = try repo.tagsForDocument(doc.id).map { TagDTO(from: $0) }
            let categories = try repo.categoriesForDocument(doc.id).map { CategoryDTO(from: $0) }
            let snippet = String(doc.body.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
            return DocumentSummaryDTO(
                id: doc.id,
                title: doc.title,
                bodySnippet: snippet,
                createdAt: doc.createdAt,
                updatedAt: doc.updatedAt,
                tags: tags,
                categories: categories
            )
        }
    }

    func getDocument(_ id: String) throws -> DocumentDetailDTO {
        guard let doc = try repo.findById(id) else {
            throw BridgeError.notFound("Document '\(id)' not found")
        }
        let tags = try repo.tagsForDocument(id).map { TagDTO(from: $0) }
        let categories = try repo.categoriesForDocument(id).map { CategoryDTO(from: $0) }
        let assets = try repo.assetsForDocument(id)
        let assetDTOs = try assets.map { asset -> AssetSummaryDTO in
            let assetTags = try assetRepo.tagsForAsset(asset.id).map { TagDTO(from: $0) }
            let assetCats = try assetRepo.categoriesForAsset(asset.id).map { CategoryDTO(from: $0) }
            return AssetSummaryDTO(
                id: asset.id,
                filename: asset.filename,
                originalFilename: asset.originalFilename,
                mimeType: asset.mimeType,
                fileSize: asset.fileSize,
                sha256: asset.sha256,
                createdAt: asset.createdAt,
                updatedAt: asset.updatedAt,
                tags: assetTags,
                categories: assetCats
            )
        }
        return DocumentDetailDTO(
            id: doc.id,
            title: doc.title,
            body: doc.body,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt,
            tags: tags,
            categories: categories,
            assets: assetDTOs
        )
    }

    func createDocument(title: String, body: String) throws -> DocumentDetailDTO {
        let now = isoNow()
        let doc = Document(id: UUID().uuidString, title: title, body: body, createdAt: now, updatedAt: now)
        try repo.insert(doc)
        return DocumentDetailDTO(
            id: doc.id,
            title: doc.title,
            body: doc.body,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt,
            tags: [],
            categories: [],
            assets: []
        )
    }

    func updateDocument(_ id: String, title: String?, body: String?) throws -> DocumentDetailDTO {
        guard var doc = try repo.findById(id) else {
            throw BridgeError.notFound("Document '\(id)' not found")
        }
        if let title = title { doc.title = title }
        if let body = body { doc.body = body }
        doc.updatedAt = isoNow()
        try repo.update(doc)
        return try getDocument(id)
    }

    func deleteDocument(_ id: String) throws {
        guard try repo.exists(id) else {
            throw BridgeError.notFound("Document '\(id)' not found")
        }
        try repo.delete(id)
    }
}

private func isoNow() -> String {
    ISO8601DateFormatter().string(from: Date())
}
