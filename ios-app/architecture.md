# Architecture

## Native / Web Boundary

The app is divided into two distinct layers that communicate exclusively through the bridge:

**Native Layer (Swift)**
- Owns the UIWindow, UIViewController hierarchy
- Hosts WKWebView as the sole UI surface
- Implements all platform integrations (mail, camera, permissions)
- Receives bridge messages and dispatches to handlers
- Returns responses via `evaluateJavaScript`

**Web Layer (TypeScript / Web Components)**
- Runs inside WKWebView
- Owns all visual UI rendering using custom elements
- Communicates with native exclusively via the bridge
- Maintains its own reactive state store
- Has no direct access to iOS APIs

The boundary is enforced by the bridge protocol. No web code calls UIKit directly; no Swift code manipulates DOM elements.

## Bridge Design

### Message Flow

```
Web Component
  → bridge.call("namespace.method", params)
    → window.webkit.messageHandlers.bridge.postMessage(jsonString)
      → WKScriptMessageHandler.userContentController(_:didReceive:)
        → BridgeRouter.route(rawJSON:completion:)
          → BridgeHandler.handle(message:completion:)
            → completion(responseJSON)
              → WebViewController.sendBridgeResponse(json)
                → evaluateJavaScript("window.nativeBridge.receiveResponse(...)")
                  → BridgeClient.receiveResponse(jsonString)
                    → Promise resolve/reject
```

### Request Envelope

```json
{
  "id": "req-001",
  "namespace": "mail",
  "method": "composeNote",
  "params": { ... }
}
```

- `id`: Caller-generated unique string for correlating responses
- `namespace`: Groups related methods (mail, camera, meta, device, permissions)
- `method`: The specific operation to invoke
- `params`: Optional method-specific parameters object

### Response Envelope — Success

```json
{
  "id": "req-001",
  "ok": true,
  "result": { ... }
}
```

### Response Envelope — Error

```json
{
  "id": "req-001",
  "ok": false,
  "error": {
    "code": "mail_unavailable",
    "message": "Mail services are not configured on this device."
  }
}
```

### Bridge Router

`BridgeRouter` maintains a dictionary of `[String: BridgeHandler]` keyed by namespace. On receiving a message it:
1. Parses the raw JSON into a `BridgeMessage`
2. Looks up the handler by `namespace`
3. Calls `handler.handle(message:completion:)`
4. Returns the handler's response string back through the completion closure
5. Returns structured error responses for unknown namespaces or parse failures

### Thread Safety

All bridge completions are delivered on the main thread since `WKScriptMessageHandler` callbacks arrive on the main thread, and UI-presenting handlers (mail, camera) also require the main thread.

## Mail Integration Strategy

`MFMailComposeViewController` is presented modally over the root view controller. The flow:

1. Web calls `mail.composeNote` or `mail.composePhoto` with metadata params
2. `MailHandler` extracts params and delegates to `MailComposeService`
3. `MailComposeService` checks `MFMailComposeViewController.canSendMail()`
4. If available: constructs the compose VC, sets recipient, subject (via SubjectFormatter), body/attachment, presents it
5. `mailComposeController(_:didFinishWith:error:)` delegate fires
6. Service maps result to status string: "sent" | "saved" | "cancelled" | "failed"
7. Bridge response is sent back to web

**Recipient**: `fluxama@gmail.com` — hardcoded in `MailComposeService.recipientEmail`

**Tradeoff**: `MFMailComposeViewController` requires a Mail account configured on device. In simulator or devices without Mail, `canSendMail()` returns false and the bridge returns an error code `mail_unavailable`.

## Camera Integration Strategy

`UIImagePickerController` is presented modally with `sourceType = .camera`:

1. Web calls `camera.capturePhoto`
2. `CameraHandler` delegates to `CameraService`
3. `CameraService` checks `UIImagePickerController.isSourceTypeAvailable(.camera)`
4. Presents picker; user captures photo
5. `imagePickerController(_:didFinishPickingMediaWithInfo:)` fires
6. Image is extracted from `UIImagePickerController.InfoKey.originalImage`
7. Image is JPEG-encoded and base64-encoded via `ImageEncoding`
8. `PhotoCaptureResult` with status "captured" and `imageBase64` is returned to web
9. Web stores base64 in state for subsequent `mail.composePhoto` call

**Tradeoff**: `UIImagePickerController` is deprecated as of iOS 14 in favor of `PHPickerViewController`, but remains functional through iOS 17+. It is preferred here because it directly supports camera capture (PHPicker is gallery-only). `AVCaptureSession` would provide more control but adds significant complexity.

## Subject Formatting Rule

Subject lines are constructed from up to five components: Category, Tag Primary, Tag Secondary, Tag Tertiary, and Subject.

**Algorithm**:
1. Collect values in order: [category, tagPrimary, tagSecondary, tagTertiary, subject]
2. Trim whitespace from each value
3. Discard any value that is nil, empty, or whitespace-only
4. Join remaining values with `": "`

**Examples**:
- Category="Ideas", TagPrimary="Urgent", Subject="My Note" → `"Ideas: Urgent: My Note"`
- Category="Work", others empty, Subject="Q4 Plan" → `"Work: Q4 Plan"`
- All empty → `""` (empty string, falls back to no subject in mail compose VC)
- Subject only → `"My Note"`

This rule is implemented in `SubjectFormatter.format(...)` and covered by unit tests in `SubjectFormatterTests.swift`.

## Capability & Permission Model

`CapabilityService` queries:
- `MFMailComposeViewController.canSendMail()` → `hasMail`
- `UIImagePickerController.isSourceTypeAvailable(.camera)` → `hasCamera`
- `AVCaptureDevice.authorizationStatus(for: .video)` → `cameraPermission`

Camera permission states map to: `"authorized"`, `"denied"`, `"notDetermined"`, `"restricted"`.

The web layer consults capabilities on startup to disable UI elements that are unavailable on the current device/simulator.
