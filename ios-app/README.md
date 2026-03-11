# iOS Utility App

A native iOS utility app that uses WKWebView as its primary UI container, with Web Components (TypeScript) handling all UI rendering. A JSON bridge connects JavaScript and Swift, enabling web UI to trigger native iOS capabilities like email composition and camera capture.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│              iOS App Shell              │
│  AppDelegate → SceneDelegate            │
│              RootViewController         │
│              WebViewController          │
│         (WKWebView host + bridge)       │
├─────────────────────────────────────────┤
│              Bridge Layer               │
│  JS window.webkit.messageHandlers       │
│  → BridgeRouter → BridgeHandler         │
│  ← window.nativeBridge.receiveResponse  │
├─────────────────────────────────────────┤
│          Native Services                │
│  MailComposeService  CameraService      │
│  CapabilityService   SubjectFormatter   │
├─────────────────────────────────────────┤
│          Web UI Layer (WKWebView)       │
│  BridgeClient → Web Components          │
│  Store (state) → Views                  │
└─────────────────────────────────────────┘
```

Swift provides the native shell and platform integrations. WKWebView is the primary UI container. Web Components (TypeScript) handle all UI rendering. A JSON bridge connects JS ↔ Swift.

## Features

- **Email Notes**: Compose and send structured email notes with category/tag metadata
- **Camera Capture**: Take photos and attach them to emails
- **Subject Formatting**: Automatic subject line construction from category/tag hierarchy
- **Permission Handling**: Graceful camera permission management

## How to Build

### Web Assets

```bash
cd Web
npm install
npm run build
```

This outputs to `Web/dist/`. Copy the contents into `Native/MyIOSApp/Resources/Web/` before building the Xcode project.

### iOS App

1. Open Xcode and create a new iOS App project targeting iOS 16+
2. Add all Swift files from `Native/MyIOSApp/` to the project
3. Add the `Resources/Web/` folder as a bundle resource group
4. Set deployment target to iOS 16.0
5. Add `NSCameraUsageDescription` to Info.plist
6. Build and run

See `ios-integration-notes.md` for detailed Xcode setup instructions.

## How to Extend

### Adding a New Bridge Namespace

1. Create a new handler file in `Native/MyIOSApp/Handlers/` implementing `BridgeHandler`
2. Register it in `WebViewController` with `router.register(namespace: "myns", handler: MyHandler())`
3. Add corresponding TypeScript types in `Web/src/types/`
4. Call via `bridge.call("myns.myMethod", params)` from any web component

### Adding a New View

1. Create a new Web Component in `Web/src/components/`
2. Create a view wrapper in `Web/src/views/`
3. Add the view name to `AppView` type in `Web/src/state/store.ts`
4. Handle navigation in `Web/src/components/app-shell.ts`

### Adding a New Native Service

1. Create the service in `Native/MyIOSApp/Services/`
2. Create DTOs in `Native/MyIOSApp/DTO/`
3. Create or update a handler in `Native/MyIOSApp/Handlers/`
4. Register the handler in `WebViewController`

## Project Structure

```
ios-utility-app/
  README.md              — This file
  architecture.md        — Detailed architecture docs
  development-plan.md    — Phase-by-phase plan
  bridge-api.md          — Full bridge API reference
  ios-integration-notes.md — Xcode/iOS integration notes

  Native/MyIOSApp/       — Swift source files
  Web/                   — TypeScript/Vite web project
  Tests/                 — Native and web unit tests
```

## Requirements

- iOS 16.0+
- Xcode 15+
- Node.js 18+ (for web build)
- Swift 5.9+
