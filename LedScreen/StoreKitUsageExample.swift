import SwiftUI
import StoreKit

// MARK: - StoreKit 2 使用示例

/*
 ============================================
 StoreKit 2 完整使用指南
 ============================================
 
 本文件展示了如何在项目中使用 StoreKitManager
 
 */

// MARK: - 1. 基础使用示例

@available(iOS 15.0, *)
class ExampleViewController: UIViewController {
    
    private let storeManager = StoreKitManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 监听购买成功通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseSuccess),
            name: NSNotification.Name("PurchaseSuccess"),
            object: nil
        )
        
        // 监听恢复成功通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestoreSuccess),
            name: NSNotification.Name("RestoreSuccess"),
            object: nil
        )
    }
    
    // MARK: - 加载产品
    func loadProducts() {
        Task {
            await storeManager.loadProducts()
            
            // 产品加载完成后更新UI
            updateProductsUI()
        }
    }
    
    // MARK: - 购买产品
    func purchaseProduct(at index: Int) {
        guard index < storeManager.products.count else { return }
        let product = storeManager.products[index]
        
        Task {
            do {
                let transaction = try await storeManager.purchase(product)
                
                // 购买成功
                showAlert(title: "购买成功", message: "感谢您的支持！")
                
            } catch StoreError.userCancelled {
                // 用户取消，不显示错误
                print("用户取消购买")
                
            } catch StoreError.pending {
                // 等待批准
                showAlert(title: "等待批准", message: "您的购买正在等待批准")
                
            } catch {
                // 其他错误
                showAlert(title: "购买失败", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - 恢复购买
    func restorePurchases() {
        Task {
            do {
                try await storeManager.restorePurchases()
                showAlert(title: "恢复成功", message: "您的购买已恢复")
                
            } catch StoreError.noRestorablePurchases {
                showAlert(title: "提示", message: "没有找到可恢复的购买")
                
            } catch {
                showAlert(title: "恢复失败", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - 检查订阅状态
    func checkSubscriptionStatus() {
        if storeManager.isVIP() {
            print("✅ 用户是VIP")
            
            if let days = storeManager.getRemainingDays() {
                print("📅 剩余天数: \(days)")
            }
            
            if let productId = storeManager.getCurrentProductID() {
                print("🎫 当前订阅: \(productId)")
            }
        } else {
            print("❌ 用户不是VIP")
        }
    }
    
    // MARK: - 更新UI
    private func updateProductsUI() {
        // 更新产品列表UI
        for (index, product) in storeManager.products.enumerated() {
            print("产品 \(index):")
            print("  名称: \(product.displayName)")
            print("  价格: \(product.displayPrice)")
            print("  描述: \(product.description)")
        }
    }
    
    // MARK: - 通知处理
    @objc private func handlePurchaseSuccess(_ notification: Notification) {
        if let productId = notification.userInfo?["productId"] as? String {
            print("✅ 购买成功通知: \(productId)")
            // 更新UI，解锁VIP功能
        }
    }
    
    @objc private func handleRestoreSuccess(_ notification: Notification) {
        print("✅ 恢复成功通知")
        // 更新UI
    }
    
    // MARK: - 辅助方法
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - 2. SwiftUI 使用示例

@available(iOS 15.0, *)
struct SubscriptionView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 订阅状态
            statusSection
            
            // 产品列表
            productsSection
            
            // 操作按钮
            actionsSection
        }
        .padding()
        .task {
            // 视图加载时获取产品
            await storeManager.loadProducts()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 订阅状态区域
    private var statusSection: some View {
        VStack(spacing: 10) {
            Text("订阅状态")
                .font(.headline)
            
            Text(storeManager.getStatusText())
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if storeManager.isVIP(), let days = storeManager.getRemainingDays() {
                Text("剩余 \(days) 天")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - 产品列表区域
    private var productsSection: some View {
        VStack(spacing: 15) {
            ForEach(storeManager.products, id: \.id) { product in
                ProductRow(product: product) {
                    purchaseProduct(product)
                }
            }
        }
    }
    
    // MARK: - 操作按钮区域
    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button("恢复购买") {
                restorePurchases()
            }
            .buttonStyle(.bordered)
            
            Button("管理订阅") {
                storeManager.openManageSubscriptions()
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - 购买产品
    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                _ = try await storeManager.purchase(product)
            } catch StoreError.userCancelled {
                // 用户取消，不显示错误
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    // MARK: - 恢复购买
    private func restorePurchases() {
        Task {
            do {
                try await storeManager.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - 产品行视图
@available(iOS 15.0, *)
struct ProductRow: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(product.displayPrice) {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - 3. 与现有VIPManager集成

/*
 如果需要同时支持 iOS 14 和 iOS 15+，可以使用以下适配器：
 */

class UnifiedStoreManager {
    
    static let shared = UnifiedStoreManager()
    
    // 检查是否是VIP
    func isVIP() -> Bool {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.isVIP()
        } else {
            return VIPManager.shared.isVIP()
        }
    }
    
    // 获取状态文本
    func getStatusText() -> String {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.getStatusText()
        } else {
            return VIPManager.shared.getVIPStatusText()
        }
    }
    
    // 恢复购买
    func restorePurchases(completion: @escaping (Result<Void, Error>) -> Void) {
        if #available(iOS 15.0, *) {
            Task {
                do {
                    try await StoreKitManager.shared.restorePurchases()
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        } else {
            VIPManager.shared.restorePurchases()
            // 监听通知来判断结果
        }
    }
}

// MARK: - 4. 测试辅助工具

@available(iOS 15.0, *)
extension StoreKitManager {
    
    /// 打印所有产品信息（调试用）
    func printAllProducts() {
        print("📦 所有产品:")
        for product in products {
            print("---")
            print("ID: \(product.id)")
            print("名称: \(product.displayName)")
            print("价格: \(product.displayPrice)")
            print("描述: \(product.description)")
            if let subscription = product.subscription {
                print("订阅周期: \(subscription.subscriptionPeriod)")
            }
        }
    }
    
    /// 打印当前交易（调试用）
    func printCurrentTransactions() async {
        print("💳 当前交易:")
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                print("---")
                print("产品ID: \(transaction.productID)")
                print("购买日期: \(transaction.purchaseDate)")
                if let expirationDate = transaction.expirationDate {
                    print("到期日期: \(expirationDate)")
                }
            }
        }
    }
}
