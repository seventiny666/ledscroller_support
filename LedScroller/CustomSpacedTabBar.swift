import UIKit

// 自定义 TabBar，支持精确控制标签位置
class CustomSpacedTabBar: UITabBar {

    private let edgeInset: CGFloat = 20 // 首页和设置距离屏幕边缘的距离

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        // iPad needs a taller tab bar so icons/titles have breathing room.
        if traitCollection.userInterfaceIdiom == .pad {
            s.height = max(s.height, 92)
        }
        return s
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 获取所有 TabBarButton
        let buttons = subviews.filter { String(describing: type(of: $0)) == "UITabBarButton" }
        
        guard buttons.count == 5 else { return } // 确保有5个按钮（3个真实 + 2个占位）
        
        let screenWidth = bounds.width
        let itemWidth: CGFloat = 80 // 每个标签的宽度
        
        // 布局方案：
        // 首页：距离左边缘 20px
        // 创作：居中
        // 设置：距离右边缘 20px
        // 占位符：填充首页和创作之间、创作和设置之间的空间
        
        // 计算位置
        let homeX = edgeInset // 首页：左边缘 + 20px
        let settingsX = screenWidth - edgeInset - itemWidth // 设置：右边缘 - 20px - 宽度
        let creationX = (screenWidth - itemWidth) / 2.0 // 创作：居中
        
        // 占位符位置（填充空隙）
        let spacer1X = homeX + itemWidth
        let spacer1Width = creationX - spacer1X
        let spacer2X = creationX + itemWidth
        let spacer2Width = settingsX - spacer2X
        
        // 按照 viewControllers 的顺序布局：首页(0) - 占位1(1) - 创作(2) - 占位2(3) - 设置(4)
        for (index, button) in buttons.enumerated() {
            var frame = button.frame
            
            switch index {
            case 0: // 首页
                frame.origin.x = homeX
                frame.size.width = itemWidth
            case 1: // 占位符1
                frame.origin.x = spacer1X
                frame.size.width = spacer1Width
            case 2: // 创作（居中）
                frame.origin.x = creationX
                frame.size.width = itemWidth
            case 3: // 占位符2
                frame.origin.x = spacer2X
                frame.size.width = spacer2Width
            case 4: // 设置
                frame.origin.x = settingsX
                frame.size.width = itemWidth
            default:
                break
            }
            
            button.frame = frame
            
            // 强制刷新按钮内部布局，确保文字正确显示
            button.setNeedsLayout()
            button.layoutIfNeeded()
        }
    }
}
