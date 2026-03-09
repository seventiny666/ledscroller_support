# LedScreen 架构设计文档

## 项目架构概览

```
┌─────────────────────────────────────────────────────────┐
│                     LedScreen App                         │
├─────────────────────────────────────────────────────────┤
│  UI Layer (UIKit)                                       │
│  ├─ MainViewController (参数调节界面)                   │
│  └─ LEDDisplayViewController (全屏展示界面)             │
├─────────────────────────────────────────────────────────┤
│  Business Logic Layer                                   │
│  ├─ CodeGenerator (代码生成核心)                        │
│  └─ EffectsRenderer (特效渲染引擎)                      │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                             │
│  ├─ ConfigModel (配置数据模型)                          │
│  └─ PresetTemplate (预设模板)                           │
├─────────────────────────────────────────────────────────┤
│  Foundation Layer                                       │
│  ├─ AppDelegate (应用生命周期)                          │
│  └─ SceneDelegate (场景管理)                            │
└─────────────────────────────────────────────────────────┘
```

## 核心模块详解

### 1. ConfigModel.swift - 数据模型层

#### LEDConfig 结构
```swift
struct LEDConfig: Codable {
    var version: String          // 版本号，用于兼容性
    var text: String            // 显示文字
    var style: StyleConfig      // 样式配置
    var effects: [EffectConfig] // 特效配置数组
}
```

**设计理念**：
- 使用 `Codable` 协议支持 JSON 序列化
- 版本号机制保证未来扩展性
- 嵌套结构清晰分离样式和特效

#### StyleConfig 子结构
```swift
struct StyleConfig: Codable {
    var fontSize: CGFloat           // 字体大小
    var color: String              // 颜色（十六进制）
    var glowIntensity: CGFloat     // 发光强度
    var animation: AnimationType   // 动画类型
    var speed: CGFloat             // 动画速度
    var backgroundColor: String    // 背景色
}
```

**关键设计**：
- 颜色使用字符串存储，便于序列化
- 枚举类型保证动画类型安全
- 所有数值类型使用 CGFloat 统一

#### PresetTemplate 预设系统
```swift
struct PresetTemplate {
    let name: String
    let config: LEDConfig
    
    static let templates: [PresetTemplate]
}
```

**优势**：
- 静态数组存储，无需网络请求
- 易于扩展新模板
- 类型安全的配置管理

---

### 2. CodeGenerator.swift - 代码生成引擎

#### 核心功能

##### 2.1 伪代码生成
```swift
static func generatePseudoCode(from config: LEDConfig) -> String
```

**实现原理**：
1. 字符串拼接构建 DSL 风格代码
2. 格式化数值（保留 1 位小数）
3. 条件渲染（动画和特效）

**输出示例**：
```swift
LedScreen.create {
    text("I LOVE U")
    .fontSize(72)
    .neonColor("#FF1493")
    .glow(0.9)
    .background("#000000")
    
    effects {
        cyber_heart(density: 0.6)
    }
}
```

##### 2.2 JSON 生成
```swift
static func generateJSON(from config: LEDConfig) -> String?
```

**特点**：
- 使用 `JSONEncoder` 原生支持
- `prettyPrinted` 格式化输出
- `sortedKeys` 保证顺序一致

##### 2.3 URL Scheme 生成
```swift
static func generateURLScheme(from config: LEDConfig) -> String?
```

**协议设计**：
```
ledscreen://import?code=<base64_encoded_json>
```

**优势**：
- 可点击链接直接导入
- Base64 编码保证 URL 安全
- 支持跨应用分享

---

### 3. MainViewController.swift - 主界面控制器

#### UI 组件架构

```
ScrollView
└── ContentView
    ├── TextField (文字输入)
    ├── Slider (字体大小)
    ├── Slider (霓虹强度)
    ├── ColorButtons (颜色选择)
    ├── SegmentedControl (动画类型)
    ├── Slider (动画速度)
    ├── EffectButtons (特效开关)
    ├── PresetButtons (预设模板)
    └── ActionButtons (预览/生成代码)
```

#### 关键方法

##### 3.1 UI 构建
```swift
private func setupUI()
```
- 使用 Auto Layout 约束布局
- 动态计算 yOffset 垂直排列
- 响应式设计支持不同屏幕

