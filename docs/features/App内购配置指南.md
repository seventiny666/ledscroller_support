# App 内购配置指南

## 当前状态

从日志中看到：`成功加载 0 个产品`

这表示 StoreKit 请求成功了，但是 App Store 返回的产品列表为空。

## 问题原因

产品列表为空通常是因为：

1. **产品ID未在 App Store Connect 中配置**
2. **产品状态不正确**（需要是"准备提交"状态）
3. **Bundle ID 不匹配**
4. **协议未签署**（需要签署付费应用协议）

## 解决步骤

### 1. 登录 App Store Connect

访问：https://appstoreconnect.apple.com

### 2. 配置产品ID

1. 进入你的 App
2. 点击"功能" → "App 内购买项目"
3. 点击"+"创建新的订阅群组（如果还没有）
4. 在订阅群组中添加以下3个产品：

#### 周订阅
- **产品ID**: `com.seventiny.ledscroller.vip.weekly`
- **引用名称**: Weekly VIP Subscription
- **订阅时长**: 1周
- **价格**: $2.99（或你想要的价格）
- **免费试用**: 3天

#### 月订阅
- **产品ID**: `com.seventiny.ledscroller.vip.monthly`
- **引用名称**: Monthly VIP Subscription
- **订阅时长**: 1个月
- **价格**: $7.99（或你想要的价格）

#### 年订阅
- **产品ID**: `com.seventiny.ledscroller.vip.yearly`
- **引用名称**: Yearly VIP Subscription
- **订阅时长**: 1年
- **价格**: $29.99（或你想要的价格）

### 3. 设置产品信息

对每个产品：
1. 添加本地化信息（至少英文和中文）
2. 设置显示名称和描述
3. 上传审核截图（如果需要）
4. 保存并提交审核

### 4. 确保产品状态

每个产品的状态应该是：
- ✅ **准备提交** 或 **已批准**
- ❌ 不能是"草稿"或"被拒绝"

### 5. 签署协议

1. 在 App Store Connect 首页
2. 点击"协议、税务和银行业务"
3. 确保已签署"付费应用协议"
4. 填写税务和银行信息

### 6. 创建沙盒测试账号

1. 在 App Store Connect 中
2. 点击"用户和访问" → "沙盒测试员"
3. 创建测试账号（使用不同于你 Apple ID 的邮箱）
4. 在设备上登录沙盒账号：
   - 设置 → App Store → 沙盒账号

## 测试步骤

### 1. 使用沙盒账号测试

```
设置 → App Store → 沙盒账号 → 登录测试账号
```

### 2. 运行 App

- 打开 VIP 订阅界面
- 应该能看到3个订阅选项和价格
- 点击订阅按钮
- 会弹出 Apple 的购买确认对话框
- 使用沙盒账号密码确认

### 3. 测试恢复购买

- 完成一次购买后
- 删除 App 重新安装
- 点击"恢复购买"
- 应该能恢复之前的订阅

## 当前代码实现

### 产品ID定义

```swift
enum ProductID: String, CaseIterable {
    case weekly = "com.seventiny.ledscroller.vip.weekly"
    case monthly = "com.seventiny.ledscroller.vip.monthly"
    case yearly = "com.seventiny.ledscroller.vip.yearly"
}
```

### 功能已实现

- ✅ 产品加载
- ✅ 购买流程
- ✅ 恢复购买
- ✅ 订阅状态管理
- ✅ 免费试用（周订阅）
- ✅ 交易验证
- ✅ 多语言支持

### 测试日志

正常情况下应该看到：
```
成功加载 3 个产品
   - Weekly: $2.99
   - Monthly: $7.99
   - Yearly: $29.99
```

当前看到：
```
成功加载 0 个产品  ← 需要在 App Store Connect 配置产品
```

## 常见问题

### Q: 为什么产品列表为空？
A: 需要在 App Store Connect 中配置产品ID，并确保状态是"准备提交"。

### Q: 测试时需要真实付款吗？
A: 不需要。使用沙盒测试账号，所有购买都是模拟的，不会真实扣款。

### Q: 如何测试免费试用？
A: 沙盒环境下，免费试用期会被压缩（3天变成3分钟），方便测试。

### Q: 产品配置后多久生效？
A: 通常几分钟到几小时。如果还是看不到，尝试：
- 重启 App
- 重启设备
- 检查网络连接
- 确认 Bundle ID 匹配

## 下一步

1. **立即**: 在 App Store Connect 配置3个产品ID
2. **然后**: 创建沙盒测试账号
3. **最后**: 在设备上测试购买流程

配置完成后，App 的订阅功能就可以正常工作了！
