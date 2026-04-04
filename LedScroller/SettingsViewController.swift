import UIKit
import StoreKit

// 设置项
@MainActor
enum SettingItem {
    case language
    case aboutUs
    case version
    case restorePurchase
    case feedback
    case rate
    case share
    
    var title: String {
        switch self {
        case .language: return "language".localized
        case .aboutUs: return "about".localized
        case .version: return "version".localized
        case .restorePurchase:
            if PurchaseManager.shared.isVIP() {
                let subscriptionType = PurchaseManager.shared.getSubscriptionTypeText()
                if !subscriptionType.isEmpty {
                    return "subscriptionMember".localized + " " + subscriptionType
                }
                return "subscriptionMember".localized
            }
            return "restorePurchase".localized
        case .feedback: return "feedback".localized
        case .rate: return "rate".localized
        case .share: return "share".localized
        }
    }

    var icon: String {
        switch self {
        case .language: return "globe"
        case .aboutUs: return "info.circle"
        case .version: return "app.badge"
        case .restorePurchase: return "arrow.clockwise.circle"
        case .feedback: return "envelope"
        case .rate: return "star"
        case .share: return "square.and.arrow.up"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .language: return UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)      // 蓝色 - 地球
        case .aboutUs: return UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)       // 浅蓝色 - 信息
        case .version: return UIColor(red: 0.56, green: 0.93, blue: 0.90, alpha: 1.0)    // 青色 - 版本（更好看的颜色）
        case .restorePurchase: return UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0) // 橙色 - 恢复
        case .feedback: return UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)      // 粉色 - 反馈
        case .rate: return UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)          // 金黄色 - 星星
        case .share: return UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)         // 绿色 - 分享
        }
    }
}

// 设置视图控制器
class SettingsViewController: UIViewController {

    private func topMostPresenter() -> UIViewController {
        // Prefer the window's root VC chain; fall back to self.
        let root = view.window?.rootViewController
        var top = root ?? self
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private let settings: [SettingItem] = [.language, .aboutUs, .version, .restorePurchase, .feedback, .rate, .share]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 确保VIP管理器状态正常
        PurchaseManager.shared.checkAndResetIfStuck()
        
        setupUI()
        
        // 监听VIP状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vipStatusDidChange),
            name: PurchaseManager.vipStatusDidChangeNotification,
            object: nil
        )
        
