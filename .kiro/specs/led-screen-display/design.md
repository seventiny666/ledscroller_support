# LED 屏幕显示功能 - 设计文档

## 概述

LED 屏幕显示功能是一个 iOS 原生应用，将用户的手机屏幕转变为可定制的 LED 显示器。应用采用暗色调霓虹朋克风格设计，提供直观的可视化编辑器和强大的 JavaScript 代码编辑器两种创建方式，支持多种显示效果类型（纯色、渐变、跑马灯、文字滚动、特殊效果等），并通过 iCloud 实现跨设备同步。

### 核心特性

- **双创建入口**: 可视化编辑器（面向普通用户）和 JavaScript 代码编辑器（面向高级用户）
- **瀑布流首页**: 响应式网格布局展示所有模板，带动态缩略图预览
- **霓虹朋克风格**: 深色背景配合霓虹色（粉、蓝、紫、青）和发光效果
- **丰富的显示类型**: 8 种基础显示类型 + 5 种特殊效果模板
- **高级动画系统**: 粒子系统、流星雨、代码雨、烟花、霓虹线条等背景效果
- **iCloud 同步**: 自动同步用户创建的模板到所有设备
- **代码沙箱**: 安全隔离的 JavaScript 执行环境，提供 Canvas API

### 技术栈

- **语言**: Swift 5.5+
- **UI 框架**: SwiftUI（主要）+ UIKit（特定场景）
- **最低支持版本**: iOS 15.0
- **核心框架**:
  - Core Animation: 动画和过渡效果
  - Core Graphics: 2D 绘图和渲染
  - Metal: 高性能粒子系统和复杂效果
  - CloudKit: iCloud 数据同步
  - JavaScriptCore: JavaScript 代码执行

## 架构

### 整体架构

应用采用 MVVM (Model-View-ViewModel) 架构模式，结合 SwiftUI 的声明式 UI 和 Combine 框架的响应式编程。

```
┌─────────────────────────────────────────────────────────────┐
│                         Presentation Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Home View   │  │ Editor Views │  │ Playback View│      │
│  │ (Waterfall)  │  │ (Visual/Code)│  │ (Fullscreen) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModel Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │HomeViewModel │  │EditorViewModel│ │PlaybackViewModel│    │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         Business Logic                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Template     │  │  Rendering   │  │  Animation   │      │
│  │ Manager      │  │  Engine      │  │  System      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Code Sandbox │  │  Effect      │                        │
│  │ (JSCore)     │  │  Processors  │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Local       │  │   iCloud     │  │  Template    │      │
│  │  Storage     │  │   Sync       │  │  Repository  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 模块划分

#### 1. UI 模块 (Presentation)
- **HomeView**: 瀑布流首页，展示模板卡片
- **VisualEditorView**: 可视化配置界面
- **CodeEditorView**: JavaScript 代码编辑器
- **FullscreenPlaybackView**: 全屏播放界面
- **ThemeSystem**: 霓虹朋克主题管理

#### 2. 业务逻辑模块 (Business Logic)
- **TemplateManager**: 模板 CRUD 操作
- **RenderingEngine**: 统一渲染引擎
- **AnimationSystem**: 动画控制和调度
- **CodeSandbox**: JavaScript 执行沙箱
- **EffectProcessors**: 各种效果处理器

#### 3. 数据模块 (Data)
- **TemplateRepository**: 模板数据访问层
- **LocalStorage**: 本地持久化
- **iCloudSyncService**: iCloud 同步服务

## 组件和接口

### 核心数据模型

#### Template (模板)

```swift
struct Template: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: TemplateCategory
    var displayType: DisplayType
    var configuration: DisplayConfiguration
    var thumbnailData: Data?
    var createdAt: Date
    var modifiedAt: Date
    var isSystemPreset: Bool
}

enum TemplateCategory: String, Codable {
    case systemPresets = "预设模板"
    case userCreated = "我的创建"
}
```

#### DisplayType (显示类型)

```swift
enum DisplayType: String, Codable {
    case solidColor = "纯色"
    case gradient = "渐变色"
    case marquee = "跑马灯"
    case blink = "闪烁"
    case textScroll = "文字滚动"
    case breathing = "呼吸灯"
    case specialEffect = "特殊效果"
    case javascriptCode = "JavaScript 代码"
}
```

#### DisplayConfiguration (显示配置)

```swift
struct DisplayConfiguration: Codable {
    var brightness: Float // 0.0 - 1.0
    var animationSpeed: Float // 0.1 - 5.0
    var colors: [Color]
    
    // 文字相关
    var text: String?
    var fontSize: CGFloat?
    var fontStyle: FontStyle?
    var textEffect: TextEffect?
    var scrollDirection: ScrollDirection?
    var backgroundColor: BackgroundStyle?
    
    // 特殊效果相关
    var specialEffect: SpecialEffectType?
    var particleConfig: ParticleConfiguration?
    var backgroundEffects: [BackgroundEffect]
    
    // JavaScript 代码
    var javascriptCode: String?
}

enum FontStyle: String, Codable {
    case system, rounded, monospaced, serif, handwriting
}

enum TextEffect: String, Codable {
    case neonGlow, shadow, stroke, none
}

