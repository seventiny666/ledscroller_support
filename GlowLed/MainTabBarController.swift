import UIKit

// 主TabBar控制器
class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // 暗色TabBar样式
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        // 设置选中和未选中的颜色
        let accentColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.isTranslucent = false
    }
    
    private func setupViewControllers() {
        // 1. 模版
        let templateVC = TemplateSquareViewController()
        let templateNav = UINavigationController(rootViewController: templateVC)
        templateNav.tabBarItem = UITabBarItem(
            title: "模版",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        templateNav.tabBarItem.tag = 0
        
        // 2. 创作 - 使用圆形加号图标
        let creationsVC = MyCreationsViewController()
        let creationsNav = UINavigationController(rootViewController: creationsVC)
        creationsNav.tabBarItem = UITabBarItem(
            title: "创作",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        creationsNav.tabBarItem.tag = 1
        
        // 3. 设置
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        settingsNav.tabBarItem.tag = 2
        
        viewControllers = [templateNav, creationsNav, settingsNav]
    }
}
