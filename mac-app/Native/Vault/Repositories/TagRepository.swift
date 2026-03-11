import Foundation

final class TagRepository {
    private let db: SQLiteManager

    init(db: SQLiteManager) {
        self.db = db
    }

    func findAll() throws -> [Tag] {
        let rows = try db.query("""
            SELECT id, name, color, created_at FROM tags ORDER BY name;
        """)
        return rows.compactMap { Tag(row: $0) }
    }

    func findById(_ id: String) throws -> Tag? {
        let rows = try db.query("""
            SELECT id, name, color, created_at FROM tags WHERE id = ?;
        """, parameters: [id])
        return rows.first.flatMap { Tag(row: $0) }
    }

    func findByName(_ name: String) throws -> Tag? {
        let rows = try db.query("""
            SELECT id, name, color, created_at FROM tags WHERE name = ?;
        """, parameters: [name])
        return rows.first.flatMap { Tag(row: $0) }
    }

    func insert(_ tag: Tag) throws {
        try db.execute("""
            INSERT INTO tags (id, name, color, created_at) VALUES (?, ?, ?, ?);
        """, parameters: [tag.id, tag.name, tag.color, tag.createdAt])
    }

    func update(_ tag: Tag) throws {
        try db.execute("""
            UPDATE tags SET name = ?, color = ? WHERE id = ?;
        """, parameters: [tag.name, tag.color, tag.id])
    }

    func delete(_ id: String) throws {
        try db.execute("DELETE FROM tags WHERE id = ?;", parameters: [id])
    }

    func exists(_ id: String) throws -> Bool {
        let rows = try db.query("SELECT 1 FROM tags WHERE id = ? LIMIT 1;", parameters: [id])
        return !rows.isEmpty
    }
}

// MARK: - Row initializer

extension Tag {
    init?(row: SQLiteRow) {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String,
              let color = row["color"] as? String,
              let createdAt = row["created_at"] as? String else { return nil }
        self.init(id: id, name: name, color: color, createdAt: createdAt)
    }
}
