# MyIOSApp.xcodeproj

This directory is a placeholder. The actual Xcode project file must be created in Xcode.

## Steps to Create the Xcode Project

1. Open Xcode
2. Choose **File → New → Project**
3. Select **iOS → App**
4. Configure:
   - **Product Name**: MyIOSApp
   - **Interface**: Storyboard
   - **Language**: Swift
   - **Include Tests**: Yes
5. Save the project **inside this directory** (`Native/`)
6. Set deployment target to **iOS 16.0**

## After Creation

1. Delete the auto-generated `ViewController.swift`
2. Add all Swift files from `Native/MyIOSApp/` to the project (drag into Xcode, selecting **"Copy items if needed"** and placing in the correct groups)
3. Add `Native/MyIOSApp/Resources/Web/` as a **folder reference** (blue folder icon) — this preserves the directory structure in the bundle
4. Add `NSCameraUsageDescription` to `Info.plist`
5. Run `npm run build` in `Web/` and copy the `dist/` contents to `Native/MyIOSApp/Resources/Web/`

## Group Structure in Xcode

```
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
    Web/  (folder reference — blue folder)
```
