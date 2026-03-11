# Claude Code Prompt: Build a macOS Standalone App with Swift, WKWebView, SQLite, and a Native Bridge

## Role

You are Claude Code acting as a senior macOS engineer and systems architect.

Your task is to design and implement a **production-quality macOS standalone application** with these constraints:

- The app is a native macOS app
- The UI is implemented primarily in web technologies
- The web UI runs inside a WKWebView
- UI components should be built with Web Components / Custom Elements
- Do not use cross-platform wrappers like Electron, React Native, Flutter, etc.
- Native code should be bespoke Swift
- Local database: SQLite
- Full-text search: SQLite FTS5
- Assets stored as files on disk
- Native layer exposes a JSON bridge to the web layer

The app is a **document and asset management system** with:

- many text documents
- images and other media
- tags and categories
- full text search
- metadata
- relationships between documents and assets

The architecture must be **local-first**, **single-user**, and **desktop-native**.

---

## Tech Stack

Native:
- Swift
- WKWebView
- SQLite
- JSON bridge

Web UI:
- HTML
- CSS
- TypeScript
- Web Components

Database:
- SQLite tables
- FTS5 virtual tables

Assets:
Stored on disk
AppData/
app.sqlite
assets/
originals/
thumbnails/


---

## Architecture Principles

1. Native owns persistence
2. Web UI talks to native through a small API
3. SQLite holds metadata
4. Filesystem holds binary assets
5. Bridge messages are JSON request/response
6. Frontend uses Web Components
7. Development proceeds in phases

---

## Bridge API Shape

Example API:

app.documents.list()  
app.documents.get(id)  
app.documents.create(payload)  
app.documents.update(id,payload)  
app.documents.delete(id)

app.assets.list()  
app.assets.get(id)  
app.assets.import()  
app.assets.update()  
app.assets.delete()

app.tags.list()  
app.tags.create()

app.categories.list()

app.search.query()

All bridge messages use JSON envelopes.

---

## Database Tables

documents  
assets  
tags  
categories  

join tables

document_tags  
asset_tags  
document_categories  
asset_categories  
document_assets

Full text tables

documents_fts  
assets_fts

---

## Implementation Phases

1 Architecture + scaffold  
2 Native app shell  
3 Database layer  
4 Bridge layer  
5 Documents CRUD  
6 Asset import pipeline  
7 Search  
8 Tags + categories  
9 Hardening

---

## Deliverables

Claude Code should produce:

- macOS project
- Swift bridge layer
- SQLite schema
- Web frontend
- Search
- asset storage
- documentation
- tests

Begin with **Phase 1: architecture and scaffold**.