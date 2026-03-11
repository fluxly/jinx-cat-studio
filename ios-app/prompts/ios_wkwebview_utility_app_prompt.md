# Claude Code Prompt: Build an iOS Utility App with WKWebView, Bespoke Swift, and a Native Bridge

## Role

You are Claude Code acting as a senior iOS engineer and systems architect.

Your task is to design and implement a **production-quality iOS application** with these constraints:

- The app is a **native iOS app**
- The UI is implemented **primarily in web technologies**
- The web UI runs inside a **`WKWebView`**
- UI components should be built with **Web Components / Custom Elements**
- Do **not** use cross-platform wrappers like React Native, Capacitor, Cordova, Flutter, Ionic, or similar frameworks
- Native code should be **bespoke Swift**
- The native layer should expose a **minimal, explicit bridge API** to the web layer
- The initial version should be a **small utility app** that can be extended later

The initial product has a simple card-based main menu with buttons for two views:

1. **Email / Note View**
2. **Camera View**

The app should be designed so more views and fields can be added later without restructuring the entire codebase.

---

## Product Requirements

### Main Menu
The home screen should show a simple card-style menu with buttons for:

- Email
- Camera

This UI lives in the web layer inside the `WKWebView`.

### Email / Note View
The Email view should allow the user to compose a note and send it as an email to:

`fluxama@gmail.com`

Fields:

- Category (dropdown)
- Tag Primary (dropdown)
- Tag Secondary (dropdown)
- Tag Tertiary (dropdown)
- Subject (text input)
- Note body (multiline text area)

When the email is sent, the subject line should be constructed exactly like this:

`Category: Tag-Primary: Tag-Secondary: Tag-Tertiary: Subject`

The note body becomes the body of the email.

### Camera View
The Camera view should:

- invoke the camera
- capture a photo
- allow the photo to be emailed to `fluxama@gmail.com`
- use the same subject line format as the Note view
- support the same dropdown/tag metadata fields as the Note view, even if the UI starts minimal

The photo can be attached to the outgoing email.

### Email Sending Behavior
Use the iOS-native mail composition flow.

Preferred approach:
- `MFMailComposeViewController`

If mail composition is unavailable:
- provide a graceful fallback strategy
- expose the error/result clearly back to the web UI

Do **not** attempt to send email silently through a private mail backend in v1.

---

## Architectural Direction

Follow the same overall pattern as the macOS project:

- native shell in Swift
- `WKWebView` for primary UI
- Web Components in the frontend
- thin JSON bridge between JS and Swift
- native layer owns platform integrations
- web layer owns UI rendering and local app flow

### Native Owns
- `WKWebView` host
- bridge routing
- camera access
- image capture handling
- mail composer presentation
- attachment handling
- permission checks
- app lifecycle and iOS integration

### Web Owns
- main menu UI
- note/email form UI
- camera metadata form UI
- state management
- composing structured requests to native
- displaying results/errors

---

## Non-Goals for v1

Do **not** include in version 1 unless needed for correctness:

- database persistence
- remote backend
- silent SMTP sending
- authentication/account systems
- cloud sync
- large offline media library
- advanced routing frameworks
- heavyweight frontend frameworks unless clearly justified

The app should be intentionally minimal, but structured well for future growth.

---

## Bridge API Requirements

Design a small, explicit, JSON-based bridge API between the web layer and Swift.

It should be:

- request/response oriented
- namespaced
- versionable
- promise-friendly in JS
- input validated
- resilient to malformed requests

### Suggested Bridge Surface

- `app.meta.getOptions()`
- `app.mail.composeNote(payload)`
- `app.mail.composePhoto(payload)`
- `app.camera.capturePhoto()`
- `app.device.getCapabilities()`
- `app.permissions.getStatus()`

You may improve naming slightly, but keep the bridge small and explicit.

### Example Request Envelope

```json
{
  "id": "req-123",
  "namespace": "mail",
  "method": "composeNote",
  "params": {
    "category": "Ideas",
    "tagPrimary": "Urgent",
    "tagSecondary": "Project-X",
    "tagTertiary": "Followup",
    "subject": "Prototype notes",
    "body": "Here are my notes..."
  }
}
```

### Example Response Envelope

```json
{
  "id": "req-123",
  "ok": true,
  "result": {
    "status": "presented"
  }
}
```

### Error Envelope

```json
{
  "id": "req-123",
  "ok": false,
  "error": {
    "code": "mail_unavailable",
    "message": "Mail composer is not available on this device."
  }
}
```

---

## Subject Line Rules

Implement a single shared subject formatting utility used by both Note and Camera flows.

Required format:

`Category: Tag-Primary: Tag-Secondary: Tag-Tertiary: Subject`

Rules:

- Preserve the exact ordering above
- Handle empty values deterministically
- Prefer a documented normalization strategy
- Do not duplicate formatting logic in multiple places

