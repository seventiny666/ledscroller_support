# 单机 App 优化方案：交易去重

## 🎯 目标
为单机 App 添加交易去重功能，防止重复处理同一笔交易。

## 📋 为什么需要交易去重？

### 可能出现重复交易的场景：
1. **App 崩溃**: 交易完成后 App 崩溃，重启后再次收到交易回调
2. **网络异常**: 网络不稳定导致交易状态多次回调
3. **系统重启**: iOS 系统重启后，未完成的交易会重新回调
4. **多次恢复购买**: 用户多次点击恢复购买

### 不去重的风险：
- ⚠️ 可能多次发放权益（虽然对订阅影响不大）
- ⚠️ 可能发送多次成功通知
- ⚠️ 日志混乱，难以追踪问题

## 💡 实现方案

### 方案 1: 使用 UserDefaults（推荐）

**优点**:
- 实现简单
- 性能好
- 适合单机 App

**缺点**:
- 可以被用户清除（但清除后恢复购买会重新验证）

### 方案 2: 使用 Keychain

**优点**:
- 更安全
- 卸载 App 后仍保留

**缺点**:
- 实现稍复杂
- 对单机 App 来说有点过度

## 🔧 实现代码（方案 1）

### 步骤 1: 添加交易去重属性

```swift
// 在 VIPManager 类中添加
extension VIPManager {
    // 已处理的交易ID集合
    private var processedTransactions: Set<String> {
        get {
            let array = userDefaults.stringArray(forKey: "processed_transactions") ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: "processed_transactions")
            userDefaults.synchronize()
        }
    }
    
    // 检查交易是否已处理
    private func isTransactionProcessed(_ transactionID: String) -> Bool {
        return processedTransactions.contains(transactionID)
    }
    
    // 标记交易为已处理
    private func markTransactionAsProcessed(_ transactionID: String) {
        var processed = processedTransactions
        processed.insert(transactionID)
        
        // 只保留最近 100 个交易ID，避免数据过大
        if processed.count > 100 {
            let sorted = Array(processed).sorted()
            processed = Set(sorted.suffix(100))
        }
        
        processedTransactions = processed
        print("✅ 交易已标记为已处理: \(transactionID)")
    }
    
    // 清理过期的交易记录（可选，在 App 启动时调用）
    func cleanupOldTransactions() {
        // 清空所有交易记录（因为恢复购买会重新验证）
        // 或者只保留最近 30 天的
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        // 这里简化处理，直接清空
        // processedTransactions = []
    }
}
```

### 步骤 2: 修改交易处理逻辑

```swift
extension VIPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("🔍 收到 \(transactions.count) 个交易更新")
        
        for transaction in transactions {
            print("🔍 处理交易: \(transaction.payment.productIdentifier), 状态: \(transaction.transactionState.rawValue)")
            
            // 获取交易ID
            let transactionID = transaction.transactionIdentifier ?? ""
            
            switch transaction.transactionState {
            case .purchased:
                // 检查是否已处理
                if !transactionID.isEmpty && isTransactionProcessed(transactionID) {
                    print("⚠️ 交易已处理过，跳过: \(transactionID)")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    continue
                }
                
                // 处理购买
                handleSuccessfulPurchase(productID: transaction.payment.productIdentifier)
                
                // 标记为已处理
                if !transactionID.isEmpty {
                    markTransactionAsProcessed(transactionID)
                }
                
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .restored:
                // 恢复购买也需要去重
                if !transactionID.isEmpty && isTransactionProcessed(transactionID) {
                    print("⚠️ 恢复的交易已处理过，跳过: \(transactionID)")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    continue
                }
                
                handleSuccessfulPurchase(productID: transaction.payment.productIdentifier)
                
                if !transactionID.isEmpty {
                    markTransactionAsProcessed(transactionID)
                }
                
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                if let error = transaction.error as? SKError {
                    if error.code != .paymentCancelled {
                        handleFailedPurchase(error: error)
                    } else {
                        // 用户取消购买
                        DispatchQueue.main.async {
                            self.isLoading = false
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
}
```

### 步骤 3: 在 App 启动时清理（可选）

