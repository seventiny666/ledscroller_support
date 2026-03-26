import Foundation
import StoreKit

// MARK: - StoreKit 2 订阅管理器
@available(iOS 15.0, *)
@MainActor
class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    // MARK: - 产品ID定义
    enum ProductIdentifier: String, CaseIterable {
        case weekly = "com.seventiny.ledscroller.vip.weekly"
        case monthly = "com.seventiny.ledscroller.vip.monthly"
        case yearly = "com.seventiny.ledscroller.vip.yearly"
        
        var displayName: String {
            switch self {
            case .weekly: return "weeklySubscription".localized
            case .monthly: return "monthlySubscription".localized
            case .yearly: return "yearlySubscription".localized
            }
        }
    }
    
    // MARK: - 订阅状态
    enum SubscriptionStatus: Equatable {
        case notSubscribed
        case subscribed(expirationDate: Date, productId: String)
        case expired
        case inGracePeriod(expirationDate: Date)
        case inBillingRetry
    }
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed {
        didSet {
            // Persist a lightweight snapshot so cold start has a stable UI state
            // even before StoreKit finishes loading.
            persistStatus(subscriptionStatus)
        }
    }
    // Keep product loading separate from purchase/restore so UI doesn't treat
    // "loading products" as "purchase in progress".
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false

    // Expose products for UIKit callers without importing SwiftUI.
    // UI code reads this when iOS 15+ to show accurate prices.
    var availableProducts: [Product] { products }
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let productIDs = ProductIdentifier.allCases.map { $0.rawValue }
    private var isUpdatingStatus = false
    
    // MARK: - Initialization
    private init() {
        // Restore last known status for a stable cold-start UI; StoreKit will
        // refresh and override this shortly after.
        restorePersistedStatusIfAvailable()

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
    
    // MARK: - Persistence

    private enum PersistKey {
        static let status = "StoreKitManager.subscriptionStatus.v1"
    }

    private struct PersistedStatus: Codable {
        enum Kind: String, Codable {
            case notSubscribed
            case subscribed
            case expired
            case inGracePeriod
            case inBillingRetry
        }

        var kind: Kind
        var expirationTimeInterval: TimeInterval?
        var productId: String?
        var savedAt: TimeInterval
    }

    private func persistStatus(_ status: SubscriptionStatus) {
        let persisted: PersistedStatus
        switch status {
        case .notSubscribed:
            persisted = PersistedStatus(kind: .notSubscribed, expirationTimeInterval: nil, productId: nil, savedAt: Date().timeIntervalSince1970)
        case .subscribed(let expirationDate, let productId):
            persisted = PersistedStatus(kind: .subscribed, expirationTimeInterval: expirationDate.timeIntervalSince1970, productId: productId, savedAt: Date().timeIntervalSince1970)
        case .expired:
            persisted = PersistedStatus(kind: .expired, expirationTimeInterval: nil, productId: nil, savedAt: Date().timeIntervalSince1970)
        case .inGracePeriod(let expirationDate):
            persisted = PersistedStatus(kind: .inGracePeriod, expirationTimeInterval: expirationDate.timeIntervalSince1970, productId: nil, savedAt: Date().timeIntervalSince1970)
        case .inBillingRetry:
            persisted = PersistedStatus(kind: .inBillingRetry, expirationTimeInterval: nil, productId: nil, savedAt: Date().timeIntervalSince1970)
        }

        do {
            let data = try JSONEncoder().encode(persisted)
            UserDefaults.standard.set(data, forKey: PersistKey.status)
        } catch {
            // Best-effort only; don't fail purchase flows due to persistence.
            print("⚠️ Persist subscription status failed: \(error)")
        }
    }

    private func restorePersistedStatusIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: PersistKey.status) else { return }
        guard let persisted = try? JSONDecoder().decode(PersistedStatus.self, from: data) else { return }

        switch persisted.kind {
        case .notSubscribed:
            subscriptionStatus = .notSubscribed
        case .expired:
            subscriptionStatus = .expired
        case .inBillingRetry:
            subscriptionStatus = .inBillingRetry
        case .subscribed:
            if let t = persisted.expirationTimeInterval, let pid = persisted.productId {
                let date = Date(timeIntervalSince1970: t)
                subscriptionStatus = .subscribed(expirationDate: date, productId: pid)
                if date <= Date() {
                    subscriptionStatus = .expired
                }
            }
        case .inGracePeriod:
            if let t = persisted.expirationTimeInterval {
                let date = Date(timeIntervalSince1970: t)
                subscriptionStatus = .inGracePeriod(expirationDate: date)
                if date <= Date() {
                    subscriptionStatus = .expired
                }
            }
        }
    }

    // MARK: - Product Lookup

    func product(for identifier: ProductIdentifier) -> Product? {
        return products.first(where: { $0.id == identifier.rawValue })
    }

    // MARK: - 加载产品
    func loadProducts() async {
        do {
            print("🛒 开始加载产品...")
            isLoadingProducts = true

            // Notify UIKit so it can show a "loading" state instead of falling back
            // to hardcoded prices.
            NotificationCenter.default.post(name: NSNotification.Name("ProductsLoading"), object: self)
            
            // 使用 StoreKit 2 API 获取产品
            let loadedProducts = try await Product.products(for: productIDs)
            
            // Keep ordering stable and aligned with UI selection indices.
            // Do NOT sort by price; promotional pricing can change the order.
            let order = ProductIdentifier.allCases.map { $0.rawValue }
            products = loadedProducts.sorted {
                (order.firstIndex(of: $0.id) ?? Int.max) < (order.firstIndex(of: $1.id) ?? Int.max)
            }

            // Bridge to legacy UIKit observers (TemplateSquareViewController.swift listens for this).
            NotificationCenter.default.post(name: NSNotification.Name("ProductsDidLoad"), object: self)
            
            if products.isEmpty {
                #if targetEnvironment(simulator)
                print("⚠️ 成功加载 0 个产品（模拟器未启用 StoreKit Configuration 时这是预期现象）")
                #else
                print("⚠️ 成功加载 0 个产品（请检查 App Store Connect 商品ID/网络/沙盒账号）")
                #endif

                // Let UIKit show a friendly hint.
                NotificationCenter.default.post(
                    name: NSNotification.Name("ProductsLoadFailed"),
                    object: self,
                    userInfo: [
                        "reason": "empty",
                        "message": "StoreKit products are empty. On simulator, set a StoreKit Configuration in the scheme." 
                    ]
                )
            } else {
                print("✅ 成功加载 \(products.count) 个产品")
            }
            for product in products {
                print("   - \(product.displayName): \(product.displayPrice)")
            }
            
            isLoadingProducts = false
        } catch {
            print("❌ 加载产品失败: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: NSNotification.Name("ProductsLoadFailed"),
                object: self,
                userInfo: [
                    "reason": "error",
                    "message": error.localizedDescription
                ]
            )
            isLoadingProducts = false
        }
    }
    
    // MARK: - 购买产品
    func purchase(_ product: Product) async throws -> Transaction? {
        print("🛍️ 开始购买: \(product.displayName)")
        isPurchasing = true
        
        defer {
            isPurchasing = false
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
        isPurchasing = true
        
        defer {
            isPurchasing = false
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
        if isUpdatingStatus { return }
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }

        var highestStatus: SubscriptionStatus = .notSubscribed
        var highestProductId: String?
        var highestExpirationDate: Date?

        // Note: `product.subscription?.status` can surface group-level statuses.
        // Always trust the verified transaction's `productID` instead of the loop variable.
        for product in products {
            guard let statuses = try? await product.subscription?.status else {
                continue
            }

            for status in statuses {
                switch status.state {
                case .subscribed:
                    if let transaction = try? checkVerified(status.transaction),
                       let expirationDate = transaction.expirationDate {
                        if highestExpirationDate == nil || expirationDate > highestExpirationDate! {
                            highestExpirationDate = expirationDate
                            highestProductId = transaction.productID
                            highestStatus = .subscribed(
                                expirationDate: expirationDate,
                                productId: transaction.productID
                            )
                        }
                    }

                case .expired:
                    if highestStatus == .notSubscribed {
                        highestStatus = .expired
                    }

                case .inGracePeriod:
                    if let transaction = try? checkVerified(status.transaction),
                       let expirationDate = transaction.expirationDate {
                        // Keep the most recent known expiration for display, even in grace.
                        if highestExpirationDate == nil || expirationDate > highestExpirationDate! {
                            highestExpirationDate = expirationDate
                            highestProductId = transaction.productID
                        }
                        highestStatus = .inGracePeriod(expirationDate: expirationDate)
                    }

                case .inBillingRetryPeriod:
                    highestStatus = .inBillingRetry

                case .revoked:
                    print("⚠️ 订阅已被撤销")

                default:
                    break
                }
            }
        }

        let previousStatus = subscriptionStatus
        subscriptionStatus = highestStatus

        // Only notify/log when something meaningful changed.
        if subscriptionStatus != previousStatus {
            NotificationCenter.default.post(name: VIPManager.vipStatusDidChangeNotification, object: self)
            printSubscriptionStatus()
        }

        if let productId = highestProductId {
            purchasedProductIDs.insert(productId)
        }
    }
    
    // MARK: - 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        // Keep this work on the main actor to avoid crossing isolation boundaries.
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)

                    await updateSubscriptionStatus()
                    await transaction.finish()

                    print("🔔 交易更新: \(transaction.productID)")
                } catch {
                    print("❌ 交易验证失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 验证交易
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
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
        case .subscribed(_, _):
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
@MainActor
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
        return VIPManager.shared.isVIP()
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