Choose one sane strategy for missing values and document it clearly. For example:
- preserve empty segments, or
- omit missing trailing segments, or
- substitute a placeholder like `Unspecified`

Pick one and apply it consistently.

---

## Camera Flow Requirements

The camera flow should:

1. request/check camera permission
2. launch native image capture UI
3. return photo capture result to the app
4. allow the user to compose an email with the captured photo attached
5. include subject metadata fields in the UI

Use native iOS APIs for camera/photo capture.

A simple and robust v1 approach is acceptable:
- `UIImagePickerController` if appropriate
- or a more modern capture approach if justified

Prefer the simpler robust option for v1.

---

## Mail Flow Requirements

Use the native mail composer.

Requirements:

- recipient fixed initially to `fluxama@gmail.com`
- subject formatted from metadata fields
- body included for note flow
- photo attached for camera flow
- result callback from native back to JS/UI
- graceful handling if device mail is unavailable

Document the tradeoffs of `MFMailComposeViewController`.

---

## Frontend Requirements

The frontend runs inside `WKWebView` and should be built with Web Components.

### Suggested Components

- `<app-shell>`
- `<main-menu-card>`
- `<email-note-view>`
- `<camera-view>`
- `<metadata-form>`
- `<status-banner>`

### UI Requirements

- card-style menu on home screen
- straightforward form UI
- mobile-friendly spacing and controls
- easy to extend later
- no heavy framework dependency unless strongly justified

### Suggested Frontend Modules

- `bridge/`
- `components/`
- `views/`
- `styles/`
- `types/`
- `state/`

Keep it simple and understandable.

---

## Native Project Structure Expectations

Use a clean separation such as:

```text
MyIOSApp/
  Native/
    MyIOSApp.xcodeproj
    MyIOSApp/
      App/
      Bridge/
      Handlers/
      Services/
      DTO/
      Utilities/
      Resources/
  Web/
    src/
      bridge/
      components/
      views/
      styles/
      types/
      state/
    public/
  Docs/
  Tests/
```

This may be refined, but keep responsibilities clear.

---

## Documentation Requirements

Create and maintain these docs:

- `README.md`
- `architecture.md`
- `development-plan.md`
- `bridge-api.md`
- `ios-integration-notes.md`

Each should be concrete and implementation-friendly.

---

## Testing Requirements

Include tests from early in the process.

### Native Tests
Test:
- bridge request parsing
- bridge routing
- subject line formatting
- permissions/capability reporting
- mail payload construction
- photo attachment preparation

### Frontend Tests
Test:
- bridge client request/response behavior
- form serialization
- subject preview behavior if present
- major component rendering/events

Keep tests practical and focused.

---

## Implementation Phases

Implement in phases.

### Phase 1: Architecture and Scaffold
Create:
- repo structure
- core docs
- implementation plan
- stubs for native and web layers

### Phase 2: iOS App Shell
Create:
- iOS app shell
- `WKWebView` host
- local web asset loading
- bridge registration

### Phase 3: Bridge Infrastructure
Create:
- request/response types
- bridge router
- handler registration
- JS bridge client

### Phase 4: Home + Navigation UI
Create:
- main menu card
- navigation between Email and Camera views
- basic status banner

### Phase 5: Note Email Flow
Create:
- metadata form
- subject formatting helper
- note body form
- native mail composer integration
- callbacks for success/error/cancel

### Phase 6: Camera Flow
Create:
- camera permission handling
- native photo capture
- photo handoff to UI/native service
- photo email composition

### Phase 7: Hardening
Create:
- validation
- error handling
- empty states
- permission messaging
- docs
- tests

### Phase 8: Packaging and Extensibility
Create:
- production bundling of web assets
- app resources wiring
- extension notes for adding future views/fields

---

## Code Quality Guidance

Write code that is:

- readable
- modular
- typed where possible
- light on unnecessary abstraction
- designed for future extension
- explicit rather than magical

Prefer maintainability over novelty.

---

## Claude Code Working Style

Work iteratively and in meaningful slices.

For each phase:

1. explain what files will be created/updated
2. implement them
3. summarize what was completed
4. note tradeoffs/TODOs
5. keep the project coherent and buildable

Prefer creating real files over giant monolithic chat outputs.

---

## Initial Execution Request

Begin with **Phase 1: Architecture and Scaffold**.

For Phase 1, produce:

- `README.md`
- `architecture.md`
- `development-plan.md`
- proposed directory structure
- explanation of native/web boundary
- explanation of camera + mail integration strategy
- explanation of the chosen subject formatting rule
- step-by-step plan for subsequent phases

Then proceed to **Phase 2: iOS App Shell** if Phase 1 is coherent.

Do not skip foundational structure.

---

## Final Reminder

This is a **bespoke native iOS app** whose UI mostly lives in a **`WKWebView`** and uses **Web Components**, with a **small JSON bridge** to native Swift for **mail composition** and **camera access**.

Implement accordingly, phase by phase, beginning now.