enum ScrollDirection: String, Codable {
    case left, right, up, down
    case diagonalUpLeft, diagonalUpRight
    case diagonalDownLeft, diagonalDownRight
}

enum BackgroundStyle: String, Codable {
    case solid, gradient, particles, codeRain, meteorShower
}

enum SpecialEffectType: String, Codable {
    case loveConfession = "爱心表白"
    case codeRain = "代码雨"
    case fireworks = "烟花"
    case meteorShower = "流星雨"
    case cheeringLight = "应援灯"
}

enum BackgroundEffect: String, Codable {
    case particles, meteorShower, codeRain, fireworks, neonLines
}
```

#### ParticleConfiguration (粒子配置)

```swift
struct ParticleConfiguration: Codable {
    var particleType: ParticleType
    var color: Color
    var density: Float // 0.0 - 1.0
    var intensity: Float // 0.0 - 1.0
}

enum ParticleType: String, Codable {
    case heart, star, circle, custom
}
```

### 核心组件接口

#### TemplateManager (模板管理器)

```swift
protocol TemplateManagerProtocol {
    func getAllTemplates() -> [Template]
    func getTemplates(category: TemplateCategory) -> [Template]
    func getTemplate(id: UUID) -> Template?
    func createTemplate(_ template: Template) async throws
    func updateTemplate(_ template: Template) async throws
    func deleteTemplate(id: UUID) async throws
    func renameTemplate(id: UUID, newName: String) async throws
    func generateThumbnail(for template: Template) async -> Data?
}
```

#### RenderingEngine (渲染引擎)

```swift
protocol RenderingEngineProtocol {
    func render(configuration: DisplayConfiguration, in context: CGContext, size: CGSize, timestamp: TimeInterval)
    func startRendering(configuration: DisplayConfiguration)
    func stopRendering()
    func updateConfiguration(_ configuration: DisplayConfiguration)
}
```

#### AnimationSystem (动画系统)

```swift
protocol AnimationSystemProtocol {
    func startAnimation(type: AnimationType, configuration: AnimationConfiguration)
    func stopAnimation()
    func pauseAnimation()
    func resumeAnimation()
    func updateSpeed(_ speed: Float)
}

struct AnimationConfiguration {
    var duration: TimeInterval
    var repeatCount: Int
    var timingFunction: CAMediaTimingFunction
}
```

#### CodeSandbox (代码沙箱)

```swift
protocol CodeSandboxProtocol {
    func execute(code: String, completion: @escaping (Result<Void, SandboxError>) -> Void)
    func provideCanvasAPI() -> JSContext
    func setMemoryLimit(_ limit: Int) // in MB
    func setExecutionTimeLimit(_ limit: TimeInterval) // per frame
    func reset()
}

enum SandboxError: Error {
    case syntaxError(line: Int, message: String)
    case runtimeError(message: String, stack: String)
    case securityViolation(api: String)
    case memoryLimitExceeded
    case executionTimeExceeded
}
```

#### iCloudSyncService (iCloud 同步服务)

```swift
protocol iCloudSyncServiceProtocol {
    var isAvailable: Bool { get }
    func startSync()
    func stopSync()
    func syncTemplate(_ template: Template) async throws
    func deleteTemplate(id: UUID) async throws
    func resolveConflict(local: Template, remote: Template) -> Template
}
```

### UI 组件

#### WaterfallLayout (瀑布流布局)

```swift
struct WaterfallLayout: Layout {
    var columns: Int
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
}
```

#### TemplateCard (模板卡片)

```swift
struct TemplateCard: View {
    let template: Template
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let onRename: (() -> Void)?
    
    var body: some View {
        // 卡片布局：缩略图预览 + 标题 + 操作按钮
    }
}
```

#### NeonButton (霓虹发光按钮)

```swift
struct NeonButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        // 深色背景 + 霓虹色边框 + 发光效果
    }
}
```

#### ThumbnailPreview (缩略图预览)

```swift
struct ThumbnailPreview: View {
    let template: Template
    @State private var isVisible: Bool = false
    
    var body: some View {
        // 使用 RenderingEngine 渲染降帧预览
    }
}
```

## 数据模型

### 数据流

```
User Action → ViewModel → Business Logic → Data Layer
                ↓                              ↓
            UI Update ← Combine Publishers ← Data Change
