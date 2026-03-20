import UIKit
import StoreKit

// MARK: - VIP订阅管理器
@objc class VIPManager: NSObject {
    @objc static let shared = VIPManager()
    
    enum ProductID: String, CaseIterable {
        case weekly = "com.ledscreen.vip.weekly"
        case monthly = "com.ledscreen.vip.monthly"
        case yearly = "com.ledscreen.vip.yearly"
        // 移除终身买断选项
    }
    
    enum VIPStatus {
        case free
        case trial(daysRemaining: Int)
        case subscribed(daysRemaining: Int)
        case lifetime
    }
    
    // 通知名称
    static let vipStatusDidChangeNotification = Notification.Name("VIPStatusDidChange")
    static let purchaseDidCompleteNotification = Notification.Name("PurchaseDidComplete")
    static let purchaseDidFailNotification = Notification.Name("PurchaseDidFail")
    
    var vipStatus: VIPStatus = .free {
        didSet {
            // 状态改变时发送通知
            NotificationCenter.default.post(name: VIPManager.vipStatusDidChangeNotification, object: self)
        }
    }
    var products: [SKProduct] = []
    var isLoading = false
    
    private var productsRequest: SKProductsRequest?
    private var restoreTimer: Timer? // 添加恢复购买超时定时器
    private var purchaseTimer: Timer? // 添加购买超时定时器
    private let userDefaults = UserDefaults.standard
    
    private let vipStatusKey = "vip_status"
    private let subscriptionEndDateKey = "subscription_end_date"
    private let trialStartDateKey = "trial_start_date"
    private let isLifetimeKey = "is_lifetime"
    private let subscriptionTypeKey = "subscription_type" // 新增：存储订阅类型
    
    private var isObserverAdded = false
    
    override init() {
        super.init()
        
        // 确保只添加一次观察者
        if !isObserverAdded {
            SKPaymentQueue.default().add(self)
            isObserverAdded = true
            print("🔍 StoreKit观察者已添加")
        }
        
        loadVIPStatus()
        requestProducts()
    }
    
    deinit {
        print("🔍 VIPManager deinit - 清理资源")
        restoreTimer?.invalidate()
        restoreTimer = nil
        purchaseTimer?.invalidate()
        purchaseTimer = nil
        
        // 确保移除StoreKit观察者
        if isObserverAdded {
            SKPaymentQueue.default().remove(self)
            isObserverAdded = false
            print("🔍 StoreKit观察者已移除")
        }
        
        // 清理通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    // 强制重置购买状态（用于调试）
    @objc func forceResetPurchaseState() {
        print("🔍 强制重置购买状态")
        DispatchQueue.main.async {
            self.isLoading = false
            self.restoreTimer?.invalidate()
            self.restoreTimer = nil
            self.purchaseTimer?.invalidate()
            self.purchaseTimer = nil
            
            // 发送重置完成通知，让UI知道状态已重置
            NotificationCenter.default.post(
                name: NSNotification.Name("VIPStateReset"),
                object: self
            )
        }
    }
    
    // 添加一个公共方法来检查和重置卡死状态
    @objc func checkAndResetIfStuck() {
        if isLoading {
            print("🔍 检测到可能的卡死状态，强制重置")
            forceResetPurchaseState()
        }
    }
    
    @objc func isVIP() -> Bool {
        switch vipStatus {
        case .free:
            return false
        case .trial, .subscribed, .lifetime:
            return true
        }
    }
    
    @objc func getVIPStatusText() -> String {
        switch vipStatus {
        case .free:
            return "vipStatusFree".localized
        case .trial(let days):
            return String(format: "vipStatusTrial".localized, days)
        case .subscribed(let days):
            return String(format: "vipStatusSubscribed".localized, days)
        case .lifetime:
            return "vipStatusLifetime".localized
        }
    }
    
    @objc func getVIPButtonText() -> String {
        switch vipStatus {
        case .free:
            return "vipButtonFree".localized
        case .trial, .subscribed, .lifetime:
            return "vipButtonManage".localized
        }
    }
    
    // 获取订阅类型显示文字
    @objc func getSubscriptionTypeText() -> String {
        guard let subscriptionTypeString = userDefaults.string(forKey: subscriptionTypeKey),
              let subscriptionType = ProductID(rawValue: subscriptionTypeString) else {
            return ""
        }
        
        switch subscriptionType {
        case .weekly:
            return "weeklyMember".localized
        case .monthly:
            return "monthlyMember".localized
        case .yearly:
            return "yearlyMember".localized
        }
    }
    
    private func loadVIPStatus() {
        // 检查终身会员
        if userDefaults.bool(forKey: isLifetimeKey) {
            vipStatus = .lifetime
            return
        }
        
        // 检查订阅状态
        if let endDate = userDefaults.object(forKey: subscriptionEndDateKey) as? Date {
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            if daysRemaining > 0 {
                vipStatus = .subscribed(daysRemaining: daysRemaining)
                return
            } else {
                // 订阅已过期，清除数据
                userDefaults.removeObject(forKey: subscriptionEndDateKey)
            }
        }
        
        // 检查试用期状态
        if let trialStartDate = userDefaults.object(forKey: trialStartDateKey) as? Date {
            let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0
            let daysRemaining = 3 - daysSinceStart
            if daysRemaining > 0 {
                vipStatus = .trial(daysRemaining: daysRemaining)
                return
            } else {
                // 试用期已过期，清除数据
                userDefaults.removeObject(forKey: trialStartDateKey)
            }
        }
        
        vipStatus = .free
    }
    
    private func requestProducts() {
        guard !ProductID.allCases.isEmpty else { return }
        
        let productIDs = Set(ProductID.allCases.map { $0.rawValue })
        productsRequest = SKProductsRequest(productIdentifiers: productIDs)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    @objc func startFreeTrial() {
        guard case .free = vipStatus else { 
            print("用户已经是VIP或正在试用中")
            return 
        }
        
        let trialStartDate = Date()
        userDefaults.set(trialStartDate, forKey: trialStartDateKey)
        userDefaults.synchronize()
        
        vipStatus = .trial(daysRemaining: 3)
        
        print("免费试用已开始")
    }
    
    @objc func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            NotificationCenter.default.post(
                name: VIPManager.purchaseDidFailNotification, 
                object: self, 
                userInfo: ["error": "设备不支持应用内购买"]
            )
            return
        }
        
        // 如果已经在处理中，不要重复处理
        if isLoading {
            print("⚠️ 已经在处理购买操作中，忽略重复请求")
            return
        }
        
        isLoading = true
        
        // 设置60秒购买超时
        purchaseTimer?.invalidate()
        purchaseTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            print("⚠️ 购买超时")
            DispatchQueue.main.async {
                self?.handlePurchaseTimeout()
            }
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
        print("开始购买产品: \(product.productIdentifier)")
    }
    
    private func handlePurchaseTimeout() {
        print("🔍 处理购买超时")
        isLoading = false
        purchaseTimer?.invalidate()
        purchaseTimer = nil
        
        NotificationCenter.default.post(
            name: VIPManager.purchaseDidFailNotification,
            object: self,
            userInfo: ["error": "购买超时，请检查网络连接后重试"]
        )
    }
    
    @objc func restorePurchases() {
        print("🔍 VIPManager.restorePurchases() 被调用")
        print("🔍 调用来源: \(Thread.callStackSymbols.prefix(3))")
        
        guard SKPaymentQueue.canMakePayments() else {
            print("⚠️ 设备不支持应用内购买")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: VIPManager.purchaseDidFailNotification, 
                    object: self, 
                    userInfo: ["error": "设备不支持应用内购买"]
                )
            }
            return
        }
        
        // 如果已经在处理中，不要重复处理
        if isLoading {
            print("⚠️ 已经在处理购买操作中，忽略重复请求")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: VIPManager.purchaseDidFailNotification,
                    object: self,
                    userInfo: ["error": "请等待当前操作完成"]
                )
            }
            return
        }
        
        print("🔍 设置 isLoading = true")
        isLoading = true
        
        // 设置30秒超时
        restoreTimer?.invalidate()
        restoreTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            print("⚠️ 恢复购买超时")
            DispatchQueue.main.async {
                self?.handleRestoreTimeout()
            }
        }
        
        print("🔍 调用 SKPaymentQueue.default().restoreCompletedTransactions()")
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        print("🔍 开始恢复购买")
    }
    
    private func handleRestoreTimeout() {
        print("🔍 处理恢复购买超时")
        isLoading = false
        restoreTimer?.invalidate()
        restoreTimer = nil
        
        NotificationCenter.default.post(
            name: VIPManager.purchaseDidFailNotification,
            object: self,
            userInfo: ["error": "恢复购买超时，请检查网络连接后重试"]
        )
    }
    
    @objc func openManageSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // 处理成功购买
    private func handleSuccessfulPurchase(productID: String) {
        // 清理定时器
        purchaseTimer?.invalidate()
        purchaseTimer = nil
        
        guard let product = ProductID(rawValue: productID) else { 
            print("未知的产品ID: \(productID)")
            return 
        }
        
        let currentDate = Date()
        
        switch product {
        case .weekly:
            let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            userDefaults.set(endDate, forKey: subscriptionEndDateKey)
            userDefaults.set(product.rawValue, forKey: subscriptionTypeKey) // 存储订阅类型
        case .monthly:
            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            userDefaults.set(endDate, forKey: subscriptionEndDateKey)
            userDefaults.set(product.rawValue, forKey: subscriptionTypeKey) // 存储订阅类型
        case .yearly:
            let endDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
            userDefaults.set(endDate, forKey: subscriptionEndDateKey)
            userDefaults.set(product.rawValue, forKey: subscriptionTypeKey) // 存储订阅类型
        }
        
        // 清除试用期数据
        userDefaults.removeObject(forKey: trialStartDateKey)
        userDefaults.synchronize()
        
        loadVIPStatus()
        isLoading = false
        
        // 发送购买成功通知
        NotificationCenter.default.post(
            name: VIPManager.purchaseDidCompleteNotification, 
            object: self, 
            userInfo: ["productID": productID]
        )
        
        print("购买成功: \(productID)")
    }
    
    // 处理购买失败
    private func handleFailedPurchase(error: Error?) {
        // 清理定时器
        purchaseTimer?.invalidate()
        purchaseTimer = nil
        restoreTimer?.invalidate()
        restoreTimer = nil
        
        isLoading = false
        
        let errorMessage = error?.localizedDescription ?? "购买失败"
        
        // 发送购买失败通知
        NotificationCenter.default.post(
            name: VIPManager.purchaseDidFailNotification, 
            object: self, 
            userInfo: ["error": errorMessage]
        )
        
        print("购买失败: \(errorMessage)")
    }
}

// MARK: - VIP标签视图
@objc class VIPBadgeView: UIView {
    
    private let containerView = UIView()
    private let vipLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 传统VIP标签样式 - 金色渐变背景
        containerView.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // 金色
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0).cgColor // 深金色边框
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // VIP文字 - 居中显示
        vipLabel.text = "VIP"
        vipLabel.textColor = .black
        vipLabel.font = .systemFont(ofSize: 12, weight: .bold)
        vipLabel.textAlignment = .center
        vipLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vipLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            vipLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            vipLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 调整为稍大一点的尺寸，更醒目的VIP标签
            widthAnchor.constraint(equalToConstant: 32),
            heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    // 移除动画效果 - 保留方法以兼容现有代码，但不执行任何动画
    @objc func startShimmering() {
        // 不再执行动画
    }
    
    @objc func stopShimmering() {
        // 不再执行动画
    }
}

// MARK: - VIP预览遮罩视图
@objc class VIPPreviewOverlayView: UIView {
    
    var onExitTapped: (() -> Void)?
    var onBecomeMemberTapped: (() -> Void)?
    
    private let containerView = UIView()
    private let exitButton = UIButton(type: .system)
    private let becomeMemberButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        exitButton.setTitle("退出", for: .normal)
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        exitButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        exitButton.layer.cornerRadius = 25
        exitButton.layer.borderWidth = 1
        exitButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(exitButton)
        
        becomeMemberButton.setTitle("成为会员", for: .normal)
        becomeMemberButton.setTitleColor(.black, for: .normal)
        becomeMemberButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        becomeMemberButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        becomeMemberButton.layer.cornerRadius = 25
        becomeMemberButton.addTarget(self, action: #selector(becomeMemberTapped), for: .touchUpInside)
        becomeMemberButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(becomeMemberButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 240),
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            exitButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            exitButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            exitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            exitButton.heightAnchor.constraint(equalToConstant: 50),
            
            becomeMemberButton.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 20),
            becomeMemberButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            becomeMemberButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            becomeMemberButton.heightAnchor.constraint(equalToConstant: 50),
            becomeMemberButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    @objc private func exitTapped() {
        onExitTapped?()
    }
    
    @objc private func becomeMemberTapped() {
        onBecomeMemberTapped?()
    }
    
