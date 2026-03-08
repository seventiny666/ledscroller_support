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
    
    private var style: LinearBorderStyle = .red
    private var outerBorderLayer: CAShapeLayer?
    private var middleBorderLayer: CAShapeLayer?
    private var innerBorderLayer: CAShapeLayer?
    private var outerGlowLayers: [CAShapeLayer] = []
    private var middleGlowLayers: [CAShapeLayer] = []
    private var innerGlowLayers: [CAShapeLayer] = []
    
    init(style: LinearBorderStyle = .red) {
        self.style = style
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
        
        // 外层虚线边框 - 距离边缘20px，线宽8px，圆角20px
        let outerInset: CGFloat = 20
        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let outerPath = UIBezierPath(roundedRect: outerRect, cornerRadius: 20)
        
        // 外层边框 - 第一层发光（扩展4px）
        let outerGlow1 = CAShapeLayer()
        outerGlow1.path = outerPath.cgPath
        outerGlow1.fillColor = UIColor.clear.cgColor
        outerGlow1.strokeColor = style.color.cgColor
        outerGlow1.lineWidth = 8 + 8
        outerGlow1.lineDashPattern = [70, 6]
        outerGlow1.opacity = 0.3
        layer.addSublayer(outerGlow1)
        outerGlowLayers.append(outerGlow1)
        
        // 外层边框 - 第二层发光（扩展10px）
        let outerGlow2 = CAShapeLayer()
        outerGlow2.path = outerPath.cgPath
        outerGlow2.fillColor = UIColor.clear.cgColor
        outerGlow2.strokeColor = style.color.cgColor
        outerGlow2.lineWidth = 8 + 20
        outerGlow2.lineDashPattern = [70, 6]
        outerGlow2.opacity = 0.15
        layer.addSublayer(outerGlow2)
        outerGlowLayers.append(outerGlow2)
        
        // 外层边框 - 主边框
        outerBorderLayer = CAShapeLayer()
        outerBorderLayer!.path = outerPath.cgPath
        outerBorderLayer!.fillColor = UIColor.clear.cgColor
        outerBorderLayer!.strokeColor = UIColor.white.cgColor
        outerBorderLayer!.lineWidth = 8
        outerBorderLayer!.lineDashPattern = [70, 6]
        outerBorderLayer!.shadowColor = style.color.cgColor
        outerBorderLayer!.shadowRadius = 12.0
        outerBorderLayer!.shadowOpacity = 1.0
        outerBorderLayer!.shadowOffset = .zero
        layer.addSublayer(outerBorderLayer!)
        
        // 中层实线边框 - 距离边缘34px，线宽3px，圆角20px
        let middleInset: CGFloat = 34
        let middleRect = bounds.insetBy(dx: middleInset, dy: middleInset)
        let middlePath = UIBezierPath(roundedRect: middleRect, cornerRadius: 20)
        
        // 中层边框 - 第一层发光
        let middleGlow1 = CAShapeLayer()
        middleGlow1.path = middlePath.cgPath
        middleGlow1.fillColor = UIColor.clear.cgColor
        middleGlow1.strokeColor = style.color.cgColor
        middleGlow1.lineWidth = 3 + 8
        middleGlow1.opacity = 0.3
        layer.addSublayer(middleGlow1)
        middleGlowLayers.append(middleGlow1)
        
        // 中层边框 - 第二层发光
        let middleGlow2 = CAShapeLayer()
        middleGlow2.path = middlePath.cgPath
        middleGlow2.fillColor = UIColor.clear.cgColor
        middleGlow2.strokeColor = style.color.cgColor
        middleGlow2.lineWidth = 3 + 20
        middleGlow2.opacity = 0.15
        layer.addSublayer(middleGlow2)
        middleGlowLayers.append(middleGlow2)
        
        // 中层边框 - 主边框
        middleBorderLayer = CAShapeLayer()
        middleBorderLayer!.path = middlePath.cgPath
        middleBorderLayer!.fillColor = UIColor.clear.cgColor
        middleBorderLayer!.strokeColor = UIColor.white.cgColor
        middleBorderLayer!.lineWidth = 3
        middleBorderLayer!.shadowColor = style.color.cgColor
        middleBorderLayer!.shadowRadius = 10.0
        middleBorderLayer!.shadowOpacity = 1.0
        middleBorderLayer!.shadowOffset = .zero
        layer.addSublayer(middleBorderLayer!)
        
        // 最内层实线边框 - 距离边缘60px，线宽3px，圆角20px，使用亮色
        let innerInset: CGFloat = 60
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 20)
        
        // 最内边框 - 第一层发光
        let innerGlow1 = CAShapeLayer()
        innerGlow1.path = innerPath.cgPath
        innerGlow1.fillColor = UIColor.clear.cgColor
        innerGlow1.strokeColor = style.brightColor.cgColor
        innerGlow1.lineWidth = 3 + 8
        innerGlow1.opacity = 0.3
        layer.addSublayer(innerGlow1)
        innerGlowLayers.append(innerGlow1)
        
        // 最内边框 - 第二层发光
        let innerGlow2 = CAShapeLayer()
        innerGlow2.path = innerPath.cgPath
        innerGlow2.fillColor = UIColor.clear.cgColor
        innerGlow2.strokeColor = style.brightColor.cgColor
        innerGlow2.lineWidth = 3 + 20
        innerGlow2.opacity = 0.15
        layer.addSublayer(innerGlow2)
        innerGlowLayers.append(innerGlow2)
        
        // 最内边框 - 主边框（使用亮色）
        innerBorderLayer = CAShapeLayer()
        innerBorderLayer!.path = innerPath.cgPath
        innerBorderLayer!.fillColor = UIColor.clear.cgColor
        innerBorderLayer!.strokeColor = style.brightColor.cgColor
        innerBorderLayer!.lineWidth = 3
        innerBorderLayer!.shadowColor = style.brightColor.cgColor
        innerBorderLayer!.shadowRadius = 10.0
        innerBorderLayer!.shadowOpacity = 1.0
        innerBorderLayer!.shadowOffset = .zero
        layer.addSublayer(innerBorderLayer!)
    }
    
    func setStyle(_ newStyle: LinearBorderStyle) {
        style = newStyle
        setupBorders()
    }
}