```

### 本地存储

使用 Core Data 存储模板数据：

```swift
// Core Data Entity
@objc(TemplateEntity)
class TemplateEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var category: String
    @NSManaged var displayType: String
    @NSManaged var configurationData: Data // JSON encoded
    @NSManaged var thumbnailData: Data?
    @NSManaged var createdAt: Date
    @NSManaged var modifiedAt: Date
    @NSManaged var isSystemPreset: Bool
    @NSManaged var iCloudRecordID: String?
}
```

### iCloud 同步策略

使用 CloudKit 进行数据同步：

1. **记录类型**: `Template`
2. **同步触发**: 
   - 创建/更新/删除模板时立即触发
   - 应用启动时拉取远程更新
   - 收到 CloudKit 通知时拉取更新
3. **冲突解决**: 
   - 比较 `modifiedAt` 时间戳
   - 保留最新版本
   - 记录冲突日志供调试

### 数据验证

```swift
struct TemplateValidator {
    static func validate(_ template: Template) throws {
        // 名称验证
        guard !template.name.isEmpty else {
            throw ValidationError.emptyName
        }
        
        // 文字长度验证
        if let text = template.configuration.text {
            guard text.count <= 500 else {
                throw ValidationError.textTooLong
            }
        }
        
        // JavaScript 代码大小验证
        if let code = template.configuration.javascriptCode {
            let codeSize = code.data(using: .utf8)?.count ?? 0
            guard codeSize <= 1_000_000 else { // 1MB
                throw ValidationError.codeTooLarge
            }
        }
        
        // 模板总大小验证
        let encoder = JSONEncoder()
        let data = try encoder.encode(template)
        guard data.count <= 1_000_000 else { // 1MB
            throw ValidationError.templateTooLarge
        }
    }
}
```


## 正确性属性

*属性是一个特征或行为，应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*

### 属性反思

在分析验收标准后，我识别出以下可以合并或简化的冗余属性：

1. **模板卡片显示属性合并**: 
   - 4.5 (所有卡片显示缩略图) 和 12.1 (所有卡片显示缩略图) 是重复的
   - 4.7 (所有卡片显示名称) 可以与缩略图显示合并为一个综合属性
   - 合并为：属性 1 - 模板卡片完整性

2. **模板分类属性合并**:
   - 5.1 (预设模板在正确分类) 和 5.2 (用户创建在正确分类) 可以合并
   - 合并为：属性 2 - 模板分类正确性

3. **用户创建模板操作属性合并**:
   - 5.5 (删除操作)、5.6 (编辑操作)、5.7 (重命名操作) 可以合并
   - 合并为：属性 3 - 用户模板操作可用性

4. **iCloud 同步延迟属性合并**:
   - 16.2 (创建同步)、16.3 (修改同步)、16.4 (删除同步) 都是测试 30 秒同步延迟
   - 合并为：属性 15 - iCloud 同步延迟

5. **JavaScript 错误处理属性合并**:
   - 18.5 (语法错误)、18.6 (运行时错误)、18.7 (安全限制) 都是错误报告
   - 合并为：属性 20 - JavaScript 错误报告

6. **性能帧率属性合并**:
   - 19.1 (动画 30fps)、19.5 (JavaScript 30fps) 都是测试帧率要求
   - 合并为：属性 21 - 渲染帧率要求

### 属性 1: 模板卡片完整性
*对于任意* 显示在首页的模板卡片，该卡片应该同时显示缩略图预览和模板名称

**验证需求: 4.5, 4.7, 12.1**

### 属性 2: 模板分类正确性
*对于任意* 模板，如果它是系统内置模板则应该出现在"预设模板"分类中，如果它是用户创建的模板则应该出现在"我的创建"分类中

**验证需求: 5.1, 5.2**

### 属性 3: 用户模板操作可用性
*对于任意* 在"我的创建"分类中的模板卡片，该卡片应该提供删除、编辑和重命名三个操作选项

**验证需求: 5.5, 5.6, 5.7**

### 属性 4: 新建模板自动分类
*对于任意* 用户新创建的模板，该模板应该自动被添加到"我的创建"分类中

**验证需求: 5.3**

### 属性 5: 模板卡片点击导航
*对于任意* 首页的模板卡片，当用户点击该卡片时，系统应该进入全屏播放模式并播放该模板的效果

**验证需求: 4.8, 6.1**

### 属性 6: 模板删除同步移除
*对于任意* 模板，当用户删除该模板时，对应的模板卡片应该从首页移除

**验证需求: 5.8**

### 属性 7: 所有显示类型支持亮度调节
*对于任意* 显示类型，配置界面应该提供亮度级别调节控件

**验证需求: 8.6**

### 属性 8: 缩略图预览帧率
*对于任意* 模板卡片的缩略图预览，其播放帧率应该至少达到 15 帧每秒

**验证需求: 12.2**

### 属性 9: 缩略图保持宽高比
*对于任意* 模板的缩略图预览，其显示的宽高比应该与原始模板效果的宽高比一致

**验证需求: 12.3**

### 属性 10: 可见区域预览优化
*对于任意* 模板卡片，只有当该卡片在可见区域内时，其缩略图预览才应该被渲染

**验证需求: 12.4**

### 属性 11: 预览延迟加载
*对于任意* 进入可见区域的模板卡片，其缩略图预览应该在 500 毫秒内开始播放

**验证需求: 12.5**

### 属性 12: 预览离开暂停
*对于任意* 离开可见区域的模板卡片，其缩略图预览应该暂停渲染

**验证需求: 12.6**

### 属性 13: 预览循环播放
*对于任意* 模板卡片的缩略图预览，应该循环播放模板效果而不是播放一次后停止

**验证需求: 12.7**

### 属性 14: JavaScript 异常捕获
*对于任意* 在代码沙箱中执行的 JavaScript 代码，如果代码抛出异常，沙箱应该捕获该异常并显示错误信息

**验证需求: 13.13**

### 属性 15: JavaScript 安全限制
*对于任意* 受限的设备敏感 API，当 JavaScript 代码尝试访问该 API 时，代码沙箱应该阻止访问并记录警告

**验证需求: 13.14, 13.16**

### 属性 16: 配置修改实时预览
*对于任意* 显示配置参数的修改，预览显示应该在 500 毫秒内更新以反映新的配置

**验证需求: 14.1**

### 属性 17: 模板加载和播放
*对于任意* 用户选择的模板，系统应该加载该模板的显示配置并进入全屏播放模式

**验证需求: 15.4**

### 属性 18: 模板删除持久化
*对于任意* 模板，当用户删除该模板时，该模板应该从本地存储和 iCloud 中被删除

**验证需求: 15.5**

### 属性 19: 模板重命名同步
*对于任意* 模板，当用户重命名该模板时，新名称应该被更新并同步到 iCloud

**验证需求: 15.6**

### 属性 20: 模板编辑界面
*对于任意* 用户选择编辑的模板，系统应该打开配置界面并允许修改该模板的参数

**验证需求: 15.7**

### 属性 21: 编辑后缩略图更新
*对于任意* 被编辑并保存的模板，其缩略图预览应该更新以反映新的配置

**验证需求: 15.8**

### 属性 22: iCloud 同步延迟
*对于任意* 模板的创建、修改或删除操作，该操作应该在 30 秒内同步到用户的其他设备（当用户已登录 iCloud 时）

**验证需求: 16.2, 16.3, 16.4**

### 属性 23: iCloud 冲突解决
*对于任意* 同步冲突（同一模板在不同设备上同时修改），系统应该保留最后修改时间戳较新的版本

**验证需求: 16.5**

### 属性 24: JavaScript 代码同步
*对于任意* 包含 JavaScript 代码的模板，当保存该模板时，代码内容应该被同步到其他设备

**验证需求: 16.7**

### 属性 25: 模板大小限制
*对于任意* 模板，其总大小（包括代码和配置）应该不超过 1MB

**验证需求: 16.8**

### 属性 26: 模板持久化往返
*对于任意* 模板，保存到本地存储后再加载，应该得到与原始模板配置完全一致的数据

**验证需求: 17.1, 17.3**

### 属性 27: 应用启动加载模板
*对于任意* 已保存到本地存储的模板，当应用启动时，该模板应该被加载并显示在首页

**验证需求: 17.2**

### 属性 28: 文字长度限制提示
*对于任意* 超过 500 个字符的文字内容，系统应该显示字符限制提示并拒绝接受

**验证需求: 18.4**

### 属性 29: JavaScript 错误报告
*对于任意* JavaScript 代码错误（语法错误、运行时错误或安全限制），代码沙箱应该显示具体的错误信息（包括错误类型、消息、行号或堆栈信息）

**验证需求: 18.5, 18.6, 18.7**

### 属性 30: 渲染帧率要求
*对于任意* 动画效果（包括 LED 显示效果和 JavaScript 代码模式），系统应该以至少 30 帧每秒的速率进行渲染

**验证需求: 19.1, 19.5**

### 属性 31: 模板切换延迟
*对于任意* 模板切换操作，系统应该在 300 毫秒内开始显示新的效果

**验证需求: 19.2**

### 属性 32: CPU 使用率限制
*对于任意* LED 显示效果，在播放时系统的 CPU 使用率应该保持在 30% 以下

**验证需求: 19.3**

### 属性 33: 低帧率性能警告
*对于任意* 导致帧率低于 20 帧每秒的 JavaScript 代码，系统应该显示性能警告

**验证需求: 19.6**

### 属性 34: 交互元素辅助功能标签
*对于任意* 交互元素（按钮、输入框、卡片等），应该提供 VoiceOver 标签以支持辅助功能

**验证需求: 20.1**

### 属性 35: 文字对比度要求
*对于任意* 文字元素，其与背景的颜色对比度应该符合 WCAG AA 标准（至少 4.5:1）

**验证需求: 20.3, 20.4**

### 属性 36: 代码模板加载
*对于任意* 用户选择的代码模板，该模板的代码应该被加载到代码编辑器中

**验证需求: 21.3**

### 属性 37: 代码模板文档
*对于任意* 代码模板，应该提供对应的说明文档

**验证需求: 21.4**


## 错误处理

### 错误分类

#### 1. 网络和同步错误

**iCloud 同步失败**
- **场景**: CloudKit 网络请求失败、用户未登录 iCloud、iCloud 配额不足
- **处理策略**:
  - 捕获 `CKError` 并分类处理
  - 显示用户友好的错误提示（深色背景 + 霓虹红色文字）
  - 提供"重试"按钮（霓虹发光样式）
  - 在本地队列中保存失败的同步操作，待网络恢复后自动重试
  - 记录错误日志供调试

```swift
enum SyncError: LocalizedError {
    case notSignedIn
    case networkUnavailable
    case quotaExceeded
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "请登录 iCloud 以启用同步功能"
        case .networkUnavailable:
            return "网络连接不可用，请检查网络设置"
        case .quotaExceeded:
            return "iCloud 存储空间不足"
        case .unknownError(let error):
            return "同步失败: \(error.localizedDescription)"
        }
    }
}
```

#### 2. 存储错误

**本地存储空间不足**
- **场景**: 设备存储空间不足，无法保存新模板
- **处理策略**:
  - 在保存前检查可用存储空间
  - 显示存储空间不足提示
  - 建议用户删除不需要的模板或清理设备存储

**数据损坏**
- **场景**: 模板数据文件损坏，无法解码
- **处理策略**:
  - 使用 `try-catch` 捕获解码错误
  - 跳过损坏的模板，继续加载其他模板
  - 显示错误提示："模板 [名称] 数据损坏，已跳过"
  - 记录错误日志，包含损坏数据的部分信息

```swift
func loadTemplates() -> [Template] {
    var templates: [Template] = []
    let entities = fetchTemplateEntities()
    
    for entity in entities {
        do {
            let template = try decodeTemplate(from: entity)
            templates.append(template)
        } catch {
            logger.error("Failed to decode template \(entity.id): \(error)")
            // 显示错误提示但继续加载其他模板
            showError("模板 \(entity.name) 数据损坏，已跳过")
        }
    }
    
    return templates
}
```

#### 3. 输入验证错误

**文字内容超长**
- **场景**: 用户输入超过 500 个字符的文字
- **处理策略**:
  - 在输入框实时显示字符计数
  - 达到 500 字符时禁用继续输入
  - 显示提示："文字内容不能超过 500 个字符"

**模板名称为空**
- **场景**: 用户尝试保存没有名称的模板
- **处理策略**:
  - 保存按钮在名称为空时禁用
  - 显示提示："请输入模板名称"

**模板大小超限**
- **场景**: 模板总大小超过 1MB
- **处理策略**:
  - 在保存前计算模板大小
  - 显示错误提示："模板大小超过限制（1MB），请减少内容或代码长度"
  - 阻止保存操作

#### 4. JavaScript 代码错误

**语法错误**
- **场景**: JavaScript 代码包含语法错误
- **处理策略**:
  - 使用 `JSContext` 的错误处理机制捕获语法错误
  - 解析错误信息，提取行号和错误描述
  - 在代码编辑器中高亮错误行
  - 显示错误面板（深色背景 + 霓虹红色文字）
  - 格式：`语法错误 (第 X 行): [错误描述]`

```swift
func executeJavaScript(_ code: String) {
    jsContext.exceptionHandler = { context, exception in
        guard let exception = exception else { return }
        
        let line = exception.objectForKeyedSubscript("line")?.toInt32() ?? 0
        let message = exception.toString() ?? "Unknown error"
        
        DispatchQueue.main.async {
            self.showError(
                type: .syntaxError,
                line: Int(line),
                message: message
            )
        }
    }
    
    jsContext.evaluateScript(code)
}
```

**运行时错误**
- **场景**: JavaScript 代码执行时抛出异常
- **处理策略**:
  - 捕获运行时异常
  - 显示错误堆栈信息
  - 停止代码执行，保持最后一帧画面
  - 提供"重新运行"按钮

**性能问题**
- **场景**: 代码执行时间超过 100ms/帧
- **处理策略**:
  - 监控每帧执行时间
  - 显示性能警告（霓虹黄色）："代码执行时间过长，可能导致卡顿"
  - 提供性能优化建议

**安全限制**
- **场景**: 代码尝试访问受限 API
- **处理策略**:
  - 在 JavaScript 环境中移除或替换受限 API
  - 捕获访问尝试
  - 显示安全警告："不允许访问 [API 名称]"
  - 记录安全日志

```swift
// 受限 API 列表
let restrictedAPIs = [
    "fetch", "XMLHttpRequest", // 网络访问
    "localStorage", "sessionStorage", // 存储访问
    "navigator.geolocation", // 位置访问
    "navigator.camera", // 相机访问
    // ... 其他敏感 API
]