    @objc func show(in parentView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parentView.topAnchor),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    @objc func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

// MARK: - VIP订阅页面专用ScrollView
class VIPScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        // 如果触摸的是按钮，允许取消滚动以便按钮能响应
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 首先检查是否有按钮在这个位置
        func findButton(in view: UIView, point: CGPoint) -> UIButton? {
            // 将点转换到view的坐标系
            let convertedPoint = self.convert(point, to: view)
            
            // 检查这个view是否是按钮且包含这个点
            if let button = view as? UIButton,
               button.isUserInteractionEnabled,
               button.isEnabled,
               !button.isHidden,
               button.alpha > 0.01,
               button.bounds.contains(convertedPoint) {
                return button
            }
            
            // 递归检查子视图（从上到下）
            for subview in view.subviews.reversed() {
                if let button = findButton(in: subview, point: point) {
                    return button
                }
            }
            
            return nil
        }
        
        // 在所有子视图中查找按钮
        if let button = findButton(in: self, point: point) {
            print("🔍 hitTest找到按钮: \(button.titleLabel?.text ?? "unknown")")
            return button
        }
        
        // 如果没有找到按钮，使用默认的hitTest
        return super.hitTest(point, with: event)
    }
}

// MARK: - VIP订阅页面
@objc class VIPSubscriptionViewController: UIViewController {
    
    private let scrollView = VIPScrollView() // 使用自定义ScrollView
    private let contentView = UIView()
    private let vipManager = VIPManager.shared
    
    // UI组件
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let featuresView = UIView()
    private let subscriptionOptionsView = UIView()
    private let bottomButtonsView = UIView()
    
    private var subscriptionButtons: [UIButton] = []
    private var selectedSubscriptionIndex = 0 // 默认选择周订阅
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加调试日志
        print("🔍 VIPSubscriptionViewController viewDidLoad")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        print("🔍 VIP标题本地化: \("vipTitle".localized)")
        print("🔍 服务条款本地化: \("termsOfService".localized)")
        print("🔍 隐私政策本地化: \("privacyPolicy".localized)")
        print("🔍 恢复购买本地化: \("restorePurchases".localized)")
        
        setupUI()
        setupNotifications()
        
