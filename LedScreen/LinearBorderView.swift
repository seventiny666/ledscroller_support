import UIKit

// 线性边框样式枚举
enum LinearBorderStyle: Int, CaseIterable {
    case red = 0, green, blue, yellow, purple, cyan, orange, white
    
    var color: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case .green: return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .blue: return UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        case .yellow: return UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .purple: return UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case .cyan: return UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .orange: return UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .white: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    // 获取更亮的颜色版本（用于最内边框）
    var brightColor: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        case .green: return UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
        case .blue: return UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        case .yellow: return UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
        case .purple: return UIColor(red: 1.0, green: 0.4, blue: 1.0, alpha: 1.0)
        case .cyan: return UIColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0)
        case .orange: return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        case .white: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
}

// 线性边框视图 - 三层边框系统
class LinearBorderView: UIView {
    
    enum DisplayMode {
        case selection      // 选择按钮模式（8个小卡片）
        case preview        // 创建页面预览区模式
        case fullscreen     // 全屏预览模式
    }
    
    private var style: LinearBorderStyle = .red
    private var displayMode: DisplayMode = .fullscreen
    private var outerBorderLayer: CAShapeLayer?
    private var middleBorderLayer: CAShapeLayer?
    private var innerBorderLayer: CAShapeLayer?
    private var outerGlowLayers: [CAShapeLayer] = []
    private var middleGlowLayers: [CAShapeLayer] = []
    private var innerGlowLayers: [CAShapeLayer] = []
    
    init(style: LinearBorderStyle = .red, isSelectionMode: Bool = false) {
        self.style = style
        self.displayMode = isSelectionMode ? .selection : .preview
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
    }
    