func setupSecureSandbox() {
    for api in restrictedAPIs {
        let script = """
        Object.defineProperty(window, '\(api)', {
            get: function() {
                throw new Error('Access to \(api) is restricted');
            }
        });
        """
        jsContext.evaluateScript(script)
    }
}
```

**内存限制**
- **场景**: 代码内存使用超过 50MB
- **处理策略**:
  - 监控 JSContext 内存使用
  - 达到 45MB 时显示警告
  - 达到 50MB 时强制停止执行
  - 显示错误："代码内存使用超过限制"

#### 5. 渲染错误

**Metal 初始化失败**
- **场景**: 设备不支持 Metal 或初始化失败
- **处理策略**:
  - 降级到 Core Graphics 渲染
  - 禁用高级粒子效果
  - 显示提示："设备不支持高级效果，已切换到兼容模式"

**帧率过低**
- **场景**: 渲染帧率持续低于 20fps
- **处理策略**:
  - 自动降低效果质量（减少粒子数量、降低分辨率）
  - 显示性能警告
  - 提供"简化效果"选项

### 错误 UI 设计

所有错误提示遵循霓虹朋克风格：

```swift
struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 错误图标（霓虹红色发光）
            Image(systemName: error.icon)
                .font(.system(size: 48))
                .foregroundColor(.neonRed)
                .shadow(color: .neonRed, radius: 10)
            
            // 错误标题
            Text(error.title)
                .font(.title2)
                .foregroundColor(.neonRed)
            
            // 错误描述
            Text(error.message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // 操作按钮
            HStack(spacing: 16) {
                if let onRetry = onRetry {
                    NeonButton(title: "重试", color: .neonBlue) {
                        onRetry()
                    }
                }
                
                NeonButton(title: "关闭", color: .neonPurple) {
                    onDismiss()
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.neonRed, lineWidth: 2)
                        .shadow(color: .neonRed, radius: 8)
                )
        )
    }
}
```

### 错误日志

使用统一的日志系统记录所有错误：

```swift
import OSLog