##### 3.2 配置更新
```swift
private func updateConfigFromUI()
```
- 从 UI 控件读取值
- 更新 `currentConfig` 模型
- 单向数据流保证一致性

##### 3.3 代码生成交互
```swift
@objc private func generateCodeTapped()
```
- 调用 `CodeGenerator` 生成代码
- 使用 `UIAlertController` 展示选项
- 支持复制到剪贴板

---

### 4. LEDDisplayViewController.swift - 全屏展示控制器

#### 核心职责
1. 全屏显示 LED 文字
2. 应用霓虹发光效果
3. 执行动画
4. 渲染特效层

#### 关键技术

##### 4.1 霓虹发光实现
```swift
textLabel.layer.shadowColor = color.cgColor
textLabel.layer.shadowRadius = 20 * glowIntensity
textLabel.layer.shadowOpacity = Float(glowIntensity)
textLabel.layer.shadowOffset = .zero
```

**原理**：
- 使用 `CALayer.shadow` 属性
- 阴影颜色与文字颜色一致
- 阴影半径和透明度可调

##### 4.2 滚动动画
```swift
private func animateScrollLeft() {
    textLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    UIView.animate(withDuration: 5.0 / Double(config.style.speed), 
                   options: [.repeat, .curveLinear]) {
        self.textLabel.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
    }
}
```

**特点**：
- 使用 `CGAffineTransform` 变换
- `.repeat` 选项实现循环
- 速度参数控制动画时长

##### 4.3 故障风动画
```swift
private func animateGlitch() {
    Timer.scheduledTimer(withTimeInterval: 0.1 / Double(config.style.speed), repeats: true) { _ in
        let randomX = CGFloat.random(in: -5...5)
        let randomY = CGFloat.random(in: -5...5)
        self.textLabel.transform = CGAffineTransform(translationX: randomX, y: randomY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.textLabel.transform = .identity
        }
    }
}
```

**实现**：
- 定时器触发随机位移
- 短暂延迟后恢复原位
- 模拟赛博朋克故障效果

---

### 5. EffectsRenderer.swift - 特效渲染引擎

#### 架构设计

```
EffectsRenderer (UIView)
├── CADisplayLink (60fps 更新循环)
├── Particle[] (粒子数组)
└── draw(_:) (自定义绘制)
```

#### Particle 粒子系统
```swift
struct Particle {
    var position: CGPoint      // 位置
    var velocity: CGPoint      // 速度
    var size: CGFloat         // 大小
    var color: UIColor        // 颜色
    var alpha: CGFloat        // 透明度
    var type: EffectType      // 类型
}
```

#### 渲染循环

##### 5.1 更新逻辑
```swift
@objc private func update() {
    // 1. 生成新粒子
    for effect in effects {
        if Double.random(in: 0...1) < Double(effect.density) * 0.02 {
            generateParticle(for: effect)
        }
    }
    
    // 2. 更新现有粒子
    particles = particles.compactMap { particle in
        var updated = particle
        updated.position.x += particle.velocity.x
        updated.position.y += particle.velocity.y
        updated.alpha -= 0.01
        
        // 移除屏幕外粒子
        if updated.alpha <= 0 || !bounds.contains(updated.position) {
            return nil
        }
        return updated
    }
    
    // 3. 触发重绘
    setNeedsDisplay()
}
```

**性能优化**：
- 使用 `compactMap` 自动清理无效粒子
- 边界检测避免无用计算
- 透明度衰减自然消失

##### 5.2 特效绘制

**爱心特效**：
```swift
private func drawHeart(at position: CGPoint, size: CGFloat, color: UIColor, in context: CGContext)
```
- 使用 `UIBezierPath` 绘制心形
- 贝塞尔曲线构建平滑轮廓
- 缩放参数适配不同大小

**烟花特效**：
```swift
context.fillEllipse(in: CGRect(...))
```
- 简单圆形粒子
- 随机颜色和方向
- 模拟爆炸扩散

**流星特效**：
```swift
context.move(to: particle.position)
context.addLine(to: CGPoint(x: particle.position.x - particle.velocity.x * 5, ...))
context.strokePath()
```
- 线段绘制拖尾效果
- 速度向量决定尾巴长度

**代码雨特效**：
```swift
text.draw(at: particle.position, withAttributes: attributes)
```
- 随机字符（0/1/A-F）
- 等宽字体模拟终端
- 绿色配色致敬《黑客帝国》

