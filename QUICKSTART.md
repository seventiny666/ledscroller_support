# GlowLed 快速开始指南

## 🚀 5 分钟上手

### 第一步：打开项目
```bash
# 在 Finder 中打开项目文件夹
open /Users/seven/Documents/appyingyong/GlowLedIos

# 或直接用 Xcode 打开
open /Users/seven/Documents/appyingyong/GlowLedIos/GlowLed.xcodeproj
```

### 第二步：配置 Xcode
1. 打开 `GlowLed.xcodeproj`
2. 选择项目根节点（蓝色图标）
3. 在 `Signing & Capabilities` 标签页：
   - 勾选 `Automatically manage signing`
   - 选择你的 Apple ID 团队
4. 如果没有 Apple ID：
   - 点击 `Add Account...`
   - 登录你的 Apple ID（免费账号即可）

### 第三步：运行项目
1. 选择目标设备：
   - 模拟器：`iPhone 15 Pro` 或任意 iOS 15+ 设备
   - 真机：连接你的 iPhone 并选择
2. 点击左上角的 ▶️ 按钮（或按 ⌘R）
3. 等待编译完成（首次约 30 秒）

### 第四步：体验功能

#### 基础功能测试
1. **修改文字**：在文本框输入 "Hello World"
2. **调整大小**：拖动"字体大小"滑块
3. **选择颜色**：点击任意颜色圆圈
4. **添加特效**：点击"💖 爱心"按钮
5. **预览效果**：点击"🚀 全屏预览"

#### 代码生成测试（核心功能）
1. 调整好参数后，点击"💻 生成代码"
2. 选择"查看代码"
3. 你会看到类似这样的伪代码：
```swift
GlowLed.create {
    text("Hello World")
    .fontSize(72)
    .neonColor("#FF00FF")
    .glow(0.8)
    .background("#000000")
    
    effects {
        cyber_heart(density: 0.5)
    }
}
```
4. 点击"复制伪代码"或"复制 JSON"
5. 粘贴到备忘录查看

#### 预设模板测试
1. 点击"表白 - I LOVE U"
2. 自动加载预设配置
3. 点击"🚀 全屏预览"查看效果
4. 点击屏幕退出全屏

## 🎨 功能详解

### 主界面控件说明

| 控件 | 功能 | 范围 |
|------|------|------|
| 文字输入框 | 输入要显示的文字 | 任意文本 |
| 字体大小滑块 | 调节文字大小 | 24-120 |
| 霓虹强度滑块 | 调节发光强度 | 0.0-1.0 |
| 颜色按钮 | 选择霓虹颜色 | 6 种预设 |
| 动画分段控件 | 选择动画类型 | 6 种动画 |
| 动画速度滑块 | 调节动画速度 | 0.5-5.0 |
| 特效按钮 | 开关特效 | 4 种特效 |
| 预设按钮 | 加载预设配置 | 4 个模板 |

### 动画效果说明

- **静止**：文字固定在屏幕中央
- **左滚**：文字从右向左滚动
- **右滚**：文字从左向右滚动
- **上滚**：文字从下向上滚动
- **下滚**：文字从上向下滚动
- **故障**：赛博朋克故障风抖动

### 特效说明

- **💖 爱心**：粉色爱心从底部上升
- **🎆 烟花**：多彩烟花随机爆炸
- **☄️ 流星**：蓝色流星从上往下
- **💻 代码雨**：绿色矩阵代码雨

## 🐛 常见问题

### Q1: 编译失败 "No signing certificate"
**解决方案**：
1. 打开项目设置
2. 选择 `Signing & Capabilities`
3. 勾选 `Automatically manage signing`
4. 选择你的 Team（需要登录 Apple ID）

### Q2: 模拟器运行很慢
**解决方案**：
- 特效密度过高会影响性能
- 建议在真机上测试
- 或减少同时开启的特效数量

### Q3: 全屏预览后无法退出
**解决方案**：
- 点击屏幕任意位置即可退出
- 或使用手势从底部上滑

### Q4: 代码生成后无法复制
**解决方案**：
- 确保点击了"复制伪代码"或"复制 JSON"
- 会自动复制到系统剪贴板
- 可以直接粘贴到其他应用

## 💡 使用技巧

### 技巧 1：快速切换配置
使用预设模板快速切换不同场景：
- 表白场景 → 点击"表白 - I LOVE U"
- 节日场景 → 点击"节日 - Happy New Year"
- 极客风格 → 点击"极客 - Code Rain"

### 技巧 2：组合特效
可以同时开启多个特效：
1. 点击"💖 爱心"
2. 再点击"🎆 烟花"
3. 两种特效会同时显示

### 技巧 3：分享配置
1. 调整好参数
2. 点击"💻 生成代码"
3. 选择"复制伪代码"
4. 发送给朋友（朋友可以手动输入参数复现）

### 技巧 4：最佳视觉效果
推荐配置：
- 字体大小：60-80
- 霓虹强度：0.7-0.9
- 背景：黑色
- 特效密度：不超过 2 个同时开启

## 📱 真机测试

### 连接 iPhone
1. 用数据线连接 iPhone 到 Mac
2. iPhone 上点击"信任此电脑"
3. Xcode 中选择你的 iPhone
4. 点击运行

### 首次安装
1. 安装后可能提示"未受信任的开发者"
2. 打开 iPhone `设置` → `通用` → `VPN与设备管理`
3. 点击你的 Apple ID
4. 点击"信任"

## 🎯 下一步

### 自定义开发
如果你想修改代码：

1. **修改颜色**：编辑 `MainViewController.swift` 第 15 行
2. **添加预设**：编辑 `ConfigModel.swift` 第 45 行
3. **调整特效**：编辑 `EffectsRenderer.swift`
4. **修改动画**：编辑 `LEDDisplayViewController.swift`

### 学习资源
- [Swift 官方文档](https://swift.org/documentation/)
- [UIKit 教程](https://developer.apple.com/documentation/uikit)
- [Core Animation 指南](https://developer.apple.com/documentation/quartzcore)

## 🎉 开始创作

现在你已经掌握了 GlowLed 的所有功能，开始创作你的赛博朋克 LED 作品吧！

有问题？查看 `README.md` 获取更多技术细节。