extension Logger {
    static let app = Logger(subsystem: "com.app.led-display", category: "app")
    static let sync = Logger(subsystem: "com.app.led-display", category: "sync")
    static let rendering = Logger(subsystem: "com.app.led-display", category: "rendering")
    static let sandbox = Logger(subsystem: "com.app.led-display", category: "sandbox")
}

// 使用示例
Logger.sync.error("iCloud sync failed: \(error.localizedDescription)")
Logger.sandbox.warning("JavaScript execution time exceeded: \(executionTime)ms")
```


## 测试策略

### 测试方法概述

本项目采用双重测试方法，结合单元测试和基于属性的测试（Property-Based Testing, PBT），以确保全面的代码覆盖和正确性验证。

- **单元测试**: 验证特定示例、边缘情况和错误条件
- **基于属性的测试**: 验证跨所有输入的通用属性
- 两者互补且都是必需的，以实现全面覆盖

### 基于属性的测试配置

**测试库选择**: 使用 [swift-check](https://github.com/typelift/SwiftCheck) 作为 Swift 的属性测试库

**配置要求**:
- 每个属性测试最少运行 100 次迭代（由于随机化）
- 每个测试必须引用其设计文档中的属性
- 标签格式: `// Feature: led-screen-display, Property X: [属性文本]`

