# TabBar 首页文字显示最终修复

## 🐛 问题

首页 TabBar 文字始终不显示，即使多次设置 title 也会被清空。

## 🔍 根本原因

iOS 17 的 `UITabBarAppearance` 在应用时会重置某些 tabBarItem 的属性，特别是第一个 item 的 title。

## ✅ 最终解决方案

在 `viewDidAppear()` 中检查并修复空的 title：

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // 再次根据 tag 设置 title（iOS 17 可能会在显示时清空）
    if let items = tabBar.items {
        for item in items {
            switch item.tag {
            case 0:
                if item.title?.isEmpty ?? true {
                    item.title = "首页"
                }
            case 1:
                if item.title?.isEmpty ?? true {
                    item.title = "创作"
                }
            case 2:
                if item.title?.isEmpty ?? true {
                    item.title = "设置"
                }
            default:
                break
            }
        }
    }
    
    tabBar.setNeedsLayout()
    tabBar.layoutIfNeeded()
}
```

## 📝 修改文件

- `GlowLed/MainTabBarController.swift`

---

**状态**：✅ 已修复
