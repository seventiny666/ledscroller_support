import UIKit

// 跑马灯边框样式枚举
enum MarqueeBorderStyle: Int, CaseIterable {
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

// 跑马灯边框视图（圆点流动边框）
class MarqueeBorderView: UIView {
    
    private var currentStyle: MarqueeBorderStyle = .style1
    private var isAnimated: Bool = false
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
    
    override init(frame: CGRect) {
        self.displayMode = .preview
        super.init(frame: frame)
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
    
    func setStyle(_ style: MarqueeBorderStyle) {
        currentStyle = style
        setNeedsLayout()
    }
    
    func setAnimated(_ animated: Bool) {
        isAnimated = animated
        if animated {
            startAnimation()
        } else {
            stopAnimation()
        }
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
        let safeInset: CGFloat
        let cornerRadius: CGFloat
        
        switch displayMode {
        case .selection:
            dotSize = 6
            safeInset = 12
            cornerRadius = 8
        case .preview:
            dotSize = 8
            safeInset = 12
            cornerRadius = 8
        case .fullScreen:
            dotSize = 16
            safeInset = 20
            cornerRadius = 40
        case .cardCover:
            dotSize = 8 // cover dots: 2pt smaller diameter; keep fullScreen unchanged
            safeInset = 6 // closer to edge, still within safe inset
            cornerRadius = 8
        }
        
        // 计算边框路径（圆角矩形）- 确保边框居中
        let borderRect = bounds.insetBy(dx: safeInset, dy: safeInset)
        
        // 根据样式设置圆点数量和颜色
        let (dotCount, dotColor) = getStyleProperties(currentStyle)
        
        // 创建圆角矩形路径上的圆点
        let points = calculateRoundedRectPoints(rect: borderRect, cornerRadius: cornerRadius, dotCount: dotCount)
        
        for (_, point) in points.enumerated() {
            let dotLayer = CAShapeLayer()
            // 创建以原点为中心的圆形路径
            let dotRect = CGRect(x: -dotSize/2, y: -dotSize/2, width: dotSize, height: dotSize)
            dotLayer.path = UIBezierPath(ovalIn: dotRect).cgPath
            dotLayer.fillColor = dotColor.cgColor
            // position是圆点的中心点，这样圆点就会以point为中心显示
            dotLayer.position = point
            
            // 添加发光效果
            dotLayer.shadowColor = dotColor.cgColor
            dotLayer.shadowRadius = dotSize * 0.8
            dotLayer.shadowOpacity = 0.9
            dotLayer.shadowOffset = .zero
            
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
        
        if isAnimated {
            startAnimation()
        }
    }
    
    private func getStyleProperties(_ style: MarqueeBorderStyle) -> (Int, UIColor) {
        // 根据显示模式调整圆点数量
        let baseCount: Int
        let color: UIColor
        
        switch style {
        case .style1:
            baseCount = 32
            color = UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0) // 洋红色
        case .style2:
            baseCount = 28
            color = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0) // 青色
        case .style3:
            baseCount = 36
            color = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) // 黄色
        case .style4:
            baseCount = 24
            color = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // 红色
        case .style5:
            baseCount = 40
            color = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0) // 绿色
        case .style6:
            baseCount = 32
            color = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0) // 蓝色
        case .style7:
            baseCount = 28
            color = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0) // 橙色
        case .style8:
            baseCount = 36
            color = UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0) // 紫色
        case .style9:
            baseCount = 24
            color = UIColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1.0) // 粉色
        case .style10:
            baseCount = 40
            color = UIColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 1.0) // 翠绿色
        case .style11:
            baseCount = 32
            color = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // 金色
        case .style12:
            baseCount = 28
            color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // 白色
        }
        
        // 根据显示模式调整圆点数量
        let dotCount: Int
        switch displayMode {
        case .selection:
            dotCount = max(baseCount / 2, 16)
        case .preview:
            dotCount = baseCount
        case .fullScreen:
            dotCount = baseCount * 2  // 全屏模式使用更多圆点
        case .cardCover:
            dotCount = max(baseCount * 3 / 4, 20)  // 创作模块卡片封面模式
        }
        
        return (dotCount, color)
    }
    
    private func calculateRoundedRectPoints(rect: CGRect, cornerRadius: CGFloat, dotCount: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // 计算圆角矩形的周长
        let width = rect.width
        let height = rect.height
        let perimeter = 2 * (width + height) - 8 * cornerRadius + 2 * .pi * cornerRadius
        
        for i in 0..<dotCount {
            let progress = CGFloat(i) / CGFloat(dotCount)
            let distance = progress * perimeter
            
            let point = calculatePointOnRoundedRect(rect: rect, cornerRadius: cornerRadius, distance: distance, perimeter: perimeter)
            points.append(point)
        }
        
        return points
    }
    
    private func calculatePointOnRoundedRect(rect: CGRect, cornerRadius: CGFloat, distance: CGFloat, perimeter: CGFloat) -> CGPoint {
        let width = rect.width
        let height = rect.height
        
        // 各段长度
        let topLength = width - 2 * cornerRadius
        let rightLength = height - 2 * cornerRadius
        let bottomLength = width - 2 * cornerRadius
        let leftLength = height - 2 * cornerRadius
        let cornerLength = .pi * cornerRadius / 2
        
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
    
    private func startAnimation() {
        guard !dotLayers.isEmpty else { return }
        
        for (index, dotLayer) in dotLayers.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [0.3, 1.0, 0.3]
            animation.keyTimes = [0.0, 0.5, 1.0]
            animation.duration = 2.0
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.05 // 错开时间创造流动效果
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            dotLayer.add(animation, forKey: "marqueeBorderAnimation")
        }
    }
    
    private func stopAnimation() {
        dotLayers.forEach { $0.removeAnimation(forKey: "marqueeBorderAnimation") }
    }
}
