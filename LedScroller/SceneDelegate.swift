import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 设置全局导航栏样式
        setupGlobalAppearance()
        
        window = UIWindow(windowScene: windowScene)
        
        // 直接显示主界面，不再显示首次启动动画
        showMainInterface()
        
        window?.makeKeyAndVisible()
    }
    
    private func showMainInterface() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-debugDigitalClock") {
            let vc = DigitalClockViewController()
            vc.modalPresentationStyle = .fullScreen
            window?.rootViewController = vc
            return
        }
        #endif

        showMainInterfaceFromDebug()
    }

    // Exposed for debug-only root controllers that need to return to the main UI.
    func showMainInterfaceFromDebug() {
        // 使用新的TabBar控制器
        let tabBarController = MainTabBarController()

        // 添加淡入过渡动画
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = tabBarController
        })
    }
    
    private func setupGlobalAppearance() {
        // 设置导航栏全局样式 - 统一为纯黑色，避免切换时的视觉闪烁
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 纯黑背景
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.shadowColor = .clear // 移除阴影，避免闪烁
        
        // 应用到所有导航栏
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactScrollEdgeAppearance = navigationBarAppearance
        }
        
        // 设置导航栏按钮颜色
        UINavigationBar.appearance().tintColor = .systemPink
        
        // 强制设置为暗色模式，确保状态栏为白色文字
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }
    }
}
