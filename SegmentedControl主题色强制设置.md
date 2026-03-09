# SegmentedControl主题色强制设置

## 问题描述

首页顶部的tab切换（热门模板/动画）选中背景显示为灰色，而不是主题色青色（#8EFFE6）。

## 问题原因

1. **自定义SegmentedControl干扰**
   - 使用了`NoAnimationSegmentedControl`禁用动画
   - 在禁用动画时可能影响了颜色设置

2. **iOS系统覆盖**
   - 某些iOS版本可能在特定时机覆盖`selectedSegmentTintColor`
   - 需要在多个生命周期方法中强制设置

## 解决方案

### 1. 在初始化时设置（第一次）

```swift
private lazy var segmentedControl: UISegmentedControl = {
    let items = [TemplateTab.popular.localizedName, TemplateTab.animation.localizedName]
    let control = NoAnimationSegmentedControl(items: items)
    
    // 立即设置主题色
    control.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
    if #available(iOS 13.0, *) {
        control.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    } else {
        control.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    }
    
    return control
}()
```

### 2. 在viewWillAppear中设置（第二次）

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // 确保主题色设置正确
    if #available(iOS 13.0, *) {
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    } else {
        segmentedControl.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    }
}
```

### 3. 在viewDidLayoutSubviews中设置（第三次）

```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if segmentedControl.bounds.height > 0 {
        segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
        segmentedControl.layer.masksToBounds = true
        
        // 再次确认选中背景色为主题色
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        }
    }
}
```

### 4. 在setupUI中设置（第四次）

```swift
private func setupUI() {
    // ... 其他代码 ...
    
    // 自定义分段控制器样式
    segmentedControl.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
    
    if #available(iOS 13.0, *) {
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    } else {
        segmentedControl.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
    }
}
```

## 设置时机

```
1. lazy var 初始化
   ↓
2. viewDidLoad → setupUI
   ↓
3. viewWillAppear
   ↓
4. viewDidLayoutSubviews
```

通过在多个生命周期方法中设置，确保颜色不会被系统覆盖。

## 主题色定义

```swift
// 主题色：青色/薄荷绿
UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)

// 十六进制
#8EFFE6

// RGB
(142, 255, 230)
```

## 背景色对比

```swift
// 整体背景：深灰色
UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
// RGB: (38, 38, 38)

// 选中背景：主题色青色
UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
// RGB: (142, 255, 230)
```

## 视觉效果

### 预期效果
```
┌────────────────────────────┐
│ [热门模板] │  动画  │
│  ▲青色背景   灰色背景  │
│   黑色文字   白色文字  │
└────────────────────────────┘
```

### 颜色对比度
- 青色背景 vs 深灰色背景：高对比度 ✅
- 黑色文字 vs 青色背景：清晰可读 ✅
- 白色文字 vs 深灰色背景：清晰可读 ✅

## 调试建议

如果颜色仍然不正确，可以添加调试代码：

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // 打印当前颜色设置
    if #available(iOS 13.0, *) {
        print("🎨 selectedSegmentTintColor: \(segmentedControl.selectedSegmentTintColor?.description ?? "nil")")
    }
    print("🎨 backgroundColor: \(segmentedControl.backgroundColor?.description ?? "nil")")
}
```

## 编译状态

✅ BUILD SUCCEEDED
✅ 无警告
✅ 无错误

## 测试步骤

1. 完全退出应用
2. 重新启动应用
3. 查看首页顶部的tab切换
4. 验证"热门模板"选中背景是否为青色
5. 点击"动画"，验证背景色是否切换为青色

## 预期结果

- ✅ 选中背景为青色（#8EFFE6）
- ✅ 与底部TabBar选中颜色一致
- ✅ 在深色背景上清晰醒目
- ✅ 切换流畅，颜色稳定

## 日期

2026年3月9日