        // 监听语言变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: NSNotification.Name("LanguageDidChange"),
            object: nil
        )
        
        // 监听应用进入后台，清理状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听VIP状态重置通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vipStateDidReset),
            name: NSNotification.Name("VIPStateReset"),
            object: nil
        )
    }
    
    @objc private func applicationDidEnterBackground() {
        // 应用进入后台时，强制重置购买状态，防止卡死
        vipManager.forceResetPurchaseState()
    }
    
    @objc private func vipStateDidReset() {
        print("🔍 收到VIP状态重置通知，确保UI可交互")
        DispatchQueue.main.async {
            // 确保视图可以交互
            self.view.isUserInteractionEnabled = true
            
            // 移除任何可能阻塞UI的遮罩
            self.view.subviews.forEach { subview in
                if subview.tag == 999 || subview is VIPPreviewOverlayView {
                    subview.removeFromSuperview()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .portrait
        
        // 强制刷新语言设置，确保本地化正确
        print("🔍 VIP界面即将显示，当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        
        // 强制重新加载语言bundle
        let currentLang = LanguageManager.shared.currentLanguage
        LanguageManager.shared.currentLanguage = currentLang
        
        // 更新UI文本
        updateUITexts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 延迟验证按钮设置，确保布局完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.verifyButtonSetup()
            
            // 测试按钮触摸
            self.testButtonTouch()
        }
    }
    
    // 测试按钮触摸响应
    private func testButtonTouch() {
        print("🔍 ===== 测试按钮触摸响应 =====")
        
        // 查找所有按钮
        func findButtons(in view: UIView) -> [UIButton] {
            var buttons: [UIButton] = []
            for subview in view.subviews {
                if let button = subview as? UIButton {
                    buttons.append(button)
                } else {
                    buttons.append(contentsOf: findButtons(in: subview))
                }
            }
            return buttons
        }
        
        let allButtons = findButtons(in: bottomButtonsView)
        
        for button in allButtons {
            let title = button.titleLabel?.text ?? "无标题"
            
            // 获取按钮在window中的frame
            if let window = button.window {
                let buttonFrameInWindow = button.convert(button.bounds, to: window)
                print("🔍 按钮 '\(title)' 在window中的frame: \(buttonFrameInWindow)")
                
                // 测试按钮中心点
                let buttonCenter = CGPoint(x: buttonFrameInWindow.midX, y: buttonFrameInWindow.midY)
                let hitView = window.hitTest(buttonCenter, with: nil)
                
                if hitView == button {
                    print("✅ 按钮 '\(title)' 可以接收触摸")
                } else {
                    print("❌ 按钮 '\(title)' 被遮挡")
                    print("   hitView类型: \(String(describing: type(of: hitView)))")
                    print("   hitView: \(String(describing: hitView))")
                    
                    // 尝试找出遮挡的原因
                    if let hitView = hitView {
                        var current: UIView? = hitView
                        var depth = 0
                        print("   遮挡视图层级:")
                        while let view = current, depth < 5 {
                            let frame = view.frame
                            let isUserInteractionEnabled = view.isUserInteractionEnabled
                            print("   - \(depth): \(String(describing: type(of: view))), frame: \(frame), 可交互: \(isUserInteractionEnabled)")
                            current = view.superview
                            depth += 1
                        }
                        
                        // 检查按钮的父视图链
                        print("   按钮的父视图链:")
                        var buttonParent: UIView? = button.superview
                        var buttonDepth = 0
                        while let view = buttonParent, buttonDepth < 5 {
                            let frame = view.frame
                            let isUserInteractionEnabled = view.isUserInteractionEnabled
                            print("   - \(buttonDepth): \(String(describing: type(of: view))), frame: \(frame), 可交互: \(isUserInteractionEnabled)")
                            buttonParent = view.superview
                            buttonDepth += 1
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 强制重置购买状态，防止卡死
        vipManager.forceResetPurchaseState()
    }
    
    deinit {
        print("🔍 VIPSubscriptionViewController deinit - 清理资源")
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
        // 强制重置购买状态
        vipManager.forceResetPurchaseState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新背景渐变大小
        if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
        
        // 更新订阅按钮渐变
        if let subscribeButton = bottomButtonsView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            applyGradientToSubscribeButton(subscribeButton)
        }
        
        // 更新全屏弹窗中的确定按钮渐变
        if let overlayView = view.viewWithTag(999),
           let confirmButton = overlayView.subviews.first?.subviews.last?.subviews.first(where: { $0 is UIButton }) as? UIButton {
            applyGradientToButton(confirmButton)
        }
    }
    
    @objc private func languageDidChange() {
        print("🔍 VIP界面收到语言变化通知")
        print("🔍 新语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        
        // 延迟更新UI，确保语言bundle已经更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateUITexts()
        }
    }
    
    private func updateUITexts() {
        print("🔍 updateUITexts called")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        
        // 更新标题和副标题
        titleLabel.text = "vipTitle".localized
        subtitleLabel.text = "vipSubtitle".localized
        
        print("🔍 更新后的标题: \(titleLabel.text ?? "nil")")
        print("🔍 更新后的副标题: \(subtitleLabel.text ?? "nil")")
        
        // 重新设置功能列表
        setupFeatures()
        
        // 重新设置订阅选项（这会重新创建按钮）
        setupSubscriptionOptions()
        
        // 重新设置底部按钮
        setupBottomButtons()
        
        // 强制刷新视图
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func setupNotifications() {
        // 监听购买完成通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(purchaseDidComplete(_:)),
            name: VIPManager.purchaseDidCompleteNotification,
            object: nil
        )
        
        // 监听购买失败通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(purchaseDidFail(_:)),
            name: VIPManager.purchaseDidFailNotification,
            object: nil
        )
        
        // 监听产品加载完成，刷新价格显示
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(productsDidLoad),
            name: NSNotification.Name("ProductsDidLoad"),
            object: nil
        )
    }
    
    @objc private func productsDidLoad() {
        DispatchQueue.main.async {
            self.setupSubscriptionOptions()
        }
    }
    
    @objc private func purchaseDidComplete(_ notification: Notification) {
        print("🔍 收到购买完成通知")
        DispatchQueue.main.async {
            if let userInfo = notification.userInfo,
               let restored = userInfo["restored"] as? Bool, restored {
                print("🔍 恢复购买成功，显示成功提示")
                // 恢复购买成功，不自动关闭界面
                self.showSuccessAlert(message: "restoreSuccess".localized, shouldDismiss: false)
            } else {
                print("🔍 新购买成功，显示成功提示并关闭界面")
                // 新购买成功，关闭界面
                self.showSuccessAlert(message: "purchaseSuccess".localized, shouldDismiss: true)
            }
        }
    }
    
    @objc private func purchaseDidFail(_ notification: Notification) {
        print("🔍 收到购买失败通知")
        DispatchQueue.main.async {
            if let userInfo = notification.userInfo,
               let cancelled = userInfo["cancelled"] as? Bool, cancelled {
                print("🔍 用户取消购买，不显示错误信息")
                // 用户取消购买，不显示错误信息
                return
            }
            
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? String {
                print("🔍 显示购买失败提示: \(error)")
                self.showAlert(title: "purchaseFailed".localized, message: error)
            } else {
                print("🔍 显示通用购买失败提示")
                self.showAlert(title: "purchaseFailed".localized, message: "purchaseFailedMessage".localized)
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0) // 改为深蓝灰色，去掉黑色遮罩
        
        // 添加背景图片
        addBackgroundImage()
        
        // 添加背景渐变层（在背景图片上方，增加深度）
        addBackgroundGradient()
        
        // 导航栏设置
        title = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        // 设置导航栏样式 - 完全透明，无遮罩
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil // 移除任何背景效果
        appearance.shadowColor = .clear // 移除阴影
        appearance.shadowImage = UIImage() // 移除阴影图片
        
        // 确保所有状态下都使用透明外观
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }
        
        // 确保导航栏完全透明，不会产生遮罩效果
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.tintColor = .white
        
        // 移除导航栏的背景视图
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        // 确保导航栏不会在滚动时显示背景
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundEffect = nil
            navigationController?.navigationBar.standardAppearance.backgroundColor = .clear
        }
        
        // 确保状态栏样式
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        // 滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false // 关键：不延迟内容触摸，让按钮立即响应
        scrollView.canCancelContentTouches = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = true // 确保可以传递触摸事件
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor), // 改为从屏幕顶部开始，避免导航栏遮罩
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupHeader()
        setupFeatures()
        setupSubscriptionOptions()
        setupBottomButtons() // 移到这里，确保所有视图都已添加到层次结构中
    }
    
    // 添加背景图片
    private func addBackgroundImage() {
        guard let backgroundImage = UIImage(named: "vipbg") else {
            print("Warning: vipbg image not found")
            return
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 将背景图片添加到视图的最底层
        view.insertSubview(backgroundImageView, at: 0)
        
        // 设置约束使背景图片填满整个视图
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // 添加背景渐变
    private func addBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        // 创建更加透明的渐变层，让背景图片更好地显示
        gradientLayer.colors = [
            UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 0.1).cgColor,  // 很透明的紫色
            UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.2).cgColor,  // 很透明的深蓝
            UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.4).cgColor  // 半透明的深色
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        view.layer.insertSublayer(gradientLayer, at: 1) // 插入到背景图片上方
        
        // 当视图大小改变时更新渐变层大小
        DispatchQueue.main.async {
            gradientLayer.frame = self.view.bounds
        }
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        // VIP图标 - 使用PNG图片
        let vipIconView = UIImageView()
        vipIconView.image = UIImage(named: "vip")
        vipIconView.contentMode = .scaleAspectFit
        vipIconView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(vipIconView)
        
        // 标题
        titleLabel.text = "vipTitle".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // 副标题
        subtitleLabel.text = "vipSubtitle".localized
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 0), // 往上移动20pt，从20改为0
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 160),
            
            vipIconView.topAnchor.constraint(equalTo: headerView.topAnchor),
            vipIconView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            vipIconView.widthAnchor.constraint(equalToConstant: 80),
            vipIconView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: vipIconView.bottomAnchor, constant: 15), // 减少间距，从20改为15
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupFeatures() {
        featuresView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featuresView)
        
        let features = [
            ("🎨", "vipFeature1".localized),
            ("✨", "vipFeature2".localized),
            ("💝", "vipFeature3".localized),
            ("🎯", "vipFeature4".localized),
            ("🚀", "vipFeature5".localized),
            ("💎", "vipFeature6".localized)
        ]
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8 // 减少间距从16到8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        featuresView.addSubview(stackView)
        
        for (icon, text) in features {
            let featureView = createFeatureView(icon: icon, text: text)
            stackView.addArrangedSubview(featureView)
        }
        
        NSLayoutConstraint.activate([
            featuresView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 30), // 增加间距，从10改为30，拉开与上面的距离
            featuresView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            featuresView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: featuresView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: featuresView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: featuresView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: featuresView.bottomAnchor)
        ])
    }
    
    private func createFeatureView(icon: String, text: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconLabel)
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.textColor = .white
        textLabel.font = .systemFont(ofSize: 16, weight: .medium)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 24), // 减少高度从30到24
            
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            textLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        return containerView
    }
    
    private func setupSubscriptionOptions() {
        subscriptionOptionsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subscriptionOptionsView)
        
        // 清空之前的按钮数组
        subscriptionButtons.removeAll()
        
        // 移除之前的子视图
        subscriptionOptionsView.subviews.forEach { $0.removeFromSuperview() }
        
        // 订阅选项容器（移除标题）
        let optionsContainer = UIView()
        optionsContainer.translatesAutoresizingMaskIntoConstraints = false
        subscriptionOptionsView.addSubview(optionsContainer)
        
        // 创建订阅选项 - 使用实际产品价格或回退价格
        var subscriptionOptions: [(String, String, String, Bool)] = []
        
        if vipManager.products.count >= 3 { // 改为3个产品
            // 使用实际产品价格
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            
            for (index, product) in vipManager.products.enumerated() {
                if index >= 3 { break } // 只处理前3个产品
                
                formatter.locale = product.priceLocale
                let priceString = formatter.string(from: product.price) ?? "$0.00"
                
                let title: String
                let subtitle: String
                let isSelected = (index == 0)
                
                switch index {
                case 0: // Weekly
                    title = "weeklySubscription".localized
                    subtitle = "freeTrial".localized
                case 1: // Monthly
                    title = "monthlySubscription".localized
                    subtitle = "mostPopular".localized
                case 2: // Yearly
                    title = "🔥 " + "yearlySubscription".localized // 添加火的图标
                    subtitle = "save76Percent".localized // 改为节省76%
                default:
                    title = product.localizedTitle
                    subtitle = ""
                }
                
                subscriptionOptions.append((title, priceString, subtitle, isSelected))
            }
        } else {
            // 如果产品还没加载完成，使用新的回退价格
            subscriptionOptions = [
                ("weeklySubscription".localized, "$2.99", "freeTrial".localized, true),
                ("monthlySubscription".localized, "$7.99", "mostPopular".localized, false),
                ("🔥 " + "yearlySubscription".localized, "$29.99", "save76Percent".localized, false)
            ]
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        optionsContainer.addSubview(stackView)
        
        for (index, (title, price, subtitle, isSelected)) in subscriptionOptions.enumerated() {
            let optionButton = createSubscriptionOption(
                title: title,
                price: price,
                subtitle: subtitle,
                isSelected: isSelected,
                index: index
            )
            stackView.addArrangedSubview(optionButton)
            subscriptionButtons.append(optionButton)
        }
        
        NSLayoutConstraint.activate([
            subscriptionOptionsView.topAnchor.constraint(equalTo: featuresView.bottomAnchor, constant: 20), // 减少间距，从30改为20
            subscriptionOptionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subscriptionOptionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // 直接约束容器到subscriptionOptionsView的顶部（移除标题的约束）
            optionsContainer.topAnchor.constraint(equalTo: subscriptionOptionsView.topAnchor),
            optionsContainer.leadingAnchor.constraint(equalTo: subscriptionOptionsView.leadingAnchor, constant: 20),
            optionsContainer.trailingAnchor.constraint(equalTo: subscriptionOptionsView.trailingAnchor, constant: -20),
            optionsContainer.bottomAnchor.constraint(equalTo: subscriptionOptionsView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor)
        ])
    }
    
    private func createSubscriptionOption(title: String, price: String, subtitle: String, isSelected: Bool, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = isSelected ? UIColor.black.withAlphaComponent(0.7) : UIColor(white: 0.1, alpha: 0.6) // 选中状态改为0.7透明度的黑色
        button.layer.cornerRadius = 12
        button.layer.borderWidth = isSelected ? 2 : 1
        button.clipsToBounds = false // 改为false，允许标签显示在按钮外部
        
        // 使用偏粉色的边框颜色（类似start free trial按钮右边的渐变色）
        if isSelected {
            button.layer.borderColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0).cgColor // 偏粉的橙黄色边框
        } else {
            button.layer.borderColor = UIColor(white: 0.5, alpha: 0.8).cgColor // 改为灰调边框，从紫色改为灰色
        }
        
        button.tag = index
        button.addTarget(self, action: #selector(subscriptionOptionTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(titleLabel)
        
        // 价格 - 右对齐，使用渐变主题色
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.textColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0) // 橙黄色，匹配渐变主题
        priceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        priceLabel.textAlignment = .right
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(priceLabel)
        
        // 副标题
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(subtitleLabel)
        
        // 右上角标签（周订阅和年订阅）- 直接添加到按钮
        var cornerLabel: UILabel?
        if index == 0 { // 周订阅 - 免费试用标签
            cornerLabel = UILabel()
            cornerLabel!.text = "freeTrial".localized
            cornerLabel!.textColor = .white
            cornerLabel!.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // 橙色背景
            cornerLabel!.font = .systemFont(ofSize: 10, weight: .bold)
            cornerLabel!.textAlignment = .center
            cornerLabel!.layer.cornerRadius = 9 // 圆角调整为高度的一半 (18/2=9)
            cornerLabel!.layer.masksToBounds = true
            cornerLabel!.layer.zPosition = 100 // 设置非常高的z层级，确保在最上层
            cornerLabel!.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(cornerLabel!)
        } else if index == 2 { // 年订阅 - 节省76%标签
            cornerLabel = UILabel()
            cornerLabel!.text = "save76Percent".localized
            cornerLabel!.textColor = .white
            cornerLabel!.backgroundColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0) // 红色背景
            cornerLabel!.font = .systemFont(ofSize: 10, weight: .bold)
            cornerLabel!.textAlignment = .center
            cornerLabel!.layer.cornerRadius = 9 // 圆角调整为高度的一半 (18/2=9)
            cornerLabel!.layer.masksToBounds = true
            cornerLabel!.layer.zPosition = 100 // 设置非常高的z层级，确保在最上层
            cornerLabel!.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(cornerLabel!)
        }
        
        var constraints = [
            button.heightAnchor.constraint(equalToConstant: 68), // 减少2pt，从70改为68
            
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            
            // 价格垂直居中显示
            priceLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8)
        ]
        
        // 添加右上角标签的约束
        if let cornerLabel = cornerLabel {
            let labelWidth: CGFloat = index == 0 ? 80 : 60 // 周订阅标签宽度增大
            constraints.append(contentsOf: [
                cornerLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: -6),
                cornerLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
                cornerLabel.widthAnchor.constraint(equalToConstant: labelWidth),
                cornerLabel.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        return button
    }
    
    private func setupBottomButtons() {
        bottomButtonsView.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonsView.isUserInteractionEnabled = true // 确保底部视图可以接收触摸事件
        bottomButtonsView.backgroundColor = .clear // 确保背景透明
        bottomButtonsView.layer.zPosition = 100 // 设置高z-index确保在最上层
        contentView.addSubview(bottomButtonsView)
        
        // 确保bottomButtonsView在最上层
        contentView.bringSubviewToFront(bottomButtonsView)
        
        print("🔍 setupBottomButtons 被调用，当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        
        // 移除之前的子视图
        bottomButtonsView.subviews.forEach { $0.removeFromSuperview() }
        
        // 开始订阅按钮
        let subscribeButton = UIButton(type: .system)
        let subscribeTitle = "startFreeTrial".localized
        subscribeButton.setTitle(subscribeTitle, for: .normal)
        subscribeButton.setTitleColor(.white, for: .normal)
        subscribeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        subscribeButton.layer.cornerRadius = 25
        subscribeButton.layer.borderWidth = 0 // 确保没有描边
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonsView.addSubview(subscribeButton)
        
        print("🔍 设置订阅按钮: '\(subscribeTitle)'")
        
        // 支付免责声明（直接放在订阅按钮下面）
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "paymentDisclaimer".localized
        disclaimerLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        disclaimerLabel.font = .systemFont(ofSize: 10)
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonsView.addSubview(disclaimerLabel)
        
        // 底部链接容器（恢复购买 | 服务条款 | 隐私政策）
        let linksContainer = UIView()
        linksContainer.translatesAutoresizingMaskIntoConstraints = false
        linksContainer.isUserInteractionEnabled = true // 确保容器可以接收触摸事件
        linksContainer.backgroundColor = .clear // 确保背景透明，不阻挡触摸
        linksContainer.clipsToBounds = false // 确保不裁剪子视图
        linksContainer.layer.zPosition = 200 // 设置更高的z-index
        bottomButtonsView.addSubview(linksContainer)
        
        print("🔍 创建链接容器，父视图可交互: \(bottomButtonsView.isUserInteractionEnabled)")
        
        // 恢复购买按钮（小字体）
        let restoreLinkButton = UIButton()
        restoreLinkButton.translatesAutoresizingMaskIntoConstraints = false
        restoreLinkButton.isUserInteractionEnabled = true
        restoreLinkButton.isEnabled = true
        restoreLinkButton.isExclusiveTouch = true // 防止多次点击
        restoreLinkButton.layer.zPosition = 300 // 设置最高的z-index
        
        // 使用最基础的按钮设置方式
        let restoreTitle = "restorePurchases".localized
        restoreLinkButton.setTitle(restoreTitle, for: .normal)
        restoreLinkButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        restoreLinkButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        restoreLinkButton.titleLabel?.font = .systemFont(ofSize: 12)
        restoreLinkButton.backgroundColor = .clear
        
        // 增大点击区域
        restoreLinkButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        // 设置target - 使用最直接的方式
        restoreLinkButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        
        // 添加调试信息
        print("🔍 设置恢复购买按钮: '\(restoreTitle)'")
        print("🔍 按钮是否启用: \(restoreLinkButton.isEnabled)")
        print("🔍 按钮是否可交互: \(restoreLinkButton.isUserInteractionEnabled)")
        
        // 添加一个测试用的触摸区域视图
        restoreLinkButton.layer.borderWidth = 0 // 移除边框，避免视觉干扰
        
        linksContainer.addSubview(restoreLinkButton)
        
        // 分隔符1
        let separator1 = UILabel()
        separator1.text = "|"
        separator1.textColor = UIColor.white.withAlphaComponent(0.3)
        separator1.font = .systemFont(ofSize: 12) // 调整为12pt字体
        separator1.translatesAutoresizingMaskIntoConstraints = false
        linksContainer.addSubview(separator1)
        
        // 服务条款按钮
        let termsButton = UIButton()
        termsButton.translatesAutoresizingMaskIntoConstraints = false
        termsButton.isUserInteractionEnabled = true
        termsButton.isEnabled = true
        termsButton.isExclusiveTouch = true // 防止多次点击
        termsButton.layer.zPosition = 300 // 设置最高的z-index
        
        // 使用最基础的按钮设置方式
        let termsTitle = "termsOfService".localized
        termsButton.setTitle(termsTitle, for: .normal)
        termsButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        termsButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        termsButton.titleLabel?.font = .systemFont(ofSize: 12)
        termsButton.backgroundColor = .clear
        
        // 增大点击区域
        termsButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        // 设置target - 使用最直接的方式
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        
        // 添加调试信息
        print("🔍 设置服务条款按钮: '\(termsTitle)'")
        print("🔍 按钮是否启用: \(termsButton.isEnabled)")
        print("🔍 按钮是否可交互: \(termsButton.isUserInteractionEnabled)")
        
        linksContainer.addSubview(termsButton)
        
        // 分隔符2
        let separator2 = UILabel()
        separator2.text = "|"
        separator2.textColor = UIColor.white.withAlphaComponent(0.3)
        separator2.font = .systemFont(ofSize: 12) // 调整为12pt字体
        separator2.translatesAutoresizingMaskIntoConstraints = false
        linksContainer.addSubview(separator2)
        
        // 隐私政策按钮
        let privacyButton = UIButton()
        privacyButton.translatesAutoresizingMaskIntoConstraints = false
        privacyButton.isUserInteractionEnabled = true
        privacyButton.isEnabled = true
        privacyButton.isExclusiveTouch = true // 防止多次点击
        privacyButton.layer.zPosition = 300 // 设置最高的z-index
        
        // 使用最基础的按钮设置方式
        let privacyTitle = "privacyPolicy".localized
        privacyButton.setTitle(privacyTitle, for: .normal)
        privacyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        privacyButton.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        privacyButton.titleLabel?.font = .systemFont(ofSize: 12)
        privacyButton.backgroundColor = .clear
        
        // 增大点击区域
        privacyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        // 设置target - 使用最直接的方式
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        
        // 添加调试信息
        print("🔍 设置隐私政策按钮: '\(privacyTitle)'")
        print("🔍 按钮是否启用: \(privacyButton.isEnabled)")
        print("🔍 按钮是否可交互: \(privacyButton.isUserInteractionEnabled)")
        
        linksContainer.addSubview(privacyButton)
        
        NSLayoutConstraint.activate([
            bottomButtonsView.topAnchor.constraint(equalTo: subscriptionOptionsView.bottomAnchor, constant: 20), // 减少间距，从30改为20
            bottomButtonsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomButtonsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomButtonsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            bottomButtonsView.heightAnchor.constraint(equalToConstant: 120), // 减少高度，因为移除了中间的恢复购买按钮
            
            subscribeButton.topAnchor.constraint(equalTo: bottomButtonsView.topAnchor),
            subscribeButton.leadingAnchor.constraint(equalTo: bottomButtonsView.leadingAnchor, constant: 20),
            subscribeButton.trailingAnchor.constraint(equalTo: bottomButtonsView.trailingAnchor, constant: -20),
            subscribeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 免责声明直接放在订阅按钮下面，往下移动4pt
            disclaimerLabel.topAnchor.constraint(equalTo: subscribeButton.bottomAnchor, constant: 16), // 从12改为16，往下移动4pt
            disclaimerLabel.leadingAnchor.constraint(equalTo: bottomButtonsView.leadingAnchor, constant: 20),
            disclaimerLabel.trailingAnchor.constraint(equalTo: bottomButtonsView.trailingAnchor, constant: -20),
            
            // 底部链接容器 - 增加高度和点击区域
            linksContainer.topAnchor.constraint(equalTo: disclaimerLabel.bottomAnchor, constant: 12),
            linksContainer.centerXAnchor.constraint(equalTo: bottomButtonsView.centerXAnchor),
            linksContainer.heightAnchor.constraint(equalToConstant: 44), // 增加高度到44pt，提供更大的点击区域
            linksContainer.leadingAnchor.constraint(greaterThanOrEqualTo: bottomButtonsView.leadingAnchor, constant: 20),
            linksContainer.trailingAnchor.constraint(lessThanOrEqualTo: bottomButtonsView.trailingAnchor, constant: -20),
            
            // 恢复购买按钮 - 确保有足够的点击区域
            restoreLinkButton.leadingAnchor.constraint(equalTo: linksContainer.leadingAnchor),
            restoreLinkButton.centerYAnchor.constraint(equalTo: linksContainer.centerYAnchor),
            restoreLinkButton.heightAnchor.constraint(equalTo: linksContainer.heightAnchor), // 占满容器高度
            
            // 分隔符1
            separator1.leadingAnchor.constraint(equalTo: restoreLinkButton.trailingAnchor, constant: 8),
            separator1.centerYAnchor.constraint(equalTo: linksContainer.centerYAnchor),
            
            // 服务条款 - 确保有足够的点击区域
            termsButton.leadingAnchor.constraint(equalTo: separator1.trailingAnchor, constant: 8),
            termsButton.centerYAnchor.constraint(equalTo: linksContainer.centerYAnchor),
            termsButton.heightAnchor.constraint(equalTo: linksContainer.heightAnchor), // 占满容器高度
            
            // 分隔符2
            separator2.leadingAnchor.constraint(equalTo: termsButton.trailingAnchor, constant: 8),
            separator2.centerYAnchor.constraint(equalTo: linksContainer.centerYAnchor),
            
            // 隐私政策 - 确保有足够的点击区域
            privacyButton.leadingAnchor.constraint(equalTo: separator2.trailingAnchor, constant: 8),
            privacyButton.trailingAnchor.constraint(equalTo: linksContainer.trailingAnchor),
            privacyButton.centerYAnchor.constraint(equalTo: linksContainer.centerYAnchor),
            privacyButton.heightAnchor.constraint(equalTo: linksContainer.heightAnchor) // 占满容器高度
        ])
        
        // 在布局完成后应用渐变
        DispatchQueue.main.async {
            self.applyGradientToSubscribeButton(subscribeButton)
            
            // 验证按钮设置
            self.verifyButtonSetup()
        }
    }
    
    // 为订阅按钮应用渐变背景
    private func applyGradientToSubscribeButton(_ button: UIButton) {
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
        gradientLayer.cornerRadius = 25
        
        button.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // 验证按钮设置
    private func verifyButtonSetup() {
        print("🔍 ===== 验证按钮设置 =====")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        
        // 查找底部按钮视图中的所有按钮
        func findButtons(in view: UIView) -> [UIButton] {
            var buttons: [UIButton] = []
            for subview in view.subviews {
                if let button = subview as? UIButton {
                    buttons.append(button)
                } else {
                    buttons.append(contentsOf: findButtons(in: subview))
                }
            }
            return buttons
        }
        
        let allButtons = findButtons(in: bottomButtonsView)
        print("🔍 找到 \(allButtons.count) 个按钮")
        
        for (index, button) in allButtons.enumerated() {
            let title = button.titleLabel?.text ?? "无标题"
            print("🔍 按钮 \(index): '\(title)'")
            print("   - Frame: \(button.frame)")
            print("   - 是否启用: \(button.isEnabled)")
            print("   - 是否可交互: \(button.isUserInteractionEnabled)")
            print("   - 父视图可交互: \(button.superview?.isUserInteractionEnabled ?? false)")
            print("   - Target数量: \(button.allTargets.count)")
            print("   - 是否隐藏: \(button.isHidden)")
            print("   - Alpha: \(button.alpha)")
            print("   - 是否独占触摸: \(button.isExclusiveTouch)")
            
            // 检查按钮的层级结构
            var currentView: UIView? = button
            var level = 0
            while let view = currentView, level < 5 {
                let className = String(describing: type(of: view))
                let isScrollView = view is UIScrollView
                print("   - 层级 \(level): \(className), 可交互: \(view.isUserInteractionEnabled), ScrollView: \(isScrollView)")
                currentView = view.superview
                level += 1
            }
            
            // 检查是否有视图遮挡按钮
            if let window = button.window {
                let buttonCenter = button.convert(CGPoint(x: button.bounds.midX, y: button.bounds.midY), to: window)
                if let hitView = window.hitTest(buttonCenter, with: nil) {
                    let hitViewClass = String(describing: type(of: hitView))
                    let isButton = hitView == button
                    print("   - 点击测试: \(isButton ? "✅ 按钮可点击" : "❌ 被遮挡")")
                    if !isButton {
                        print("   - 遮挡视图: \(hitViewClass)")
                    }
                }
            }
            print("   ---")
        }
        
        // 检查scrollView是否影响触摸
        print("🔍 ScrollView状态:")
        print("   - 是否可交互: \(scrollView.isUserInteractionEnabled)")
        print("   - 是否可滚动: \(scrollView.isScrollEnabled)")
        print("   - ContentSize: \(scrollView.contentSize)")
        print("   - Frame: \(scrollView.frame)")
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        print("🔍 关闭订阅界面")
        
        // 强制清理所有可能的遮罩和定时器
        vipManager.forceResetPurchaseState()
        
        // 移除所有遮罩视图（包括VIP预览遮罩）
        view.subviews.forEach { subview in
            if subview is VIPPreviewOverlayView {
                subview.removeFromSuperview()
            }
        }
        
        // 移除自定义alert遮罩
        if let overlayView = view.viewWithTag(999) {
            overlayView.removeFromSuperview()
        }
        
        // 确保导航栏显示
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        // 关闭当前视图控制器
        dismiss(animated: true) {
            print("🔍 订阅界面已关闭")
        }
    }
    
    @objc private func subscriptionOptionTapped(_ sender: UIButton) {
        // 更新选中状态
        selectedSubscriptionIndex = sender.tag
        
        for (index, button) in subscriptionButtons.enumerated() {
            let isSelected = index == selectedSubscriptionIndex
            button.backgroundColor = isSelected ? UIColor.black.withAlphaComponent(0.7) : UIColor(white: 0.1, alpha: 0.6) // 选中状态改为0.7透明度的黑色
            button.layer.borderWidth = isSelected ? 2 : 1
            
            // 使用渐变边框颜色
            if isSelected {
                button.layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0).cgColor // 橙色边框
            } else {
                button.layer.borderColor = UIColor(white: 0.5, alpha: 0.8).cgColor // 改为灰调边框，从紫色改为灰色
            }
        }
    }
    
    @objc private func subscribeTapped() {
        print("🔍 订阅按钮被点击，选择的索引: \(selectedSubscriptionIndex)")
        
        // 检查当前loading状态
        if vipManager.isLoading {
            print("⚠️ 当前正在处理其他购买操作，忽略订阅请求")
            showAlert(title: "tip".localized, message: "请等待当前操作完成")
            return
        }
        
        // 如果选择的是周订阅且用户是免费用户，开始免费试用
        if selectedSubscriptionIndex == 0 && !vipManager.isVIP() {
            print("🔍 开始免费试用")
            vipManager.startFreeTrial()
            showSuccessAlert(message: "freeTrialStarted".localized, shouldDismiss: true)
        } else {
            // 其他情况进行购买
            guard selectedSubscriptionIndex < vipManager.products.count else { 
                print("⚠️ 产品列表未加载完成")
                showAlert(title: "tip".localized, message: "loadingProducts".localized)
                return 
            }
            let product = vipManager.products[selectedSubscriptionIndex]
            print("🔍 开始购买产品: \(product.productIdentifier)")
            vipManager.purchase(product: product)
        }
    }
    
    @objc private func restoreTapped() {
        print("🔍 ===== 恢复购买按钮被点击 =====")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        print("🔍 本地化测试 - restorePurchases: \("restorePurchases".localized)")
        print("🔍 调用线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 检查当前loading状态
        if vipManager.isLoading {
            print("⚠️ 当前正在处理其他购买操作，忽略恢复购买请求")
            showAlert(title: "tip".localized, message: "请等待当前操作完成")
            return
        }
        
        // 显示加载状态，但不立即显示alert
        print("🔍 开始恢复购买操作")
        vipManager.restorePurchases()
        print("🔍 已调用恢复购买方法")
        // 移除立即显示的alert，等待恢复结果
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        print("🔍 Button touch down: \(sender.titleLabel?.text ?? "unknown")")
        sender.alpha = 0.5
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        print("🔍 Button touch up: \(sender.titleLabel?.text ?? "unknown")")
        sender.alpha = 1.0
    }
    
    @objc private func termsTapped() {
        print("🔍 ===== 服务条款按钮被点击 =====")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        print("🔍 本地化标题: \("termsOfService".localized)")
        print("🔍 本地化内容长度: \("termsContent".localized.count)")
        print("🔍 本地化内容前100字符: \(String("termsContent".localized.prefix(100)))")
        print("🔍 调用线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 确保在主线程执行
        DispatchQueue.main.async {
            print("🔍 准备显示服务条款弹窗")
            self.showDetailedAlert(title: "termsOfService".localized, message: "termsContent".localized)
        }
    }
    
    @objc private func privacyTapped() {
        print("🔍 ===== 隐私政策按钮被点击 =====")
        print("🔍 当前语言: \(LanguageManager.shared.currentLanguage.rawValue)")
        print("🔍 本地化标题: \("privacyPolicy".localized)")
        print("🔍 本地化内容长度: \("privacyContent".localized.count)")
        print("🔍 本地化内容前100字符: \(String("privacyContent".localized.prefix(100)))")
        print("🔍 调用线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 确保在主线程执行
        DispatchQueue.main.async {
            print("🔍 准备显示隐私政策弹窗")
            self.showDetailedAlert(title: "privacyPolicy".localized, message: "privacyContent".localized)
        }
    }
    
    private func showDetailedAlert(title: String, message: String) {
        print("🔍 showDetailedAlert called with title: \(title)")
        print("🔍 Message length: \(message.count)")
        print("🔍 Message preview: \(String(message.prefix(100)))...")
        
        // 隐藏导航栏以避免左上角按钮显示
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 创建完全全屏弹窗视图
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.systemBackground
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加暗紫色到黑色的上下渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1.0).cgColor,  // 暗紫色
            UIColor.black.cgColor  // 黑色
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        overlayView.layer.insertSublayer(gradientLayer, at: 0)
        
        // 状态栏区域标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 右上角关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor.white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissCustomAlert), for: .touchUpInside)
        
        // 内容滚动视图 - 重新设计
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // 内容容器视图
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .clear
        
        // 内容标签
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = UIColor.white
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 12
        
        let attributedText = NSMutableAttributedString(string: message)
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        attributedText.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: attributedText.length))
        
        // 为小标题设置加粗
        formatSubtitles(in: attributedText)
        
        messageLabel.attributedText = attributedText
        
        // 添加视图层次
        view.addSubview(overlayView)
        overlayView.addSubview(titleLabel)
        overlayView.addSubview(closeButton)
        overlayView.addSubview(scrollView)
        scrollView.addSubview(contentContainer)
        contentContainer.addSubview(messageLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 覆盖层完全全屏
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: overlayView.leadingAnchor, constant: 60),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: overlayView.trailingAnchor, constant: -60),
            
            // 关闭按钮
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // 滚动视图
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.bottomAnchor),
            
            // 内容容器
            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 内容标签
            messageLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            messageLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -60)
        ])
        
        // 存储引用以便关闭
        overlayView.tag = 999
        
        // 动画显示
        overlayView.alpha = 0
        overlayView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            overlayView.alpha = 1
            overlayView.transform = .identity
        }) { _ in
            print("🔍 Full-screen custom alert presented successfully")
            
            // 强制更新布局并计算内容大小
            DispatchQueue.main.async {
                overlayView.layoutIfNeeded()
                let contentHeight = messageLabel.intrinsicContentSize.height + 80 // 加上padding
                print("🔍 Content height: \(contentHeight)")
                print("🔍 ScrollView frame: \(scrollView.frame)")
                print("🔍 MessageLabel frame: \(messageLabel.frame)")
            }
        }
    }
    
    // 格式化内容文本
    private func formatContentText(_ text: String) -> String {
        return text
    }
    
    // 为小标题设置加粗和增大字号
    private func formatSubtitles(in attributedText: NSMutableAttributedString) {
        let text = attributedText.string
        let pattern = #"^\d+\.\s*[^\n]+"# // 匹配 "数字. 标题" 格式
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                // 为小标题设置加粗字体和增大字号（+2px）
                attributedText.addAttribute(.font, 
                                          value: UIFont.systemFont(ofSize: 18, weight: .bold), 
                                          range: match.range)
                attributedText.addAttribute(.foregroundColor, 
                                          value: UIColor.white, // 确保使用白色
                                          range: match.range)
            }
        } catch {
            print("Regex error: \(error)")
        }
    }
    
    // 为按钮应用渐变背景
    private func applyGradientToButton(_ button: UIButton) {
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
        gradientLayer.cornerRadius = 12
        
        button.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    @objc private func dismissCustomAlert() {
        if let overlayView = view.viewWithTag(999) {
            UIView.animate(withDuration: 0.2, animations: {
                overlayView.alpha = 0
            }) { _ in
                overlayView.removeFromSuperview()
                // 恢复导航栏显示
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                print("🔍 Custom alert dismissed")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        // 确保在主线程执行，并检查当前是否已有模态视图
        DispatchQueue.main.async {
            // 如果当前已经有模态视图在显示，先关闭它（关闭alert，不是整个view controller）
            if let presentedAlert = self.presentedViewController {
                presentedAlert.dismiss(animated: false) {
                    self.presentAlertSafely(title: title, message: message)
                }
            } else {
                self.presentAlertSafely(title: title, message: message)
            }
        }
    }
    
    private func presentAlertSafely(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String, shouldDismiss: Bool = true) {
        // 确保在主线程执行，并检查当前是否已有模态视图
        DispatchQueue.main.async {
            // 如果当前已经有模态视图在显示，先关闭它（关闭alert，不是整个view controller）
            if let presentedAlert = self.presentedViewController {
                presentedAlert.dismiss(animated: false) {
                    self.presentSuccessAlertSafely(message: message, shouldDismiss: shouldDismiss)
                }
            } else {
                self.presentSuccessAlertSafely(message: message, shouldDismiss: shouldDismiss)
            }
        }
    }
    
    private func presentSuccessAlertSafely(message: String, shouldDismiss: Bool) {
        let alert = UIAlertController(title: "success".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default) { _ in
            if shouldDismiss {
                self.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - StoreKit Extensions
extension VIPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            // 按价格排序：周 < 月 < 年
            self.products = response.products.sorted { product1, product2 in
                let order: [String] = [
                    ProductID.weekly.rawValue,
                    ProductID.monthly.rawValue,
                    ProductID.yearly.rawValue
                ]
                
                let index1 = order.firstIndex(of: product1.productIdentifier) ?? 0
                let index2 = order.firstIndex(of: product2.productIdentifier) ?? 0
                
                return index1 < index2
            }
            
            print("成功加载 \(self.products.count) 个产品")
            
            // 发送产品加载完成通知
            NotificationCenter.default.post(name: NSNotification.Name("ProductsDidLoad"), object: self)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.handleFailedPurchase(error: error)
        }
        print("产品请求失败: \(error.localizedDescription)")
    }
}

extension VIPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("🔍 收到 \(transactions.count) 个交易更新")
        
        for transaction in transactions {
            print("🔍 处理交易: \(transaction.payment.productIdentifier), 状态: \(transaction.transactionState.rawValue)")
            
            switch transaction.transactionState {
            case .purchased:
                handleSuccessfulPurchase(productID: transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                handleSuccessfulPurchase(productID: transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError {
                    if error.code != .paymentCancelled {
                        handleFailedPurchase(error: error)
                    } else {
                        // 用户取消购买 - 确保重置loading状态并发送通知
                        DispatchQueue.main.async {
                            self.isLoading = false
                            // 发送取消通知，让UI知道操作已完成
                            NotificationCenter.default.post(
                                name: VIPManager.purchaseDidFailNotification,
                                object: self,
                                userInfo: ["error": "用户取消了购买", "cancelled": true]
                            )
                        }
                        print("用户取消了购买")
                    }
                } else {
                    handleFailedPurchase(error: transaction.error)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred:
                print("购买被延迟，等待批准")
            case .purchasing:
                print("正在购买...")
            @unknown default:
                print("未知的交易状态")
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("🔍 恢复购买完成回调被调用")
        DispatchQueue.main.async {
            // 清理定时器
            self.restoreTimer?.invalidate()
            self.restoreTimer = nil
            
            print("🔍 设置 isLoading = false")
            self.isLoading = false
            self.loadVIPStatus()
            
            // 检查是否有恢复的交易
            let restoredTransactions = queue.transactions.filter { $0.transactionState == .restored }
            print("🔍 恢复的交易数量: \(restoredTransactions.count)")
            
            if restoredTransactions.isEmpty {
                print("🔍 没有可恢复的购买，发送失败通知")
                // 没有可恢复的购买
                NotificationCenter.default.post(
                    name: VIPManager.purchaseDidFailNotification, 
                    object: self, 
                    userInfo: ["error": "noRestorablePurchases".localized]
                )
            } else {
                print("🔍 有可恢复的购买，发送成功通知")
                // 发送恢复成功通知
                NotificationCenter.default.post(
                    name: VIPManager.purchaseDidCompleteNotification, 
                    object: self, 
                    userInfo: ["restored": true]
                )
            }
            
            print("🔍 恢复购买完成，恢复了 \(restoredTransactions.count) 个交易")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("🔍 恢复购买失败回调被调用: \(error.localizedDescription)")
        DispatchQueue.main.async {
            // 清理定时器
            self.restoreTimer?.invalidate()
            self.restoreTimer = nil
            
            self.handleFailedPurchase(error: error)
        }
        print("恢复购买失败: \(error.localizedDescription)")
    }
}

// 禁用点击动画的自定义 SegmentedControl
class NoAnimationSegmentedControl: UISegmentedControl {
    
    // 主题色
    private let themeColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    
    override init(items: [Any]?) {
        super.init(items: items)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }
    
    private func setupAppearance() {
        // 使用 iOS 13+ 的新 API
        if #available(iOS 13.0, *) {
            selectedSegmentTintColor = themeColor
        } else {
            tintColor = themeColor
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if #available(iOS 13.0, *) {
            selectedSegmentTintColor = themeColor
        }
        
        // 延迟更新选中胶囊颜色
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateSelectedSegmentColor()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13.0, *) {
            selectedSegmentTintColor = themeColor
        }
        
        // 每次布局时更新选中胶囊颜色
        updateSelectedSegmentColor()
    }
    
    override var selectedSegmentIndex: Int {
        didSet {
            // 选中改变时更新颜色
            updateSelectedSegmentColor()
        }
    }
    
    // 只更新选中segment的小胶囊背景色
    private func updateSelectedSegmentColor() {
        // 找到所有UIImageView（这些是segment按钮，包含选中的小胶囊）
        let imageViews = subviews.filter { String(describing: type(of: $0)) == "UIImageView" }
        
        // 有2个UIImageView，分别对应2个segment
        // selectedSegmentIndex = 0 时，imageViews[0] 是选中的
        // selectedSegmentIndex = 1 时，imageViews[1] 是选中的
        for (index, imageView) in imageViews.enumerated() {
            if index == selectedSegmentIndex {
                // 选中的segment，设置青色背景
                imageView.backgroundColor = themeColor
                
                // 调整frame：左边距2px，上下各缩小2px（总共少4px高度）
                let originalFrame = imageView.frame
                let insetFrame = CGRect(
                    x: originalFrame.origin.x + 2,
                    y: originalFrame.origin.y + 2,
                    width: originalFrame.width - 2,  // 只减左边的2px
                    height: originalFrame.height - 4  // 上下各2px
                )
                imageView.frame = insetFrame
                
                // 设置圆角，保持胶囊形状
                imageView.layer.cornerRadius = insetFrame.height / 2
                imageView.layer.masksToBounds = true
            } else {
                // 未选中的segment，设置透明背景
                imageView.backgroundColor = .clear
                
                // 也设置圆角，保持一致
                imageView.layer.cornerRadius = imageView.bounds.height / 2
                imageView.layer.masksToBounds = true
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // 触摸结束后更新颜色
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateSelectedSegmentColor()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
}

// 爱心格子视图 - 用于热门动画封面
class HeartGridView: UIView {
    
    private var gridSize: CGFloat = 12  // 封面用较小的格子
    private var spacing: CGFloat = 2.5
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
                }
            }
        }
        
        // 触发重绘
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义爱心形状（15x15网格）
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果网格太小无法容纳内容，调整格子大小
        if rows < heartRows || cols < heartCols {
            let maxGridSizeForHeight = rect.height / CGFloat(heartRows + 2)
            let maxGridSizeForWidth = rect.width / CGFloat(heartCols + 2)
            gridSize = min(maxGridSizeForHeight, maxGridSizeForWidth, 12) // 最大不超过12px
            gridSize = max(gridSize, 4) // 最小4px
            
            // 重新计算行列数
            cols = Int((rect.width + spacing) / (gridSize + spacing))
            rows = Int((rect.height + spacing) / (gridSize + spacing))
            cols = max(cols, heartCols + 2)
            rows = max(rows, heartRows + 2)
        }
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算爱心在网格中的真正居中位置
        let exactHeartStartRow = (Double(rows) - Double(heartRows)) / 2.0
        let exactHeartStartCol = (Double(cols) - Double(heartCols)) / 2.0
        
        let centeredHeartStartRow = Int(exactHeartStartRow.rounded())
        let centeredHeartStartCol = Int(exactHeartStartCol.rounded())
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                var isRedGrid = false
                
                // 判断是否在爱心图案内
                let heartRow = row - centeredHeartStartRow
                let heartCol = col - centeredHeartStartCol
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isRedGrid = heartPattern[heartRow][heartCol]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回15x15的爱心图案（与HeartGridViewController相同）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, true,  true,  true,  false, false, false, true,  true,  true,  false, false, false, false],
            [false, true,  true,  true,  true,  true,  false, true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        ]
    }
}

// I LOVE U 格子视图 - 用于热门动画封面
class ILoveUView: UIView {
    
    private var gridSize: CGFloat = 12  // 封面用格子大小与红心封面保持一致
    private var spacing: CGFloat = 2.5
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
                }
            }
        }
        
        // 触发重绘
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义爱心形状（15x15网格，与HeartGridView一致）
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果网格太小无法容纳内容，调整格子大小（与HeartGridView逻辑一致）
        if rows < heartRows || cols < heartCols + 4 { // 需要额外空间放置I和U
            let maxGridSizeForHeight = rect.height / CGFloat(heartRows + 2)
            let maxGridSizeForWidth = rect.width / CGFloat(heartCols + 6) // 为I和U留出空间
            gridSize = min(maxGridSizeForHeight, maxGridSizeForWidth, 12) // 最大不超过12px，与红心封面保持一致
            gridSize = max(gridSize, 4) // 最小4px，与红心封面保持一致
            
            // 重新计算行列数
            cols = Int((rect.width + spacing) / (gridSize + spacing))
            rows = Int((rect.height + spacing) / (gridSize + spacing))
            cols = max(cols, heartCols + 4)
            rows = max(rows, heartRows)
        }
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算爱心在网格中的真正居中位置
        let exactHeartStartRow = (Double(rows) - Double(heartRows)) / 2.0
        let exactHeartStartCol = (Double(cols) - Double(heartCols)) / 2.0
        
        let centeredHeartStartRow = Int(exactHeartStartRow.rounded())
        let centeredHeartStartCol = Int(exactHeartStartCol.rounded())
        
        // 获取字母I和U的图案（封面版本较小）
        let letterI = getLetterIPattern()
        let letterU = getLetterUPattern()
        
        // 计算字母I的位置（爱心左边，调整距离适应15x15爱心）
        let iStartRow = centeredHeartStartRow + (heartRows - letterI.count) / 2
        let iStartCol = max(0, centeredHeartStartCol - 2) // 调整为2格距离
        
        // 计算字母U的位置（爱心右边，调整距离适应15x15爱心）
        let uStartRow = centeredHeartStartRow + (heartRows - letterU.count) / 2
        let uStartCol = min(cols - letterU[0].count, centeredHeartStartCol + heartCols + 1) // 调整为1格距离
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                var isRedGrid = false
                
                // 判断是否在爱心图案内
                let heartRow = row - centeredHeartStartRow
                let heartCol = col - centeredHeartStartCol
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isRedGrid = heartPattern[heartRow][heartCol]
                }
                
                // 判断是否在字母I内
                let iRow = row - iStartRow
                let iCol = col - iStartCol
                if iRow >= 0 && iRow < letterI.count && iCol >= 0 && iCol < letterI[0].count {
                    isRedGrid = isRedGrid || letterI[iRow][iCol]
                }
                
                // 判断是否在字母U内
                let uRow = row - uStartRow
                let uCol = col - uStartCol
                if uRow >= 0 && uRow < letterU.count && uCol >= 0 && uCol < letterU[0].count {
                    isRedGrid = isRedGrid || letterU[uRow][uCol]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回15x15的爱心图案（与HeartGridView保持一致）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, true,  true,  false, false, false, true,  true,  false, false, false, false, false],
            [false, false, true,  true,  true,  true,  false, true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        ]
    }
    
    // 字母I的图案（高度与爱心协调）
    private func getLetterIPattern() -> [[Bool]] {
        return [
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true]
        ]
    }
    
    // 字母U的图案（圆角矩形样式，无上边）
    private func getLetterUPattern() -> [[Bool]] {
        return [
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [false, true,  false, true,  false],
            [false, true,  true,  true,  false]
        ]
    }
}

