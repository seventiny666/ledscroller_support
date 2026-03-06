import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 设置全局导航栏样式
        setupGlobalAppearance()
        
        window = UIWindow(windowScene: windowScene)
        
        // 检查是否是首次启动
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // 首次启动，显示启动动画
            let launchVC = LaunchAnimationViewController()
            launchVC.onAnimationComplete = { [weak self] in
                // 动画完成后，切换到主界面
                self?.showMainInterface()
            }
            window?.rootViewController = launchVC
            
            // 标记已经启动过
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        } else {
            // 非首次启动，直接显示主界面
            showMainInterface()
        }
        
        window?.makeKeyAndVisible()
    }
    
    private func showMainInterface() {
        // 使用新的TabBar控制器
        let tabBarController = MainTabBarController()
        
        // 添加淡入过渡动画
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = tabBarController
        })
    }
    
    private func setupGlobalAppearance() {
        // 设置导航栏全局样式
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1) // 深色背景
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // 应用到所有导航栏
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        if #available(iOS 15.0, *) {
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

// MARK: - 启动动画视图控制器
class LaunchAnimationViewController: UIViewController {
    
    private let logoLabel = UILabel()
    var onAnimationComplete: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1)
        
        // GlowLed Logo文字
        logoLabel.text = "GlowLed"
        logoLabel.font = .boldSystemFont(ofSize: 48)
        logoLabel.textColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        logoLabel.textAlignment = .center
        logoLabel.alpha = 0
        logoLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        
        // 添加霓虹发光效果
        logoLabel.layer.shadowColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        logoLabel.layer.shadowRadius = 20
        logoLabel.layer.shadowOpacity = 0.8
        logoLabel.layer.shadowOffset = .zero
        
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func startAnimation() {
        // 第一阶段：淡入+放大
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.logoLabel.alpha = 1.0
            self.logoLabel.transform = .identity
        }) { _ in
            // 第二阶段：脉动效果
            self.pulseAnimation()
        }
    }
    
    private func pulseAnimation() {
        UIView.animate(withDuration: 0.6, delay: 0, options: [.autoreverse], animations: {
            self.logoLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.logoLabel.layer.shadowRadius = 30
        }) { _ in
            // 第三阶段：淡出
            self.fadeOutAnimation()
        }
    }
    
    private func fadeOutAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseIn, animations: {
            self.logoLabel.alpha = 0
            self.logoLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            // 动画完成，通知回调
            self.onAnimationComplete?()
        }
    }
}
