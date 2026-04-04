import Foundation
import StoreKit

// MARK: - 统一购买管理器 (StoreKit 2)
// iOS 15.0+ 部署目标，使用 StoreKit 2 处理订阅
@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()
    private init() {}

    // MARK: - Notifications

    /// VIP 状态变更通知（供 UI 层观察）
    static let vipStatusDidChangeNotification = Notification.Name("VIPStatusDidChangeNotification")

    /// 购买完成通知
    static let purchaseDidCompleteNotification = Notification.Name("PurchaseDidCompleteNotification")

    /// 购买失败通知
    static let purchaseDidFailNotification = Notification.Name("PurchaseDidFailNotification")

    // MARK: - Status

    func isVIP() -> Bool {
        return StoreKitManager.shared.isVIP()
    }

    func getVIPStatusText() -> String {
        return StoreKitManager.shared.getStatusText()
    }

    func getVIPButtonText() -> String {
        return isVIP() ? "vipButtonManage".localized : "vipButtonFree".localized
    }

    func isLoading() -> Bool {
        return StoreKitManager.shared.isPurchasing
    }

    // Used by Settings.
    func getSubscriptionTypeText() -> String {
        if let productId = StoreKitManager.shared.getCurrentProductID() {
            switch productId {
            case StoreKitManager.ProductIdentifier.weekly.rawValue:
                return "weeklyMember".localized
            case StoreKitManager.ProductIdentifier.monthly.rawValue:
                return "monthlyMember".localized
            case StoreKitManager.ProductIdentifier.yearly.rawValue:
                return "yearlyMember".localized
            default:
                return ""
            }
        }
        return ""
    }

    // MARK: - Actions

    /// 强制重置购买状态（用于调试或防卡死）
    func forceResetPurchaseState() {
        // StoreKit 2 使用 Task 管理，不需要手动重置
        StoreKitManager.shared.resetLoadingState()
    }

    /// 检查并重置可能的卡死状态
    func checkAndResetIfStuck() {
        if isLoading() {
            print("🔍 检测到可能的卡死状态，强制重置")
            forceResetPurchaseState()
        }
    }

    func restorePurchases() {
        Task { @MainActor in
            do {
                try await StoreKitManager.shared.restorePurchases()
                NotificationCenter.default.post(
                    name: PurchaseManager.purchaseDidCompleteNotification,
                    object: self,
                    userInfo: ["restored": true]
                )
                NotificationCenter.default.post(
                    name: PurchaseManager.vipStatusDidChangeNotification,
                    object: self
                )
            } catch {
                NotificationCenter.default.post(
                    name: PurchaseManager.purchaseDidFailNotification,
                    object: self,
                    userInfo: ["error": error.localizedDescription]
                )
            }
        }
    }

    // StoreKit2 purchase (index matches StoreKitManager.products ordering).
    func purchaseProduct(at index: Int) {
        Task { @MainActor in
            let identifiers = StoreKitManager.ProductIdentifier.allCases
            guard index >= 0, index < identifiers.count else {
                NotificationCenter.default.post(
                    name: PurchaseManager.purchaseDidFailNotification,
                    object: self,
                    userInfo: ["error": "loadingProducts".localized]
                )
                return
            }

            let identifier = identifiers[index]
            guard let product = StoreKitManager.shared.product(for: identifier) else {
                NotificationCenter.default.post(
                    name: PurchaseManager.purchaseDidFailNotification,
                    object: self,
                    userInfo: ["error": "loadingProducts".localized]
                )
                return
            }

            do {
                _ = try await StoreKitManager.shared.purchase(product)
                NotificationCenter.default.post(
                    name: PurchaseManager.purchaseDidCompleteNotification,
                    object: self,
                    userInfo: ["productID": product.id]
                )
                NotificationCenter.default.post(
                    name: PurchaseManager.vipStatusDidChangeNotification,
                    object: self
                )
            } catch {
                if let storeError = error as? StoreError, storeError == .userCancelled {
                    NotificationCenter.default.post(
                        name: PurchaseManager.purchaseDidFailNotification,
                        object: self,
                        userInfo: ["error": storeError.localizedDescription, "cancelled": true]
                    )
                } else {
                    NotificationCenter.default.post(
                        name: PurchaseManager.purchaseDidFailNotification,
                        object: self,
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
    }
}
