import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 使用新的TabBar控制器
        let tabBarController = MainTabBarController()
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