**示例属性测试**:

```swift
import XCTest
import SwiftCheck
@testable import LEDDisplay

class TemplatePropertiesTests: XCTestCase {
    
    // Feature: led-screen-display, Property 1: 模板卡片完整性
    func testTemplateCardCompleteness() {
        property("All template cards should display both thumbnail and name") <- forAll { (template: Template) in
            let card = TemplateCard(template: template)
            let hasThumbnail = card.thumbnailView != nil
            let hasName = !card.nameLabel.text.isEmpty
            return hasThumbnail && hasName
        }.withSize(100)
    }
    
    // Feature: led-screen-display, Property 2: 模板分类正确性
    func testTemplateCategoryCorrectness() {
        property("Templates should be in correct category based on isSystemPreset") <- forAll { (template: Template) in
            let manager = TemplateManager()
            let category = manager.getCategory(for: template)
            
            if template.isSystemPreset {
                return category == .systemPresets
            } else {
                return category == .userCreated
            }
        }.withSize(100)
    }
    
    // Feature: led-screen-display, Property 26: 模板持久化往返
    func testTemplatePersistenceRoundTrip() {
        property("Saving and loading a template should preserve all data") <- forAll { (template: Template) in
            let repository = TemplateRepository()
            
            // 保存模板
            try? repository.save(template)
            
            // 加载模板
            guard let loaded = try? repository.load(id: template.id) else {
                return false
            }
            
            // 验证所有字段相等
            return template.id == loaded.id &&
                   template.name == loaded.name &&
                   template.category == loaded.category &&
                   template.displayType == loaded.displayType &&
                   template.configuration == loaded.configuration
        }.withSize(100)
    }
    
    // Feature: led-screen-display, Property 30: 渲染帧率要求
    func testRenderingFrameRate() {
        property("Rendering should maintain at least 30 FPS") <- forAll { (config: DisplayConfiguration) in
            let engine = RenderingEngine()
            let monitor = FrameRateMonitor()
            
            engine.startRendering(configuration: config)
            monitor.startMonitoring()
            
            // 监控 5 秒
            Thread.sleep(forTimeInterval: 5.0)
            
            let averageFPS = monitor.getAverageFPS()
            engine.stopRendering()
            
            return averageFPS >= 30.0
        }.withSize(100)
    }
}
```

### 生成器定义

为了支持属性测试，需要为自定义类型定义生成器：

```swift
import SwiftCheck

extension Template: Arbitrary {
    public static var arbitrary: Gen<Template> {
        return Gen.compose { c in
            Template(
                id: UUID(),
                name: String.arbitrary.generate,
                category: c.generate(using: TemplateCategory.arbitrary),
                displayType: c.generate(using: DisplayType.arbitrary),
                configuration: c.generate(using: DisplayConfiguration.arbitrary),
                thumbnailData: nil,
                createdAt: Date(),
                modifiedAt: Date(),
                isSystemPreset: Bool.arbitrary.generate
            )
        }
    }
}

extension DisplayConfiguration: Arbitrary {
    public static var arbitrary: Gen<DisplayConfiguration> {
        return Gen.compose { c in
            DisplayConfiguration(
                brightness: Float.arbitrary.generate.clamped(to: 0...1),
                animationSpeed: Float.arbitrary.generate.clamped(to: 0.1...5.0),
                colors: Gen.arrayOf(Color.arbitrary).generate,
                text: String.arbitrary.generate.prefix(500),
                fontSize: CGFloat.arbitrary.generate.clamped(to: 12...200),
                fontStyle: c.generate(using: FontStyle.arbitrary),
                textEffect: c.generate(using: TextEffect.arbitrary),
                scrollDirection: c.generate(using: ScrollDirection.arbitrary),
                backgroundColor: c.generate(using: BackgroundStyle.arbitrary),
                specialEffect: c.generate(using: SpecialEffectType.arbitrary),
                particleConfig: c.generate(using: ParticleConfiguration.arbitrary),
                backgroundEffects: Gen.arrayOf(BackgroundEffect.arbitrary).generate,
                javascriptCode: String.arbitrary.generate.prefix(10000)
            )
        }
    }
}
```

