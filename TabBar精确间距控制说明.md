# TabBar 精确间距控制说明

## 需求
首页和设置标签距离屏幕左右边缘各 20px，三个标签（首页、创作、设置）均匀分布。

## 实现方案

### 1. 创建自定义 TabBar 类
**文件**：`LedScreen/CustomSpacedTabBar.swift`

```swift
class CustomSpacedTabBar: UITabBar {
    private let edgeInset: CGFloat = 20 // 距离屏幕边缘的距离
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 获取所有 TabBarButton
        let buttons = subviews.filter { 
            String(describing: type(of: $0)) == "UITabBarButton" 
        }
        
        let screenWidth = bounds.width
        let usableWidth = screenWidth - (edgeInset * 2) // 可用宽度
        let itemWidth = usableWidth / 5.0 // 5个标签均分
        
        // 重新布局每个按钮
        for (index, button) in buttons.enumerated() {
            let xPosition = edgeInset + (CGFloat(index) * itemWidth)
            button.frame = CGRect(
                x: xPosition,
                y: button.frame.origin.y,
                width: itemWidth,
                height: button.frame.height
            )
        }
    }
}
```

### 2. 使用占位标签撑开空间
**布局结构**：首页 - [占位1] - 创作 - [占位2] - 设置

- 总共 5 个标签位置
- 3 个真实标签（可见、可点击）
- 2 个占位标签（不可见、不可点击）

### 3. 在 MainTabBarController 中应用

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    // 使用自定义 TabBar
    setValue(CustomSpacedTabBar(), forKey: "tabBar")
    
    self.delegate = self
    setupViewControllers()
    setupTabBar()
}
```

## 布局效果

```
|<-20px->|  首页  |  [占位]  |  创作  |  [占位]  |  设置  |<-20px->|
|        |        |          |        |          |        |        |
屏幕左边缘                                                  屏幕右边缘
```

### 计算公式
- 屏幕宽度：`screenWidth`
- 可用宽度：`usableWidth = screenWidth - 40px`（左右各 20px）
- 每个标签宽度：`itemWidth = usableWidth / 5`
- 标签位置：`x = 20px + (index × itemWidth)`

### 示例（iPhone 15 Pro，屏幕宽度 393px）
- 可用宽度：393 - 40 = 353px
- 每个标签宽度：353 / 5 = 70.6px
- 首页位置：20px
- 占位1位置：90.6px
- 创作位置：161.2px
- 占位2位置：231.8px
- 设置位置：302.4px

## 修改的文件

### 新增文件
1. ✅ `LedScreen/CustomSpacedTabBar.swift` - 自定义 TabBar 类

### 修改文件
1. ✅ `LedScreen/MainTabBarController.swift`
   - 在 `viewDidLoad()` 中使用自定义 TabBar
   - 在 `setupViewControllers()` 中添加占位标签

2. ✅ `LedScreen.xcodeproj/project.pbxproj`
   - 添加 CustomSpacedTabBar.swift 到项目

## 技术细节

### 为什么使用 5 个标签？
iOS 的 TabBar 会自动均分标签宽度。通过添加 2 个不可见的占位标签，可以让 3 个真实标签之间有更大的间距。

### 为什么重写 layoutSubviews？
iOS 的 TabBar 内部使用 `UITabBarButton` 来显示每个标签。通过重写 `layoutSubviews`，我们可以在系统布局完成后，手动调整每个按钮的位置。

### 占位标签的设置
```swift
let spacer = UIViewController()
spacer.tabBarItem = UITabBarItem(title: "", image: nil, tag: 99)
spacer.tabBarItem.isEnabled = false // 不可点击
```

## 优点
1. ✅ 精确控制边距（20px）
2. ✅ 标签均匀分布
3. ✅ 不影响点击区域
4. ✅ 适配所有屏幕尺寸
5. ✅ 代码简洁易维护

## 调整方法

### 修改边距
在 `CustomSpacedTabBar.swift` 中修改：
```swift
private let edgeInset: CGFloat = 30 // 改为 30px
```

### 修改标签数量
如果要改为 4 个真实标签，需要：
1. 添加第 4 个 ViewController
2. 调整占位标签数量
3. 修改 `itemWidth` 计算公式

## 兼容性
- ✅ iOS 13.0+
- ✅ 所有 iPhone 尺寸
- ✅ 横屏和竖屏

## 注意事项
1. 占位标签的 tag 使用 98、99，避免与真实标签冲突
2. 占位标签必须设置 `isEnabled = false`
3. 自定义 TabBar 必须在 `viewDidLoad()` 中设置

---

**创建时间**：2026年3月9日  
**状态**：✅ 已完成，编译通过