// 520封面视图 - 用于热门动画封面
class View520: UIView {
    
    private var gridSize: CGFloat = 6  // 封面用更小的格子，让520数字看起来密集一些
    private var spacing: CGFloat = 2.0
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
                }
            }
        }
        
        // 触发重绘
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义520数字图案
        let digit5 = getDigit5Pattern()
        let digit2 = getDigit2Pattern()
        let digit0 = getDigit0Pattern()
        
        let digitRows = digit5.count
        let digitCols = digit5[0].count
        
        // 强制使用固定的小格子尺寸，不进行自动放大（与红心封面保持一致）
        // 不再根据内容大小调整格子尺寸，保持12px的固定尺寸
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算520在网格中的居中位置
        let totalDigitWidth = digitCols * 3 + 4 // 3个数字 + 间距(2+2格)
        let exactDigitStartRow = (Double(rows) - Double(digitRows)) / 2.0
        let exactDigitStartCol = (Double(cols) - Double(totalDigitWidth)) / 2.0
        
        let centeredDigitStartRow = Int(exactDigitStartRow.rounded())
        let centeredDigitStartCol = Int(exactDigitStartCol.rounded())
        
        // 计算每个数字的起始列
        let digit5StartCol = centeredDigitStartCol
        let digit2StartCol = digit5StartCol + digitCols + 2 // 5后面加2格间距
        let digit0StartCol = digit2StartCol + digitCols + 2 // 2后面加2格间距
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                var isRedGrid = false
                
                // 判断是否在数字5内
                let digitRow = row - centeredDigitStartRow
                let digit5Col = col - digit5StartCol
                if digitRow >= 0 && digitRow < digitRows && digit5Col >= 0 && digit5Col < digitCols {
                    isRedGrid = digit5[digitRow][digit5Col]
                }
                
                // 判断是否在数字2内
                let digit2Col = col - digit2StartCol
                if digitRow >= 0 && digitRow < digitRows && digit2Col >= 0 && digit2Col < digitCols {
                    isRedGrid = isRedGrid || digit2[digitRow][digit2Col]
                }
                
                // 判断是否在数字0内
                let digit0Col = col - digit0StartCol
                if digitRow >= 0 && digitRow < digitRows && digit0Col >= 0 && digit0Col < digitCols {
                    isRedGrid = isRedGrid || digit0[digitRow][digit0Col]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 数字5的图案（7x4网格 - 封面优化版本）
    private func getDigit5Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [true,  false, false, false],
            [true,  false, false, false],
            [true,  true,  true,  true],
            [false, false, false, true],
            [false, false, false, true],
            [true,  true,  true,  true]
        ]
    }
    
    // 数字2的图案（7x4网格 - 封面优化版本）
    private func getDigit2Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [false, false, false, true],
            [false, false, false, true],
            [true,  true,  true,  true],
            [true,  false, false, false],
            [true,  false, false, false],
            [true,  true,  true,  true]
        ]
    }
    
    // 数字0的图案（7x4网格 - 封面优化版本）
    private func getDigit0Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  true,  true,  true]
        ]
    }
}