### 单元测试策略

单元测试专注于特定示例、边缘情况和集成点。避免编写过多的单元测试——基于属性的测试已经处理了大量输入的覆盖。

#### UI 测试

使用 XCTest UI Testing 验证用户界面交互：

```swift
class HomeViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    // 测试创建入口存在性
    func testCreationButtonsExist() {
        let addLEDButton = app.buttons["+ 新增 LED"]
        let codeModeButton = app.buttons["</> 代码模式"]
        
        XCTAssertTrue(addLEDButton.exists)
        XCTAssertTrue(codeModeButton.exists)
    }
    
    // 测试点击新增 LED 按钮导航
    func testAddLEDButtonNavigation() {
        let addLEDButton = app.buttons["+ 新增 LED"]
        addLEDButton.tap()
        
        // 验证进入可视化编辑器
        XCTAssertTrue(app.navigationBars["可视化编辑器"].exists)
    }
    
    // 测试点击代码模式按钮导航
    func testCodeModeButtonNavigation() {
        let codeModeButton = app.buttons["</> 代码模式"]
        codeModeButton.tap()
        
        // 验证进入代码编辑器
        XCTAssertTrue(app.navigationBars["代码编辑器"].exists)
    }
    
    // 测试全屏播放交互
    func testFullscreenPlayback() {
        // 点击第一个模板卡片
        let firstCard = app.collectionViews.cells.firstMatch
        firstCard.tap()
        
        // 验证进入全屏模式（状态栏隐藏）
        XCTAssertFalse(app.statusBars.firstMatch.exists)
        
        // 点击屏幕显示退出按钮
        app.tap()
        let exitButton = app.buttons["退出"]
        XCTAssertTrue(exitButton.waitForExistence(timeout: 1.0))
        
        // 点击退出按钮返回首页
        exitButton.tap()
        XCTAssertTrue(app.collectionViews.firstMatch.exists)
    }
}
```

#### 业务逻辑测试

```swift
class TemplateManagerTests: XCTestCase {
    var manager: TemplateManager!
    
    override func setUp() {
        super.setUp()
        manager = TemplateManager()
    }
    
    // 测试创建模板
    func testCreateTemplate() async throws {
        let template = Template(
            id: UUID(),
            name: "测试模板",
            category: .userCreated,
            displayType: .solidColor,
            configuration: DisplayConfiguration(
                brightness: 1.0,
                animationSpeed: 1.0,
                colors: [.red]
            ),
            thumbnailData: nil,
            createdAt: Date(),
            modifiedAt: Date(),
            isSystemPreset: false
        )
        
        try await manager.createTemplate(template)
        
        let loaded = manager.getTemplate(id: template.id)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.name, "测试模板")
    }
    
    // 测试删除模板
    func testDeleteTemplate() async throws {
        let template = createTestTemplate()
        try await manager.createTemplate(template)
        
        try await manager.deleteTemplate(id: template.id)
        
        let loaded = manager.getTemplate(id: template.id)
        XCTAssertNil(loaded)
    }
    
    // 测试模板分类过滤
    func testGetTemplatesByCategory() {
        let systemTemplate = createTestTemplate(isSystemPreset: true)
        let userTemplate = createTestTemplate(isSystemPreset: false)
        
        let systemTemplates = manager.getTemplates(category: .systemPresets)
        let userTemplates = manager.getTemplates(category: .userCreated)
        
        XCTAssertTrue(systemTemplates.contains { $0.id == systemTemplate.id })
        XCTAssertTrue(userTemplates.contains { $0.id == userTemplate.id })
    }
}
```

#### JavaScript 沙箱测试

```swift
class CodeSandboxTests: XCTestCase {
    var sandbox: CodeSandbox!
    
    override func setUp() {
        super.setUp()
        sandbox = CodeSandbox()
        sandbox.setMemoryLimit(50) // 50MB
        sandbox.setExecutionTimeLimit(0.1) // 100ms
    }
    
    // 测试语法错误捕获
    func testSyntaxErrorHandling() {
        let code = "function test() { return 1 + ; }" // 语法错误
        
        let expectation = XCTestExpectation(description: "Syntax error caught")
        
        sandbox.execute(code: code) { result in
            switch result {
            case .failure(let error):
                if case .syntaxError(let line, let message) = error {
                    XCTAssertGreaterThan(line, 0)
                    XCTAssertFalse(message.isEmpty)
                    expectation.fulfill()
                }
            case .success:
                XCTFail("Should have failed with syntax error")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // 测试运行时错误捕获
    func testRuntimeErrorHandling() {
        let code = """
        function test() {
            throw new Error("Test error");
        }
        test();
        """
        
        let expectation = XCTestExpectation(description: "Runtime error caught")
        
        sandbox.execute(code: code) { result in
            switch result {
            case .failure(let error):
                if case .runtimeError(let message, let stack) = error {
                    XCTAssertTrue(message.contains("Test error"))
                    XCTAssertFalse(stack.isEmpty)
                    expectation.fulfill()
                }
            case .success:
                XCTFail("Should have failed with runtime error")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // 测试安全限制
    func testSecurityRestrictions() {
        let code = "fetch('https://example.com');" // 受限 API
        
        let expectation = XCTestExpectation(description: "Security violation caught")
        
        sandbox.execute(code: code) { result in
            switch result {
            case .failure(let error):
                if case .securityViolation(let api) = error {
                    XCTAssertEqual(api, "fetch")
                    expectation.fulfill()
                }
            case .success:
                XCTFail("Should have failed with security violation")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // 测试 Canvas API 可用性
    func testCanvasAPIAvailability() {
        let code = """
        const canvas = getCanvas();
        canvas.fillRect(0, 0, 100, 100);
        """
        
        let expectation = XCTestExpectation(description: "Canvas API works")
        
        sandbox.execute(code: code) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Canvas API should be available: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

#### iCloud 同步测试

```swift
class iCloudSyncServiceTests: XCTestCase {
    var syncService: iCloudSyncService!
    
