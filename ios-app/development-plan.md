# Development Plan

## Phase 1 — Foundation (Complete)

### 1.1 Project Scaffold
- [x] Directory structure created
- [x] Documentation files written
- [x] `.xcodeproj` placeholder created (must be generated in Xcode)

### 1.2 Web Project Setup
- [x] `package.json` with Vite + TypeScript + Vitest
- [x] `tsconfig.json` strict config
- [x] `public/index.html` entry point

### 1.3 Bridge Core
- [x] `src/types/bridge.ts` — request/response type definitions
- [x] `src/bridge/bridge-client.ts` — BridgeClient class with promise map
- [x] `BridgeMessage.swift` — Codable struct + parse factory
- [x] `BridgeResponse.swift` — success/error envelopes + BridgeResponseBuilder
- [x] `BridgeError.swift` — error enum + code constants
- [x] `BridgeRouter.swift` — namespace registry + routing logic

## Phase 2 — Native Services (Complete)

### 2.1 App Lifecycle
- [x] `AppDelegate.swift`
- [x] `SceneDelegate.swift`
- [x] `RootViewController.swift`
- [x] `WebViewController.swift` — WKWebView host, bridge message handler

### 2.2 Utilities
- [x] `Logger.swift` — structured logging
- [x] `SubjectFormatter.swift` — deterministic subject line construction
- [x] `ImageEncoding.swift` — JPEG encode/decode, base64
- [x] `TemporaryFileManager.swift` — temp file lifecycle

### 2.3 Services
- [x] `MailComposeService.swift` — MFMailComposeViewController integration
- [x] `CameraService.swift` — UIImagePickerController integration
- [x] `CapabilityService.swift` — device feature detection

### 2.4 DTOs
- [x] `MailRequestDTO.swift` — MailNoteRequest, MailPhotoRequest
- [x] `PhotoCaptureResultDTO.swift` — PhotoCaptureResult
- [x] `CapabilityDTO.swift` — DeviceCapabilities
- [x] `PermissionStatusDTO.swift` — PermissionStatusResult

### 2.5 Handlers
- [x] `MetaHandler.swift` — meta.getOptions
- [x] `MailHandler.swift` — mail.composeNote, mail.composePhoto
- [x] `CameraHandler.swift` — camera.capturePhoto
- [x] `DeviceHandler.swift` — device.getCapabilities
- [x] `PermissionsHandler.swift` — permissions.getStatus

## Phase 3 — Web UI (Complete)

### 3.1 Types & State
- [x] `src/types/mail.ts`
- [x] `src/types/meta.ts`
- [x] `src/types/camera.ts`
- [x] `src/state/store.ts` — reactive state + subscription

### 3.2 Styles
- [x] `src/styles/app.css` — mobile-first, CSS custom properties

### 3.3 Components
- [x] `src/components/status-banner.ts` — success/error/loading/idle with auto-dismiss
- [x] `src/components/metadata-form.ts` — category/tag/subject form
- [x] `src/components/main-menu-card.ts` — home screen navigation cards
- [x] `src/components/email-note-view.ts` — email composition view
- [x] `src/components/camera-view.ts` — camera capture + photo mail view
- [x] `src/components/app-shell.ts` — top-level routing shell

### 3.4 Views
- [x] `src/views/home-view.ts`
- [x] `src/views/email-view.ts`
- [x] `src/views/camera-compose-view.ts`

## Phase 4 — Tests (Complete)

### 4.1 Native Tests
- [x] `SubjectFormatterTests.swift` — exhaustive formatter coverage
- [x] `BridgeTests.swift` — routing, parsing, response format
- [x] `MailComposeTests.swift` — DTO parsing, subject construction
- [x] `CameraServiceTests.swift` — result encoding, image round-trip

### 4.2 Web Tests
- [x] `bridge-client-tests.ts` — promise lifecycle, ID generation
- [x] `component-tests.ts` — metadata-form rendering + values, status-banner visibility

## Phase 5 — Integration & Polish (Future)

### 5.1 Build Pipeline
- [ ] Add `npm run build` copy-to-Resources script
- [ ] Add Xcode build phase to run web build automatically
- [ ] Set up proper bundle path resolution for WKWebView

### 5.2 Error Handling
- [ ] Retry logic for transient bridge failures
- [ ] Offline/no-mail graceful degradation UI
- [ ] Camera permission prompt with explanation UI

### 5.3 Production Hardening
- [ ] Content Security Policy for WKWebView
- [ ] WKWebView navigation policy to block external URLs
- [ ] Memory pressure handling for large images
- [ ] Accessibility (VoiceOver) for web components

### 5.4 Testing Expansion
- [ ] UI/Integration tests with XCUITest
- [ ] E2E web tests with Playwright
- [ ] Bridge stress tests (concurrent calls, large payloads)