// 爱心流星雨封面视图
class LoveRainCoverView: UIView {
    
    private var animationTimer: Timer?
    private var hearts: [HeartParticle] = []
    
    struct HeartParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var speed: CGFloat
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 创建初始爱心粒子
        createHearts()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createHearts() {
        hearts.removeAll()
        
        // 创建多个爱心粒子
        for _ in 0..<8 {
            let heart = HeartParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: -50...bounds.height),
                size: CGFloat.random(in: 8...16),
                alpha: CGFloat.random(in: 0.3...0.8),
                speed: CGFloat.random(in: 1...3)
            )
            hearts.append(heart)
        }
    }
    
    private func updateAnimation() {
        // 更新爱心位置
        for i in 0..<hearts.count {
            hearts[i].y += hearts[i].speed
            
            // 如果爱心超出底部，重新从顶部开始
            if hearts[i].y > bounds.height + 20 {
                hearts[i].y = -20
                hearts[i].x = CGFloat.random(in: 0...bounds.width)
                hearts[i].size = CGFloat.random(in: 8...16)
                hearts[i].alpha = CGFloat.random(in: 0.3...0.8)
                hearts[i].speed = CGFloat.random(in: 1...3)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建爱心
        if hearts.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createHearts()
        }
        
        // 绘制爱心粒子
        for heart in hearts {
            drawHeart(at: CGPoint(x: heart.x, y: heart.y), size: heart.size, alpha: heart.alpha)
        }
        
        // 在中心绘制"I LOVE U"文字
        drawCenterText(in: rect)
    }
    
    private func drawHeart(at center: CGPoint, size: CGFloat, alpha: CGFloat) {
        let path = UIBezierPath()
        let heartSize = size
        
        // 简化的爱心形状
        path.move(to: CGPoint(x: center.x, y: center.y + heartSize * 0.3))
        
        path.addCurve(
            to: CGPoint(x: center.x - heartSize * 0.4, y: center.y - heartSize * 0.2),
            controlPoint1: CGPoint(x: center.x - heartSize * 0.4, y: center.y + heartSize * 0.1),
            controlPoint2: CGPoint(x: center.x - heartSize * 0.4, y: center.y - heartSize * 0.1)
        )
        
        path.addArc(
            withCenter: CGPoint(x: center.x - heartSize * 0.2, y: center.y - heartSize * 0.2),
            radius: heartSize * 0.2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addArc(
            withCenter: CGPoint(x: center.x + heartSize * 0.2, y: center.y - heartSize * 0.2),
            radius: heartSize * 0.2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + heartSize * 0.3),
            controlPoint1: CGPoint(x: center.x + heartSize * 0.4, y: center.y - heartSize * 0.1),
            controlPoint2: CGPoint(x: center.x + heartSize * 0.4, y: center.y + heartSize * 0.1)
        )
        
        path.close()
        
        // 设置粉色并绘制
        UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: alpha).setFill()
        path.fill()
    }
    
    private func drawCenterText(in rect: CGRect) {
        let text = "I   LOVE   U"  // 增加单词间距
        let fontSize: CGFloat = min(rect.width, rect.height) * 0.3
        let font = UIFont.systemFont(ofSize: fontSize, weight: .black)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 0.8)
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
}

