import Foundation

final class CategoryRepository {
    private let db: SQLiteManager

    init(db: SQLiteManager) {
        self.db = db
    }

    func findAll() throws -> [Category] {
        let rows = try db.query("""
            SELECT id, name, parent_id, created_at FROM categories ORDER BY name;
        """)
        return rows.compactMap { Category(row: $0) }
    }

    func findById(_ id: String) throws -> Category? {
        let rows = try db.query("""
            SELECT id, name, parent_id, created_at FROM categories WHERE id = ?;
        """, parameters: [id])
        return rows.first.flatMap { Category(row: $0) }
    }

    func findByName(_ name: String) throws -> Category? {
        let rows = try db.query("""
            SELECT id, name, parent_id, created_at FROM categories WHERE name = ?;
        """, parameters: [name])
        return rows.first.flatMap { Category(row: $0) }
    }

    func findChildren(ofParent parentId: String) throws -> [Category] {
        let rows = try db.query("""
            SELECT id, name, parent_id, created_at FROM categories
            WHERE parent_id = ? ORDER BY name;
        """, parameters: [parentId])
        return rows.compactMap { Category(row: $0) }
    }

    func insert(_ category: Category) throws {
        try db.execute("""
            INSERT INTO categories (id, name, parent_id, created_at) VALUES (?, ?, ?, ?);
        """, parameters: [category.id, category.name, category.parentId as Any, category.createdAt])
    }

    func update(_ category: Category) throws {
        try db.execute("""
            UPDATE categories SET name = ?, parent_id = ? WHERE id = ?;
        """, parameters: [category.name, category.parentId as Any, category.id])
    }

    func delete(_ id: String) throws {
        try db.execute("DELETE FROM categories WHERE id = ?;", parameters: [id])
    }

    func exists(_ id: String) throws -> Bool {
        let rows = try db.query("SELECT 1 FROM categories WHERE id = ? LIMIT 1;", parameters: [id])
        return !rows.isEmpty
    }
}

// MARK: - Row initializer

extension Category {
    init?(row: SQLiteRow) {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String,
              let createdAt = row["created_at"] as? String else { return nil }
        let parentId = row["parent_id"] as? String
        self.init(id: id, name: name, parentId: parentId, createdAt: createdAt)
    }
}
