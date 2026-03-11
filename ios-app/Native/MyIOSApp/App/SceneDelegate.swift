import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            AppLogger.log(.error, "Scene is not a UIWindowScene")
            return
        }

        let rootViewController = RootViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window

        AppLogger.log(.info, "Scene connected, window created with RootViewController")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        AppLogger.log(.debug, "Scene did disconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppLogger.log(.debug, "Scene did become active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        AppLogger.log(.debug, "Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLogger.log(.debug, "Scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLogger.log(.debug, "Scene did enter background")
    }
}