    override func setUp() {
        super.setUp()
        syncService = iCloudSyncService()
    }
    
    // 测试同步可用性检查
    func testSyncAvailability() {
        // 这个测试依赖于设备是否登录 iCloud
        if syncService.isAvailable {
            XCTAssertTrue(true, "iCloud is available")
        } else {
            XCTAssertTrue(true, "iCloud is not available (expected in simulator)")
        }
    }
    
    // 测试冲突解决（使用 mock）
    func testConflictResolution() {
        let now = Date()
        let earlier = now.addingTimeInterval(-3600) // 1 小时前
        
        let localTemplate = Template(
            id: UUID(),
            name: "Local",
            category: .userCreated,
            displayType: .solidColor,
            configuration: DisplayConfiguration(brightness: 0.5, animationSpeed: 1.0, colors: [.red]),
            thumbnailData: nil,
            createdAt: earlier,
            modifiedAt: now, // 更新
            isSystemPreset: false
        )
        
        let remoteTemplate = Template(
            id: localTemplate.id,
            name: "Remote",
            category: .userCreated,
            displayType: .gradient,
            configuration: DisplayConfiguration(brightness: 0.8, animationSpeed: 2.0, colors: [.blue]),
            thumbnailData: nil,
            createdAt: earlier,
            modifiedAt: earlier, // 未更新
            isSystemPreset: false
        )
        
        let resolved = syncService.resolveConflict(local: localTemplate, remote: remoteTemplate)
        
        // 应该保留本地版本（更新）
        XCTAssertEqual(resolved.name, "Local")
        XCTAssertEqual(resolved.modifiedAt, now)
    }
}
```

### 性能测试

```swift
class PerformanceTests: XCTestCase {
    
    // 测试应用启动时间
    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // 测试模板加载性能
    func testTemplateLoadingPerformance() {
        let manager = TemplateManager()
        
        // 创建 100 个测试模板
        for i in 0..<100 {
            let template = createTestTemplate(name: "Template \(i)")
            try? manager.createTemplate(template)
        }
        
        measure {
            let _ = manager.getAllTemplates()
        }
    }
    
    // 测试渲染性能
    func testRenderingPerformance() {
        let engine = RenderingEngine()
        let config = DisplayConfiguration(
            brightness: 1.0,
            animationSpeed: 1.0,
            colors: [.red, .blue, .green]
        )
        
        measure {
            for _ in 0..<100 {
                engine.render(
                    configuration: config,
                    in: CGContext(),
                    size: CGSize(width: 375, height: 812),
                    timestamp: Date().timeIntervalSince1970
                )
            }
        }
    }
}
```

### 测试覆盖率目标

- **代码覆盖率**: 最低 80%
- **关键路径覆盖率**: 100%（模板 CRUD、渲染引擎、同步服务）
- **UI 覆盖率**: 主要用户流程 100%

### 持续集成

使用 GitHub Actions 或 Xcode Cloud 进行持续集成：

```yaml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_14.0.app
    
    - name: Build and Test
      run: |
        xcodebuild test \
          -scheme LEDDisplay \
          -destination 'platform=iOS Simulator,name=iPhone 14 Pro,OS=16.0' \
          -enableCodeCoverage YES
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v2
      with:
        files: ./coverage.xml
```

### 测试数据管理

使用测试夹具（fixtures）管理测试数据：

```swift
struct TestFixtures {
    static let sampleTemplates: [Template] = [
        Template(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "纯红色",
            category: .systemPresets,
            displayType: .solidColor,
            configuration: DisplayConfiguration(
                brightness: 1.0,
                animationSpeed: 1.0,
                colors: [.red]
            ),
            thumbnailData: nil,
            createdAt: Date(),
            modifiedAt: Date(),
            isSystemPreset: true
        ),
        // ... 更多示例模板
    ]
    
    static let sampleJavaScriptCode = """
    const canvas = getCanvas();
    const ctx = canvas.getContext('2d');
    
    function draw(timestamp) {
        ctx.fillStyle = 'black';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        ctx.fillStyle = '#FF10F0';
        ctx.fillRect(100, 100, 200, 200);
    }
    
    setAnimationLoop(draw);
    """
}
```

