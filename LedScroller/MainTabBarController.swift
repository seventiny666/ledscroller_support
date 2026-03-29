import UIKit

// 主TabBar控制器
class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 使用自定义 TabBar
        setValue(CustomSpacedTabBar(), forKey: "tabBar")

        // iPadOS may switch UITabBarController to the new top-tab style in regular width.
        // Force compact width on iPad so we keep the bottom tab bar with icons.
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 17.0, *) {
                traitOverrides.horizontalSizeClass = .compact
            }
        }
        
        self.delegate = self
        setupViewControllers() // 先设置视图控制器
        setupTabBar() // 再设置 TabBar 样式
        setupLanguageChangeNotification() // 添加语言切换监听
        
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
                        item.title = "home".localized
                        print("🔍 TabBar viewDidAppear: Fixed tag 0 title to '\("home".localized)'")
                    }
                case 1:
                    if item.title?.isEmpty ?? true {
                        item.title = "creations".localized
                        print("🔍 TabBar viewDidAppear: Fixed tag 1 title to '\("creations".localized)'")
                    }
                case 2:
                    if item.title?.isEmpty ?? true {
                        item.title = "settings".localized
                        print("🔍 TabBar viewDidAppear: Fixed tag 2 title to '\("settings".localized)'")
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
        
        // Configure all layout styles (iPad may use inline/compactInline; iPhone typically uses stacked).
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let tabScale: CGFloat = isPad ? 1.2 : 1.0
        let tabFontSize: CGFloat = (isPad ? 14 : 11) * tabScale

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: tabFontSize)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: tabFontSize, weight: .medium)
        ]

        let layouts = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]
        for layout in layouts {
            layout.normal.iconColor = UIColor.systemGray
            layout.normal.titleTextAttributes = normalAttributes
            layout.selected.iconColor = accentColor
            layout.selected.titleTextAttributes = selectedAttributes
        }
        
        // 应用到所有状态的TabBar
        tabBar.standardAppearance = appearance
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
                    item.title = "home".localized
                    print("🔍 TabBar: Set tag 0 title to '\("home".localized)'")
                case 1:
                    item.title = "creations".localized
                    print("🔍 TabBar: Set tag 1 title to '\("creations".localized)'")
                case 2:
                    item.title = "settings".localized
                    print("🔍 TabBar: Set tag 2 title to '\("settings".localized)'")
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
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let tabScale: CGFloat = isPad ? 1.2 : 1.0
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: (isPad ? 22 : 17) * tabScale, weight: .regular)

        func sym(_ name: String) -> UIImage? {
            UIImage(systemName: name, withConfiguration: symbolConfig)
        }

        // 1. 首页
        let templateVC = TemplateSquareViewController()
        let templateNav = UINavigationController(rootViewController: templateVC)
        
        // 直接使用本地化字符串
        templateNav.tabBarItem = UITabBarItem(
            title: "home".localized,
            image: sym("square.grid.2x2"),
            selectedImage: sym("square.grid.2x2.fill")
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
            title: "creations".localized,
            image: sym("plus.circle"),
            selectedImage: sym("plus.circle.fill")
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
            title: "settings".localized,
            image: sym("gearshape"),
            selectedImage: sym("gearshape.fill")
        )
        settingsNav.tabBarItem.tag = 2
        
        // 禁用iOS 17.4+的胶囊高亮效果
        if #available(iOS 17.4, *) {
            settingsNav.tabBarItem.isSpringLoaded = false
        }
        
        print("🔍 TabBar: 设置 tabBarItem.title = '\(settingsNav.tabBarItem.title ?? "nil")'")
        
        if isPad {
            // Larger nav title fonts on iPad (do not affect iPhone).
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            navAppearance.shadowColor = .clear
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
            ]
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]

            [templateNav, creationsNav, settingsNav].forEach { nav in
                nav.navigationBar.standardAppearance = navAppearance
                nav.navigationBar.compactAppearance = navAppearance
                if #available(iOS 15.0, *) {
                    nav.navigationBar.scrollEdgeAppearance = navAppearance
                }
            }
        }

        // 使用5个标签布局：首页 - 占位1 - 创作 - 占位2 - 设置
        viewControllers = [templateNav, spacer1, creationsNav, spacer2, settingsNav]

        print("🔍 TabBar: viewControllers count = \(viewControllers?.count ?? 0)")
    }
    
    // MARK: - Language Change Support
    private func setupLanguageChangeNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: NSNotification.Name("LanguageDidChange"),
            object: nil
        )
    }
    
    @objc private func languageDidChange() {
        // 更新所有TabBar标题
        updateTabBarTitles()
        
        // 强制刷新TabBar布局
        DispatchQueue.main.async {
            self.tabBar.setNeedsLayout()
            self.tabBar.layoutIfNeeded()
        }
    }
    
    private func updateTabBarTitles() {
        guard let items = tabBar.items else { return }
        
        for item in items {
            switch item.tag {
            case 0:
                item.title = "home".localized
                print("🔍 TabBar Language Change: Updated tag 0 title to '\("home".localized)'")
            case 1:
                item.title = "creations".localized
                print("🔍 TabBar Language Change: Updated tag 1 title to '\("creations".localized)'")
            case 2:
                item.title = "settings".localized
                print("🔍 TabBar Language Change: Updated tag 2 title to '\("settings".localized)'")
            default:
                break
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
