import Foundation
import SQLite3

enum SQLiteError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case stepFailed(String)
    case bindFailed(String)
    case columnTypeMismatch(Int32, String)

    var errorDescription: String? {
        switch self {
        case .openFailed(let msg): return "SQLite open failed: \(msg)"
        case .prepareFailed(let msg): return "SQLite prepare failed: \(msg)"
        case .stepFailed(let msg): return "SQLite step failed: \(msg)"
        case .bindFailed(let msg): return "SQLite bind failed: \(msg)"
        case .columnTypeMismatch(let col, let expected): return "Column \(col) type mismatch, expected \(expected)"
        }
    }
}

/// A row from a SQLite query result.
typealias SQLiteRow = [String: Any?]

final class SQLiteManager {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.jinxcatstudio.vault.sqlite", qos: .userInitiated)

    init() throws {
        let url = try Self.databaseURL()
        let path = url.path

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK, let handle = handle else {
            let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw SQLiteError.openFailed(msg)
        }
        db = handle
        NSLog("[SQLiteManager] Opened database at \(path)")

        try configureDatabase()
    }

    /// Initializer for testing — uses an in-memory database when `inMemory` is true,
    /// or a temporary file-based database.
    init(inMemory: Bool) throws {
        let path = inMemory ? ":memory:" : {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("vault_test_\(UUID().uuidString).sqlite")
            return tmp.path
        }()

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK, let handle = handle else {
            let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw SQLiteError.openFailed(msg)
        }
        db = handle
        try configureDatabase()
    }

    deinit {
        if let db = db {
            sqlite3_close_v2(db)
        }
    }

    // MARK: - Configuration

    private func configureDatabase() throws {
        try execute("PRAGMA journal_mode=WAL;")
        try execute("PRAGMA foreign_keys=ON;")
        try execute("PRAGMA synchronous=NORMAL;")
        try execute("PRAGMA cache_size=-8000;") // 8MB cache
    }

    // MARK: - Public API

    /// Execute a statement that returns no rows (INSERT, UPDATE, DELETE, CREATE, etc.)
    func execute(_ sql: String, parameters: [Any?] = []) throws {
        try queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt else {
                throw SQLiteError.prepareFailed(errorMessage())
            }
            defer { sqlite3_finalize(stmt) }

            try bind(parameters: parameters, to: stmt)

            let result = sqlite3_step(stmt)
            guard result == SQLITE_DONE || result == SQLITE_ROW else {
                throw SQLiteError.stepFailed(errorMessage())
            }
        }
    }

    /// Execute a query and return all rows.
    func query(_ sql: String, parameters: [Any?] = []) throws -> [SQLiteRow] {
        try queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt else {
                throw SQLiteError.prepareFailed(errorMessage())
            }
            defer { sqlite3_finalize(stmt) }

            try bind(parameters: parameters, to: stmt)

            var rows: [SQLiteRow] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let columnCount = sqlite3_column_count(stmt)
                var row: SQLiteRow = [:]
                for i in 0..<columnCount {
                    let name = String(cString: sqlite3_column_name(stmt, i))
                    row[name] = columnValue(stmt: stmt, index: i)
                }
                rows.append(row)
            }
            return rows
        }
    }

    /// Execute multiple SQL statements separated by semicolons (for migrations).
    func executeScript(_ sql: String) throws {
        try queue.sync {
            var errorMsg: UnsafeMutablePointer<CChar>?
            guard sqlite3_exec(db, sql, nil, nil, &errorMsg) == SQLITE_OK else {
                let msg = errorMsg.map { String(cString: $0) } ?? "unknown"
                sqlite3_free(errorMsg)
                throw SQLiteError.stepFailed(msg)
            }
        }
    }

    /// Last inserted row ID
    var lastInsertRowId: Int64 {
        queue.sync { sqlite3_last_insert_rowid(db) }
    }

    // MARK: - Private helpers

    private func bind(parameters: [Any?], to stmt: OpaquePointer) throws {
        for (index, param) in parameters.enumerated() {
            let i = Int32(index + 1)
            let rc: Int32
            switch param {
            case nil, is NSNull:
                rc = sqlite3_bind_null(stmt, i)
            case let int as Int:
                rc = sqlite3_bind_int64(stmt, i, Int64(int))
            case let int as Int64:
                rc = sqlite3_bind_int64(stmt, i, int)
            case let int as Int32:
                rc = sqlite3_bind_int64(stmt, i, Int64(int))
            case let double as Double:
                rc = sqlite3_bind_double(stmt, i, double)
            case let string as String:
                rc = sqlite3_bind_text(stmt, i, string, -1, SQLITE_TRANSIENT)
            case let data as Data:
                rc = data.withUnsafeBytes { ptr in
                    sqlite3_bind_blob(stmt, i, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
                }
            case let bool as Bool:
                rc = sqlite3_bind_int64(stmt, i, bool ? 1 : 0)
            default:
                let mirror = Mirror(reflecting: param as Any)
                if mirror.displayStyle == .optional {
                    rc = sqlite3_bind_null(stmt, i)
                } else {
                    throw SQLiteError.bindFailed("Unsupported parameter type at index \(index): \(type(of: param))")
                }
            }
            guard rc == SQLITE_OK else {
                throw SQLiteError.bindFailed("Bind at index \(i) failed: \(errorMessage())")
            }
        }
    }

    private func columnValue(stmt: OpaquePointer, index: Int32) -> Any? {
        switch sqlite3_column_type(stmt, index) {
        case SQLITE_INTEGER:
            return sqlite3_column_int64(stmt, index)
        case SQLITE_FLOAT:
            return sqlite3_column_double(stmt, index)
        case SQLITE_TEXT:
            return String(cString: sqlite3_column_text(stmt, index))
        case SQLITE_BLOB:
            let byteCount = sqlite3_column_bytes(stmt, index)
            guard let bytes = sqlite3_column_blob(stmt, index) else { return nil }
            return Data(bytes: bytes, count: Int(byteCount))
        case SQLITE_NULL:
            return nil
        default:
            return nil
        }
    }

    private func errorMessage() -> String {
        guard let db = db else { return "no database" }
        return String(cString: sqlite3_errmsg(db))
    }

    // MARK: - Database URL

    private static func databaseURL() throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vaultDir = appSupport.appendingPathComponent("com.jinxcatstudio.vault")
        try FileManager.default.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        return vaultDir.appendingPathComponent("vault.sqlite")
    }
}

// Make SQLITE_TRANSIENT available as a proper constant
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
