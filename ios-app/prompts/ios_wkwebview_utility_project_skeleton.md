# Project Skeleton: iOS Utility App with WKWebView, Mail, and Camera

This companion document defines a concrete repository structure for Claude Code to follow.

Its goal is to keep the project organized, incremental, and easy to extend.

---

# Top-Level Repository Layout

```text
ios-utility-app/
  README.md
  architecture.md
  development-plan.md
  bridge-api.md
  ios-integration-notes.md

  Native/
    MyIOSApp.xcodeproj
    MyIOSApp/

      App/
        AppDelegate.swift
        SceneDelegate.swift
        RootViewController.swift
        WebViewController.swift

      Bridge/
        BridgeMessage.swift
        BridgeResponse.swift
        BridgeError.swift
        BridgeRouter.swift

      Handlers/
        MetaHandler.swift
        MailHandler.swift
        CameraHandler.swift
        DeviceHandler.swift
        PermissionsHandler.swift

      Services/
        MailComposeService.swift
        CameraService.swift
        SubjectFormatter.swift
        CapabilityService.swift

      DTO/
        MailRequestDTO.swift
        PhotoCaptureResultDTO.swift
        CapabilityDTO.swift
        PermissionStatusDTO.swift

      Utilities/
        TemporaryFileManager.swift
        ImageEncoding.swift
        Logger.swift

      Resources/
        Web/

  Web/
    package.json
    tsconfig.json

    src/
      bridge/
        bridge-client.ts
        bridge-types.ts

      state/
        store.ts

      components/
        app-shell.ts
        main-menu-card.ts
        email-note-view.ts
        camera-view.ts
        metadata-form.ts
        status-banner.ts

      views/
        home-view.ts
        email-view.ts
        camera-compose-view.ts

      styles/
        app.css

      types/
        mail.ts
        meta.ts
        camera.ts
        bridge.ts

    public/
      index.html

  Tests/
    NativeTests/
      BridgeTests.swift
      SubjectFormatterTests.swift
      MailComposeTests.swift
      CameraServiceTests.swift

    WebTests/
      component-tests.ts
      bridge-client-tests.ts
```

---

# Native Layer Responsibilities

The native layer owns:

- `WKWebView` hosting
- bridge message routing
- mail composer presentation
- camera/photo capture
- permission checks
- device capability reporting
- image attachment preparation
- temporary file handling
- native result callbacks

The native layer should not delegate platform integration details to the web UI.

---

# Web Layer Responsibilities

The web layer owns:

- home screen/menu rendering
- note/email form rendering
- camera metadata form rendering
- collecting dropdown and text values
- view navigation/state
- calling the bridge
- displaying success/error/cancel messages

The web layer should treat the native layer as a local JSON API.

---

# Main Views

## Home Screen
A card-style main menu with buttons:

- Email
- Camera

## Email View
A form with:
- Category dropdown
- Tag Primary dropdown
- Tag Secondary dropdown
- Tag Tertiary dropdown
- Subject input
- Note body textarea
- Send button

## Camera View
A form/workflow with:
- metadata inputs matching Email view
- capture photo button
- send photo button
- status feedback

---

# Bridge Architecture

Bridge requests from JS use structured envelopes.

Example request:

```json
{
  "id": "req-001",
  "namespace": "mail",
  "method": "composeNote",
  "params": {
    "category": "Ideas",
    "tagPrimary": "Urgent",
    "tagSecondary": "Project-X",
    "tagTertiary": "Followup",
    "subject": "Prototype notes",
    "body": "Here are my notes"
  }
}
```

Example success response:

```json
{
  "id": "req-001",
  "ok": true,
  "result": {
    "status": "presented"
  }
}
```

Example error response:

```json
{
  "id": "req-001",
  "ok": false,
  "error": {
    "code": "mail_unavailable",
    "message": "Mail composer is not available on this device."
  }
}
```

The bridge router should:
1. validate request shape
2. dispatch by namespace + method
3. call the correct handler
4. return structured JSON

---

# Services

## MailComposeService
Responsible for:
- checking mail availability
- presenting the composer
- setting recipient, subject, body
- attaching images
- reporting result status

## CameraService
Responsible for:
- checking camera availability
- requesting/reading permission
- presenting camera capture UI
- returning image data/result metadata

## SubjectFormatter
Responsible for:
- one canonical subject-building implementation
- trimming/normalizing values
- deterministic output

## CapabilityService
Responsible for:
- reporting device capabilities to the web UI
- exposing camera/mail availability

---

# Subject Formatting Rule

Use a deterministic omission strategy:

1. trim inputs
2. remove empty segments
3. preserve order
4. join remaining segments with `: `

Thus:

- Category
- Tag Primary
- Tag Secondary
- Tag Tertiary
- Subject

becomes:

`Category: Tag-Primary: Tag-Secondary: Tag-Tertiary: Subject`

If some fields are blank, they are omitted cleanly rather than leaving empty separators.

This rule should be tested in `SubjectFormatterTests.swift`.

---

# Bridge Client (Web)

The web layer should have a small helper:

`bridge-client.ts`

Usage example:

```ts
const result = await bridge.call("mail.composeNote", payload)
```

The client should:

- assign request IDs
- send through `window.webkit.messageHandlers.bridge.postMessage`
- manage pending promises
- resolve or reject on native response
- expose a tiny stable API

---

# Component Guidance

## `<main-menu-card>`
Renders the entry buttons for Email and Camera.

## `<metadata-form>`
Renders the reusable metadata controls:
- Category
- Tag Primary
- Tag Secondary
- Tag Tertiary
- Subject

This should be reusable by both Email and Camera views.

## `<email-note-view>`
Wraps metadata form + note body + send action.

## `<camera-view>`
Handles capture action, metadata form, and send-photo action.

## `<status-banner>`
Displays success, warning, and error states.

---

# Testing Strategy

Native tests should cover:
- request/response parsing
- bridge routing
- subject formatting
- mail payload creation
- camera result handling
- capability reporting

Web tests should cover:
- component rendering
- bridge client behavior
- form serialization
- view transitions
- status message display

---

# Build Flow

Development:

```text
npm run dev
xcode run
```

Production:

```text
npm run build
bundle built web assets into Native/Resources/Web
archive iOS app
```

---

# Claude Code Instructions

When implementing:

1. create files exactly as structured unless there is a strong reason to refine
2. keep components small
3. keep the bridge explicit
4. avoid unnecessary frameworks
5. prefer straightforward UIKit + WKWebView integration
6. keep the app easy to extend later

Implement incrementally and keep the project coherent at each phase.

---

# Final Goal

A minimal iOS utility app where:

- Swift provides the native shell and platform integrations
- `WKWebView` provides the main UI
- Web Components provide modular screens
- the user can send a note by email
- the user can capture a photo and email it
- metadata fields drive the email subject format
- the architecture is clean enough to grow later
