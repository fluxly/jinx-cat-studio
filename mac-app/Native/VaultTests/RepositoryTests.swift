import XCTest
@testable import Vault

final class RepositoryTests: XCTestCase {

    var db: SQLiteManager!
    var documentRepo: DocumentRepository!
    var assetRepo: AssetRepository!
    var tagRepo: TagRepository!
    var categoryRepo: CategoryRepository!

    override func setUpWithError() throws {
        db = try SQLiteManager(inMemory: true)
        // Create minimal schema for tests
        try db.executeScript("""
            CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL DEFAULT '',
                body TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            CREATE TABLE IF NOT EXISTS assets (
                id TEXT PRIMARY KEY,
                filename TEXT NOT NULL,
                original_filename TEXT NOT NULL,
                mime_type TEXT NOT NULL,
                file_size INTEGER NOT NULL DEFAULT 0,
                sha256 TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            CREATE TABLE IF NOT EXISTS tags (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                color TEXT NOT NULL DEFAULT '#808080',
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                parent_id TEXT REFERENCES categories(id),
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            CREATE TABLE IF NOT EXISTS document_tags (
                document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
                PRIMARY KEY (document_id, tag_id)
            );
            CREATE TABLE IF NOT EXISTS asset_tags (
                asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
                PRIMARY KEY (asset_id, tag_id)
            );
            CREATE TABLE IF NOT EXISTS document_categories (
                document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
                PRIMARY KEY (document_id, category_id)
            );
            CREATE TABLE IF NOT EXISTS asset_categories (
                asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
                PRIMARY KEY (asset_id, category_id)
            );
            CREATE TABLE IF NOT EXISTS document_assets (
                document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
                PRIMARY KEY (document_id, asset_id)
            );
        """)

        documentRepo = DocumentRepository(db: db)
        assetRepo = AssetRepository(db: db)
        tagRepo = TagRepository(db: db)
        categoryRepo = CategoryRepository(db: db)
    }

    override func tearDownWithError() throws {
        db = nil
        documentRepo = nil
        assetRepo = nil
        tagRepo = nil
        categoryRepo = nil
    }

    // MARK: - Document Tests

    func testDocumentCRUD() throws {
        let doc = Document(id: "doc1", title: "Test Doc", body: "Hello world",
                           createdAt: "2024-01-01T00:00:00Z", updatedAt: "2024-01-01T00:00:00Z")
        try documentRepo.insert(doc)

        let fetched = try documentRepo.findById("doc1")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Test Doc")
        XCTAssertEqual(fetched?.body, "Hello world")

        var updated = fetched!
        updated.title = "Updated Title"
        updated.updatedAt = "2024-01-02T00:00:00Z"
        try documentRepo.update(updated)

        let afterUpdate = try documentRepo.findById("doc1")
        XCTAssertEqual(afterUpdate?.title, "Updated Title")

        try documentRepo.delete("doc1")
        let afterDelete = try documentRepo.findById("doc1")
        XCTAssertNil(afterDelete)
    }

    func testDocumentFindAll() throws {
        try documentRepo.insert(Document(id: "d1", title: "A", body: "",
                                          createdAt: "2024-01-01T00:00:00Z", updatedAt: "2024-01-01T00:00:00Z"))
        try documentRepo.insert(Document(id: "d2", title: "B", body: "",
                                          createdAt: "2024-01-01T00:00:00Z", updatedAt: "2024-01-02T00:00:00Z"))
        let all = try documentRepo.findAll()
        XCTAssertEqual(all.count, 2)
    }

    // MARK: - Tag Tests

    func testTagCRUD() throws {
        let tag = Tag(id: "tag1", name: "Important", color: "#ff0000", createdAt: "2024-01-01T00:00:00Z")
        try tagRepo.insert(tag)

        let fetched = try tagRepo.findById("tag1")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Important")
        XCTAssertEqual(fetched?.color, "#ff0000")

        try tagRepo.delete("tag1")
        let afterDelete = try tagRepo.findById("tag1")
        XCTAssertNil(afterDelete)
    }

    func testTagAssignmentToDocument() throws {
        try documentRepo.insert(Document(id: "doc1", title: "Doc", body: "",
                                          createdAt: "2024-01-01T00:00:00Z", updatedAt: "2024-01-01T00:00:00Z"))
        try tagRepo.insert(Tag(id: "tag1", name: "Work", color: "#0000ff", createdAt: "2024-01-01T00:00:00Z"))

        try documentRepo.addTag("tag1", toDocument: "doc1")

        let tags = try documentRepo.tagsForDocument("doc1")
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags.first?.id, "tag1")

        try documentRepo.removeTag("tag1", fromDocument: "doc1")
        let afterRemove = try documentRepo.tagsForDocument("doc1")
        XCTAssertEqual(afterRemove.count, 0)
    }

    // MARK: - Category Tests

    func testCategoryHierarchy() throws {
        let parent = Category(id: "cat1", name: "Engineering", parentId: nil, createdAt: "2024-01-01T00:00:00Z")
        let child = Category(id: "cat2", name: "iOS", parentId: "cat1", createdAt: "2024-01-01T00:00:00Z")

        try categoryRepo.insert(parent)
        try categoryRepo.insert(child)

        let children = try categoryRepo.findChildren(ofParent: "cat1")
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.name, "iOS")

        let fetched = try categoryRepo.findById("cat2")
        XCTAssertEqual(fetched?.parentId, "cat1")
    }

    // MARK: - Asset Tests

    func testAssetCRUD() throws {
        let asset = Asset(id: "asset1", filename: "abc123.png", originalFilename: "photo.png",
                          mimeType: "image/png", fileSize: 1024, sha256: "abc",
                          createdAt: "2024-01-01T00:00:00Z", updatedAt: "2024-01-01T00:00:00Z")
        try assetRepo.insert(asset)

        let fetched = try assetRepo.findById("asset1")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.originalFilename, "photo.png")
        XCTAssertEqual(fetched?.fileSize, 1024)

        let bySHA = try assetRepo.findBySHA256("abc")
        XCTAssertEqual(bySHA?.id, "asset1")

        try assetRepo.delete("asset1")
        XCTAssertNil(try assetRepo.findById("asset1"))
    }
}
