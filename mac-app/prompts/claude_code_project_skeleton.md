# Claude Code Companion: Project Skeleton

This file defines the repository layout.

myapp/

README.md
architecture.md
development-plan.md

Native/
MyApp.xcodeproj
MyApp/

App/
AppDelegate.swift
MainWindowController.swift
WebViewController.swift

Bridge/
BridgeRouter.swift
BridgeMessage.swift
BridgeResponse.swift
BridgeError.swift

Handlers/
DocumentsHandler.swift
AssetsHandler.swift
TagsHandler.swift
CategoriesHandler.swift
SearchHandler.swift

Database/
SQLiteManager.swift
MigrationRunner.swift

Schema/
001_initial.sql
002_fts.sql

Models/
Document.swift
Asset.swift
Tag.swift
Category.swift

DTO/
DocumentSummaryDTO.swift
AssetSummaryDTO.swift
TagDTO.swift
CategoryDTO.swift

Repositories/
DocumentRepository.swift
AssetRepository.swift
TagRepository.swift
CategoryRepository.swift

Services/
DocumentService.swift
AssetService.swift
TagService.swift
CategoryService.swift
SearchService.swift

Web/

src/
bridge/
bridge-client.ts

components/
app-shell.ts
document-list.ts
document-editor.ts
asset-list.ts
asset-detail.ts
search-panel.ts

views/
documents-view.ts
assets-view.ts
search-view.ts

styles/
app.css

types/
document.ts
asset.ts
tag.ts
category.ts

public/
index.html

Tests/

NativeTests/
DatabaseTests.swift
RepositoryTests.swift
BridgeTests.swift

WebTests/
component-tests.ts

Responsibilities

Native layer:

SQLite

filesystem

bridge routing

validation

Web layer:

UI

navigation

state

calling bridge APIs