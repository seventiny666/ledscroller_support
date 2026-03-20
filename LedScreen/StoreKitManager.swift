import Foundation
import StoreKit

// MARK: - StoreKit 2 订阅管理器
@available(iOS 15.0, *)
@MainActor
class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    // MARK: - 产品ID定义
    enum ProductIdentifier: String, CaseIterable {
        case weekly = "com.ledscreen.vip.weekly"
        case monthly = "com.ledscreen.vip.monthly"
        case yearly = "com.ledscreen.vip.yearly"
        
        var displayName: String {
            switch self {
            case .weekly: return "weeklySubscription".localized
            case .monthly: return "monthlySubscription".localized
            case .yearly: return "yearlySubscription".localized
            }
        }
    }
    
    // MARK: - 订阅状态
    enum SubscriptionStatus {
        case notSubscribed
        case subscribed(expirationDate: Date, productId: String)
        case expired
        case inGracePeriod(expirationDate: Date)
        case inBillingRetry
    }
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published private(set) var isLoading = false
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let productIDs = ProductIdentifier.allCases.map { $0.rawValue }
    
    // MARK: - Initialization
    private init() {
        // 启动交易监听器
        updateListenerTask = listenForTransactions()
        
        // 加载产品和订阅状态
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 加载产品
    func loadProducts() async {
        do {
            print("🛒 开始加载产品...")
            isLoading = true
            
            // 使用 StoreKit 2 API 获取产品
            let loadedProducts = try await Product.products(for: productIDs)
            
            // 按价格排序（从低到高）
            products = loadedProducts.sorted { $0.price < $1.price }
            
            print("✅ 成功加载 \(products.count) 个产品")
            for product in products {
                print("   - \(product.displayName): \(product.displayPrice)")
            }
            
            isLoading = false
        } catch {
            print("❌ 加载产品失败: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // MARK: - 购买产品
    func purchase(_ product: Product) async throws -> Transaction? {
        print("🛍️ 开始购买: \(product.displayName)")
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        // 执行购买
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // 验证交易
            let transaction = try checkVerified(verification)
            
            // 更新订阅状态
            await updateSubscriptionStatus()
            
            // 完成交易
            await transaction.finish()
            
            print("✅ 购买成功: \(product.displayName)")
            
            // 发送购买成功通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PurchaseSuccess"),
                object: nil,
                userInfo: ["productId": product.id]
            )
            
            return transaction
            
        case .userCancelled:
            print("⚠️ 用户取消购买")
            throw StoreError.userCancelled
            
        case .pending:
            print("⏳ 购买等待批准")
            throw StoreError.pending
            
        @unknown default:
            print("❌ 未知的购买结果")
            throw StoreError.unknown
        }
    }
    
    // MARK: - 恢复购买
    func restorePurchases() async throws {
        print("🔄 开始恢复购买...")
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        // StoreKit 2 会自动同步购买记录
        try await AppStore.sync()
        
        // 更新订阅状态
        await updateSubscriptionStatus()
        
        if subscriptionStatus != .notSubscribed {
            print("✅ 恢复购买成功")
            
            // 发送恢复成功通知
            NotificationCenter.default.post(
                name: NSNotification.Name("RestoreSuccess"),
                object: nil
            )
        } else {
            print("⚠️ 没有找到可恢复的购买")
            throw StoreError.noRestorablePurchases
        }
    }
    
    // MARK: - 更新订阅状态
    func updateSubscriptionStatus() async {
        var highestStatus: SubscriptionStatus = .notSubscribed
        var highestProduct: Product?
        var highestExpirationDate: Date?
        
        // 检查所有订阅产品的状态
        for product in products {
            guard let statuses = try? await product.subscription?.status else {
                continue
            }
            
            for status in statuses {
                switch status.state {
                case .subscribed:
                    // 验证交易
                    if let transaction = try? checkVerified(status.transaction) {
                        if let expirationDate = transaction.expirationDate {
                            // 找到最晚过期的订阅
                            if highestExpirationDate == nil || expirationDate > highestExpirationDate! {
                                highestExpirationDate = expirationDate
                                highestProduct = product
                                highestStatus = .subscribed(
                                    expirationDate: expirationDate,
                                    productId: product.id
                                )
                            }
                        }
                    }
                    
                case .expired:
                    if highestStatus == .notSubscribed {
                        highestStatus = .expired
                    }
                    
                case .inGracePeriod:
                    if let transaction = try? checkVerified(status.transaction),
                       let expirationDate = transaction.expirationDate {
                        highestStatus = .inGracePeriod(expirationDate: expirationDate)
                    }
                    
                case .inBillingRetryPeriod:
                    highestStatus = .inBillingRetry
                    
                case .revoked:
                    print("⚠️ 订阅已被撤销")
                    
                @unknown default:
                    break
                }
            }
        }
        
        subscriptionStatus = highestStatus
        
        // 更新已购买的产品ID集合
        if let productId = highestProduct?.id {
            purchasedProductIDs.insert(productId)
        }
        
        // 打印当前订阅状态
        printSubscriptionStatus()
    }
    
    // MARK: - 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 监听所有交易更新
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // 更新订阅状态
                    await self.updateSubscriptionStatus()
                    
                    // 完成交易
                    await transaction.finish()
                    
                    print("🔔 交易更新: \(transaction.productID)")
                } catch {
                    print("❌ 交易验证失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // 交易验证失败
            throw StoreError.failedVerification
        case .verified(let safe):
            // 交易验证成功
            return safe
        }
    }
    
    // MARK: - 辅助方法
    
    /// 检查是否是VIP用户
    func isVIP() -> Bool {
        switch subscriptionStatus {
        case .subscribed, .inGracePeriod:
            return true
        default:
            return false
        }
    }
    
    /// 获取订阅到期日期
    func getExpirationDate() -> Date? {
        switch subscriptionStatus {
        case .subscribed(let expirationDate, _):
            return expirationDate
        case .inGracePeriod(let expirationDate):
            return expirationDate
        default:
            return nil
        }
    }
    
    /// 获取剩余天数
    func getRemainingDays() -> Int? {
        guard let expirationDate = getExpirationDate() else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
    
    /// 获取当前订阅的产品ID
    func getCurrentProductID() -> String? {
        switch subscriptionStatus {
        case .subscribed(_, let productId):
            return productId
        default:
            return nil
        }
    }
    
    /// 获取订阅状态文本
    func getStatusText() -> String {
        switch subscriptionStatus {
        case .notSubscribed:
            return "vipStatusFree".localized
        case .subscribed(let expirationDate, _):
            let days = getRemainingDays() ?? 0
            return String(format: "vipStatusSubscribed".localized, days)
        case .expired:
            return "订阅已过期"
        case .inGracePeriod(let expirationDate):
            return "宽限期：\(expirationDate.formatted())"
        case .inBillingRetry:
            return "续订失败，请更新付款方式"
        }
    }
    
    /// 打印订阅状态（调试用）
    private func printSubscriptionStatus() {
        print("📊 当前订阅状态:")
        switch subscriptionStatus {
        case .notSubscribed:
            print("   - 未订阅")
        case .subscribed(let expirationDate, let productId):
            print("   - 已订阅")
            print("   - 产品ID: \(productId)")
            print("   - 到期日期: \(expirationDate.formatted())")
            print("   - 剩余天数: \(getRemainingDays() ?? 0)")
        case .expired:
            print("   - 已过期")
        case .inGracePeriod(let expirationDate):
            print("   - 宽限期")
            print("   - 到期日期: \(expirationDate.formatted())")
        case .inBillingRetry:
            print("   - 续订重试中")
        }
    }
    
    /// 打开订阅管理页面
    func openManageSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Store Errors
@available(iOS 15.0, *)
enum StoreError: LocalizedError {
    case failedVerification
    case userCancelled
    case pending
    case unknown
    case noRestorablePurchases
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        case .userCancelled:
            return "用户取消购买"
        case .pending:
            return "购买等待批准"
        case .unknown:
            return "未知错误"
        case .noRestorablePurchases:
            return "没有找到可恢复的购买"
        }
    }
}

