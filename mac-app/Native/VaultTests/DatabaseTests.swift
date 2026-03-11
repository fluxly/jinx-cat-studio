import XCTest
@testable import Vault

final class DatabaseTests: XCTestCase {

    var db: SQLiteManager!

    override func setUpWithError() throws {
        // Use in-memory equivalent: a temp file
        db = try SQLiteManager(inMemory: true)
    }

    override func tearDownWithError() throws {
        db = nil
    }

    func testExecuteAndQuery() throws {
        try db.execute("""
            CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
        """)
        try db.execute("INSERT INTO test (name) VALUES (?);", parameters: ["hello"])
        try db.execute("INSERT INTO test (name) VALUES (?);", parameters: ["world"])

        let rows = try db.query("SELECT * FROM test ORDER BY id;")
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0]["name"] as? String, "hello")
        XCTAssertEqual(rows[1]["name"] as? String, "world")
    }

    func testIntegerBindingAndRetrieval() throws {
        try db.execute("CREATE TABLE nums (val INTEGER);")
        try db.execute("INSERT INTO nums VALUES (?);", parameters: [Int64(42)])
        let rows = try db.query("SELECT val FROM nums;")
        XCTAssertEqual(rows.first?["val"] as? Int64, 42)
    }

    func testNullBinding() throws {
        try db.execute("CREATE TABLE nullable (val TEXT);")
        try db.execute("INSERT INTO nullable VALUES (?);", parameters: [nil])
        let rows = try db.query("SELECT val FROM nullable;")
        XCTAssertEqual(rows.count, 1)
        XCTAssertNil(rows.first?["val"] as? String)
    }

    func testPreparedStatementError() throws {
        XCTAssertThrowsError(try db.execute("SELECT * FROM nonexistent_table;"))
    }

    func testWALMode() throws {
        let rows = try db.query("PRAGMA journal_mode;")
        let mode = rows.first?["journal_mode"] as? String
        XCTAssertEqual(mode, "wal")
    }

    func testExecuteScript() throws {
        let sql = """
            CREATE TABLE foo (id INTEGER PRIMARY KEY);
            INSERT INTO foo VALUES (1);
            INSERT INTO foo VALUES (2);
        """
        try db.executeScript(sql)
        let rows = try db.query("SELECT COUNT(*) as cnt FROM foo;")
        XCTAssertEqual(rows.first?["cnt"] as? Int64, 2)
    }
}
