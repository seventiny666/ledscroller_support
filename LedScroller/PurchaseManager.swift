import Foundation
import StoreKit

// Unified purchase facade.
// - iOS 15+: prefers StoreKit 2 for correct subscription entitlement handling.
// - iOS 14: falls back to legacy StoreKit 1 (VIPManager).
//
// This keeps call sites simple (isVIP/restore/purchase) while avoiding
// re-implementing receipt validation without a server.
@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()
    private init() {}

    // MARK: - Notifications (bridge legacy + StoreKit2 to existing UI)

    // Existing screens already observe these VIPManager notifications.
    // Keep them as the UI-facing contract.
    static let vipStatusDidChangeNotification = VIPManager.vipStatusDidChangeNotification
    static let purchaseDidCompleteNotification = VIPManager.purchaseDidCompleteNotification
    static let purchaseDidFailNotification = VIPManager.purchaseDidFailNotification

    // MARK: - Status

    func isVIP() -> Bool {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.isVIP()
        }
        return VIPManager.shared.isVIP()
    }

    func getVIPStatusText() -> String {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.getStatusText()
        }
        return VIPManager.shared.getVIPStatusText()
    }

    func getVIPButtonText() -> String {
        // StoreKit2 does not maintain the legacy button wording; reuse the same UX.
        return isVIP() ? "vipButtonManage".localized : "vipButtonFree".localized
    }

    func isLoading() -> Bool {
        if #available(iOS 15.0, *) {
            return StoreKitManager.shared.isPurchasing
        }
        return VIPManager.shared.isLoading
    }

    // Used by Settings.
    func getSubscriptionTypeText() -> String {
        if #available(iOS 15.0, *) {
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
        return VIPManager.shared.getSubscriptionTypeText()
    }

    // MARK: - Legacy Helpers

    func forceResetPurchaseState() {
        // Legacy only; StoreKit2 has no equivalent.
        if #available(iOS 15.0, *) {
            return
        }
        VIPManager.shared.forceResetPurchaseState()
    }

    func checkAndResetIfStuck() {
        if #available(iOS 15.0, *) {
            return
        }
        VIPManager.shared.checkAndResetIfStuck()
    }

    func startFreeTrialIfAvailable() {
        // StoreKit2: free trial should be configured in App Store Connect and handled by system.
        if #available(iOS 15.0, *) {
            return
        }
        VIPManager.shared.startFreeTrial()
    }

    // MARK: - Actions

    func restorePurchases() {
        if #available(iOS 15.0, *) {
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
            return
        }

        VIPManager.shared.restorePurchases()
    }

    // StoreKit2 purchase (index matches StoreKitManager.products ordering).
    @available(iOS 15.0, *)
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
