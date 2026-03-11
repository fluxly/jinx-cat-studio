# Implementation Prompts: Incremental Claude Code Runs for the iOS Utility App

This file breaks the work into small Claude Code runs so the project stays stable and coherent.

Run these in order.

---

## Run 1 — Initialize Repository

Prompt:

Create the initial repository layout exactly as defined in `ios_wkwebview_utility_project_skeleton.md`.

Tasks:
1. Create the full directory structure.
2. Add placeholder files for Swift, TypeScript, and Markdown files.
3. Add a top-level README describing:
   - native iOS shell
   - `WKWebView` UI
   - JSON bridge
   - mail compose integration
   - camera integration
4. Keep implementations minimal and scaffold-focused.

Do not implement business logic yet.

---

## Run 2 — iOS App Shell

Prompt:

Implement the iOS app shell.

Tasks:
1. Create the Xcode project.
2. Implement:
   - `AppDelegate`
   - `SceneDelegate`
   - `RootViewController`
   - `WebViewController`
3. Instantiate a `WKWebView`.
4. Load the local frontend HTML from bundled resources.
5. Register a script message handler named `bridge`.

The app should launch and display the frontend page.

---

## Run 3 — Bridge Infrastructure

Prompt:

Implement the native/web bridge infrastructure.

Create:
- `BridgeMessage.swift`
- `BridgeResponse.swift`
- `BridgeError.swift`
- `BridgeRouter.swift`

Requirements:
- define request envelope
- define success/error response envelopes
- validate namespace and method
- route to handlers
- keep the bridge explicit and JSON-based

Do not implement handler business logic yet.

---

## Run 4 — Web Bridge Client

Prompt:

Implement the frontend bridge client.

Create:
- `src/bridge/bridge-client.ts`
- `src/bridge/bridge-types.ts`

Requirements:
- Promise-based API
- automatic request IDs
- send requests through `window.webkit.messageHandlers.bridge.postMessage`
- receive native responses and resolve/reject pending requests
- support calls like:
  - `bridge.call("mail.composeNote", payload)`
  - `bridge.call("camera.capturePhoto", {})`

---

## Run 5 — Home Screen UI

Prompt:

Implement the initial frontend shell and main menu UI.

Create:
- `app-shell.ts`
- `main-menu-card.ts`
- `home-view.ts`
- `app.css`

Requirements:
- card-style home screen
- Email button
- Camera button
- simple navigation/state handling
- mobile-friendly layout

---

## Run 6 — Metadata Form Component

Prompt:

Implement a reusable metadata form component.

Create:
- `metadata-form.ts`
- supporting types if needed

Fields:
- Category
- Tag Primary
- Tag Secondary
- Tag Tertiary
- Subject

Requirements:
- reusable by both Email and Camera flows
- easy to extend later
- emits structured form values

---

## Run 7 — Subject Formatter + Tests

Prompt:

Implement native subject formatting.

Create:
- `SubjectFormatter.swift`
- `SubjectFormatterTests.swift`

Use this rule:
- trim values
- drop empty segments
- preserve order
- join with `: `

Order:
Category, Tag Primary, Tag Secondary, Tag Tertiary, Subject

Use the formatter from both note and camera mail flows.

---

## Run 8 — Mail Compose Service

Prompt:

Implement native mail composition support.

Create:
- `MailComposeService.swift`
- `MailRequestDTO.swift`
- `MailComposeTests.swift`

Requirements:
- use `MFMailComposeViewController`
- fixed recipient `fluxama@gmail.com`
- set formatted subject
- set note body
- report mail availability
- return structured result states

Do not attach photos yet.

---

## Run 9 — Note Email View

Prompt:

Implement the note email screen.

Create:
- `email-note-view.ts`
- `email-view.ts`
- `MailHandler.swift`

Requirements:
- render metadata form
- render note textarea
- send payload through `mail.composeNote`
- handle success/error/cancel feedback
- use shared bridge client

---

## Run 10 — Device + Permission Reporting

Prompt:

Implement capability and permission reporting.

Create:
- `DeviceHandler.swift`
- `PermissionsHandler.swift`
- `CapabilityService.swift`
- DTOs for capability and permission status

Expose:
- camera availability
- mail availability
- camera permission state

Return results to the web UI through bridge endpoints.

---

## Run 11 — Camera Service

Prompt:

Implement native camera capture.

Create:
- `CameraService.swift`
- `PhotoCaptureResultDTO.swift`
- `CameraServiceTests.swift`

Requirements:
- use `UIImagePickerController` for v1
- check availability/permissions
- present capture UI
- return captured image result
- prepare image data for later email attachment use

---

## Run 12 — Camera View UI

Prompt:

Implement the camera view UI.

Create:
- `camera-view.ts`
- `camera-compose-view.ts`

Requirements:
- allow metadata entry
- invoke `camera.capturePhoto`
- show basic captured-photo status
- keep the UI minimal but extensible

---

## Run 13 — Compose Photo Email

Prompt:

Implement email composition with a captured photo attachment.

Requirements:
- add `mail.composePhoto`
- attach captured image to `MFMailComposeViewController`
- use shared subject formatting
- keep recipient fixed to `fluxama@gmail.com`
- surface result status back to the UI

Update both native services and web UI as needed.

---

## Run 14 — Meta Options Source

Prompt:

Implement a simple source of dropdown options.

Create:
- `MetaHandler.swift`

Requirements:
- expose category and tag option lists to the frontend
- keep the source simple for v1 (hardcoded or config-backed)
- structure it so it can later be replaced with persistence or remote config

Use `app.meta.getOptions()` from the web UI.

---

## Run 15 — Hardening and Packaging

Prompt:

Improve production readiness.

Tasks:
- better error handling
- structured logging
- graceful fallback when mail or camera is unavailable
- permission messaging
- bundle built web assets into app resources
- update docs
- verify the project is easy to extend

---

## Final Result

Following these runs should produce:

- native iOS app shell
- `WKWebView` UI built with Web Components
- email note flow
- camera capture flow
- photo email attachment flow
- JSON bridge
- clean repo structure
- implementation-friendly docs
