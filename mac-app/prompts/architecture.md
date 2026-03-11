# Vault — Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        macOS App                            │
│                                                             │
│  ┌─────────────┐     ┌───────────────────────────────────┐ │
│  │  AppDelegate │────▶│  MainWindowController             │ │
│  └─────────────┘     │  (NSWindowController)              │ │
│                       └─────────────┬─────────────────────┘ │
│                                     │                        │
│                       ┌─────────────▼─────────────────────┐ │
│                       │  WebViewController                  │ │
│                       │  (NSViewController + WKWebView)    │ │
│                       └──────────┬──────────┬─────────────┘ │
│                                  │          │               │
│           ┌──────────────────────▼──┐   ┌──▼─────────────┐ │
│           │  BridgeRouter           │   │  WKWebView      │ │
│           │  routes by namespace    │   │  (Web UI)       │ │
│           └──────┬──────────────────┘   └────────────────┘ │
│                  │                                          │
│         ┌────────┼────────┐                                │
│         ▼        ▼        ▼   (+ TagsHandler, etc.)        │
│  ┌──────────┐ ┌───────┐ ┌──────────┐                       │
│  │ Documents│ │Assets │ │ Search   │  ← Handlers           │
│  │ Handler  │ │Handler│ │ Handler  │                       │
│  └────┬─────┘ └───┬───┘ └────┬─────┘                       │
│       ▼           ▼          ▼                              │
│  ┌──────────────────────────────────┐                       │
│  │           Services               │                       │
│  │  DocumentService  AssetService   │                       │
│  │  TagService  CategoryService     │                       │
│  │  SearchService                   │                       │
│  └──────────────┬───────────────────┘                       │
│                 ▼                                           │
│  ┌──────────────────────────────────┐                       │
│  │         Repositories             │                       │
│  │  DocumentRepo  AssetRepo         │                       │
│  │  TagRepo  CategoryRepo           │                       │
│  └──────────────┬───────────────────┘                       │
│                 ▼                                           │
│  ┌──────────────────────────────────┐                       │
│  │         SQLiteManager            │                       │
│  │   WAL mode, serial queue         │                       │
│  │   System SQLite3 (C API)         │                       │
│  └──────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Layers

### Native Layer (Swift)

| Layer | Responsibility |
|-------|---------------|
| **App** | Application lifecycle, window management, WKWebView setup |
| **Bridge** | JS↔Swift message routing, serialization (AnyCodable, BridgeRouter) |
| **Handlers** | Per-namespace bridge endpoint dispatch |
| **Services** | Business logic (file I/O, orchestration, validation) |
| **Repositories** | SQL query wrappers, no business logic |
| **Database** | SQLiteManager (thread-safe), MigrationRunner |
| **Models** | Plain Swift structs matching DB schema |
| **DTOs** | Encodable response shapes sent to JavaScript |

### Web Layer (TypeScript / Vanilla JS)

| Layer | Responsibility |
|-------|---------------|
| **BridgeClient** | Promise wrapper over WKScriptMessageHandler |
| **Components** | Reusable Web Components (document-list, document-editor, etc.) |
| **Views** | Page-level components composing multiple sub-components |
| **Types** | TypeScript interfaces matching DTO shapes |

## Database Schema

The database uses SQLite with WAL journal mode and foreign key enforcement.

### Core Tables
- `documents` — Title + body text
- `assets` — File metadata (stored separately on disk)
- `tags` — Named, colored labels
- `categories` — Hierarchical classification

### Junction Tables
- `document_tags`, `asset_tags` — Many-to-many tag assignments
- `document_categories`, `asset_categories` — Many-to-many category assignments
- `document_assets` — Documents can reference assets

### Full-Text Search
- `documents_fts` — FTS5 virtual table on documents (title + body)
- `assets_fts` — FTS5 virtual table on assets (filename + original_filename)
- Triggers keep FTS indices synchronized with base tables

## Bridge Protocol

All communication between the web UI and native Swift layer uses a JSON message protocol
over WKScriptMessageHandler.

### Message Shape (JS → Swift)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "namespace": "documents",
  "method": "list",
  "params": {}
}
```

### Response Shape (Swift → JS)
```json
{ "id": "...", "success": true, "data": [...] }
{ "id": "...", "success": false, "error": { "code": "NOT_FOUND", "message": "..." } }
```

Responses are base64-encoded to avoid JavaScript string-escaping issues.

## Threading Model

- **Main thread**: WKWebView, AppKit UI, `evaluateJavaScript`
- **Bridge queue**: `com.jinxcatstudio.vault.bridge` — processes incoming bridge messages
- **SQLite queue**: `com.jinxcatstudio.vault.sqlite` — serializes all database access
- **File I/O**: `DispatchQueue.global(qos: .userInitiated)` for asset imports

## Security Considerations

- No network access is required or requested
- `NSAllowsLocalNetworking: true` in App Transport Security for local file:// loading
- Code signing disabled in development (`CODE_SIGNING_REQUIRED: NO`)
- No entitlements currently required (sandboxing can be added later)

## File Storage

Assets are stored at:
```
~/Library/Application Support/com.jinxcatstudio.vault/assets/{uuid}.{ext}
```

Deduplication is performed via SHA-256 hash on import.