```swift
// 在 AppDelegate 或 SceneDelegate 中调用
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 清理过期的交易记录（可选）
    VIPManager.shared.cleanupOldTransactions()
    
    return true
}
```

## 🧪 测试方案

### 测试场景 1: 正常购买
1. 购买一个订阅
2. 检查交易ID是否被记录
3. 验证权益正常到账

### 测试场景 2: 重复交易
1. 购买后立即杀掉 App
2. 重启 App
3. 验证不会重复发放权益

### 测试场景 3: 恢复购买
1. 删除 App 重装
2. 点击恢复购买
3. 验证权益正常恢复
4. 再次点击恢复购买
5. 验证不会重复处理

### 测试场景 4: 多次恢复
1. 连续多次点击恢复购买
2. 验证只处理一次

## 📊 性能影响

- **内存占用**: 约 1-2 KB（100个交易ID）
- **存储占用**: 约 1-2 KB
- **性能影响**: 可忽略不计

## 🔍 调试日志

添加后的日志输出示例：
```
🔍 收到 1 个交易更新
🔍 处理交易: com.ledscreen.vip.weekly, 状态: 1
✅ 交易已标记为已处理: 1000000123456789
购买成功: com.ledscreen.vip.weekly

// 如果重复收到同一交易
🔍 收到 1 个交易更新
🔍 处理交易: com.ledscreen.vip.weekly, 状态: 1
⚠️ 交易已处理过，跳过: 1000000123456789
```

## ⚠️ 注意事项

### 1. 交易ID 为空的情况
某些情况下 `transactionIdentifier` 可能为 nil，需要处理：
```swift
let transactionID = transaction.transactionIdentifier ?? ""
if transactionID.isEmpty {
    print("⚠️ 交易ID为空，无法去重")
    // 仍然处理交易，但不记录
}
```

### 2. 恢复购买的特殊处理
恢复购买时，如果用户真的需要重新恢复（比如重装 App），需要允许处理：
```swift
// 可以在恢复购买时清空已处理记录
func restorePurchases() {
    // 清空记录，允许重新处理
    // processedTransactions = []
    
    // 然后调用恢复
    SKPaymentQueue.default().restoreCompletedTransactions()
}
```

### 3. 数据迁移
如果之前没有去重，现在添加后，不会影响已有用户：
- 新交易会被记录
- 旧交易不会被重复处理（因为已经完成）

## 📝 完整代码示例

将以上代码整合到 `VIPManager` 中：

```swift
// MARK: - 交易去重
extension VIPManager {
    private var processedTransactions: Set<String> {
        get {
            let array = userDefaults.stringArray(forKey: "processed_transactions") ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: "processed_transactions")
            userDefaults.synchronize()
        }
    }
    
    private func isTransactionProcessed(_ transactionID: String) -> Bool {
        return processedTransactions.contains(transactionID)
    }
    
    private func markTransactionAsProcessed(_ transactionID: String) {
        var processed = processedTransactions
        processed.insert(transactionID)
        
        if processed.count > 100 {
            let sorted = Array(processed).sorted()
            processed = Set(sorted.suffix(100))
        }
        
        processedTransactions = processed
        print("✅ 交易已标记为已处理: \(transactionID)")
    }
    
    func cleanupOldTransactions() {
        // 可选：清理过期记录
    }
}
```

## ✅ 实施检查清单

- [ ] 添加 `processedTransactions` 属性
- [ ] 实现 `isTransactionProcessed` 方法
- [ ] 实现 `markTransactionAsProcessed` 方法
- [ ] 修改 `paymentQueue` 方法添加去重逻辑
- [ ] 测试正常购买流程
- [ ] 测试重复交易场景
- [ ] 测试恢复购买流程
- [ ] 添加调试日志
- [ ] 代码审查
- [ ] 提交代码

## 🎯 预期效果

添加交易去重后：
- ✅ 防止重复处理交易
- ✅ 提升系统稳定性
- ✅ 日志更清晰
- ✅ 用户体验更好

## 📚 参考资料

- [Apple: Finishing a Transaction](https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/finishing_a_transaction)
- [Apple: Persisting a Purchase](https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/persisting_a_purchase)
