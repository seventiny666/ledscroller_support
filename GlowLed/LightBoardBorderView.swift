import UIKit

// 灯牌边框样式枚举
enum LightBoardBorderStyle: Int, CaseIterable {
    case style1 = 0
    case style2
    case style3
    case style4
    case style5
    case style6
    case style7
    case style8
    case style9
    case style10
    case style11
    case style12
}

// 灯牌边框视图（带呼吸灯效果的圆点边框）
class LightBoardBorderView: UIView {
    
    private var currentStyle: LightBoardBorderStyle = .style1
    private var dotLayers: [CAShapeLayer] = []
    private let displayMode: DisplayMode
    
    enum DisplayMode {
        case selection      // 选择按钮模式
        case preview       // 预览模式
        case fullScreen    // 全屏模式
        case cardCover     // 创作模块卡片封面模式
    }
    
    init(displayMode: DisplayMode = .preview) {
        self.displayMode = displayMode
        super.init(frame: .zero)
        setupView()
    }
    
    // 保持向后兼容
    init(isPreviewMode: Bool = true) {
        self.displayMode = isPreviewMode ? .preview : .selection
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.displayMode = .preview
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    func setStyle(_ style: LightBoardBorderStyle) {
        currentStyle = style
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorder()
    }
    
    private func updateBorder() {
        // 移除旧的圆点层
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
        
        // 根据显示模式设置参数
        let dotSize: CGFloat
        let borderWidth: CGFloat
        let safeInset: CGFloat
        let cornerRadius: CGFloat
        
        switch displayMode {
        case .selection:
            dotSize = 6
            borderWidth = 10  // 边框宽度
            safeInset = 12
            cornerRadius = 8
        case .preview:
            dotSize = 8
            borderWidth = 12  // 边框宽度
            safeInset = 12
            cornerRadius = 16
        case .fullScreen:
            dotSize = 16
            borderWidth = 20  // 边框宽度
            safeInset = 20
            cornerRadius = 40
        case .cardCover:
            dotSize = 12
            borderWidth = 16  // 边框宽度
            safeInset = 12
            cornerRadius = 12
        }
        
        // 计算边框路径
        let borderRect = bounds.insetBy(dx: safeInset, dy: safeInset)
        
        // 根据样式获取边框颜色和圆点数量
        let (borderColor, dotCount) = getStyleProperties(currentStyle)
        
        // 绘制边框
        let borderLayer = CAShapeLayer()
        borderLayer.path = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius).cgPath
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = borderWidth
        layer.addSublayer(borderLayer)
        
        // 计算圆点位置
        let _ = 2 * (borderRect.width + borderRect.height - 4 * cornerRadius) + 2 * .pi * cornerRadius
        
        // 创建圆点
        for i in 0..<dotCount {
            let progress = CGFloat(i) / CGFloat(dotCount)
            let position = calculatePositionOnRoundedRect(progress: progress, rect: borderRect, cornerRadius: cornerRadius)
            
            let dotLayer = CAShapeLayer()
            // 创建以原点为中心的圆形路径
            let dotRect = CGRect(x: -dotSize/2, y: -dotSize/2, width: dotSize, height: dotSize)
            dotLayer.path = UIBezierPath(ovalIn: dotRect).cgPath
            dotLayer.fillColor = UIColor.white.cgColor
            dotLayer.position = position
            
            // 添加发光效果
            dotLayer.shadowColor = UIColor.white.cgColor
            dotLayer.shadowRadius = dotSize * 0.6
            dotLayer.shadowOpacity = 0.9
            dotLayer.shadowOffset = .zero
            
            // 只在预览模式和全屏模式下添加呼吸灯动画
            if displayMode == .preview || displayMode == .fullScreen {
                addBreathingAnimation(to: dotLayer, index: i)
            }
            
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
    }
    
    private func getStyleProperties(_ style: LightBoardBorderStyle) -> (UIColor, Int) {
        // 根据显示模式调整圆点数量
        let baseDotCount: Int
        switch displayMode {
        case .selection:
            baseDotCount = 16
        case .preview:
            baseDotCount = 24
        case .fullScreen:
            baseDotCount = 48
        case .cardCover:
            baseDotCount = 20
        }
        
        let borderColor: UIColor
        switch style {
        case .style1:
            borderColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // 红色
        case .style2:
            borderColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0) // 绿色
        case .style3:
            borderColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0) // 蓝色
        case .style4:
            borderColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) // 黄色
        case .style5:
            borderColor = UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0) // 洋红色
        case .style6:
            borderColor = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0) // 青色
        case .style7:
            borderColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0) // 橙色
        case .style8:
            borderColor = UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0) // 紫色
        case .style9:
            borderColor = UIColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1.0) // 粉色
        case .style10:
            borderColor = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0) // 翠绿色
        case .style11:
            borderColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 金色
        case .style12:
            borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // 银色
        }
        
        return (borderColor, baseDotCount)
    }
    
    private func calculatePositionOnRoundedRect(progress: CGFloat, rect: CGRect, cornerRadius: CGFloat) -> CGPoint {
        let width = rect.width
        let height = rect.height
        
        // 各段长度
        let topLength = width - 2 * cornerRadius
        let rightLength = height - 2 * cornerRadius
        let bottomLength = width - 2 * cornerRadius
        let leftLength = height - 2 * cornerRadius
        let cornerLength = .pi * cornerRadius / 2
        
        let totalLength = topLength + rightLength + bottomLength + leftLength + 4 * cornerLength
        let distance = progress * totalLength
        
        var currentDistance = distance
        
        // 顶边（左上角圆弧后到右上角圆弧前）
        if currentDistance <= topLength {
            return CGPoint(x: rect.minX + cornerRadius + currentDistance, y: rect.minY)
        }
        currentDistance -= topLength
        
        // 右上角圆弧
        if currentDistance <= cornerLength {
            let angle = -(.pi / 2) + (currentDistance / cornerRadius)
            let centerX = rect.maxX - cornerRadius
            let centerY = rect.minY + cornerRadius
            return CGPoint(
                x: centerX + cornerRadius * cos(angle),
                y: centerY + cornerRadius * sin(angle)
            )
        }
        currentDistance -= cornerLength
        
        // 右边
        if currentDistance <= rightLength {
            return CGPoint(x: rect.maxX, y: rect.minY + cornerRadius + currentDistance)
        }
        currentDistance -= rightLength
        
        // 右下角圆弧
        if currentDistance <= cornerLength {
            let angle = (currentDistance / cornerRadius)
            let centerX = rect.maxX - cornerRadius
            let centerY = rect.maxY - cornerRadius
            return CGPoint(
                x: centerX + cornerRadius * cos(angle),
                y: centerY + cornerRadius * sin(angle)
            )
        }
        currentDistance -= cornerLength
        
        // 底边
        if currentDistance <= bottomLength {
            return CGPoint(x: rect.maxX - cornerRadius - currentDistance, y: rect.maxY)
        }
        currentDistance -= bottomLength
        
        // 左下角圆弧
        if currentDistance <= cornerLength {
            let angle = (.pi / 2) + (currentDistance / cornerRadius)
            let centerX = rect.minX + cornerRadius
            let centerY = rect.maxY - cornerRadius
            return CGPoint(
                x: centerX + cornerRadius * cos(angle),
                y: centerY + cornerRadius * sin(angle)
            )
        }
        currentDistance -= cornerLength
        
        // 左边
        if currentDistance <= leftLength {
            return CGPoint(x: rect.minX, y: rect.maxY - cornerRadius - currentDistance)
        }
        currentDistance -= leftLength
        
        // 左上角圆弧
        let angle = .pi + (currentDistance / cornerRadius)
        let centerX = rect.minX + cornerRadius
        let centerY = rect.minY + cornerRadius
        return CGPoint(
            x: centerX + cornerRadius * cos(angle),
            y: centerY + cornerRadius * sin(angle)
        )
    }
    
    private func addBreathingAnimation(to layer: CAShapeLayer, index: Int) {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        
        // 交替呼吸效果：奇偶圆点相位相反
        if index % 2 == 0 {
            // 偶数圆点：从亮到暗
            animation.values = [1.0, 1.0, 0.5, 0.5, 1.0]
            animation.keyTimes = [0.0, 0.25, 0.5, 0.75, 1.0]
        } else {
            // 奇数圆点：从暗到亮（相反相位）
            animation.values = [0.5, 0.5, 1.0, 1.0, 0.5]
            animation.keyTimes = [0.0, 0.25, 0.5, 0.75, 1.0]
        }
        
        animation.duration = 2.0
        animation.repeatCount = .infinity
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        
        layer.add(animation, forKey: "breathingAnimation")
    }
}