    private func setupBorders() {
        // 清除旧的边框和发光层
        outerBorderLayer?.removeFromSuperlayer()
        middleBorderLayer?.removeFromSuperlayer()
        innerBorderLayer?.removeFromSuperlayer()
        outerGlowLayers.forEach { $0.removeFromSuperlayer() }
        middleGlowLayers.forEach { $0.removeFromSuperlayer() }
        innerGlowLayers.forEach { $0.removeFromSuperlayer() }
        outerGlowLayers.removeAll()
        middleGlowLayers.removeAll()
        innerGlowLayers.removeAll()
        
        let bounds = self.bounds
        
        // 根据模式选择不同的参数
        let outerInset: CGFloat
        let outerLineWidth: CGFloat
        let outerCornerRadius: CGFloat
        let outerGlow1Width: CGFloat
        let outerGlow2Width: CGFloat
        let outerGlowOpacity: Float
        let outerShadowRadius: CGFloat
        let outerShadowOpacity: Float
        let outerDashPattern: [NSNumber]
        
        let middleInset: CGFloat
        let middleLineWidth: CGFloat
        let middleCornerRadius: CGFloat
        let middleGlow1Width: CGFloat
        let middleGlow2Width: CGFloat
        let middleGlowOpacity: Float
        let middleShadowRadius: CGFloat
        let middleShadowOpacity: Float
        
        let innerInset: CGFloat
        let innerLineWidth: CGFloat
        let innerCornerRadius: CGFloat
        let innerGlow1Width: CGFloat
        let innerGlow2Width: CGFloat
        let innerGlowOpacity: Float
        let innerShadowRadius: CGFloat
        let innerShadowOpacity: Float
        
        switch displayMode {
        case .selection:
            // 选择按钮模式 - 更小更精致，发光效果减弱
            outerInset = 4
            outerLineWidth = 2
            outerCornerRadius = 5
            outerGlow1Width = 8
            outerGlow2Width = 18
            outerGlowOpacity = 0.1
            outerShadowRadius = 8.0
            outerShadowOpacity = 0.3
            outerDashPattern = [60, 6]
            
            middleInset = 7
            middleLineWidth = 1.3
            middleCornerRadius = 4
            middleGlow1Width = 6
            middleGlow2Width = 16
            middleGlowOpacity = 0.1
            middleShadowRadius = 6.0
            middleShadowOpacity = 0.3
            
            innerInset = 10
            innerLineWidth = 1.2
            innerCornerRadius = 4
            innerGlow1Width = 6
            innerGlow2Width = 16
            innerGlowOpacity = 0.1
            innerShadowRadius = 6.0
            innerShadowOpacity = 0.3
            
        case .preview:
            // 创建页面预览区模式 - 适中尺寸，适中发光
            outerInset = 18
            outerLineWidth = 8
            outerCornerRadius = 12
            outerGlow1Width = 14
            outerGlow2Width = 20
            outerGlowOpacity = 0.2
            outerShadowRadius = 8.0
            outerShadowOpacity = 0.6
            outerDashPattern = [50, 3]
            
            middleInset = 28
            middleLineWidth = 3
            middleCornerRadius = 12
            middleGlow1Width = 7
            middleGlow2Width = 18
            middleGlowOpacity = 0.2
            middleShadowRadius = 7.0
            middleShadowOpacity = 0.5
            
            innerInset = 40
            innerLineWidth = 3
            innerCornerRadius = 12
            innerGlow1Width = 7
            innerGlow2Width = 18
            innerGlowOpacity = 0.2
            innerShadowRadius = 8.0
            innerShadowOpacity = 0.6
            
        case .fullscreen:
            // 全屏预览模式 - 更大的尺寸，发光效果强
            outerInset = 26
            outerLineWidth = 8
            outerCornerRadius = 36
            outerGlow1Width = 16
            outerGlow2Width = 28
            outerGlowOpacity = 0.3
            outerShadowRadius = 12.0
            outerShadowOpacity = 1.0
            outerDashPattern = [70, 6]
            
            middleInset = 40
            middleLineWidth = 3
            middleCornerRadius = 36
            middleGlow1Width = 11
            middleGlow2Width = 23
            middleGlowOpacity = 0.3
            middleShadowRadius = 10.0
            middleShadowOpacity = 1.0
            
            innerInset = 66
            innerLineWidth = 3
            innerCornerRadius = 36
            innerGlow1Width = 11
            innerGlow2Width = 23
            innerGlowOpacity = 0.3
            innerShadowRadius = 10.0
            innerShadowOpacity = 1.0
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
        
        // 外层边框 - 第二层发光
        let outerGlow2 = CAShapeLayer()
        outerGlow2.path = outerPath.cgPath
        outerGlow2.fillColor = UIColor.clear.cgColor
        outerGlow2.strokeColor = style.color.cgColor
        outerGlow2.lineWidth = outerGlow2Width
        outerGlow2.lineDashPattern = outerDashPattern
        outerGlow2.opacity = outerGlowOpacity
        layer.addSublayer(outerGlow2)
        outerGlowLayers.append(outerGlow2)
        
        // 外层边框 - 主边框
        outerBorderLayer = CAShapeLayer()
        outerBorderLayer!.path = outerPath.cgPath
        outerBorderLayer!.fillColor = UIColor.clear.cgColor
        outerBorderLayer!.strokeColor = UIColor.white.cgColor
        outerBorderLayer!.lineWidth = outerLineWidth
        outerBorderLayer!.lineDashPattern = outerDashPattern
        outerBorderLayer!.shadowColor = style.color.cgColor
        outerBorderLayer!.shadowRadius = outerShadowRadius
        outerBorderLayer!.shadowOpacity = outerShadowOpacity
        outerBorderLayer!.shadowOffset = .zero
        layer.addSublayer(outerBorderLayer!)
        
        // 中层实线边框
        let middleRect = bounds.insetBy(dx: middleInset, dy: middleInset)
        let middlePath = UIBezierPath(roundedRect: middleRect, cornerRadius: middleCornerRadius)
        
        // 中层边框 - 第一层发光
        let middleGlow1 = CAShapeLayer()
        middleGlow1.path = middlePath.cgPath
        middleGlow1.fillColor = UIColor.clear.cgColor
        middleGlow1.strokeColor = style.color.cgColor
        middleGlow1.lineWidth = middleGlow1Width
        middleGlow1.opacity = middleGlowOpacity
        layer.addSublayer(middleGlow1)
        middleGlowLayers.append(middleGlow1)
        
        // 中层边框 - 第二层发光
        let middleGlow2 = CAShapeLayer()
        middleGlow2.path = middlePath.cgPath
        middleGlow2.fillColor = UIColor.clear.cgColor
        middleGlow2.strokeColor = style.color.cgColor
        middleGlow2.lineWidth = middleGlow2Width
        middleGlow2.opacity = middleGlowOpacity
        layer.addSublayer(middleGlow2)
        middleGlowLayers.append(middleGlow2)
        
        // 中层边框 - 主边框
        middleBorderLayer = CAShapeLayer()
        middleBorderLayer!.path = middlePath.cgPath
        middleBorderLayer!.fillColor = UIColor.clear.cgColor
        middleBorderLayer!.strokeColor = UIColor.white.cgColor
        middleBorderLayer!.lineWidth = middleLineWidth
        middleBorderLayer!.shadowColor = style.color.cgColor
        middleBorderLayer!.shadowRadius = middleShadowRadius
        middleBorderLayer!.shadowOpacity = middleShadowOpacity
        middleBorderLayer!.shadowOffset = .zero
        layer.addSublayer(middleBorderLayer!)
        
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
        
        // 最内边框 - 第二层发光
        let innerGlow2 = CAShapeLayer()
        innerGlow2.path = innerPath.cgPath
        innerGlow2.fillColor = UIColor.clear.cgColor
        innerGlow2.strokeColor = style.brightColor.cgColor
        innerGlow2.lineWidth = innerGlow2Width
        innerGlow2.opacity = innerGlowOpacity
        layer.addSublayer(innerGlow2)
        innerGlowLayers.append(innerGlow2)
        
        // 最内边框 - 主边框（使用亮色）
        innerBorderLayer = CAShapeLayer()
        innerBorderLayer!.path = innerPath.cgPath
        innerBorderLayer!.fillColor = UIColor.clear.cgColor
        innerBorderLayer!.strokeColor = style.brightColor.cgColor
        innerBorderLayer!.lineWidth = innerLineWidth
        innerBorderLayer!.shadowColor = style.brightColor.cgColor
        innerBorderLayer!.shadowRadius = innerShadowRadius
        innerBorderLayer!.shadowOpacity = innerShadowOpacity
        innerBorderLayer!.shadowOffset = .zero
        layer.addSublayer(innerBorderLayer!)
    }
    
    func setStyle(_ newStyle: LinearBorderStyle) {
        style = newStyle
        setupBorders()
    }
}
