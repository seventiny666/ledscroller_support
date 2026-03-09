import UIKit

// 主TabBar控制器
class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 使用自定义 TabBar
        setValue(CustomSpacedTabBar(), forKey: "tabBar")
        
        self.delegate = self
        setupViewControllers() // 先设置视图控制器
        setupTabBar() // 再设置 TabBar 样式
        
        // 延迟刷新TabBar布局，确保文字正确显示
        DispatchQueue.main.async {
            self.tabBar.setNeedsLayout()
            self.tabBar.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 再次根据 tag 设置 title（iOS 17 可能会在显示时清空）
        if let items = tabBar.items {
            for item in items {
                switch item.tag {
                case 0:
                    if item.title?.isEmpty ?? true {
                        item.title = "首页"
                        print("🔍 TabBar viewDidAppear: Fixed tag 0 title to '首页'")
                    }
                case 1:
                    if item.title?.isEmpty ?? true {
                        item.title = "创作"
                        print("🔍 TabBar viewDidAppear: Fixed tag 1 title to '创作'")
                    }
                case 2:
                    if item.title?.isEmpty ?? true {
                        item.title = "设置"
                        print("🔍 TabBar viewDidAppear: Fixed tag 2 title to '设置'")
                    }
                default:
                    break
                }
            }
        }
        
        // 强制刷新 TabBar 以确保文字显示
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        
        // 调试：打印所有 tabBarItem 的 title
        if let items = tabBar.items {
            for (index, item) in items.enumerated() {
                print("🔍 TabBar item[\(index)]: title = '\(item.title ?? "nil")', tag = \(item.tag)")
            }
        }
    }
    
    // 完全禁用TabBar切换动画
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 禁用所有动画效果
        UIView.setAnimationsEnabled(false)
        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(true)
        }
        return true
    }
    
    // 自定义TabBar切换动画 - 返回nil禁用过渡动画
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 返回nil禁用过渡动画
        return nil
    }
    
    private func setupTabBar() {
        // 暗色TabBar样式 - 统一为纯黑色，避免切换时的视觉闪烁
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 纯黑背景
        appearance.shadowColor = .clear // 移除阴影，避免闪烁
        
        // 设置选中和未选中的颜色
        let accentColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        
        // 配置 stacked 布局（图标在上，文字在下）- 增加字体大小和间距
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 11)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // 应用到所有状态的TabBar
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // 确保TabBar不透明
        tabBar.isTranslucent = false
        tabBar.barTintColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        tabBar.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // 禁用iOS 17+的新动画效果和点击高亮
        if #available(iOS 17.0, *) {
            tabBar.layer.allowsGroupOpacity = false
        }
        
        print("🔍 TabBar: setupTabBar completed")
        
        // 根据 tag 重新设置 title，确保正确对应
        if let items = tabBar.items {
            for item in items {
                switch item.tag {
                case 0:
                    item.title = "首页"
                    print("🔍 TabBar: Set tag 0 title to '首页'")
                case 1:
                    item.title = "创作"
                    print("🔍 TabBar: Set tag 1 title to '创作'")
                case 2:
                    item.title = "设置"
                    print("🔍 TabBar: Set tag 2 title to '设置'")
                case 98, 99:
                    // 占位符标签 - 完全隐藏
                    item.title = ""
                    item.image = nil
                    item.isEnabled = false
                default:
                    break
                }
            }
        }
    }
    
    private func setupViewControllers() {
        // 1. 首页
        let templateVC = TemplateSquareViewController()
        let templateNav = UINavigationController(rootViewController: templateVC)
        
        // 直接使用中文，避免本地化问题
        templateNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        templateNav.tabBarItem.tag = 0
        
        // 禁用iOS 17.4+的胶囊高亮效果
        if #available(iOS 17.4, *) {
            templateNav.tabBarItem.isSpringLoaded = false
        }
        
        print("🔍 TabBar: 首页 tabBarItem.title = '\(templateNav.tabBarItem.title ?? "nil")'")
        
        // 添加占位符1（不可见）
        let spacer1 = UIViewController()
        spacer1.tabBarItem = UITabBarItem(title: "", image: nil, tag: 99)
        spacer1.tabBarItem.isEnabled = false
        
        // 2. 创作
        let creationsVC = MyCreationsViewController()
        let creationsNav = UINavigationController(rootViewController: creationsVC)
        creationsNav.tabBarItem = UITabBarItem(
            title: "创作",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        creationsNav.tabBarItem.tag = 1
        
        // 禁用iOS 17.4+的胶囊高亮效果
        if #available(iOS 17.4, *) {
            creationsNav.tabBarItem.isSpringLoaded = false
        }
        
        print("🔍 TabBar: 创作 tabBarItem.title = '\(creationsNav.tabBarItem.title ?? "nil")'")
        
        // 添加占位符2（不可见）
        let spacer2 = UIViewController()
        spacer2.tabBarItem = UITabBarItem(title: "", image: nil, tag: 98)
        spacer2.tabBarItem.isEnabled = false
        
        // 3. 设置
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        settingsNav.tabBarItem.tag = 2
        
        // 禁用iOS 17.4+的胶囊高亮效果
        if #available(iOS 17.4, *) {
            settingsNav.tabBarItem.isSpringLoaded = false
        }
        
        print("🔍 TabBar: 设置 tabBarItem.title = '\(settingsNav.tabBarItem.title ?? "nil")'")
        
        // 使用5个标签布局：首页 - 占位1 - 创作 - 占位2 - 设置
        viewControllers = [templateNav, spacer1, creationsNav, spacer2, settingsNav]
        
        print("🔍 TabBar: viewControllers count = \(viewControllers?.count ?? 0)")
    }
}
