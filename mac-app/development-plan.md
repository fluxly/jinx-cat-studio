# Vault — Development Plan

## Phase 1: Foundation (Complete)

**Goal**: Working app skeleton that launches, initializes the database, and loads the web UI.

- [x] Xcode project via xcodegen
- [x] AppDelegate + MainWindowController
- [x] WKWebView setup with bridge message handler
- [x] SQLiteManager with WAL mode
- [x] MigrationRunner with schema versioning
- [x] Schema migration 001 (core tables)
- [x] Schema migration 002 (FTS5 + triggers)
- [x] Info.plist

## Phase 2: Core Bridge & Data Layer (Complete)

**Goal**: Full round-trip from JavaScript to database and back.

- [x] BridgeMessage / BridgeResponse / BridgeError types
- [x] AnyCodable for JSON serialization
- [x] BridgeRouter with namespace dispatch
- [x] Document, Asset, Tag, Category models
- [x] DocumentRepository, AssetRepository, TagRepository, CategoryRepository
- [x] DocumentService, AssetService, TagService, CategoryService, SearchService
- [x] DocumentsHandler, AssetsHandler, TagsHandler, CategoriesHandler, SearchHandler

## Phase 3: Web UI (Complete)

**Goal**: Functional document and asset management UI.

- [x] BridgeClient TypeScript implementation
- [x] app-shell Web Component (sidebar navigation)
- [x] document-list-view with create/delete
- [x] document-editor with autosave (debounced)
- [x] asset-list-view with import via NSOpenPanel
- [x] asset-detail panel
- [x] search-view with FTS5-powered results
- [x] Dark/light mode CSS
- [x] Toast notification system

## Phase 4: Polish & Enhancement

**Goal**: Production-quality experience.

- [ ] Drag-and-drop asset import (drop files onto window)
- [ ] Document markdown rendering (split edit/preview mode)
- [ ] Tag management UI (create, color picker, bulk assign)
- [ ] Category management UI (hierarchy tree)
- [ ] Asset thumbnails for images (use `QLThumbnailGenerator`)
- [ ] Document linking (embed asset previews inline)
- [ ] Keyboard shortcuts (⌘N new doc, ⌘F search, etc.)
- [ ] Sidebar resizing via NSSplitView
- [ ] Quick Look integration for asset preview
- [ ] Export documents (plain text, markdown, HTML)
- [ ] iCloud sync via NSUbiquitousKeyValueStore or CloudKit

## Phase 5: App Store Preparation

**Goal**: Shipping-ready release.

- [ ] Enable macOS App Sandbox entitlements
- [ ] Add NSUserSelectedFilesReadWrite entitlement for asset import
- [ ] Code signing with Developer ID
- [ ] Notarization
- [ ] App icon (1024×1024 + all required sizes)
- [ ] Privacy manifest (PrivacyInfo.xcprivacy)
- [ ] Crash reporting integration
- [ ] Analytics (privacy-preserving, optional)
- [ ] App Store screenshots
- [ ] Help documentation

## Known Issues & Technical Debt

1. **DocumentService.getDocument** loads asset tags/categories in a loop — could be optimized with a JOIN query.
2. **SearchService** FTS5 results return SQLite `rank` (negative float) as score — consider normalizing.
3. **AssetService** does not validate file size limits — add configurable maximum.
4. **MigrationRunner** applies migrations in a single transaction per file — consider wrapping all pending migrations in one transaction.
5. **Web UI app.js** is hand-written vanilla JS; long-term should adopt a proper build pipeline (Vite + the TypeScript source in `Web/src/`).
6. **No undo support** — document edits are committed immediately; consider a command pattern or Core Data managed object context.

## Testing Strategy

### Native (XCTest)
- `DatabaseTests` — SQLiteManager correctness (CRUD, WAL, NULL handling)
- `RepositoryTests` — Repository layer with in-memory SQLite
- `BridgeTests` — AnyCodable serialization, BridgeMessage decoding, BridgeRouter routing

### Web (Vitest/Jest)
- `component-tests.ts` — BridgeClient mock integration, component rendering

### Integration
- Manual testing with real database
- Simulator/device testing across macOS 13, 14, 15