// MARK: - StoreKit 1 兼容层（用于 iOS 14 及以下）
class StoreKitLegacyManager: NSObject {
    static let shared = StoreKitLegacyManager()
    
    // 检查是否支持 StoreKit 2
    static var isStoreKit2Available: Bool {
        if #available(iOS 15.0, *) {
            return true
        }
        return false
    }
    
    // 获取合适的管理器
    static func getManager() -> Any {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared
        } else {
            // 返回旧的 VIPManager（StoreKit 1）
            return VIPManager.shared
        }
    }
    
    // MARK: - 统一接口方法（无需可用性检查）
    
    /// 检查是否是VIP（统一接口）
    func checkVIPStatus() -> Bool {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.isVIP()
        }
        return false
    }
    
    /// 获取VIP状态文本（统一接口）
    func getVIPStatusText() -> String {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.getStatusText()
        }
        return ""
    }
    
    /// 获取产品数量（统一接口）
    func getProductCount() -> Int {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.products.count
        }
        return 0
    }
    
    /// 获取产品列表（统一接口）
    @available(iOS 15.0, *)
    func getProducts() -> [Any] {
        return StoreKitManager.shared.products
    }
    
    /// 购买产品（统一接口）
    @available(iOS 15.0, *)
    func purchase(productIndex: Int) async throws -> Any? {
        let products = StoreKitManager.shared.products
        guard productIndex < products.count else { return nil }
        return try await StoreKitManager.shared.purchase(products[productIndex])
    }
    
    /// 恢复购买（统一接口）
    @available(iOS 15.0, *)
    func restorePurchases() async throws {
        try await StoreKitManager.shared.restorePurchases()
    }
    
    /// 加载产品（统一接口）
    @available(iOS 15.0, *)
    func loadProducts() async {
        await StoreKitManager.shared.loadProducts()
    }
    
    /// 更新订阅状态（统一接口）
    @available(iOS 15.0, *)
    func updateSubscriptionStatus() async {
        await StoreKitManager.shared.updateSubscriptionStatus()
    }
}