        // 监听VIP状态重置
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vipStateDidReset),
            name: NSNotification.Name("VIPStateReset"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var isRefreshingVIPStatus = false

    @objc private func vipStatusDidChange() {
        print("🔍 设置界面：收到VIP状态变化通知")

        // Debounce: subscription state can trigger multiple notifications quickly.
        // Rebuilding the whole stack repeatedly can freeze UI and exacerbate crashes.
        if isRefreshingVIPStatus { return }
        isRefreshingVIPStatus = true

        DispatchQueue.main.async {
            self.refreshSettingsDisplay()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshingVIPStatus = false
            }
        }
    }
    
    @objc private func vipStateDidReset() {
        print("🔍 设置界面：收到VIP状态重置通知")
        DispatchQueue.main.async {
            // 确保界面可以正常交互
            self.view.isUserInteractionEnabled = true
            self.refreshSettingsDisplay()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppDelegate.orientationLock = .portrait

        // 刷新设置项显示，特别是恢复购买项的标题
        refreshSettingsDisplay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Ensure we return to portrait after any landscape-only modules.
        AppDelegate.orientationLock = .portrait
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func refreshSettingsDisplay() {
        // 重新创建设置卡片以更新VIP状态显示
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for setting in settings {
            let card = createSettingCard(for: setting)
            stackView.addArrangedSubview(card)
        }
    }
    
    private func setupUI() {
        title = "settings".localized
        // 设置渐变背景
        setupGradientBackground()
        
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        // 设置导航栏样式 - 透明背景让渐变显示
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.063, green: 0.039, blue: 0.141, alpha: 1.0) // #100A24 顶部渐变色

        if isPad {
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
        } else {
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        }
        appearance.shadowColor = .clear // 移除阴影
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 直接使用 stackView 放置设置卡片，不使用 scrollView（避免滚动导致标题消失）
        // 设置页面只有7个按钮，一屏可以完全展示
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = isPad ? 22 : 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: isPad ? 25 : 10),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: isPad ? -35 : -20)
        ])
        
        // 添加设置卡片
        for setting in settings {
            let card = createSettingCard(for: setting)
            stackView.addArrangedSubview(card)
        }
    }

    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        // linear-gradient(180deg, #100A24 0%, #04030B 100%)
        gradientLayer.colors = [
            UIColor(red: 0x10/255.0, green: 0x0A/255.0, blue: 0x24/255.0, alpha: 1.0).cgColor, // #100A24
            UIColor(red: 0x04/255.0, green: 0x03/255.0, blue: 0x0B/255.0, alpha: 1.0).cgColor  // #04030B
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0) // 顶部
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)   // 底部
        gradientLayer.frame = view.bounds
        gradientLayer.name = "gradientBackground"

        // 移除旧的渐变层
        view.layer.sublayers?.removeAll { $0.name == "gradientBackground" }

        // 插入到最底层
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新渐变层frame
        if let gradientLayer = view.layer.sublayers?.first(where: { $0.name == "gradientBackground" }) as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    private func createSettingCard(for item: SettingItem) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.12) // 透明度改为0.12
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false

        // 图标 - 使用各自的配色
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = item.iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconImageView)
        
        // 为图标添加发光效果
        iconImageView.layer.shadowColor = item.iconColor.cgColor
        iconImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        iconImageView.layer.shadowOpacity = 0.8
        iconImageView.layer.shadowRadius = 8
        
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: isPad ? 20 : 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        
        // 箭头（所有按钮都有）
        let arrowImageView = UIImageView()
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .gray
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(arrowImageView)
        
        // 版本号（仅版本项显示，放在箭头左边）
        if case .version = item {
            let versionLabel = UILabel()
            // 动态获取版本号
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.7"
            versionLabel.text = appVersion
            // 彩色渐变文字效果
            versionLabel.textColor = UIColor(red: 0.56, green: 0.93, blue: 0.90, alpha: 1.0) // #8FFFE6 青色
            versionLabel.font = .systemFont(ofSize: isPad ? 18 : 14, weight: .medium)
            versionLabel.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(versionLabel)
            
            NSLayoutConstraint.activate([
                versionLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
                versionLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: isPad ? 76 : 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: isPad ? 30 : 24),
            iconImageView.heightAnchor.constraint(equalToConstant: isPad ? 30 : 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            arrowImageView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: isPad ? 14 : 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: isPad ? 22 : 20)
        ])
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(settingCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.tag = settings.firstIndex(of: item) ?? 0
        
        return card
    }
    
    @objc private func settingCardTapped(_ gesture: UITapGestureRecognizer) {
        print("🔍 ===== settingCardTapped 被触发 =====")
        guard let index = gesture.view?.tag, index < settings.count else {
            print("❌ 无效的index或超出范围")
            return
        }
        let item = settings[index]
        print("🔍 点击的设置项: \(item.title)")
        handleSettingTap(item, sourceView: gesture.view)
        print("🔍 ===== settingCardTapped 结束 =====")
    }

    private func handleSettingTap(_ item: SettingItem, sourceView: UIView?) {
        print("🔍 ===== handleSettingTap 开始 =====")
        print("🔍 处理设置项: \(item.title)")
        switch item {
        case .language:
            print("🔍 -> 语言设置")
            showLanguageSelector()
        case .aboutUs:
            print("🔍 -> 关于我们")
            let vc = AboutViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .version:
            print("🔍 -> 版本信息")
            showAlert(title: "version".localized, message: "versionMessage".localized)
        case .restorePurchase:
            print("🔍 -> 恢复购买/订阅管理")
            handleRestorePurchase()
        case .feedback:
            print("🔍 -> 反馈")
            let vc = FeedbackViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .rate:
            print("🔍 -> 评分")
            presentRateSheet(sourceView: sourceView)
        case .share:
            print("🔍 -> 分享")
            presentShareSheet(sourceView: sourceView)
        }
        print("🔍 ===== handleSettingTap 结束 =====")
    }

    private func presentShareSheet(sourceView: UIView?) {
        let appStoreURL = "https://apps.apple.com/app/id6761117233"

        let message: String
        if Locale.preferredLanguages.first?.hasPrefix("zh") == true {
            message = "我在用 LedScroller 做 LED 跑马灯字幕，效果很酷。App Store 搜索『LedScroller』或点这里： \(appStoreURL)"
        } else {
            message = "I’m using LedScroller to create LED marquee messages. Get it here: \(appStoreURL)"
        }

        let vc = UIActivityViewController(activityItems: [message, URL(string: appStoreURL) as Any], applicationActivities: nil)

        if let popover = vc.popoverPresentationController {
            popover.sourceView = sourceView ?? view
            if let sourceView {
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            }
        }

        present(vc, animated: true)
    }

    private func presentRateSheet(sourceView: UIView?) {
        // Custom sheet so we can control width, button layout, and colors.
        showCustomRateAlert()
    }

    private func showCustomRateAlert() {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        let alertView = UIView()
        alertView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        alertView.layer.cornerRadius = 16
        alertView.translatesAutoresizingMaskIntoConstraints = false

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissCustomRateAlert), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "rateSheetTitle".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = "rateSheetMessage".localized
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let feedbackButton = UIButton(type: .system)
        feedbackButton.setTitle("later".localized, for: .normal) // 改为"下次再说"
        feedbackButton.setTitleColor(.white, for: .normal)
        feedbackButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        feedbackButton.backgroundColor = UIColor(white: 0.3, alpha: 1.0) // 灰色背景
        feedbackButton.layer.cornerRadius = 22 // 胶囊形状
        feedbackButton.clipsToBounds = true
        feedbackButton.translatesAutoresizingMaskIntoConstraints = false
        feedbackButton.addAction(UIAction { [weak self] _ in
            self?.dismissCustomRateAlert()
            // 直接关闭，不跳转
        }, for: .touchUpInside)

        let rateButton = UIButton(type: .system)
        rateButton.setTitle("rateSheetRate".localized, for: .normal)
        rateButton.setTitleColor(.white, for: .normal)
        rateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        rateButton.backgroundColor = .systemPink
        rateButton.layer.cornerRadius = 22 // 胶囊形状
        rateButton.clipsToBounds = true
        rateButton.translatesAutoresizingMaskIntoConstraints = false
        rateButton.addAction(UIAction { [weak self] _ in
            self?.dismissCustomRateAlert()
            self?.requestReviewOrOpenAppStore()
        }, for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [feedbackButton, rateButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(overlayView)
        overlayView.addSubview(alertView)
        alertView.addSubview(closeButton)
        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(buttonStack)

        overlayView.tag = 9998

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let alertWidth: CGFloat = isPad ? 460 : 360 // iPad: 460, iPhone: 原始360

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            alertView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: alertWidth),

            closeButton.topAnchor.constraint(equalTo: alertView.topAnchor, constant: isPad ? 16 : 12),
            closeButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: isPad ? -16 : -12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: isPad ? 28 : 22),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: isPad ? 18 : 12),
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: isPad ? 28 : 20),
            buttonStack.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            buttonStack.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: isPad ? -40 : -30)
        ])
    }

    @objc private func dismissCustomRateAlert() {
        view.viewWithTag(9998)?.removeFromSuperview()
    }

    private func requestReviewOrOpenAppStore() {
        // Best effort: system rating prompt (Apple controls if/when it appears).
        if #available(iOS 14.0, *), let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        } else if #available(iOS 10.3, *) {
            requestReviewLegacy()
        }

        // Fallback: open the App Store write-review page.
        let appStoreAppId = "6761117233"
        if let url = URL(string: "https://apps.apple.com/app/id\(appStoreAppId)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    @available(iOS 10.3, *)
    private func requestReviewLegacy() {
        // Avoid direct reference to deprecated +requestReview() to keep builds warning-free.
        let selector = NSSelectorFromString("requestReview")
        if SKStoreReviewController.responds(to: selector) {
            _ = SKStoreReviewController.perform(selector)
        }
    }
    
    private func handleRestorePurchase() {
        print("🔍 ===== handleRestorePurchase 开始 =====")
        if PurchaseManager.shared.isVIP() {
            print("🔍 用户已是VIP，显示管理订阅弹窗")
            showCustomVIPAlert(
                title: "vipMember".localized,
                message: PurchaseManager.shared.getVIPStatusText(),
                primaryButtonTitle: PurchaseManager.shared.getVIPButtonText(),
                primaryAction: {
                    print("🔍 管理订阅按钮被点击")
                    if #available(iOS 15.0, *) {
                        StoreKitManager.shared.openManageSubscriptions()
                    } else {
                        VIPManager.shared.openManageSubscriptions()
                    }
                }
            )
        } else {
            print("🔍 用户非VIP，显示开通VIP弹窗")
            // 非VIP用户，显示开通VIP - 交换按钮位置，恢复购买在上面，开通VIP在下面
            showCustomVIPAlert(
                title: "vipMember".localized,
                message: "vipAlertMessage".localized,
                primaryButtonTitle: "restorePurchases".localized, // 交换：恢复购买作为主按钮
                primaryAction: {
                    print("🔍 ===== primaryAction（恢复购买）被调用 =====")
                    print("🔍 设置界面：恢复购买按钮被点击")
                    // 不直接调用恢复购买，而是打开VIP订阅界面
                    self.showVIPSubscription()
                    print("🔍 ===== primaryAction（恢复购买）结束 =====")
                },
                secondaryButtonTitle: PurchaseManager.shared.getVIPButtonText(), // 交换：开通VIP作为次要按钮
                secondaryAction: {
                    print("🔍 ===== secondaryAction（开通VIP）被调用 =====")
                    print("🔍 设置界面：立即开通VIP按钮被点击")
                    self.showVIPSubscription()
                    print("🔍 ===== secondaryAction（开通VIP）结束 =====")
                }
            )
        }
        print("🔍 ===== handleRestorePurchase 结束 =====")
    }
    
    private func showVIPSubscription() {
        print("🔍 ===== showVIPSubscription 开始 =====")
        print("🔍 设置界面：准备显示VIP订阅界面")
        print("🔍 当前线程: \(Thread.current)")
        print("🔍 view.window: \(String(describing: view.window))")
        print("🔍 presentedViewController: \(String(describing: presentedViewController))")
        
        // 确保VIP管理器状态正常
        PurchaseManager.shared.checkAndResetIfStuck()
        
        // 检查是否还有遮罩视图
        if let remainingOverlay = view.viewWithTag(9999) {
            print("⚠️ 发现残留的overlayView，强制移除")
            remainingOverlay.removeFromSuperview()
        }
        
        // 确保视图可以交互
        view.isUserInteractionEnabled = true
        print("🔍 view.isUserInteractionEnabled: \(view.isUserInteractionEnabled)")
        
        DispatchQueue.main.async {
            // Defensive: remove any lingering overlay that could block touches.
            let removedBefore = self.removeBlockingOverlays()
            print("🔍 Settings: removedBeforePush=\(removedBefore)")

            let vipVC = VIPSubscriptionViewController()
            vipVC.hidesBottomBarWhenPushed = true

            // Prefer push (Settings is already inside a UINavigationController via MainTabBarController).
            if let nav = self.navigationController {
                print("🔍 设置界面：push VIP订阅界面")
                nav.pushViewController(vipVC, animated: true)

                // After navigation transition starts, clear any lingering blockers again.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let removedAfter = self.removeBlockingOverlays()
                    let top = nav.topViewController
                    print("🔍 Settings: removedAfterPush=\(removedAfter) topVC=\(String(describing: top))")

                    if let window = nav.view.window {
                        print("🔍 Settings: window subviews (count=\(window.subviews.count))")
                        for v in window.subviews {
                            let name = NSStringFromClass(type(of: v))
                            print(" - \(name) frame=\(v.frame) alpha=\(v.alpha) tag=\(v.tag) interactive=\(v.isUserInteractionEnabled)")
                        }
                    } else {
                        print("⚠️ Settings: nav.view.window is nil")
                    }
                }
                return
            }

            // Fallback: present full screen.
            let nav = UINavigationController(rootViewController: vipVC)
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .coverVertical

            let presenter = self.topMostPresenter()
            print("🔍 设置界面：present VIP订阅界面")
            print("🔍 presenter: \(String(describing: presenter))")
            print("🔍 presenter.presentedViewController: \(String(describing: presenter.presentedViewController))")

            if presenter.presentedViewController != nil {
                print("⚠️ presenter 已有正在展示的控制器，先不重复 present")
                return
            }

            presenter.present(nav, animated: true) {
                print("🔍 设置界面：VIP订阅界面已显示")
            }
        }
        
        print("🔍 ===== showVIPSubscription 结束 =====")
    }
    
    private func showCustomVIPAlert(
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryButtonTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        // 创建自定义弹窗视图
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let alertView = UIView()
        alertView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        alertView.layer.cornerRadius = 16
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        // 关闭按钮（右上角X）- 改为和订阅界面一样的样式
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = .clear
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissCustomAlert), for: .touchUpInside)
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold) // 增加2pt，从18改为20
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 消息（二级标题，最多2行）
        let messageLabel = UILabel()
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2 // 二级标题最多2行显示
        
        // 设置1.5倍行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 16 * 0.5 // 字体大小 * 0.5 = 1.5倍行高
        paragraphStyle.alignment = .center
        
        let attributedText = NSAttributedString(
            string: message,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: paragraphStyle
            ]
        )
        messageLabel.attributedText = attributedText
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 主按钮（现在是恢复购买）
        let primaryButton = UIButton(type: .system)
        primaryButton.setTitle(primaryButtonTitle, for: .normal)
        primaryButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .normal) // 改为半透明白色文字
        primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        primaryButton.backgroundColor = UIColor.white.withAlphaComponent(0.1) // 改为半透明背景，不使用渐变
        primaryButton.layer.cornerRadius = 22 // 改为胶囊形状，高度44的一半
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.addAction(UIAction { _ in
            print("🔍 ===== 主按钮点击事件触发 =====")
            print("🔍 主按钮被点击: \(primaryButtonTitle)")
            print("🔍 当前线程: \(Thread.current)")
            print("🔍 开始调用 dismissCustomAlertWithCompletion")
            self.dismissCustomAlertWithCompletion {
                print("🔍 主按钮：弹窗已关闭，执行primaryAction")
                print("🔍 准备执行 primaryAction")
                primaryAction()
                print("🔍 primaryAction 已执行")
            }
            print("🔍 ===== 主按钮点击事件结束 =====")
        }, for: .touchUpInside)
        
        // 添加视图到层次结构
        view.addSubview(overlayView)
        overlayView.addSubview(alertView)
        alertView.addSubview(closeButton)
        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(primaryButton)
        
        // 存储overlayView引用以便关闭
        overlayView.tag = 9999
        
        var constraints = [
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            alertView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: isPad ? 360 : 320), // iPad: 360, iPhone: 原始320
            closeButton.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 16), // 往下移动4pt，从12改为16
            closeButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16), // 往左移动4pt，从-12改为-16
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20), // 往下移动4pt，从16改为20
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            primaryButton.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 32), // 宽度再减少12pt，左右各减少6pt (26->32)
            primaryButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -32), // 宽度再减少12pt，左右各减少6pt (-26->-32)
            primaryButton.heightAnchor.constraint(equalToConstant: 44) // 按钮高度减少4pt (48->44)
        ]
        
        // 如果有次要按钮，添加它
        if let secondaryButtonTitle = secondaryButtonTitle, let secondaryAction = secondaryAction {
            print("🔍 创建次要按钮: \(secondaryButtonTitle)")
            let secondaryButton = UIButton(type: .system)
            secondaryButton.setTitle(secondaryButtonTitle, for: .normal)
            secondaryButton.setTitleColor(.white, for: .normal) // 改为白色文字
            secondaryButton.titleLabel?.font = .systemFont(ofSize: 16)
            secondaryButton.backgroundColor = .clear // 改为透明背景，使用渐变
            secondaryButton.layer.cornerRadius = 22 // 改为胶囊形状，高度44的一半
            secondaryButton.isUserInteractionEnabled = true // 确保可交互
            secondaryButton.translatesAutoresizingMaskIntoConstraints = false
            secondaryButton.addAction(UIAction { _ in
                print("🔍 ===== 次要按钮点击事件触发 =====")
                print("🔍 次要按钮被点击: \(secondaryButtonTitle)")
                print("🔍 当前线程: \(Thread.current)")
                print("🔍 开始调用 dismissCustomAlertWithCompletion")
                self.dismissCustomAlertWithCompletion {
                    print("🔍 次要按钮：弹窗已关闭，执行secondaryAction")
                    print("🔍 准备执行 secondaryAction")
                    secondaryAction()
                    print("🔍 secondaryAction 已执行")
                }
                print("🔍 ===== 次要按钮点击事件结束 =====")
            }, for: .touchUpInside)
            
            alertView.addSubview(secondaryButton)
            
            constraints.append(contentsOf: [
                secondaryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32), // 增加间距从24到32
                secondaryButton.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 32), // 宽度再减少12pt，左右各减少6pt (26->32)
                secondaryButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -32), // 宽度再减少12pt，左右各减少6pt (-26->-32)
                secondaryButton.heightAnchor.constraint(equalToConstant: 44), // 按钮高度减少4pt (48->44)
                
                primaryButton.topAnchor.constraint(equalTo: secondaryButton.bottomAnchor, constant: 16), // 增加间距从12到16
                primaryButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -44) // 背景高度再增加10pt (从-34到-44)
            ])
            
            // 在布局完成后应用渐变背景
            DispatchQueue.main.async {
                print("🔍 为次要按钮应用渐变背景，bounds: \(secondaryButton.bounds)")
                self.applyGradientToVIPButton(secondaryButton)
            }
        } else {
            constraints.append(contentsOf: [
                primaryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32), // 增加间距从24到32
                primaryButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -44) // 背景高度再增加10pt (从-34到-44)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        // 直接显示，不使用动画
        overlayView.alpha = 1
        alertView.transform = .identity
    }
    
    @objc private func dismissCustomAlert() {
        guard let overlayView = view.viewWithTag(9999) else { return }
        
        // 直接移除，不使用动画
        overlayView.removeFromSuperview()
    }
    
    private func dismissCustomAlertWithCompletion(_ completion: @escaping () -> Void) {
        print("🔍 ===== dismissCustomAlertWithCompletion 开始 =====")
        print("🔍 dismissCustomAlertWithCompletion 被调用")
        print("🔍 调用栈: \(Thread.callStackSymbols.prefix(5))")

        // Remove any lingering overlays that could block touches (some simulator/iOS
        // versions keep views alive across presentations).
        let removed = removeBlockingOverlays()
        if removed == 0 {
            print("🔍 没有找到overlayView，直接执行completion")
        } else {
            print("🔍 已移除 \(removed) 个overlayView")
        }

        print("🔍 执行completion回调")
        completion()
        print("🔍 completion回调已执行")
        print("🔍 ===== dismissCustomAlertWithCompletion 结束 =====")
    }

    @discardableResult
    private func removeBlockingOverlays() -> Int {
        var removed = 0

        func removeTaggedOverlay(in container: UIView?, tag: Int) {
            guard let container else { return }
            if let overlay = container.viewWithTag(tag) {
                overlay.isUserInteractionEnabled = false
                overlay.removeFromSuperview()
                removed += 1
            }
        }

        func removeFullscreenInvisibleBlockers(in window: UIWindow) {
            let winBounds = window.bounds
            for subview in window.subviews {
                guard subview.isUserInteractionEnabled, !subview.isHidden, subview.alpha > 0.0 else { continue }

                let isFullscreen = subview.frame.equalTo(winBounds)
                let className = NSStringFromClass(type(of: subview))
                let looksLikeOverlay = className.localizedCaseInsensitiveContains("overlay")

                // Heuristic: full-screen views that are transparent-ish and block touches.
                // Use a slightly higher threshold; some overlays use alpha 0.1.
                let isTransparentish = subview.alpha < 0.2

                if isFullscreen && (looksLikeOverlay || isTransparentish) {
                    print("⚠️ Removing blocker view: \(className) frame=\(subview.frame) alpha=\(subview.alpha) tag=\(subview.tag)")
                    subview.isUserInteractionEnabled = false
                    subview.removeFromSuperview()
                    removed += 1
                }
            }
        }

        // Current VC view.
        removeTaggedOverlay(in: view, tag: 9999)
        removeTaggedOverlay(in: view, tag: 999)

        // Window/root chain.
        removeTaggedOverlay(in: view.window, tag: 9999)
        removeTaggedOverlay(in: view.window, tag: 999)
        removeTaggedOverlay(in: view.window?.rootViewController?.view, tag: 9999)
        removeTaggedOverlay(in: view.window?.rootViewController?.view, tag: 999)

        // As a last resort, scan all scene windows.
        for window in UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }) {
            removeTaggedOverlay(in: window, tag: 9999)
            removeTaggedOverlay(in: window, tag: 999)
            removeFullscreenInvisibleBlockers(in: window)
        }

        return removed
    }
    
    // 为VIP按钮应用渐变背景（和订阅界面一样的渐变）
    private func applyGradientToVIPButton(_ button: UIButton) {
        // 如果bounds还没有设置，延迟执行
        if button.bounds.width == 0 || button.bounds.height == 0 {
            print("🔍 按钮bounds为零，延迟应用渐变")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.applyGradientToVIPButton(button)
            }
            return
        }
        
        print("🔍 应用渐变背景到按钮，bounds: \(button.bounds)")
        
        // 移除之前的渐变层
        button.layer.sublayers?.removeAll { $0 is CAGradientLayer }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0).cgColor,  // 橙色
            UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0).cgColor   // 粉色
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = button.bounds
        gradientLayer.cornerRadius = 22 // 改为胶囊形状圆角，匹配按钮
        
        // 确保渐变层在最底层，不会阻止触摸事件
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        print("🔍 渐变背景已应用，gradientLayer.frame: \(gradientLayer.frame)")
    }
    
    private func showLanguageSelector() {
        // 使用自定义暗色弹窗
        let languageSelectorView = LanguageSelectorView()
        languageSelectorView.onLanguageSelected = { [weak self] language in
            self?.confirmLanguageChange(to: language)
        }
        languageSelectorView.show(in: self)
    }
    
    private func confirmLanguageChange(to language: LanguageManager.Language) {
        // 如果选择的是当前语言，不需要确认
        if language == LanguageManager.shared.currentLanguage {
            return
        }
        
        // 显示自定义确认弹窗
        let languageName = language.displayName
        let confirmView = LanguageConfirmView(languageName: languageName)
        confirmView.onConfirm = { [weak self] in
            self?.changeLanguage(to: language)
        }
        confirmView.show(in: self)
    }
    
    private func changeLanguage(to language: LanguageManager.Language) {
        // 保存语言设置
        LanguageManager.shared.currentLanguage = language
        
        // 立即刷新整个应用界面
        reloadApplication()
    }
    
    private func reloadApplication() {
        // 获取window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // 创建新的TabBarController
        let newTabBarController = MainTabBarController()
        
        // 设置选中设置页面（保持在当前页面）
        newTabBarController.selectedIndex = 4 // 设置页面在第5个位置（index 4）
        
        // 使用动画切换根视图控制器
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = newTabBarController
        }, completion: nil)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "done".localized, style: .default))
        present(alert, animated: true)
    }
}


