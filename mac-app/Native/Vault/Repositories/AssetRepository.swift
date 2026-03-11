import Foundation

final class AssetRepository {
    private let db: SQLiteManager

    init(db: SQLiteManager) {
        self.db = db
    }

    func findAll() throws -> [Asset] {
        let rows = try db.query("""
            SELECT id, filename, original_filename, mime_type, file_size, sha256, created_at, updated_at
            FROM assets
            ORDER BY updated_at DESC;
        """)
        return rows.compactMap { Asset(row: $0) }
    }

    func findById(_ id: String) throws -> Asset? {
        let rows = try db.query("""
            SELECT id, filename, original_filename, mime_type, file_size, sha256, created_at, updated_at
            FROM assets WHERE id = ?;
        """, parameters: [id])
        return rows.first.flatMap { Asset(row: $0) }
    }

    func findBySHA256(_ sha256: String) throws -> Asset? {
        let rows = try db.query("""
            SELECT id, filename, original_filename, mime_type, file_size, sha256, created_at, updated_at
            FROM assets WHERE sha256 = ? LIMIT 1;
        """, parameters: [sha256])
        return rows.first.flatMap { Asset(row: $0) }
    }

    func insert(_ asset: Asset) throws {
        try db.execute("""
            INSERT INTO assets (id, filename, original_filename, mime_type, file_size, sha256, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """, parameters: [
            asset.id, asset.filename, asset.originalFilename,
            asset.mimeType, asset.fileSize, asset.sha256,
            asset.createdAt, asset.updatedAt
        ])
    }

    func update(_ asset: Asset) throws {
        try db.execute("""
            UPDATE assets
            SET filename = ?, original_filename = ?, mime_type = ?, file_size = ?, sha256 = ?, updated_at = ?
            WHERE id = ?;
        """, parameters: [
            asset.filename, asset.originalFilename,
            asset.mimeType, asset.fileSize, asset.sha256,
            asset.updatedAt, asset.id
        ])
    }

    func delete(_ id: String) throws {
        try db.execute("DELETE FROM assets WHERE id = ?;", parameters: [id])
    }

    func exists(_ id: String) throws -> Bool {
        let rows = try db.query("SELECT 1 FROM assets WHERE id = ? LIMIT 1;", parameters: [id])
        return !rows.isEmpty
    }

    // MARK: - Tag associations

    func tagsForAsset(_ assetId: String) throws -> [Tag] {
        let rows = try db.query("""
            SELECT t.id, t.name, t.color, t.created_at
            FROM tags t
            JOIN asset_tags at ON at.tag_id = t.id
            WHERE at.asset_id = ?
            ORDER BY t.name;
        """, parameters: [assetId])
        return rows.compactMap { Tag(row: $0) }
    }

    func addTag(_ tagId: String, toAsset assetId: String) throws {
        try db.execute("""
            INSERT OR IGNORE INTO asset_tags (asset_id, tag_id) VALUES (?, ?);
        """, parameters: [assetId, tagId])
    }

    func removeTag(_ tagId: String, fromAsset assetId: String) throws {
        try db.execute("""
            DELETE FROM asset_tags WHERE asset_id = ? AND tag_id = ?;
        """, parameters: [assetId, tagId])
    }

    // MARK: - Category associations

    func categoriesForAsset(_ assetId: String) throws -> [Category] {
        let rows = try db.query("""
            SELECT c.id, c.name, c.parent_id, c.created_at
            FROM categories c
            JOIN asset_categories ac ON ac.category_id = c.id
            WHERE ac.asset_id = ?
            ORDER BY c.name;
        """, parameters: [assetId])
        return rows.compactMap { Category(row: $0) }
    }

    func addCategory(_ categoryId: String, toAsset assetId: String) throws {
        try db.execute("""
            INSERT OR IGNORE INTO asset_categories (asset_id, category_id) VALUES (?, ?);
        """, parameters: [assetId, categoryId])
    }

    func removeCategory(_ categoryId: String, fromAsset assetId: String) throws {
        try db.execute("""
            DELETE FROM asset_categories WHERE asset_id = ? AND category_id = ?;
        """, parameters: [assetId, categoryId])
    }
}

// MARK: - Row initializer

extension Asset {
    init?(row: SQLiteRow) {
        guard let id = row["id"] as? String,
              let filename = row["filename"] as? String,
              let originalFilename = row["original_filename"] as? String,
              let mimeType = row["mime_type"] as? String,
              let createdAt = row["created_at"] as? String,
              let updatedAt = row["updated_at"] as? String else { return nil }
        let fileSize = (row["file_size"] as? Int64) ?? 0
        let sha256 = (row["sha256"] as? String) ?? ""
        self.init(
            id: id,
            filename: filename,
            originalFilename: originalFilename,
            mimeType: mimeType,
            fileSize: fileSize,
            sha256: sha256,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
