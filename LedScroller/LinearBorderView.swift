import UIKit

// 线性边框样式枚举
enum LinearBorderStyle: Int, CaseIterable {
    case red = 0, green, blue, yellow, purple, cyan, orange, white
    case pink, gold, coral, teal
    
    var color: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case .green: return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .blue: return UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0) // 提高亮度和饱和度
        case .yellow: return UIColor(red: 1.0, green: 0.95, blue: 0.0, alpha: 1.0) // 提高饱和度
        case .purple: return UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case .cyan: return UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .orange: return UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .white: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // 新增4个颜色 - 第三行
        case .pink: return UIColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1.0) // Deep Pink #FF1493
        case .gold: return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold #FFD700
        case .coral: return UIColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0) // Tomato #FF6347
        case .teal: return UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1.0) // Dark Turquoise #00CED1
        }
    }
    
    // 获取更亮的颜色版本（用于最内边框）
    var brightColor: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        case .green: return UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
        case .blue: return UIColor(red: 0.3, green: 0.75, blue: 1.0, alpha: 1.0) // 亮蓝色 - 调整以匹配新的基础蓝色
        case .yellow: return UIColor(red: 1.0, green: 0.98, blue: 0.5, alpha: 1.0) // 亮黄色 - 调整以匹配新的基础黄色
        case .purple: return UIColor(red: 1.0, green: 0.4, blue: 1.0, alpha: 1.0)
        case .cyan: return UIColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0)
        case .orange: return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        case .white: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // 新增4个颜色的亮色版本
        case .pink: return UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1.0) // 亮粉色
        case .gold: return UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0) // 亮金色
        case .coral: return UIColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 1.0) // 亮珊瑚色
        case .teal: return UIColor(red: 0.3, green: 0.9, blue: 0.9, alpha: 1.0) // 亮青绿色
        }
    }
}

// 线性边框视图 - 外层边框 + 中间圆点 + 内层边框系统
class LinearBorderView: UIView {
    
    enum DisplayMode {
        case selection      // 选择按钮模式（8个小卡片）
        case preview        // 创建页面预览区模式
        case fullscreen     // 全屏预览模式
        case cardCover      // 创作模块卡片封面模式
    }
    
    private var style: LinearBorderStyle = .red
    private var displayMode: DisplayMode = .fullscreen
    private var outerBorderLayer: CAShapeLayer?
    private var innerBorderLayer: CAShapeLayer?
    private var outerGlowLayers: [CAShapeLayer] = []
    private var innerGlowLayers: [CAShapeLayer] = []
    
    // 圆点相关属性
    private var dotLayers: [CAShapeLayer] = []
    private var dotAnimationTimer: Timer?
    
