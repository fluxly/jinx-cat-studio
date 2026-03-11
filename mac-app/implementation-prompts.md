
# Incremental Claude Code Runs

Run these prompts sequentially in Claude Code.

Each run should produce a commit.

---

Run 1 — Initialize repository

Create the repo layout defined in project_skeleton.md.
Add placeholder files.
Create README and architecture docs.

---

Run 2 — macOS app shell

Create Xcode project.

Implement:

AppDelegate  
MainWindowController  
WebViewController  

Create WKWebView and load local HTML.

---

Run 3 — Bridge infrastructure

Create:

BridgeMessage.swift  
BridgeResponse.swift  
BridgeError.swift  
BridgeRouter.swift  

Implement message routing.

---

Run 4 — Web bridge client

Create bridge-client.ts.

Promise-based API.

bridge.call("documents.list",{})

---

Run 5 — SQLite manager

Implement SQLiteManager.swift.

Open DB  
enable WAL  
run migrations

---

Run 6 — Migration runner

Implement schema version table.

Load SQL files from Schema directory.

---

Run 7 — Repository layer

Create repositories:

DocumentRepository  
AssetRepository  
TagRepository  
CategoryRepository  

Repositories perform SQL queries only.

---

Run 8 — Service layer

Create services that orchestrate repositories.

DocumentService  
AssetService  
SearchService

---

Run 9 — Bridge handlers

Implement:

DocumentsHandler  
AssetsHandler  
TagsHandler  
CategoriesHandler  
SearchHandler  

---

Run 10 — Document UI

Create Web Components:

document-list  
document-editor

---

Run 11 — Asset import

Native code copies files into assets/originals.

Compute SHA256.

Store metadata.

---

Run 12 — Search

Create FTS tables.

Implement SearchService.

Create search UI.

---

Run 13 — Tags

Tag creation and assignment.

---

Run 14 — Hardening

Error handling  
logging  
validation

---

Run 15 — Packaging

Bundle web assets into app resources.

Ensure DB stored in Application Support.

---

Final result:

macOS desktop app  
WKWebView UI  
SQLite database  
JSON bridge  
file-based assets