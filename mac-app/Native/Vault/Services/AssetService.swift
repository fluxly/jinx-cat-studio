import Foundation
import CryptoKit

final class AssetService {
    private let repo: AssetRepository
    private let tagRepo: TagRepository
    private let categoryRepo: CategoryRepository
    private let assetsDirectory: URL

    init(repo: AssetRepository, tagRepo: TagRepository, categoryRepo: CategoryRepository) {
        self.repo = repo
        self.tagRepo = tagRepo
        self.categoryRepo = categoryRepo
        self.assetsDirectory = Self.makeAssetsDirectory()
    }

    private static func makeAssetsDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.jinxcatstudio.vault/assets")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func listAssets() throws -> [AssetSummaryDTO] {
        let assets = try repo.findAll()
        return try assets.map { try makeSummaryDTO(for: $0) }
    }

    func getAsset(_ id: String) throws -> AssetSummaryDTO {
        guard let asset = try repo.findById(id) else {
            throw BridgeError.notFound("Asset '\(id)' not found")
        }
        return try makeSummaryDTO(for: asset)
    }

    /// Imports a file from a source URL into the vault's asset storage.
    func importAsset(from sourceURL: URL) throws -> AssetSummaryDTO {
        let originalFilename = sourceURL.lastPathComponent
        let mimeType = mimeTypeForExtension(sourceURL.pathExtension)

        let data = try Data(contentsOf: sourceURL)
        let sha256 = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        let fileSize = Int64(data.count)

        // Deduplicate by SHA256
        if let existing = try repo.findBySHA256(sha256) {
            return try makeSummaryDTO(for: existing)
        }

        let id = UUID().uuidString
        let ext = sourceURL.pathExtension.isEmpty ? "bin" : sourceURL.pathExtension
        let filename = "\(id).\(ext)"
        let destURL = assetsDirectory.appendingPathComponent(filename)

        try data.write(to: destURL)

        let now = isoNow()
        let asset = Asset(
            id: id,
            filename: filename,
            originalFilename: originalFilename,
            mimeType: mimeType,
            fileSize: fileSize,
            sha256: sha256,
            createdAt: now,
            updatedAt: now
        )
        try repo.insert(asset)
        return try makeSummaryDTO(for: asset)
    }

    func updateAsset(_ id: String, originalFilename: String?) throws -> AssetSummaryDTO {
        guard var asset = try repo.findById(id) else {
            throw BridgeError.notFound("Asset '\(id)' not found")
        }
        if let name = originalFilename { asset.originalFilename = name }
        asset.updatedAt = isoNow()
        try repo.update(asset)
        return try makeSummaryDTO(for: asset)
    }

    func deleteAsset(_ id: String) throws {
        guard let asset = try repo.findById(id) else {
            throw BridgeError.notFound("Asset '\(id)' not found")
        }
        let fileURL = assetsDirectory.appendingPathComponent(asset.filename)
        try repo.delete(id)
        // Remove file if it exists; ignore errors (file might already be gone)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func fileURL(for assetId: String) throws -> URL {
        guard let asset = try repo.findById(assetId) else {
            throw BridgeError.notFound("Asset '\(assetId)' not found")
        }
        return assetsDirectory.appendingPathComponent(asset.filename)
    }

    // MARK: - Private helpers

    private func makeSummaryDTO(for asset: Asset) throws -> AssetSummaryDTO {
        let tags = try repo.tagsForAsset(asset.id).map { TagDTO(from: $0) }
        let categories = try repo.categoriesForAsset(asset.id).map { CategoryDTO(from: $0) }
        return AssetSummaryDTO(
            id: asset.id,
            filename: asset.filename,
            originalFilename: asset.originalFilename,
            mimeType: asset.mimeType,
            fileSize: asset.fileSize,
            sha256: asset.sha256,
            createdAt: asset.createdAt,
            updatedAt: asset.updatedAt,
            tags: tags,
            categories: categories
        )
    }

    private func mimeTypeForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "md": return "text/markdown"
        case "html": return "text/html"
        case "json": return "application/json"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "zip": return "application/zip"
        default: return "application/octet-stream"
        }
    }
}

private func isoNow() -> String {
    ISO8601DateFormatter().string(from: Date())
}
