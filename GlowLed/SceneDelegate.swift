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
        view.backgroundColor = UIColor.black // 纯黑背景更突出霓虹效果
        
        // GlowLed Logo文字
        logoLabel.text = "GlowLed"
        logoLabel.font = .boldSystemFont(ofSize: 52) // 稍微增大字体
        logoLabel.textColor = UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 1.0) // 更鲜艳的青色
        logoLabel.textAlignment = .center
        logoLabel.alpha = 0
        logoLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3) // 从更小开始
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        
        // 添加多层霓虹发光效果
        logoLabel.layer.shadowColor = UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 1.0).cgColor
        logoLabel.layer.shadowRadius = 25
        logoLabel.layer.shadowOpacity = 1.0
        logoLabel.layer.shadowOffset = .zero
        
        // 添加外层发光
        let outerGlow = CALayer()
        outerGlow.backgroundColor = UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 0.3).cgColor
        outerGlow.cornerRadius = 30
        view.layer.insertSublayer(outerGlow, below: logoLabel.layer)
        
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func startAnimation() {
        // 第一阶段：快速闪现 + 弹性放大
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseOut, animations: {
            self.logoLabel.alpha = 1.0
        }) { _ in
            // 第二阶段：弹性放大到正常大小
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                self.logoLabel.transform = .identity
                self.logoLabel.layer.shadowRadius = 35
            }) { _ in
                // 第三阶段：连续脉动效果
                self.continuousPulseAnimation()
            }
        }
    }
    
    private func continuousPulseAnimation() {
        // 连续脉动3次
        UIView.animate(withDuration: 0.4, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.logoLabel.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.logoLabel.layer.shadowRadius = 45
            // 颜色变化效果
            self.logoLabel.textColor = UIColor(red: 0xFF/255.0, green: 0x00/255.0, blue: 0xFF/255.0, alpha: 1.0) // 变为洋红色
            self.logoLabel.layer.shadowColor = UIColor(red: 0xFF/255.0, green: 0x00/255.0, blue: 0xFF/255.0, alpha: 1.0).cgColor
        })
        
        // 2秒后停止脉动并淡出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.logoLabel.layer.removeAllAnimations()
            self.fadeOutAnimation()
        }
    }
    
    private func fadeOutAnimation() {
        UIView.animate(withDuration: 0.6, delay: 0.2, options: .curveEaseIn, animations: {
            self.logoLabel.alpha = 0
            self.logoLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.logoLabel.layer.shadowRadius = 60 // 最后一次强烈发光
        }) { _ in
            // 动画完成，通知回调
            self.onAnimationComplete?()
        }
    }
}
