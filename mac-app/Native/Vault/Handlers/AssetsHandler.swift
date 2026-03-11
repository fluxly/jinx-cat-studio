import Cocoa
import WebKit

final class AssetsHandler: BridgeHandler {
    let namespace = "assets"
    private let service: AssetService
    private weak var webView: WKWebView?

    init(service: AssetService, webView: WKWebView) {
        self.service = service
        self.webView = webView
    }

    func handle(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        do {
            switch message.method {
            case "list":
                let assets = try service.listAssets()
                let encoded = try encodeToAny(assets)
                completion(.success(id: message.id, data: encoded))

            case "get":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let asset = try service.getAsset(id)
                let encoded = try encodeToAny(asset)
                completion(.success(id: message.id, data: encoded))

            case "import":
                // Must run file picker on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.showImportPanel(message: message, completion: completion)
                }

            case "update":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                let originalFilename = message.params["original_filename"]?.value as? String
                let asset = try service.updateAsset(id, originalFilename: originalFilename)
                let encoded = try encodeToAny(asset)
                completion(.success(id: message.id, data: encoded))

            case "delete":
                guard let id = message.params["id"]?.value as? String else {
                    throw BridgeError.invalidParams("Missing required parameter: id")
                }
                try service.deleteAsset(id)
                completion(.success(id: message.id, data: AnyCodable(true)))

            default:
                throw BridgeError.unknownMethod(message.method, namespace: namespace)
            }
        } catch let error as BridgeError {
            completion(.failure(id: message.id, bridgeError: error))
        } catch {
            completion(.failure(id: message.id, bridgeError: .internalError(error.localizedDescription)))
        }
    }

    private func showImportPanel(message: BridgeMessage, completion: @escaping BridgeCompletion) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Import Asset"
        panel.prompt = "Import"

        guard let window = webView?.window else {
            completion(.failure(id: message.id, bridgeError: .internalError("No window available")))
            return
        }

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else {
                completion(.failure(id: message.id, bridgeError: BridgeError(.userCancelled, "Import cancelled")))
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let asset = try self?.service.importAsset(from: url) else {
                        completion(.failure(id: message.id, bridgeError: .internalError("Service unavailable")))
                        return
                    }
                    let encoded = try encodeToAny(asset)
                    completion(.success(id: message.id, data: encoded))
                } catch let error as BridgeError {
                    completion(.failure(id: message.id, bridgeError: error))
                } catch {
                    completion(.failure(id: message.id, bridgeError: .internalError(error.localizedDescription)))
                }
            }
        }
    }
}
