import Foundation

struct Migration {
    let version: Int
    let filename: String
    let sql: String
}

final class MigrationRunner {
    private let db: SQLiteManager

    init(dbManager: SQLiteManager) {
        self.db = dbManager
    }

    func runMigrations() throws {
        // Ensure schema_version table exists
        try db.execute("""
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY,
                applied_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
        """)

        let applied = try appliedVersions()
        let pending = try pendingMigrations(applied: applied)

        for migration in pending {
            NSLog("[MigrationRunner] Applying migration \(migration.version): \(migration.filename)")
            try db.executeScript(migration.sql)
            try db.execute(
                "INSERT INTO schema_version (version) VALUES (?);",
                parameters: [migration.version]
            )
            NSLog("[MigrationRunner] Migration \(migration.version) applied successfully")
        }

        if pending.isEmpty {
            NSLog("[MigrationRunner] No pending migrations")
        }
    }

    private func appliedVersions() throws -> Set<Int> {
        let rows = try db.query("SELECT version FROM schema_version ORDER BY version;")
        let versions = rows.compactMap { row -> Int? in
            guard let v = row["version"] as? Int64 else { return nil }
            return Int(v)
        }
        return Set(versions)
    }

    private func pendingMigrations(applied: Set<Int>) throws -> [Migration] {
        let bundle = Bundle.main
        guard let schemaDir = bundle.resourceURL?.appendingPathComponent("schema") else {
            NSLog("[MigrationRunner] No schema directory in bundle, skipping migrations")
            return []
        }

        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: schemaDir, includingPropertiesForKeys: nil) else {
            NSLog("[MigrationRunner] Could not list schema directory")
            return []
        }

        let sqlFiles = files
            .filter { $0.pathExtension == "sql" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var migrations: [Migration] = []
        for file in sqlFiles {
            guard let version = extractVersion(from: file.lastPathComponent) else {
                NSLog("[MigrationRunner] Skipping file with unrecognized name: \(file.lastPathComponent)")
                continue
            }
            guard !applied.contains(version) else { continue }

            guard let sql = try? String(contentsOf: file, encoding: .utf8) else {
                throw BridgeError(.internalError, "Cannot read migration file: \(file.lastPathComponent)")
            }
            migrations.append(Migration(version: version, filename: file.lastPathComponent, sql: sql))
        }

        return migrations.sorted { $0.version < $1.version }
    }

    /// Extracts version number from filenames like "001_initial.sql" -> 1
    private func extractVersion(from filename: String) -> Int? {
        let parts = filename.split(separator: "_", maxSplits: 1)
        guard let prefix = parts.first, let version = Int(prefix) else { return nil }
        return version
    }
}
