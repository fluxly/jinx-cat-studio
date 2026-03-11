import Foundation

final class DocumentRepository {
    let db: SQLiteManager

    init(db: SQLiteManager) {
        self.db = db
    }

    func findAll() throws -> [Document] {
        let rows = try db.query("""
            SELECT id, title, body, created_at, updated_at
            FROM documents
            ORDER BY updated_at DESC;
        """)
        return rows.compactMap { Document(row: $0) }
    }

    func findById(_ id: String) throws -> Document? {
        let rows = try db.query("""
            SELECT id, title, body, created_at, updated_at
            FROM documents WHERE id = ?;
        """, parameters: [id])
        return rows.first.flatMap { Document(row: $0) }
    }

    func insert(_ document: Document) throws {
        try db.execute("""
            INSERT INTO documents (id, title, body, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?);
        """, parameters: [document.id, document.title, document.body, document.createdAt, document.updatedAt])
    }

    func update(_ document: Document) throws {
        try db.execute("""
            UPDATE documents
            SET title = ?, body = ?, updated_at = ?
            WHERE id = ?;
        """, parameters: [document.title, document.body, document.updatedAt, document.id])
    }

    func delete(_ id: String) throws {
        try db.execute("DELETE FROM documents WHERE id = ?;", parameters: [id])
    }

    func exists(_ id: String) throws -> Bool {
        let rows = try db.query("SELECT 1 FROM documents WHERE id = ? LIMIT 1;", parameters: [id])
        return !rows.isEmpty
    }

    // MARK: - Tag associations

    func tagsForDocument(_ documentId: String) throws -> [Tag] {
        let rows = try db.query("""
            SELECT t.id, t.name, t.color, t.created_at
            FROM tags t
            JOIN document_tags dt ON dt.tag_id = t.id
            WHERE dt.document_id = ?
            ORDER BY t.name;
        """, parameters: [documentId])
        return rows.compactMap { Tag(row: $0) }
    }

    func addTag(_ tagId: String, toDocument documentId: String) throws {
        try db.execute("""
            INSERT OR IGNORE INTO document_tags (document_id, tag_id) VALUES (?, ?);
        """, parameters: [documentId, tagId])
    }

    func removeTag(_ tagId: String, fromDocument documentId: String) throws {
        try db.execute("""
            DELETE FROM document_tags WHERE document_id = ? AND tag_id = ?;
        """, parameters: [documentId, tagId])
    }

    // MARK: - Category associations

    func categoriesForDocument(_ documentId: String) throws -> [Category] {
        let rows = try db.query("""
            SELECT c.id, c.name, c.parent_id, c.created_at
            FROM categories c
            JOIN document_categories dc ON dc.category_id = c.id
            WHERE dc.document_id = ?
            ORDER BY c.name;
        """, parameters: [documentId])
        return rows.compactMap { Category(row: $0) }
    }

    func addCategory(_ categoryId: String, toDocument documentId: String) throws {
        try db.execute("""
            INSERT OR IGNORE INTO document_categories (document_id, category_id) VALUES (?, ?);
        """, parameters: [documentId, categoryId])
    }

    func removeCategory(_ categoryId: String, fromDocument documentId: String) throws {
        try db.execute("""
            DELETE FROM document_categories WHERE document_id = ? AND category_id = ?;
        """, parameters: [documentId, categoryId])
    }

    // MARK: - Asset associations

    func assetsForDocument(_ documentId: String) throws -> [Asset] {
        let rows = try db.query("""
            SELECT a.id, a.filename, a.original_filename, a.mime_type, a.file_size, a.sha256, a.created_at, a.updated_at
            FROM assets a
            JOIN document_assets da ON da.asset_id = a.id
            WHERE da.document_id = ?
            ORDER BY a.original_filename;
        """, parameters: [documentId])
        return rows.compactMap { Asset(row: $0) }
    }

    func linkAsset(_ assetId: String, toDocument documentId: String) throws {
        try db.execute("""
            INSERT OR IGNORE INTO document_assets (document_id, asset_id) VALUES (?, ?);
        """, parameters: [documentId, assetId])
    }

    func unlinkAsset(_ assetId: String, fromDocument documentId: String) throws {
        try db.execute("""
            DELETE FROM document_assets WHERE document_id = ? AND asset_id = ?;
        """, parameters: [documentId, assetId])
    }
}

// MARK: - Row initializers

private extension Document {
    init?(row: SQLiteRow) {
        guard let id = row["id"] as? String,
              let title = row["title"] as? String,
              let body = row["body"] as? String,
              let createdAt = row["created_at"] as? String,
              let updatedAt = row["updated_at"] as? String else { return nil }
        self.init(id: id, title: title, body: body, createdAt: createdAt, updatedAt: updatedAt)
    }
}
