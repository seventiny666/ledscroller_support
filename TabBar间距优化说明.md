# TabBar 间距优化说明

## 问题描述
TabBar 的"首页"、"创作"、"设置"三个标签之间的间距太近，图标和文字挤在一起，视觉效果不够舒适。

## 优化方案

### 1. 增加文字大小
- **原值**：字体大小 10pt
- **新值**：字体大小 11pt
- **效果**：文字更清晰易读

### 2. 调整文字位置
- **方法**：使用 `titlePositionAdjustment`
- **调整**：文字向下移动 2pt
- **效果**：增加图标和文字之间的垂直间距

### 3. 调整图标位置
- **方法**：使用 `imageInsets`
- **调整**：图标向上移动 2pt（top: -2, bottom: 2）
- **效果**：进一步拉开图标和文字的距离

## 修改的文件
- ✅ `LedScroller/MainTabBarController.swift`

## 具体修改

### setupTabBar() 方法

```swift
// 1. 增加字体大小
let normalAttributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: UIColor.systemGray,
    .font: UIFont.systemFont(ofSize: 11) // 从 10 增加到 11
]
let selectedAttributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: accentColor,
    .font: UIFont.systemFont(ofSize: 11, weight: .medium) // 从 10 增加到 11
]

// 2. 在 appearance 中设置文字位置调整
appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)

// 3. 为每个 tabBarItem 单独调整图标和文字位置
for item in items {
    switch item.tag {
    case 0, 1, 2:
        item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
        item.imageInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)
    default:
        break
    }
}
```

## 视觉效果

### 优化前
- 图标和文字间距：约 2-3pt
- 文字大小：10pt
- 整体感觉：拥挤

### 优化后
- 图标和文字间距：约 6-7pt（增加了 4pt）
- 文字大小：11pt
- 整体感觉：舒适、清晰

## 技术说明

### UIOffset
- `horizontal`：水平偏移（正值向右，负值向左）
- `vertical`：垂直偏移（正值向下，负值向上）

### UIEdgeInsets
- `top`：负值表示向上移动
- `bottom`：正值表示增加底部空间
- 组合使用可以精确控制图标位置

## 兼容性
- ✅ iOS 13.0+
- ✅ iOS 15.0+（使用 UITabBarAppearance）
- ✅ iOS 17.0+（已禁用新动画效果）

## 测试建议
1. 在不同尺寸的设备上测试（iPhone SE、iPhone 15、iPhone 15 Pro Max）
2. 检查横屏和竖屏模式
3. 确认选中和未选中状态的视觉效果
4. 验证文字不会被截断

## 注意事项
- 如果觉得间距还不够，可以继续增加 `vertical` 的值（建议不超过 4）
- 如果文字被截断，可以减小字体大小或调整 `titlePositionAdjustment`
- 保持三个标签的设置一致，确保视觉统一

---

**修改时间**：2026年3月9日  
**状态**：✅ 已完成，编译通过
