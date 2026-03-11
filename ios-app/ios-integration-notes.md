# iOS Integration Notes

## WKWebView Setup

### Configuration

```swift
let config = WKWebViewConfiguration()
let contentController = WKUserContentController()
contentController.add(self, name: "bridge")
config.userContentController = contentController
let webView = WKWebView(frame: .zero, configuration: config)
```

The message handler name `"bridge"` maps to `window.webkit.messageHandlers.bridge` in JavaScript.

### Script Message Handler Leak

`WKUserContentController` retains its message handlers strongly. If `WebViewController` registers itself directly as the handler, it creates a retain cycle. The recommended pattern is a weak-proxy:

```swift
class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ uc: WKUserContentController, didReceive msg: WKScriptMessage) {
        delegate?.userContentController(uc, didReceive: msg)
    }
}
// Usage:
contentController.add(WeakScriptMessageHandler(self), name: "bridge")
```

Remove the handler on deinit:
```swift
deinit {
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "bridge")
}
```

### Loading Local Resources

Load `index.html` from the app bundle's `Resources/Web/` group:

```swift
if let webDir = Bundle.main.url(forResource: "Web", withExtension: nil, subdirectory: "Resources"),
   let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources/Web") {
    webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
}
```

`loadFileURL(_:allowingReadAccessTo:)` grants the webView read access to the entire directory, which allows Vite's bundled assets (JS, CSS, chunks) to be loaded.

**Important**: The web directory must be added to Xcode as a "folder reference" (blue folder icon), not a group (yellow folder icon). Folder references preserve directory structure in the bundle.

### App Transport Security

For local file loading, no special ATS exceptions are needed. If the app ever loads remote content, add appropriate ATS entries to Info.plist.

---

## MFMailComposeViewController Tradeoffs

### Availability Check

Always call `MFMailComposeViewController.canSendMail()` before presenting. Returns false when:
- No Mail accounts configured on device
- Running in Simulator (always false in most Simulator configurations)
- Parental Controls restrict mail

### Delegate Pattern

The compose VC must be dismissed by its delegate:
```swift
func mailComposeController(_ controller: MFMailComposeViewController,
                           didFinishWith result: MFMailComposeResult,
                           error: Error?) {
    controller.dismiss(animated: true) {
        // call completion here
    }
}
```

Result mapping:
```swift
switch result {
case .sent:      return "sent"
case .saved:     return "saved"
case .cancelled: return "cancelled"
case .failed:    return "failed"
@unknown default: return "failed"
}
```

### Attachments

For photo attachments, use JPEG data:
```swift
composer.addAttachmentData(jpegData, mimeType: "image/jpeg", fileName: "photo.jpg")
```

### Simulator Testing

Since `canSendMail()` always returns false in Simulator, test the mail flow on a physical device with a Mail account configured, or mock `MailComposeService` in tests.

---

## UIImagePickerController Usage

### Camera Source Check

```swift
guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
    // camera unavailable (Simulator, restricted device)
    return
}
```

### Presenting

```swift
let picker = UIImagePickerController()
picker.sourceType = .camera
picker.delegate = self
picker.allowsEditing = false
viewController.present(picker, animated: true)
```

### Delegate

```swift
func imagePickerController(_ picker: UIImagePickerController,
                           didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)
    if let image = info[.originalImage] as? UIImage {
        // encode and return
    }
}

func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    // return cancelled status
}
```

### Deprecation Note

`UIImagePickerController` is deprecated in iOS 14 for photo library access (replaced by `PHPickerViewController`). However, for **camera capture** specifically, it remains the only non-`AVCaptureSession` API through iOS 17. It continues to function and is appropriate for this use case.

---

## Permission Handling

### Camera Permission

Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to capture photos for email attachments.</string>
```

Check authorization:
```swift
import AVFoundation

let status = AVCaptureDevice.authorizationStatus(for: .video)
switch status {
case .authorized:     // proceed
case .notDetermined:  AVCaptureDevice.requestAccess(for: .video) { granted in ... }
case .denied:         // direct user to Settings
case .restricted:     // cannot request
@unknown default:     break
}
```

The camera permission description string is required by App Store Connect; the app will crash on launch if missing when camera access is attempted.

### Mail Permission

Mail does not require explicit user permission. `MFMailComposeViewController.canSendMail()` reflects availability without a permission prompt.

---

## Info.plist Requirements

Minimum required keys:

```xml
<!-- Camera usage -->
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to capture photos for email attachments.</string>

<!-- Required for all apps -->
<key>UIApplicationSceneManifest</key>
<!-- ... scene configuration ... -->

<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

If using SceneDelegate (recommended for iOS 13+), ensure the scene configuration in Info.plist matches the delegate class name.

---

## WKWebView Navigation Policy

To prevent the webView from navigating to external URLs (e.g., from links in content):

```swift
func webView(_ webView: WKWebView,
             decidePolicyFor action: WKNavigationAction,
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if action.navigationType == .linkActivated {
        decisionHandler(.cancel)
        if let url = action.request.url {
            UIApplication.shared.open(url)
        }
    } else {
        decisionHandler(.allow)
    }
}
```

---

## Xcode Project Setup Checklist

1. Create new iOS App project (Swift, UIKit, SceneDelegate enabled)
2. Set deployment target: iOS 16.0
3. Delete default `ViewController.swift`
4. Add all Swift files from `Native/MyIOSApp/` maintaining the group structure
5. Add `Resources/Web/` as a **folder reference** (drag with "Create folder references" option)
6. Add `NSCameraUsageDescription` to Info.plist
7. Build phases: verify `Resources/Web` appears in "Copy Bundle Resources"
8. In SceneDelegate, ensure `WebViewController` is initialized in `RootViewController`
9. Import `MessageUI.framework` in Link Binary With Libraries (usually auto-linked)
10. Test on device for mail functionality
