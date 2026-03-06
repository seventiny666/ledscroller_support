import UIKit

// 主TabBar控制器
class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // 暗色TabBar样式 - 兼容新版本iOS
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        // 设置选中和未选中的颜色
        let accentColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        // 应用到所有状态的TabBar
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // 确保TabBar不透明
        tabBar.isTranslucent = false
        tabBar.barTintColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        tabBar.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
    }
    
    private func setupViewControllers() {
        // 1. 首页
        let templateVC = TemplateSquareViewController()
        let templateNav = UINavigationController(rootViewController: templateVC)
        
        // 使用 .localized 以支持应用内语言切换
        templateNav.tabBarItem = UITabBarItem(
            title: "home".localized,
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        templateNav.tabBarItem.tag = 0
        
        // 2. 创作
        let creationsVC = MyCreationsViewController()
        let creationsNav = UINavigationController(rootViewController: creationsVC)
        creationsNav.tabBarItem = UITabBarItem(
            title: "creations".localized,
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        creationsNav.tabBarItem.tag = 1
        
        // 3. 设置
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "settings".localized,
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        settingsNav.tabBarItem.tag = 2
        
        viewControllers = [templateNav, creationsNav, settingsNav]
    }
}
