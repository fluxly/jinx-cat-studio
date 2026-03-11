# Bridge API Reference

## Overview

All communication between the web layer and native Swift layer uses a JSON message bus over WKWebView's script message handler.

**Sending a request (JS → Native)**:
```js
window.webkit.messageHandlers.bridge.postMessage(jsonString);
```

**Receiving a response (Native → JS)**:
```js
window.nativeBridge.receiveResponse(jsonString);
```

In practice, use the `BridgeClient` which wraps this in a Promise:
```ts
import { bridge } from './bridge/bridge-client';
const result = await bridge.call('namespace.method', { key: 'value' });
```

---

## Request Format

```json
{
  "id": "req-001",
  "namespace": "mail",
  "method": "composeNote",
  "params": { ... }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique request identifier for response correlation |
| `namespace` | string | yes | Handler group: `meta`, `mail`, `camera`, `device`, `permissions` |
| `method` | string | yes | Method name within the namespace |
| `params` | object | no | Method-specific parameters |

## Response Format — Success

```json
{
  "id": "req-001",
  "ok": true,
  "result": { ... }
}
```

## Response Format — Error

```json
{
  "id": "req-001",
  "ok": false,
  "error": {
    "code": "error_code",
    "message": "Human-readable description."
  }
}
```

---

## Namespace: `meta`

### `meta.getOptions`

Returns hardcoded category and tag option lists for UI dropdowns.

**Request params**: none

**Response result**:
```json
{
  "categories": ["Ideas", "Tasks", "Reference", "Journal", "Project", "Personal", "Work", "Other"],
  "tagOptions": ["Urgent", "Important", "Someday", "Waiting", "Active", "Backlog", "Done", "Other"]
}
```

**Error codes**: none (always succeeds)

**Example**:
```ts
const options = await bridge.call<MetaOptions>('meta.getOptions');
```

---

## Namespace: `mail`

### `mail.composeNote`

Opens `MFMailComposeViewController` to compose a text-only email note.

**Request params**:
```json
{
  "category": "Ideas",
  "tagPrimary": "Urgent",
  "tagSecondary": "",
  "tagTertiary": "",
  "subject": "My Note",
  "body": "Note body text here."
}
```

All params fields are optional strings.

**Subject line construction**: `SubjectFormatter` joins non-empty values: Category → TagPrimary → TagSecondary → TagTertiary → Subject, separated by `": "`.

**Hardcoded recipient**: `fluxama@gmail.com`

**Response result**:
```json
{ "status": "sent" }
```

Status values:
| Value | Meaning |
|-------|---------|
| `"sent"` | User tapped Send |
| `"saved"` | User saved as draft |
| `"cancelled"` | User cancelled |
| `"failed"` | Send failed (rare) |

**Error codes**:
| Code | Description |
|------|-------------|
| `mail_unavailable` | `MFMailComposeViewController.canSendMail()` returned false |
| `invalid_params` | Parameter extraction failed |

**Example**:
```ts
const result = await bridge.call<MailResult>('mail.composeNote', {
  category: 'Ideas',
  tagPrimary: 'Urgent',
  subject: 'My Idea',
  body: 'Details here.'
});
// result.status === 'sent' | 'saved' | 'cancelled' | 'failed'
```

---

### `mail.composePhoto`

Opens `MFMailComposeViewController` to send a photo as an email attachment.

**Request params**:
```json
{
  "category": "Work",
  "tagPrimary": "Active",
  "tagSecondary": "",
  "tagTertiary": "",
  "subject": "Photo",
  "imageBase64": "<base64-encoded JPEG string>"
}
```

`imageBase64` is a base64-encoded JPEG string (no data URI prefix). Typically populated from a prior `camera.capturePhoto` result stored in app state.

**Response result**: Same as `mail.composeNote` — `{ "status": "sent" | "saved" | "cancelled" | "failed" }`

**Error codes**:
| Code | Description |
|------|-------------|
| `mail_unavailable` | Mail not available on device |
| `invalid_image` | `imageBase64` is missing or cannot be decoded |
| `invalid_params` | Parameter extraction failed |

**Example**:
```ts
const result = await bridge.call<MailResult>('mail.composePhoto', {
  category: 'Work',
  subject: 'Site Photo',
  imageBase64: store.getState().capturedImageBase64
});
```

---

## Namespace: `camera`

### `camera.capturePhoto`

Presents `UIImagePickerController` with `.camera` source type. User captures a photo. Returns base64-encoded JPEG.

**Request params**: none (no current parameters)

**Response result**:
```json
{
  "status": "captured",
  "imageBase64": "<base64-encoded JPEG>",
  "error": null
}
```

Status values:
| Value | Meaning |
|-------|---------|
| `"captured"` | Photo captured, `imageBase64` is populated |
| `"cancelled"` | User cancelled picker |
| `"failed"` | Capture failed (error string in `error` field) |
| `"unavailable"` | Camera not available on this device/simulator |

**Error codes**:
| Code | Description |
|------|-------------|
| `camera_unavailable` | `UIImagePickerController.isSourceTypeAvailable(.camera)` is false |
| `capture_failed` | Image could not be encoded |

**Example**:
```ts
const result = await bridge.call<CaptureResult>('camera.capturePhoto');
if (result.status === 'captured') {
  store.setState({ capturedImageBase64: result.imageBase64 });
}
```

---

## Namespace: `device`

### `device.getCapabilities`

Returns device feature availability flags.

**Request params**: none

**Response result**:
```json
{
  "hasMail": true,
  "hasCamera": true,
  "cameraPermission": "authorized"
}
```

`cameraPermission` values: `"authorized"`, `"denied"`, `"notDetermined"`, `"restricted"`

**Error codes**: none (always succeeds)

**Example**:
```ts
const caps = await bridge.call<DeviceCapabilities>('device.getCapabilities');
if (!caps.hasMail) { /* disable mail UI */ }
```

---

## Namespace: `permissions`

### `permissions.getStatus`

Returns current permission states for all protected capabilities.

**Request params**: none

**Response result**:
```json
{
  "camera": "notDetermined",
  "mail": "available"
}
```

`camera` values: `"authorized"`, `"denied"`, `"notDetermined"`, `"restricted"`
`mail` values: `"available"`, `"unavailable"`

**Error codes**: none (always succeeds)

**Example**:
```ts
const perms = await bridge.call<PermissionStatus>('permissions.getStatus');
if (perms.camera === 'denied') { /* show settings prompt */ }
```

---

## Error Code Reference

| Code | Namespace | Description |
|------|-----------|-------------|
| `invalid_request` | all | JSON parse failure or missing required field |
| `unknown_namespace` | all | No handler registered for the given namespace |
| `unknown_method` | all | Handler does not recognize the method name |
| `mail_unavailable` | mail | MFMailComposeViewController.canSendMail() == false |
| `invalid_params` | mail | Required params missing or wrong type |
| `invalid_image` | mail | imageBase64 cannot be decoded to UIImage |
| `camera_unavailable` | camera | Camera hardware not available |
| `capture_failed` | camera | Image encoding failed after capture |
| `handler_error` | all | Unexpected handler-level error (catch-all) |