---

## 数据流设计

### 单向数据流

```
User Input → UI Controls → updateConfigFromUI() → currentConfig
                                                        ↓
                                                   CodeGenerator
                                                        ↓
                                                  Generated Code
                                                        ↓
                                                   Clipboard
```

### 预览流程

```
currentConfig → LEDDisplayViewController.init(config:)
                        ↓
                   setupUI()
                        ↓
                   startAnimations()
                        ↓
              EffectsRenderer.startAnimating()
```

---

## 性能优化策略

### 1. 粒子系统优化
- **限制粒子数量**：通过密度参数控制生成频率
- **自动清理**：透明度和边界双重检测
- **批量更新**：使用 `compactMap` 一次性处理

### 2. 渲染优化
- **CADisplayLink**：与屏幕刷新率同步
- **按需绘制**：只在 `update()` 时调用 `setNeedsDisplay()`
- **图层复用**：特效层和文字层分离

### 3. 内存管理
- **弱引用**：Timer 使用 `[weak self]` 避免循环引用
- **及时释放**：`viewWillDisappear` 停止动画
- **结构体优先**：Particle 使用 struct 减少堆分配

---

## 扩展性设计

### 1. 新增特效
```swift
// 1. 在 ConfigModel.swift 添加枚举
enum EffectType: String, Codable {
    case newEffect = "new_effect"
}

// 2. 在 EffectsRenderer.swift 实现生成逻辑
case .newEffect:
    particle = Particle(...)

// 3. 在 draw() 添加绘制逻辑
case .newEffect:
    drawNewEffect(...)
```

### 2. 新增动画
```swift
// 1. 在 ConfigModel.swift 添加枚举
enum AnimationType: String, Codable {
    case newAnimation = "new_animation"
}

// 2. 在 LEDDisplayViewController.swift 实现
case .newAnimation:
    animateNewAnimation()
```

### 3. 新增预设
```swift
// 在 ConfigModel.swift 的 templates 数组添加
PresetTemplate(
    name: "新预设",
    config: LEDConfig(...)
)
```

---

## 安全性考虑

### 1. 代码注入防护
- JSON 解析使用 `Codable` 协议
- 严格类型检查
- 无 `eval()` 或动态执行

### 2. 数据验证
```swift
// 字体大小范围限制
fontSizeSlider.minimumValue = 24
fontSizeSlider.maximumValue = 120

// 颜色格式验证
UIColor(hex: string) // 自动处理非法输入
```

### 3. URL Scheme 安全
- Base64 编码防止注入
- 解析失败返回 nil
- 不执行任意代码

---

## 测试建议

### 单元测试
```swift
// CodeGenerator 测试
func testGeneratePseudoCode() {
    let config = LEDConfig(...)
    let code = CodeGenerator.generatePseudoCode(from: config)
    XCTAssertTrue(code.contains("LedScreen.create"))
}

// JSON 序列化测试
func testJSONRoundTrip() {
    let config = LEDConfig(...)
    let json = CodeGenerator.generateJSON(from: config)
    let parsed = CodeGenerator.parseJSON(json!)
    XCTAssertEqual(config.text, parsed?.text)
}
```

### UI 测试
- 测试所有按钮响应
- 测试滑块范围
- 测试全屏切换
- 测试横竖屏旋转

### 性能测试
- 监控 FPS（目标 60fps）
- 测试粒子数量上限
- 测试内存占用
- 测试电池消耗

---

## 技术债务

### 当前已知问题
1. **特效密度过高时性能下降**
   - 解决方案：添加粒子数量上限
   
2. **代码预览界面无语法高亮**
   - 解决方案：集成第三方语法高亮库

3. **无法导入他人分享的代码**
   - 解决方案：实现 URL Scheme 解析和导入功能

### 未来优化方向
1. 使用 Metal 替代 Core Graphics 提升性能
2. 添加代码分享二维码功能
3. 支持自定义字体
4. 支持渐变色和多色文字
5. 添加音效和触觉反馈

---

## 总结

LedScreen 采用经典的 MVC 架构，清晰分离数据、业务逻辑和 UI 层。核心亮点"代码生成"功能通过 `CodeGenerator` 模块实现，支持三种格式输出。特效系统基于粒子引擎，性能优化良好。整体架构具有良好的扩展性和可维护性。