// 烟花封面视图
class FireworksCoverView: UIView {
    
    private var animationTimer: Timer?
    private var particles: [FireworkParticle] = []
    
    struct FireworkParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var color: UIColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 创建初始烟花粒子
        createParticles()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createParticles() {
        particles.removeAll()
        
        // 创建多个烟花粒子
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),  // 红色
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),  // 金色
            UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0),  // 蓝色
            UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 1.0)   // 粉色
        ]
        
        for _ in 0..<12 {
            let particle = FireworkParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 4...8),
                alpha: CGFloat.random(in: 0.5...1.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(particle)
        }
    }
    
    private func updateAnimation() {
        // 随机改变粒子透明度（闪烁效果）
        for i in 0..<particles.count {
            if Float.random(in: 0...1) < 0.3 {
                particles[i].alpha = CGFloat.random(in: 0.3...1.0)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建粒子
        if particles.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createParticles()
        }
        
        // 绘制烟花粒子
        for particle in particles {
            let particleRect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            
            let path = UIBezierPath(ovalIn: particleRect)
            particle.color.withAlphaComponent(particle.alpha).setFill()
            path.fill()
            
            // 添加发光效果
            let glowPath = UIBezierPath(ovalIn: particleRect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5))
            particle.color.withAlphaComponent(particle.alpha * 0.3).setFill()
            glowPath.fill()
        }
    }
}

// 烟花绽放封面视图
class FireworksBloomCoverView: UIView {
    
    private var animationTimer: Timer?
    private var particles: [BloomParticle] = []
    
    struct BloomParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var color: UIColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 创建初始粒子
        createParticles()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createParticles() {
        particles.removeAll()
        
        // 创建多个烟花绽放粒子（更密集）
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),  // 红色
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),  // 金色
            UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0),  // 蓝色
            UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 1.0),  // 粉色
            UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)   // 绿色
        ]
        
        for _ in 0..<20 {
            let particle = BloomParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 3...6),
                alpha: CGFloat.random(in: 0.5...1.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(particle)
        }
    }
    
    private func updateAnimation() {
        // 随机改变粒子透明度（闪烁效果）
        for i in 0..<particles.count {
            if Float.random(in: 0...1) < 0.4 {
                particles[i].alpha = CGFloat.random(in: 0.3...1.0)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建粒子
        if particles.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createParticles()
        }
        
        // 绘制烟花粒子
        for particle in particles {
            let particleRect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            
            let path = UIBezierPath(ovalIn: particleRect)
            particle.color.withAlphaComponent(particle.alpha).setFill()
            path.fill()
            
            // 添加发光效果
            let glowPath = UIBezierPath(ovalIn: particleRect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5))
            particle.color.withAlphaComponent(particle.alpha * 0.3).setFill()
            glowPath.fill()
        }
    }
}

// 模版分类
enum TemplateCategory: String, CaseIterable {
    case neon = "霓虹灯看板"
    case idol = "偶像应援"
    case ledScreen = "LED横幅"
    case popularAnimation = "热门动画"
    case clock = "数字时钟"
    case other = "其他分类"
    
    var localizedName: String {
        switch self {
        case .neon: return "neon".localized
        case .idol: return "idol".localized
        case .ledScreen: return "led".localized
        case .popularAnimation: return "popularAnimation".localized
        case .clock: return "clock".localized
        case .other: return "other".localized
        }
    }
    
    var titleColor: UIColor {
        switch self {
        case .neon:
            return UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0) // #8EFFE6
        case .idol:
            return UIColor(red: 0xFF/255.0, green: 0x6B/255.0, blue: 0xD6/255.0, alpha: 1.0) // #FF6BD6
        case .ledScreen:
            return UIColor(red: 0x6B/255.0, green: 0xFF/255.0, blue: 0xB0/255.0, alpha: 1.0) // #6BFFB0
        case .popularAnimation:
            return UIColor(red: 0xFF/255.0, green: 0x69/255.0, blue: 0xB4/255.0, alpha: 1.0) // #FF69B4 粉红色
        case .clock, .other:
            return .white
        }
    }
}

// Tab类型
enum TemplateTab: String {
    case popular = "热门模版"
    case animation = "动画模版"
    
    var localizedName: String {
        switch self {
        case .popular: return "popular".localized
        case .animation: return "animation".localized
        }
    }
}

// 模版广场视图控制器
class TemplateSquareViewController: UIViewController {
    
    private var tableView: UITableView!
    private var categories: [TemplateCategory] = []
    private var currentTab: TemplateTab = .popular
    private lazy var segmentedControl: UISegmentedControl = {
        let items = [TemplateTab.popular.localizedName, TemplateTab.animation.localizedName]
        let control = NoAnimationSegmentedControl(items: items)
        
        // 设置深色背景，让主题色更突出
        control.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateCategories()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制恢复竖屏
        AppDelegate.orientationLock = .portrait
        
        // 刷新UI以应用语言更改
        refreshUI()
        
        // 强制刷新布局，修复从横屏返回后卡片尺寸异常的问题
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保分段控制器是胶囊形状（圆角为高度的一半）
        if segmentedControl.bounds.height > 0 {
            segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
            segmentedControl.layer.masksToBounds = true
        }
    }
    
