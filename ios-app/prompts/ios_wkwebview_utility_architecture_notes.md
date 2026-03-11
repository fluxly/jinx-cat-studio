# Architecture Notes: iOS Utility App with WKWebView, Mail Compose, and Camera

## Purpose

This document describes the intended architecture for a minimal iOS utility app whose user interface is primarily implemented in web technologies inside a `WKWebView`, with native Swift handling camera and email integration.

The initial app is intentionally small, but it should be structured so additional views, fields, and native capabilities can be added later with minimal rework.

---

## Product Summary

The app starts with a simple main menu card containing two actions:

- Email
- Camera

### Email / Note Flow
The Email view lets the user enter:

- Category
- Tag Primary
- Tag Secondary
- Tag Tertiary
- Subject
- Note body

The app formats the subject line as:

`Category: Tag-Primary: Tag-Secondary: Tag-Tertiary: Subject`

and opens a native mail composer addressed to:

`fluxama@gmail.com`

### Camera Flow
The Camera view allows the user to:

- capture a photo
- provide the same metadata fields
- email the photo with the formatted subject line

---

## High-Level Architecture

The app is split into two primary layers:

### 1. Native Layer (Swift)
Responsible for:

- hosting the `WKWebView`
- bridge request routing
- invoking native iOS APIs
- presenting `MFMailComposeViewController`
- camera capture and permissions
- packaging photo attachments
- surfacing native results and errors

### 2. Web Layer (HTML/CSS/TypeScript)
Responsible for:

- rendering the main menu and forms
- view transitions/navigation
- collecting metadata fields
- making structured bridge calls
- rendering errors and status

This split keeps platform-specific logic in native code and product/UI logic in the web layer.

---

## Why This Architecture

This pattern preserves the benefits of native iOS integration while allowing the product UI to evolve quickly using web technologies and custom elements.

Advantages:

- native access to mail and camera
- web-based UI iteration speed
- reusable UI patterns for future screens
- explicit and inspectable boundary between layers
- no dependency on cross-platform wrapper frameworks

Tradeoff:

- the bridge contract must be designed carefully
- some platform interactions remain imperative and asynchronous

This is acceptable for the size and goals of the app.

---

## Native / Web Boundary

### Native Owns
- `WKWebView`
- bridge registration and routing
- mail composition
- camera/photo capture
- permission checking
- temporary attachment file management
- device capability reporting

### Web Owns
- visual structure
- main menu card
- metadata forms
- note body entry
- screen state
- request initiation
- user feedback rendering

The web layer should not talk directly to iOS APIs. It should only call the bridge.

---

## Recommended Native Stack

- Swift
- UIKit app shell
- `WKWebView`
- `WKScriptMessageHandler`
- `MFMailComposeViewController`
- `UIImagePickerController` for v1 simplicity
- a small bridge router
- DTO/request objects
- lightweight utility classes for subject formatting and attachment handling

A SwiftUI app shell is also possible, but UIKit + `WKWebView` hosting is often the simplest direct fit for this pattern.

---

## Mail Integration Strategy

### Preferred v1 Approach
Use `MFMailComposeViewController`.

Why:
- native and supported flow
- easy to attach subject/body/recipient
- easy to add an image attachment
- appropriate user-visible behavior for a utility app

### Constraints
- the composer only works when mail services are available on the device
- the app does not send silently; the user completes or cancels the message

### Required Native Behavior
Native code should:

1. validate mail availability
2. construct the subject using one shared formatter
3. set recipient to `fluxama@gmail.com`
4. set message body for note flow
5. attach image for camera flow
6. return status to the bridge/UI after composer completion

Example result states:

- `presented`
- `sent`
- `saved`
- `cancelled`
- `failed`
- `unavailable`

---

## Camera Integration Strategy

### Preferred v1 Approach
Use `UIImagePickerController` for camera capture because it is straightforward and sufficient for a minimal utility app.

Flow:

1. web UI requests `app.camera.capturePhoto()`
2. native checks availability and permission
3. native presents camera UI
4. native receives captured image
5. image is converted into an attachment-ready representation
6. user may proceed to compose email with attachment

Later upgrades could replace this with a more advanced camera pipeline, but that is unnecessary in v1.

---

## Subject Formatting Strategy

The app needs one consistent subject format:

`Category: Tag-Primary: Tag-Secondary: Tag-Tertiary: Subject`

A single shared formatter should be used by both the note and camera flows.

### Recommended Rule
Use a deterministic omission strategy:

- trim all values
- discard empty segments
- keep order
- join remaining segments with `: `

So if only Category, Tag Primary, and Subject are present:

`Ideas: Urgent: Prototype notes`

This is cleaner than preserving empty placeholder segments and avoids awkward repeated separators.

Document this clearly and test it.

---

## Bridge Design

Use a JSON request/response bridge.

### Request Envelope
Fields:
- `id`
- `namespace`
- `method`
- `params`

### Response Envelope
Fields:
- `id`
- `ok`
- `result` or `error`

### Principles
- explicit method routing
- strict validation
- no arbitrary command execution
- promise-friendly web client
- consistent machine-readable errors

Suggested namespaces:
- `meta`
- `mail`
- `camera`
- `device`
- `permissions`

---

## Web UI Structure

The frontend should be organized into Web Components.

Suggested custom elements:

- `<app-shell>`
- `<main-menu-card>`
- `<email-note-view>`
- `<camera-view>`
- `<metadata-form>`
- `<status-banner>`

### Component Pattern
Each component should:
- encapsulate rendering
- emit explicit events
- call bridge services via a shared client
- avoid hidden global dependencies when possible

---

## Proposed Repository Structure

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

      Utilities/
        TemporaryFileManager.swift
        ImageEncoding.swift

      Resources/
        Web/

  Web/
    package.json
    tsconfig.json
    src/
      bridge/
        bridge-client.ts
        bridge-types.ts
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
      state/
        store.ts
      styles/
        app.css
      types/
        mail.ts
        meta.ts
        camera.ts
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

## Extensibility Notes

The app should be built so these future additions are straightforward:

- more metadata fields
- more destination email addresses
- saved drafts
- local persistence
- multiple card actions on the home screen
- additional native integrations
- OCR or text extraction from photos
- attachment previews
- configurable option lists for categories/tags

This means keeping:
- the bridge small but extensible
- form serialization generic where reasonable
- metadata handling centralized
- mail subject formatting in one place

---

## Summary

The best v1 architecture is:

- native iOS shell in Swift
- `WKWebView` as primary UI container
- Web Components for all major screens
- JSON bridge for native interactions
- `MFMailComposeViewController` for email
- `UIImagePickerController` for initial camera support
- one shared subject formatter
- simple card-style menu as the main entry point

This keeps the app minimal, robust, and ready to grow.