    init(style: LinearBorderStyle = .red, isSelectionMode: Bool = false) {
        self.style = style
        self.displayMode = isSelectionMode ? .selection : .preview
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    init(style: LinearBorderStyle = .red, displayMode: DisplayMode) {
        self.style = style
        self.displayMode = displayMode
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupBorders()
        setupDots()
        // 只在全屏模式下添加呼吸动画
        if displayMode == .fullscreen {
            startBreathingAnimation()
        }
    }
    
    deinit {
        stopDotAnimation()
    }
    
    private func setupBorders() {
        // 清除旧的边框和发光层
        outerBorderLayer?.removeFromSuperlayer()
        innerBorderLayer?.removeFromSuperlayer()
        outerGlowLayers.forEach { $0.removeFromSuperlayer() }
        innerGlowLayers.forEach { $0.removeFromSuperlayer() }
        outerGlowLayers.removeAll()
        innerGlowLayers.removeAll()
        
        let bounds = self.bounds
        
        // 根据模式选择不同的参数
        let outerInset: CGFloat
        let outerLineWidth: CGFloat
        let outerCornerRadius: CGFloat
        let outerGlow1Width: CGFloat
        let outerGlowOpacity: Float
        let outerDashPattern: [NSNumber]
        
        let innerInset: CGFloat
        let innerLineWidth: CGFloat
        let innerCornerRadius: CGFloat
        let innerGlow1Width: CGFloat
        let innerGlowOpacity: Float
        
        switch displayMode {
        case .selection:
            // 选择按钮模式
            outerInset = 4
            outerLineWidth = 2
            outerCornerRadius = 5
            outerGlow1Width = 8
            outerGlowOpacity = 0.1
            outerDashPattern = [60, 6]
            
            innerInset = 10
            innerLineWidth = 1.2
            innerCornerRadius = 4
            innerGlow1Width = 6
            innerGlowOpacity = 0.1
            
        case .preview:
            // 创建页面预览区模式
            outerInset = 10
            outerLineWidth = 6
            outerCornerRadius = 12
            outerGlow1Width = 14
            outerGlowOpacity = 0.2
            outerDashPattern = [50, 3]
            
            innerInset = 32  // 内边框距离再-4px
            innerLineWidth = 3
            innerCornerRadius = 12
            innerGlow1Width = 7
            innerGlowOpacity = 0.2
            
        case .fullscreen:
            // 全屏预览模式
            outerInset = 24
            outerLineWidth = 8
            outerCornerRadius = 34
            outerGlow1Width = 16
            outerGlowOpacity = 0.2
            outerDashPattern = [76, 6]
            
            innerInset = 70
            innerLineWidth = 3
            innerCornerRadius = 30
            innerGlow1Width = 11
            innerGlowOpacity = 0.2
            
        case .cardCover:
            // 卡片封面模式
            // Expand borders outward, but keep a small safe distance from the cover edge.
            outerInset = 6
            outerLineWidth = 2
            outerCornerRadius = 10 // -2pt
            outerGlow1Width = 14
            outerGlowOpacity = 0.2
            outerDashPattern = [50, 3]
            
            // Make the inner border larger (closer to the cover safe area) so it wraps around the cover text.
            innerInset = 16
            innerLineWidth = 1 // -2pt
            innerCornerRadius = 8 // -4pt
            innerGlow1Width = 7
            innerGlowOpacity = 0.2
        }
        
        // 外层虚线边框
        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let outerPath = UIBezierPath(roundedRect: outerRect, cornerRadius: outerCornerRadius)
        
        // 外层边框 - 第一层发光
        let outerGlow1 = CAShapeLayer()
        outerGlow1.path = outerPath.cgPath
        outerGlow1.fillColor = UIColor.clear.cgColor
        outerGlow1.strokeColor = style.color.cgColor
        outerGlow1.lineWidth = outerGlow1Width
        outerGlow1.lineDashPattern = outerDashPattern
        outerGlow1.opacity = outerGlowOpacity
        layer.addSublayer(outerGlow1)
        outerGlowLayers.append(outerGlow1)
        
        // 外层边框 - 主边框（使用调整后的颜色）
        outerBorderLayer = CAShapeLayer()
        outerBorderLayer!.path = outerPath.cgPath
        outerBorderLayer!.fillColor = UIColor.clear.cgColor
        outerBorderLayer!.strokeColor = getAdjustedOuterBorderColor().cgColor  // 使用调整后的颜色
        outerBorderLayer!.lineWidth = outerLineWidth
        outerBorderLayer!.lineDashPattern = outerDashPattern
        layer.addSublayer(outerBorderLayer!)
        
        // 最内层实线边框 - 使用亮色
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: innerCornerRadius)
        
        // 最内边框 - 第一层发光
        let innerGlow1 = CAShapeLayer()
        innerGlow1.path = innerPath.cgPath
        innerGlow1.fillColor = UIColor.clear.cgColor
        innerGlow1.strokeColor = style.brightColor.cgColor
        innerGlow1.lineWidth = innerGlow1Width
        innerGlow1.opacity = innerGlowOpacity
        layer.addSublayer(innerGlow1)
        innerGlowLayers.append(innerGlow1)
        
        // 最内边框 - 主边框（使用亮色）
        innerBorderLayer = CAShapeLayer()
        innerBorderLayer!.path = innerPath.cgPath
        innerBorderLayer!.fillColor = UIColor.clear.cgColor
        innerBorderLayer!.strokeColor = style.brightColor.cgColor
        innerBorderLayer!.lineWidth = innerLineWidth
        layer.addSublayer(innerBorderLayer!)
    }
    