// MARK: - 语言选择弹窗视图
class LanguageSelectorView: UIView {
    
    var onLanguageSelected: ((LanguageManager.Language) -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private weak var presentingVC: UIViewController?
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        // 半透明背景
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 容器视图
        containerView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 标题
        titleLabel.text = "language".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 滚动视图
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        // 语言列表堆栈
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // 添加语言选项
        let currentLanguage = LanguageManager.shared.currentLanguage
        for language in LanguageManager.Language.allCases {
            let button = createLanguageButton(language: language, isSelected: language == currentLanguage)
            stackView.addArrangedSubview(button)
        }
        
        // 取消按钮（胶囊形状）
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: isPad ? 394 : 314), // iPad: 394, iPhone: 原始314
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: isPad ? 680 : 620), // iPad: 680, iPhone: 原始620
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: isPad ? 28 : 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: isPad ? 24 : 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: isPad ? -24 : -20),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: isPad ? 20 : 16),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: isPad ? 24 : 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: isPad ? -24 : -20),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: isPad ? -20 : -16),
            scrollView.heightAnchor.constraint(lessThanOrEqualToConstant: isPad ? 500 : 440), // iPad: 500, iPhone: 原始440
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: isPad ? 24 : 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: isPad ? -24 : -20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: isPad ? -40 : -34), // iPad: -40, iPhone: 原始-34
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 添加点击背景关闭手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    private func createLanguageButton(language: LanguageManager.Language, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: isSelected ? .semibold : .regular)
        button.contentHorizontalAlignment = .left
        
        // 使用iOS 15+的新方式设置内边距和间隔
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            config.title = language.displayName
            config.baseForegroundColor = .white
            
            // 创建国旗emoji图片
            let flagImage = createEmojiImage(from: language.flagEmoji, size: CGSize(width: 20, height: 20))
            config.image = flagImage
            config.imagePlacement = .leading
            config.imagePadding = 8 // 图标和文字间隔增加4pt (原来是4pt，现在是8pt)
            
            button.configuration = config
        } else {
            // iOS 15以下的兼容处理，使用字符串方式但增加间隔
            let flagAndName = "\(language.flagEmoji)    \(language.displayName)" // 增加更多空格
            button.setTitle(flagAndName, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
        
        button.backgroundColor = isSelected ? UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.2) : .clear
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // 添加选中标记
        if isSelected {
            let checkmark = UILabel()
            checkmark.text = "✓"
            checkmark.textColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
            checkmark.font = .systemFont(ofSize: 18, weight: .bold)
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(checkmark)
            
            NSLayoutConstraint.activate([
                checkmark.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
                checkmark.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
        }
        
        button.tag = LanguageManager.Language.allCases.firstIndex(of: language) ?? 0
        button.addTarget(self, action: #selector(languageButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    // 创建emoji图片的辅助方法
    private func createEmojiImage(from emoji: String, size: CGSize) -> UIImage? {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let attributedString = NSAttributedString(string: emoji, attributes: attributes)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            attributedString.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func show(in viewController: UIViewController) {
        presentingVC = viewController
        
        guard let window = viewController.view.window else { return }
        
        frame = window.bounds
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor),
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // 动画显示
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func languageButtonTapped(_ sender: UIButton) {
        let languages = LanguageManager.Language.allCases
        guard sender.tag < languages.count else { return }
        let selectedLanguage = languages[sender.tag]
        
        dismiss()
        onLanguageSelected?(selectedLanguage)
    }
    
    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }
    
    @objc private func backgroundTapped() {
        dismiss()
        onCancel?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension LanguageSelectorView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 只有点击背景时才触发，点击容器内部不触发
        return touch.view == self
    }
}

// MARK: - 语言确认弹窗视图
class LanguageConfirmView: UIView {
    
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private weak var presentingVC: UIViewController?
    
    init(languageName: String) {
        super.init(frame: .zero)
        setupUI(languageName: languageName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(languageName: String) {
        // 半透明背景
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 容器视图
        containerView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 标题
        titleLabel.text = "selectLanguage".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 确认按钮（胶囊形状）
        let useLanguageText = String(format: "useLanguage".localized, languageName)
        confirmButton.setTitle(useLanguageText, for: .normal)
        confirmButton.setTitleColor(.black, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        confirmButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(confirmButton)
        
        // 取消按钮（胶囊形状）
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            confirmButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34)
        ])
        
        // 添加点击背景关闭手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    func show(in viewController: UIViewController) {
        presentingVC = viewController
        
        guard let window = viewController.view.window else { return }
        
        frame = window.bounds
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor),
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // 动画显示
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func confirmTapped() {
        dismiss()
        onConfirm?()
    }
    
    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }
    
    @objc private func backgroundTapped() {
        dismiss()
        onCancel?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension LanguageConfirmView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 只有点击背景时才触发，点击容器内部不触发
        return touch.view == self
    }
}
