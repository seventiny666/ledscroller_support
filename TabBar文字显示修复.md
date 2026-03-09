# TabBar文字显示修复

## 问题描述

TabBar底部的"创作"和"设置"文字显示不全，与"首页"文字不在同一高度。点击一次后恢复正常。

## 问题原因

1. **自定义布局冲突**
   - CustomSpacedTabBar修改了按钮的frame
   - 但没有触发按钮内部的布局更新
   - 导致文字显示区域计算错误

2. **位置调整干扰**
   - 设置了titlePositionAdjustment和imageInsets
   - 在初始布局时可能导致文字位置异常
   - 点击后系统重新布局才恢复正常

## 解决方案

### 1. 强制刷新按钮布局

在CustomSpacedTabBar的layoutSubviews中，修改frame后立即刷新按钮布局：

```swift
button.frame = frame

// 强制刷新按钮内部布局，确保文字正确显示
button.setNeedsLayout()
button.layoutIfNeeded()
```

### 2. 延迟刷新TabBar

在MainTabBarController的viewDidLoad中，延迟刷新TabBar布局：

```swift
// 延迟刷新TabBar布局，确保文字正确显示
DispatchQueue.main.async {
    self.tabBar.setNeedsLayout()
    self.tabBar.layoutIfNeeded()
}
```

### 3. 移除位置调整

移除可能导致布局问题的titlePositionAdjustment和imageInsets设置：

```swift
// 之前
item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
item.imageInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)

// 现在
// 不设置，使用系统默认布局
```

## 修改文件

1. `LedScreen/CustomSpacedTabBar.swift`
   - 在layoutSubviews中添加按钮布局刷新

2. `LedScreen/MainTabBarController.swift`
   - 在viewDidLoad中添加延迟刷新
   - 移除titlePositionAdjustment设置
   - 移除imageInsets设置
   - 移除appearance中的titlePositionAdjustment

## 技术细节

### 布局刷新时机

```
1. viewDidLoad
   ├─ setupViewControllers (创建TabBarItem)
   ├─ setupTabBar (设置样式)
   └─ DispatchQueue.main.async (延迟刷新)

2. layoutSubviews (CustomSpacedTabBar)
   ├─ 修改按钮frame
   └─ 刷新按钮内部布局

3. viewDidAppear
   └─ 再次确认title设置
```

### 为什么点击后恢复正常？

点击TabBar按钮时，系统会：
1. 触发按钮的高亮状态
2. 重新计算按钮布局
3. 刷新文字显示区域
4. 因此文字显示恢复正常

现在通过主动触发布局刷新，避免了这个问题。

## 测试验证

### 测试步骤
1. 完全退出应用
2. 重新启动应用
3. 观察TabBar底部文字
4. 验证三个标签文字是否：
   - 完整显示
   - 在同一高度
   - 对齐一致

### 预期结果
- ✅ "首页"文字完整显示
- ✅ "创作"文字完整显示
- ✅ "设置"文字完整显示
- ✅ 三个文字在同一基线上
- ✅ 无需点击即可正常显示

## 编译状态

✅ BUILD SUCCEEDED
✅ 无警告
✅ 无错误

## 相关问题

如果将来遇到类似的TabBar布局问题，检查：
1. 自定义TabBar是否正确刷新子视图布局
2. TabBarItem的位置调整是否合理
3. 布局刷新时机是否正确

## 日期

2026年3月9日