    // 设置中间圆点矩形
    private func setupDots() {
        // 清除旧的圆点
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
        
        let bounds = self.bounds
        
        // 根据模式选择不同的参数
        let outerInset: CGFloat
        let innerInset: CGFloat  // 内边框距离
        let outerCornerRadius: CGFloat  // 外边框的圆角
        let middleCornerRadius: CGFloat // 中间圆点的圆角
        let dotCount: Int  // 圆点数量
        
        switch displayMode {
        case .selection:
            outerInset = 4   // 外边框距离
            innerInset = 10  // 内边框距离
            outerCornerRadius = 5  // 外边框圆角
            middleCornerRadius = 5
            dotCount = 16  // 圆点数量
            
        case .preview:
            outerInset = 10  // 外边框距离
            innerInset = 32  // 内边框距离再-4px (36-4=32)
            outerCornerRadius = 12  // 外边框圆角
            middleCornerRadius = 12
            dotCount = 24  // 圆点数量
            
        case .fullscreen:
            outerInset = 24  // 外边框距离
            innerInset = 70  // 内边框距离
            outerCornerRadius = 34  // 外边框圆角
            middleCornerRadius = 34
            dotCount = 48  // 圆点数量
            
        case .cardCover:
            outerInset = 6   // 外边框距离
            innerInset = 16  // 内边框距离
            outerCornerRadius = 10  // 外边框圆角 (-2pt)
            middleCornerRadius = 8  // 中间圆点圆角 (-4pt)
            dotCount = 24  // 圆点数量
        }
        
        // 计算圆点矩形位置
        let middleInset: CGFloat
        if displayMode == .fullscreen {
            // 全屏模式：白色外框和黄色内框的正中间
            middleInset = (outerInset + innerInset) / 2
        } else if displayMode == .cardCover {
            // Cover: move the dot ring outward (radius +2pt)
            middleInset = outerInset + 6
        } else {
            // 其他模式：外边框距离 + 10px
            middleInset = outerInset + 10
        }
        
        // 圆点直径计算 - 根据模式设置特定尺寸
        var dotSize: CGFloat
        switch displayMode {
        case .selection:
            dotSize = 3  // 3px
        case .preview:
            dotSize = 8  // 8px
        case .fullscreen:
            dotSize = 10  // 10px
        case .cardCover:
            dotSize = 3  // cover dots were too small; make them visible
        }
        
        // 计算中间矩形区域
        let middleRect = bounds.insetBy(dx: middleInset, dy: middleInset)
        
        // 沿着圆角矩形路径放置圆点
        for i in 0..<dotCount {
            let progress = CGFloat(i) / CGFloat(dotCount)
            let position = calculatePositionOnRoundedRect(progress: progress, rect: middleRect, cornerRadius: middleCornerRadius)
            
            let dotLayer = CAShapeLayer()
            // 创建以原点为中心的圆形路径
            let dotRect = CGRect(x: -dotSize/2, y: -dotSize/2, width: dotSize, height: dotSize)
            dotLayer.path = UIBezierPath(ovalIn: dotRect).cgPath
            dotLayer.fillColor = UIColor.white.withAlphaComponent(0.9).cgColor
            dotLayer.position = position
            
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
    }
    
    // 计算圆角矩形路径上的位置（参照LightBoardBorderView的实现）
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
    
    // 开始呼吸动画（仅全屏模式）
    private func startBreathingAnimation() {
        for (index, dotLayer) in dotLayers.enumerated() {
            addBreathingAnimation(to: dotLayer, index: index)
        }
    }
    
    // 停止圆点动画
    private func stopDotAnimation() {
        dotAnimationTimer?.invalidate()
        dotAnimationTimer = nil
        
        // 移除所有动画
        dotLayers.forEach { dotLayer in
            dotLayer.removeAllAnimations()
        }
    }
    
    // 呼吸动画效果（参照灯牌边框）
    private func addBreathingAnimation(to layer: CAShapeLayer, index: Int) {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        
        // 交替呼吸效果：奇偶圆点相位相反，过渡更自然
        if index % 2 == 0 {
            // 偶数圆点：从亮到暗，更平滑的过渡
            animation.values = [1.0, 0.8, 0.4, 0.6, 1.0]
            animation.keyTimes = [0.0, 0.2, 0.5, 0.8, 1.0]
        } else {
            // 奇数圆点：从暗到亮（相反相位），更平滑的过渡
            animation.values = [0.4, 0.6, 1.0, 0.8, 0.4]
            animation.keyTimes = [0.0, 0.2, 0.5, 0.8, 1.0]
        }
        
        animation.duration = 3.0  // 延长动画时间，让过渡更缓慢自然
        animation.repeatCount = .infinity
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        
        layer.add(animation, forKey: "breathingAnimation")
    }
    
    func setStyle(_ newStyle: LinearBorderStyle) {
        style = newStyle
        setupBorders()
        setupDots()
    }
    
    // 获取调整后的外边框颜色（与内边框同色系，但亮度+30%，饱和度-15%）
    private func getAdjustedOuterBorderColor() -> UIColor {
        let baseColor = style.brightColor  // 使用内边框的亮色
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 获取HSB值
        baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // 调整亮度+30%，饱和度-15%
        let adjustedBrightness = min(brightness + 0.3, 1.0)  // 亮度+30%，但不超过1.0
        let adjustedSaturation = max(saturation - 0.15, 0.0)  // 饱和度-15%，但不低于0.0
        
        return UIColor(hue: hue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: alpha)
    }
}
