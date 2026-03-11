# Vault

A native macOS document and asset management application built with Swift and WKWebView.

## Overview

Vault is a standalone macOS app (bundle ID: `com.jinxcatstudio.vault`) that provides:

- Document creation and editing with full-text search
- Asset (file) import and management
- Tagging and categorization for both documents and assets
- Fast FTS5-powered full-text search across all content
- Dark/light mode adaptive UI built with Web Components

## Requirements

- macOS 13.0+
- Xcode 15+ with Swift 5.9+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting Started

### Generate the Xcode project

```bash
cd Native/
xcodegen generate
```

### Open in Xcode

```bash
open Native/Vault.xcodeproj
```

### Build and run

Press **⌘R** in Xcode, or use:

```bash
xcodebuild -project Native/Vault.xcodeproj -scheme Vault -configuration Debug build
```

## Directory Structure

```
mac-app/
├── Native/              # Swift/Xcode project
│   ├── project.yml      # xcodegen spec
│   └── Vault/
│       ├── App/         # AppDelegate, window/view controllers
│       ├── Bridge/      # JS<->Swift bridge (BridgeRouter, messages, etc.)
│       ├── Handlers/    # Per-namespace bridge handlers
│       ├── Database/    # SQLite manager and migration runner
│       ├── Models/      # Swift model structs
│       ├── DTO/         # Codable response DTOs
│       ├── Repositories/# SQL query wrappers
│       ├── Services/    # Business logic layer
│       └── Resources/
│           ├── Info.plist
│           ├── web/     # Compiled web UI (index.html, app.js, app.css)
│           └── schema/  # SQL migration files
├── Web/                 # TypeScript web UI source
│   └── src/
│       ├── bridge/      # BridgeClient TypeScript implementation
│       ├── components/  # Web Components
│       ├── views/       # Page-level views
│       └── types/       # TypeScript type definitions
└── Tests/
    ├── NativeTests/     # (see Native/VaultTests/)
    └── WebTests/        # TypeScript component tests
```

## Architecture

See [architecture.md](architecture.md) for detailed system design documentation.

## Development Plan

See [development-plan.md](development-plan.md) for the phased implementation roadmap.

## Web UI Development

The web UI source lives in `Web/src/`. The compiled output (`app.js`) is checked in to
`Native/Vault/Resources/web/` so the app works without a build step.

To compile TypeScript changes:

```bash
cd Web/
npm install
npm run build   # compiles and copies to Resources/web/
npm run watch   # watch mode
```

## Database

The SQLite database is stored at:
```
~/Library/Application Support/com.jinxcatstudio.vault/vault.sqlite
```

Assets are stored at:
```
~/Library/Application Support/com.jinxcatstudio.vault/assets/
```

Migrations run automatically on startup from `Resources/schema/` SQL files.

## Bridge Protocol

The JavaScript-to-Swift bridge uses WKScriptMessageHandler:

**JS → Swift:**
```js
window.webkit.messageHandlers.bridge.postMessage({
  id: "uuid",
  namespace: "documents",
  method: "list",
  params: {}
})
```

**Swift → JS (success):**
```js
window.__bridgeCallbackB64(id, base64EncodedJSON)
// where JSON is: {"id":"uuid","success":true,"data":[...]}
```

**Swift → JS (error):**
```json
{"id":"uuid","success":false,"error":{"code":"NOT_FOUND","message":"..."}}
```