    private func updateCategories() {
        switch currentTab {
        case .popular:
            // 热门模版：霓虹灯看板、偶像应援、LED横幅
            categories = [.neon, .idol, .ledScreen]
        case .animation:
            // 动画模版：热门动画、数字时钟、其他分类
            categories = [.popularAnimation, .clock, .other]
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 隐藏导航栏标题
        title = ""
        
        // 设置导航栏样式 - 统一为纯黑色
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 纯黑背景
        appearance.shadowColor = .clear // 移除阴影
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 设置分段控制器 - 放在导航栏标题位置
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // 未选中状态：白色半透明文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)
        
        // 选中状态：黑色文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        
        // 将分段控制器设置为导航栏的titleView
        navigationItem.titleView = segmentedControl
        
        // 设置分段控制器的固定尺寸（增加高度以显示内边距效果）
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.widthAnchor.constraint(equalToConstant: 220),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40) // 从36增加到40，让选中背景看起来有内边距
        ])
        
        // 创建表格视图
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        
        // 根据屏幕尺寸动态调整contentInset
        let screenHeight = UIScreen.main.bounds.height
        let topInset: CGFloat = screenHeight >= 926 ? 16 : 12 // 大屏设备增加顶部间距
        let bottomInset: CGFloat = screenHeight >= 926 ? 30 : 20 // 大屏设备增加底部间距
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // 表格视图直接从顶部开始
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func segmentChanged() {
        currentTab = segmentedControl.selectedSegmentIndex == 0 ? .popular : .animation
        updateCategories()
        tableView.reloadData()
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    private func refreshUI() {
        // 更新分段控制器的标题
        segmentedControl.setTitle(TemplateTab.popular.localizedName, forSegmentAt: 0)
        segmentedControl.setTitle(TemplateTab.animation.localizedName, forSegmentAt: 1)
        
        // 刷新表格视图以更新分类标题
        tableView.reloadData()
    }
    
    func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension TemplateSquareViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! TemplateCategoryCell
        let category = categories[indexPath.section]
        cell.configure(with: category, tab: currentTab)
        cell.onItemTapped = { [weak self] item in
            self?.handleItemTap(item)
        }
        cell.onVIPSubscriptionNeeded = { [weak self] in
            self?.showVIPSubscription()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let category = categories[indexPath.section]
        
        // 动态计算卡片尺寸，与CollectionView的sizeForItemAt保持一致
        // 卡片宽度 = (屏幕宽度 - 左右边距40 - 中间间距16) / 2
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = (screenWidth - 56) / 2 // 左右各20px，中间16px
        let cardHeight = cardWidth * 0.95 // 与sizeForItemAt中的比例保持一致
        let lineSpacing: CGFloat = 16
        
        switch category {
        case .clock:
            // 时钟分类只有1个卡片，1行
            return cardHeight
        case .popularAnimation:
            // 热门动画分类有6个卡片，3行（2+2+2）
            // 3行卡片 + 2个行间距
            return cardHeight * 3 + lineSpacing * 2
        default:
            // 其他分类有4个卡片，2行（2+2）
            // 2行卡片 + 1个行间距
            return cardHeight * 2 + lineSpacing * 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let category = categories[section]
        
        // 如果是热门动画分类，添加火焰图标
        if category == .popularAnimation {
            // 创建火焰图标视图（使用渐变色）
            let fireIconView = UIView()
            fireIconView.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(fireIconView)
            
            // 创建火焰emoji标签
            let fireLabel = UILabel()
            fireLabel.text = "🔥"
            fireLabel.font = .systemFont(ofSize: 20)
            fireLabel.translatesAutoresizingMaskIntoConstraints = false
            fireIconView.addSubview(fireLabel)
            
            // 标题文字
            let label = UILabel()
            label.text = category.localizedName
            label.textColor = UIColor.white.withAlphaComponent(0.9)
            // 根据屏幕尺寸动态调整字体大小
            let screenHeight = UIScreen.main.bounds.height
            let fontSize: CGFloat = screenHeight >= 926 ? 20 : 18 // 大屏设备使用20pt
            label.font = .systemFont(ofSize: fontSize, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                fireIconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                fireIconView.topAnchor.constraint(equalTo: headerView.topAnchor),
                fireIconView.widthAnchor.constraint(equalToConstant: 24),
                fireIconView.heightAnchor.constraint(equalToConstant: 24),
                
                fireLabel.centerXAnchor.constraint(equalTo: fireIconView.centerXAnchor),
                fireLabel.centerYAnchor.constraint(equalTo: fireIconView.centerYAnchor),
                
                label.leadingAnchor.constraint(equalTo: fireIconView.trailingAnchor, constant: 8),
                label.topAnchor.constraint(equalTo: headerView.topAnchor)
            ])
        } else {
            // 其他分类：标题文字（去掉图标）
            let label = UILabel()
            label.text = category.localizedName
            label.textColor = UIColor.white.withAlphaComponent(0.9) // 白色 0.9透明度
            // 根据屏幕尺寸动态调整字体大小
            let screenHeight = UIScreen.main.bounds.height
            let fontSize: CGFloat = screenHeight >= 926 ? 20 : 18 // 大屏设备使用20pt
            label.font = .systemFont(ofSize: fontSize, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                label.topAnchor.constraint(equalTo: headerView.topAnchor)
            ])
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Header包含：标题 + 标题到卡片的间距
        // 根据屏幕尺寸动态调整
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight >= 926 { // iPhone 14 Pro Max及以上大屏设备
            return 42 // 大屏设备增加header高度
        } else {
            return 36 // 标准高度
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Footer是模块之间的间距
        // 最后一个section不需要footer
        if section == categories.count - 1 {
            return 0
        }
        
        // 根据屏幕尺寸动态调整模块间距
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight >= 926 { // iPhone 14 Pro Max及以上大屏设备
            return 40 // 大屏设备增加间距
        } else {
            return 32 // 标准间距
        }
    }
    
    private func handleItemTap(_ item: LEDItem) {
        // 检查是否需要VIP且用户不是VIP
        if item.isVIPRequired && !VIPManager.shared.isVIP() {
            showVIPPreview(for: item)
            return
        }
        
        // 特殊效果直接跳转
        if item.isHeartGrid {
            // 爱心格子：跳转到爱心格子全屏预览
            AppDelegate.orientationLock = .landscape
            let heartGridVC = HeartGridViewController()
            heartGridVC.modalPresentationStyle = .fullScreen
            present(heartGridVC, animated: true)
        } else if item.isILoveU {
            // I LOVE U：跳转到I LOVE U全屏预览
            AppDelegate.orientationLock = .landscape
            let iLoveUVC = ILoveUViewController()
            iLoveUVC.modalPresentationStyle = .fullScreen
            present(iLoveUVC, animated: true)
        } else if item.is520 {
            // 520：跳转到520全屏预览
            AppDelegate.orientationLock = .landscape
            let view520VC = View520ViewController()
            view520VC.modalPresentationStyle = .fullScreen
            present(view520VC, animated: true)
        } else if item.isLoveRain {
            // 爱心流星雨：跳转到爱心雨动画
            AppDelegate.orientationLock = .landscape
            let loveRainVC = LoveRainViewController()
            loveRainVC.modalPresentationStyle = .fullScreen
            present(loveRainVC, animated: true)
        } else if item.isFlipClock {
            AppDelegate.orientationLock = .landscape
            let clockVC = FlipClockViewController()
            clockVC.modalPresentationStyle = .fullScreen
            present(clockVC, animated: true)
        } else if item.isFireworksBloom {
            let fireworksVC = FireworksBloomViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else if item.isFireworks {
            let fireworksVC = FireworksViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else if currentTab == .popular && (item.isNeonTemplate || item.isIdolTemplate || item.isLEDTemplate) {
            // 热门模版：点击封面直接进入全屏预览（无按钮）
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        } else {
            // 其他：普通LED卡片直接全屏预览
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        }
    }
    
    private func showVIPPreview(for item: LEDItem) {
        // 先进入全屏预览
        AppDelegate.orientationLock = .landscape
        let displayVC = LEDFullScreenViewController(ledItem: item)
        displayVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        present(displayVC, animated: true) {
            // 预览页面显示后，添加VIP遮罩
            let overlayView = VIPPreviewOverlayView()
            overlayView.tag = 999 // 添加tag便于识别和移除
            overlayView.onExitTapped = {
                overlayView.hide {
                    displayVC.dismiss(animated: true)
                }
            }
            overlayView.onBecomeMemberTapped = {
                overlayView.hide {
                    displayVC.dismiss(animated: true) {
                        self.showVIPSubscription()
                    }
                }
            }
            overlayView.show(in: displayVC.view)
        }
    }
    
    private func showVIPSubscription() {
        // 确保在主线程执行，并清理可能存在的遮罩视图
        DispatchQueue.main.async {
            // 移除所有可能的遮罩视图
            self.view.subviews.forEach { subview in
                if subview is VIPPreviewOverlayView {
                    subview.removeFromSuperview()
                }
            }
            
            // 如果当前有模态视图，先关闭
            if self.presentedViewController != nil {
                self.dismiss(animated: false) {
                    self.presentVIPSubscriptionSafely()
                }
            } else {
                self.presentVIPSubscriptionSafely()
            }
        }
    }
    
    private func presentVIPSubscriptionSafely() {
        let vipVC = VIPSubscriptionViewController()
        let nav = UINavigationController(rootViewController: vipVC)
        nav.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(nav, animated: true)
    }
}

// MARK: - 模版分类Cell
class TemplateCategoryCell: UITableViewCell {
    
    private var collectionView: UICollectionView!
    private var items: [LEDItem] = []
    private var currentTab: TemplateTab = .popular
    var onItemTapped: ((LEDItem) -> Void)?
    var onVIPSubscriptionNeeded: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 强制刷新CollectionView布局，修复从横屏返回后尺寸异常的问题
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TemplateItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        collectionView.isScrollEnabled = false
        collectionView.clipsToBounds = false // 关闭裁剪，让底部卡片完全显示
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with category: TemplateCategory, tab: TemplateTab) {
        currentTab = tab
        items = getItems(for: category)
        collectionView.reloadData()
    }
    
    private func getItems(for category: TemplateCategory) -> [LEDItem] {
        let allItems = LEDDataManager.shared.loadItems()
        
        switch category {
        case .popularAnimation:
            // 返回热门动画：爱心格子、爱心雨、烟花、烟花绽放
            var items: [LEDItem] = []
            
            // 爱心格子（新增的第一个卡片）
            var heartGridItem = LEDItem(
                id: "heart-grid-animation",
                text: "红心",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0,
                isVIPRequired: true // 需要VIP
            )
            // 标记为特殊的爱心格子动画
            heartGridItem.isHeartGrid = true
            items.append(heartGridItem)
            
            // I LOVE U（新增的第二个卡片）
            var iLoveUItem = LEDItem(
                id: "i-love-u-animation",
                text: "I LOVE U",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0,
                isVIPRequired: true // 需要VIP
            )
            // 标记为特殊的I LOVE U动画
            iLoveUItem.isILoveU = true
            items.append(iLoveUItem)
            
            // 520（新增的第三个卡片）
            var item520 = LEDItem(
                id: "520-animation",
                text: "520",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0,
                isVIPRequired: true // 需要VIP
            )
            // 标记为特殊的520动画
            item520.is520 = true
            items.append(item520)
            
            // 爱心雨
            if var loveRainItem = allItems.first(where: { $0.isLoveRain }) {
                loveRainItem.isVIPRequired = true // 需要VIP
                items.append(loveRainItem)
            }
            
            // 烟花
            if var fireworksItem = allItems.first(where: { $0.isFireworks }) {
                fireworksItem.isVIPRequired = true // 需要VIP
                items.append(fireworksItem)
            }
            
            // 烟花绽放
            if var fireworksBloomItem = allItems.first(where: { $0.isFireworksBloom }) {
                fireworksBloomItem.isVIPRequired = true // 需要VIP
                items.append(fireworksBloomItem)
            }
            
            return items
        case .clock:
            // 返回翻页时钟和占位符
            var items = allItems.filter { $0.isFlipClock }
            // 如果没有时钟，创建占位符
            if items.isEmpty {
                let clockItem = LEDItem(
                    id: "clock-placeholder",
                    text: "数字时钟",
                    fontSize: 50,
                    textColor: "#8EFFE6",
                    backgroundColor: "#1a1a2e",
                    glowIntensity: 3.0
                )
                items.append(clockItem)
            }
            return items
        case .other:
            // 返回预设卡片 + 用户创建的卡片
            let presetItems = allItems.filter { $0.isDefaultPreset }
            let userItems = allItems.filter { 
                !$0.isFlipClock && !$0.isNeonTemplate && !$0.isIdolTemplate && 
                !$0.isLEDTemplate && !$0.isDefaultPreset && 
                !$0.isFireworks && !$0.isFireworksBloom && !$0.isLoveRain
            }
            // 预设卡片在前，用户创建的在后
            return presetItems + userItems
        case .neon:
            // 霓虹灯看板模版（占位）- 改为4个
            return createPlaceholderItems(category: "neon", count: 4)
        case .idol:
            // 偶像应援模版（占位）- 改为4个
            return createPlaceholderItems(category: "idol", count: 4)
        case .ledScreen:
            // LED屏幕模版（占位）- 改为4个
            return createPlaceholderItems(category: "led", count: 4)
        }
    }
    
    private func createPlaceholderItems(category: String, count: Int) -> [LEDItem] {
        var items: [LEDItem] = []
        
        // 定义每个分类的文字内容
        let texts: [String]
        switch category {
        case "neon":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "idol":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "led":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        default:
            texts = ["TEXT 1", "TEXT 2", "TEXT 3", "TEXT 4"]
        }
        
        // 根据分类设置不同的滚动类型
        let scrollType: LEDItem.ScrollType
        let speed: Double
        switch category {
        case "neon", "idol":
            // 霓虹灯和偶像屏幕：使用闪烁效果
            scrollType = .blink
            speed = 0.5 // 闪烁速度（更快）
        case "led":
            // LED屏幕：从右到左滚动
            scrollType = .scrollLeft
            speed = 2.0 // 滚动速度
        default:
            scrollType = .none
            speed = 1.5
        }
        
        for i in 1...count {
            let text = i <= texts.count ? texts[i - 1] : "TEXT \(i)"
            let imageName = "\(category)_\(i)" // 例如：neon_1, idol_2, led_3
            
            // 根据需求设置VIP标识
            var isVIPRequired = false
            switch category {
            case "neon":
                // 霓虹灯屏幕模块的第1、2、3个需要VIP
                isVIPRequired = (i <= 3)
            case "idol":
                // 偶像屏幕模块的第1、2个需要VIP
                isVIPRequired = (i <= 2)
            case "led":
                // LED屏幕的全部卡片需要VIP
                isVIPRequired = true
            default:
                isVIPRequired = false
            }
            
            let item = LEDItem(
                id: "\(category)-\(i)",
                text: text,
                fontSize: 120, // 进一步增加字体大小到120pt，全屏预览更醒目
                textColor: "#FFFFFF", // 白色
                backgroundColor: "#1a1a2e",
                backgroundImageName: imageName, // 添加背景图片
                glowIntensity: 3.0,
                scrollType: scrollType,
                speed: speed,
                fontName: "PingFangSC-Semibold", // 设置为粗体字体
                isVIPRequired: isVIPRequired
            )
            items.append(item)
        }
        return items
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension TemplateCategoryCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! TemplateItemCell
        let item = items[indexPath.item]
        cell.configure(with: item, tab: currentTab)
        
        if currentTab == .popular {
            // 热门模版：只有试用按钮
            cell.onTryTapped = { [weak self] item in
                // 检查是否需要VIP且用户不是VIP
                if item.isVIPRequired && !VIPManager.shared.isVIP() {
                    self?.onVIPSubscriptionNeeded?()
                    return
                }
                
                // 试用：进入编辑页面
                guard let self = self else { return }
                if let parentVC = self.parentViewController as? TemplateSquareViewController {
                    let createVC = LEDCreateViewController(editingItem: item, isTemplateEdit: true)
                    createVC.onSave = {
                        parentVC.showToast(message: "saved".localized)
                    }
                    let nav = UINavigationController(rootViewController: createVC)
                    nav.modalPresentationStyle = .fullScreen
                    parentVC.present(nav, animated: true)
                }
            }
            
            cell.onPreviewTapped = { [weak self] item in
                // 点击封面：直接进入全屏预览（无按钮）
                self?.onItemTapped?(item)
            }
        } else {
            // 动画模版：点击封面直接进入对应效果
            cell.onPreviewTapped = { [weak self] item in
                self?.onItemTapped?(item)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 动态计算卡片宽度，适配不同屏幕尺寸
        // 2列布局：左右边距各20px，中间间距16px
        let width = (collectionView.bounds.width - 56) / 2
        let height = width * 0.95 // 保持宽高比
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 不再需要，因为点击由cell内部处理
    }
}

// MARK: - 模版项Cell
class TemplateItemCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let overlayTextLabel = UILabel() // 封面图片上的文字
    private let titleLabel = UILabel() // 卡片下方的标题（动画模版用）
    private let containerView = UIView()
    private let buttonStack = UIStackView() // 按钮容器
    private let tryButton = UIButton(type: .system) // 试用按钮
    private let previewButton = UIButton(type: .system) // 预览按钮
    private let vipBadgeView = VIPBadgeView() // VIP标签
    private var currentItem: LEDItem?
    var onTryTapped: ((LEDItem) -> Void)?
    var onPreviewTapped: ((LEDItem) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 容器
        containerView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.18)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = false // 改为false，避免裁剪底部内容
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 图片（16:9比例）
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        containerView.addSubview(imageView)
        
        // 添加点击手势到图片
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tapGesture)
        
        // 封面图片上的文字（霓虹效果）
        overlayTextLabel.textColor = .white
        // 根据屏幕尺寸动态调整字体大小
        let screenHeight = UIScreen.main.bounds.height
        let overlayFontSize: CGFloat = screenHeight >= 926 ? 22 : 20 // 大屏设备使用22pt
        let titleFontSize: CGFloat = screenHeight >= 926 ? 15 : 13 // 大屏设备使用15pt
        let buttonFontSize: CGFloat = screenHeight >= 926 ? 14 : 12 // 大屏设备使用14pt
        let previewFontSize: CGFloat = screenHeight >= 926 ? 13 : 11 // 大屏设备使用13pt
        
        // 封面图片上的文字（霓虹效果）
        overlayTextLabel.textColor = .white
        overlayTextLabel.font = .systemFont(ofSize: overlayFontSize, weight: .bold)
        overlayTextLabel.textAlignment = .center
        overlayTextLabel.numberOfLines = 2
        overlayTextLabel.adjustsFontSizeToFitWidth = true
        overlayTextLabel.minimumScaleFactor = 0.5
        overlayTextLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayTextLabel)
        
        // 标题（动画模版用）
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: titleFontSize, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 按钮容器
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)
        
        // 试用模版按钮（胶囊形状）
        tryButton.setTitle("try".localized, for: .normal)
        tryButton.setTitleColor(.white, for: .normal)
        tryButton.titleLabel?.font = .systemFont(ofSize: buttonFontSize, weight: .medium)
        tryButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.3)
        tryButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        tryButton.layer.masksToBounds = true
        tryButton.layer.borderWidth = 1
        tryButton.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        tryButton.addTarget(self, action: #selector(tryButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(tryButton)
        
        // 预览模版按钮（胶囊形状）
        previewButton.setTitle("preview".localized, for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: previewFontSize, weight: .medium)
        previewButton.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        previewButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        previewButton.layer.masksToBounds = true
        previewButton.layer.borderWidth = 1
        previewButton.layer.borderColor = UIColor.systemPink.cgColor
        previewButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(previewButton)
        
        // VIP标签（右上角）
        vipBadgeView.translatesAutoresizingMaskIntoConstraints = false
        vipBadgeView.isHidden = true // 默认隐藏
        containerView.addSubview(vipBadgeView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 9),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -9),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0),
            
            overlayTextLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            overlayTextLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            overlayTextLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            overlayTextLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            buttonStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            buttonStack.heightAnchor.constraint(equalToConstant: 14), // 高度14px
            
            // VIP标签约束
            vipBadgeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            vipBadgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保按钮始终是胶囊形状（圆角为高度的一半）
        // 使用实际高度来计算，确保完美的胶囊形状
        if tryButton.bounds.height > 0 {
            tryButton.layer.cornerRadius = tryButton.bounds.height / 2
        }
        if previewButton.bounds.height > 0 {
            previewButton.layer.cornerRadius = previewButton.bounds.height / 2
        }
    }
    
    @objc private func imageTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    @objc private func tryButtonTapped() {
        guard let item = currentItem else { return }
        onTryTapped?(item)
    }
    
    @objc private func previewButtonTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    func configure(with item: LEDItem, tab: TemplateTab) {
        currentItem = item
        
        // 移除之前可能添加的所有自定义视图
        imageView.subviews.forEach { subview in
            if subview is HeartGridView || subview is ILoveUView || subview is View520 || subview is LoveRainCoverView || subview is FireworksCoverView || subview is FireworksBloomCoverView {
                subview.removeFromSuperview()
            }
        }
        
        // 如果是爱心格子动画，添加自定义视图
        if item.isHeartGrid {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let heartGridView = HeartGridView()
            heartGridView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(heartGridView)
            
            NSLayoutConstraint.activate([
                heartGridView.topAnchor.constraint(equalTo: imageView.topAnchor),
                heartGridView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                heartGridView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                heartGridView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            heartGridView.setNeedsLayout()
            heartGridView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                heartGridView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是I LOVE U动画，添加自定义视图
        if item.isILoveU {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let iLoveUView = ILoveUView()
            iLoveUView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(iLoveUView)
            
            NSLayoutConstraint.activate([
                iLoveUView.topAnchor.constraint(equalTo: imageView.topAnchor),
                iLoveUView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                iLoveUView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                iLoveUView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            iLoveUView.setNeedsLayout()
            iLoveUView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                iLoveUView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是爱心流星雨动画，添加自定义封面视图
        if item.isLoveRain {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let loveRainCoverView = LoveRainCoverView()
            loveRainCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(loveRainCoverView)
            
            NSLayoutConstraint.activate([
                loveRainCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                loveRainCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                loveRainCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                loveRainCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            loveRainCoverView.setNeedsLayout()
            loveRainCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                loveRainCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是520动画，添加自定义视图
        if item.is520 {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let view520 = View520()
            view520.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(view520)
            
            NSLayoutConstraint.activate([
                view520.topAnchor.constraint(equalTo: imageView.topAnchor),
                view520.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                view520.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                view520.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            view520.setNeedsLayout()
            view520.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                view520.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是烟花动画，添加自定义封面视图
        if item.isFireworks {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let fireworksCoverView = FireworksCoverView()
            fireworksCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(fireworksCoverView)
            
            NSLayoutConstraint.activate([
                fireworksCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                fireworksCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                fireworksCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                fireworksCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            fireworksCoverView.setNeedsLayout()
            fireworksCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                fireworksCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是烟花绽放动画，添加自定义封面视图
        if item.isFireworksBloom {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let fireworksBloomCoverView = FireworksBloomCoverView()
            fireworksBloomCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(fireworksBloomCoverView)
            
            NSLayoutConstraint.activate([
                fireworksBloomCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                fireworksBloomCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                fireworksBloomCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                fireworksBloomCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            fireworksBloomCoverView.setNeedsLayout()
            fireworksBloomCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                fireworksBloomCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        if tab == .popular {
            // 热门模版：只显示试用按钮，隐藏预览按钮和标题
            // 特殊动画（爱心格子、I LOVE U、520、爱心流星雨、烟花、烟花绽放）不显示文字
            if !item.isHeartGrid && !item.isILoveU && !item.is520 && !item.isLoveRain && !item.isFireworks && !item.isFireworksBloom {
                overlayTextLabel.text = item.text
                overlayTextLabel.isHidden = false
            }
            titleLabel.isHidden = true
            buttonStack.isHidden = false
            tryButton.isHidden = false
            previewButton.isHidden = true
            
            // 调整按钮高度
            buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttonStack.addArrangedSubview(tryButton)
            
            // 强制立即布局并更新按钮圆角
            layoutIfNeeded()
            if tryButton.bounds.height > 0 {
                tryButton.layer.cornerRadius = tryButton.bounds.height / 2
            }
        } else {
            // 动画模版：显示标题，隐藏按钮和封面文字
            overlayTextLabel.isHidden = true
            titleLabel.text = item.text
            titleLabel.isHidden = false
            buttonStack.isHidden = true
        }
        
        // 封面图片上的文字添加霓虹效果
        overlayTextLabel.layer.shadowColor = UIColor(red: 255/255.0, green: 31/255.0, blue: 157/255.0, alpha: 0.75).cgColor
        overlayTextLabel.layer.shadowRadius = 20
        overlayTextLabel.layer.shadowOpacity = 1.0
        overlayTextLabel.layer.shadowOffset = .zero
        overlayTextLabel.layer.masksToBounds = false
        
        // 尝试加载图片，如果没有则使用占位颜色（特殊动画除外）
        if !item.isHeartGrid && !item.isILoveU && !item.is520 && !item.isLoveRain && !item.isFireworks && !item.isFireworksBloom {
            if let imageName = item.imageName, !imageName.isEmpty {
                imageView.image = UIImage(named: imageName)
            } else {
                // 使用占位颜色
                imageView.image = nil
                imageView.backgroundColor = UIColor(hex: item.backgroundColor)
            }
        }
        
        // 显示或隐藏VIP标签
        vipBadgeView.isHidden = !item.isVIPRequired
        if item.isVIPRequired {
            vipBadgeView.startShimmering()
        } else {
            vipBadgeView.stopShimmering()
        }
    }
}

// LEDItem扩展：添加模版相关属性
extension LEDItem {
    var isNeonTemplate: Bool {
        return id.hasPrefix("neon-")
    }
    
    var isIdolTemplate: Bool {
        return id.hasPrefix("idol-")
    }
    
    var isLEDTemplate: Bool {
        return id.hasPrefix("led-")
    }
    
    var imageName: String? {
        // 图片命名规则：category_number.png
        // 例如：neon_1.png, idol_2.png, led_3.png, clock_1.png
        if isNeonTemplate {
            return "neon_\(id.replacingOccurrences(of: "neon-", with: ""))"
        } else if isIdolTemplate {
            return "idol_\(id.replacingOccurrences(of: "idol-", with: ""))"
        } else if isLEDTemplate {
            return "led_\(id.replacingOccurrences(of: "led-", with: ""))"
        } else if isFlipClock {
            // 翻页时钟使用 clock_1
            return "clock_1"
        }
        return nil
    }
}

// UIView扩展：获取父视图控制器
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
