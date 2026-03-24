import UIKit

class EffectsRenderer: UIView {
    
    private let effects: [LEDConfig.EffectConfig]
    private var displayLink: CADisplayLink?
    private var particles: [Particle] = []
    
    struct Particle {
        var position: CGPoint
        var velocity: CGPoint
        var size: CGFloat
        var color: UIColor
        var alpha: CGFloat
        var type: LEDConfig.EffectConfig.EffectType
    }
    
    init(effects: [LEDConfig.EffectConfig]) {
        self.effects = effects
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimating() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        // 生成新粒子
        for effect in effects {
            if Double.random(in: 0...1) < Double(effect.density) * 0.02 {
                generateParticle(for: effect)
            }
        }
        
        // 更新粒子
        particles = particles.compactMap { particle in
            var updated = particle
            updated.position.x += particle.velocity.x
            updated.position.y += particle.velocity.y
            updated.alpha -= 0.01
            
            // 移除屏幕外或透明的粒子
            if updated.alpha <= 0 || !bounds.contains(updated.position) {
                return nil
            }
            return updated
        }
        
        setNeedsDisplay()
    }
    
    private func generateParticle(for effect: LEDConfig.EffectConfig) {
        let particle: Particle
        
        switch effect.type {
        case .cyberHeart:
            particle = Particle(
                position: CGPoint(x: CGFloat.random(in: 0...bounds.width), y: bounds.height),
                velocity: CGPoint(x: CGFloat.random(in: -1...1), y: -2),
                size: CGFloat.random(in: 10...20),
                color: .systemPink,
                alpha: 1.0,
                type: .cyberHeart
            )
            
        case .fireworks:
            particle = Particle(
                position: CGPoint(x: CGFloat.random(in: 0...bounds.width), y: CGFloat.random(in: 0...bounds.height)),
                velocity: CGPoint(x: CGFloat.random(in: -3...3), y: CGFloat.random(in: -3...3)),
                size: CGFloat.random(in: 3...8),
                color: [UIColor.systemRed, .systemYellow, .systemBlue, .systemPink].randomElement()!,
                alpha: 1.0,
                type: .fireworks
            )
            
        case .meteor:
            particle = Particle(
                position: CGPoint(x: CGFloat.random(in: 0...bounds.width), y: 0),
                velocity: CGPoint(x: CGFloat.random(in: -2...2), y: 5),
                size: CGFloat.random(in: 2...5),
                color: .cyan,
                alpha: 1.0,
                type: .meteor
            )
            
        case .codeRain:
            particle = Particle(
                position: CGPoint(x: CGFloat.random(in: 0...bounds.width), y: 0),
                velocity: CGPoint(x: 0, y: 3),
                size: 12,
                color: .systemGreen,
                alpha: 1.0,
                type: .codeRain
            )
        }
        
        particles.append(particle)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for particle in particles {
            context.setAlpha(particle.alpha)
            
            switch particle.type {
            case .cyberHeart:
                drawHeart(at: particle.position, size: particle.size, color: particle.color, in: context)
                
            case .fireworks:
                context.setFillColor(particle.color.cgColor)
                context.fillEllipse(in: CGRect(x: particle.position.x - particle.size/2,
                                               y: particle.position.y - particle.size/2,
                                               width: particle.size,
                                               height: particle.size))
                
            case .meteor:
                context.setStrokeColor(particle.color.cgColor)
                context.setLineWidth(particle.size)
                context.move(to: particle.position)
                context.addLine(to: CGPoint(x: particle.position.x - particle.velocity.x * 5,
                                           y: particle.position.y - particle.velocity.y * 5))
                context.strokePath()
                
            case .codeRain:
                let text = ["0", "1", "A", "B", "C", "D", "E", "F"].randomElement()!
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: particle.size, weight: .regular),
                    .foregroundColor: particle.color.withAlphaComponent(particle.alpha)
                ]
                text.draw(at: particle.position, withAttributes: attributes)
            }
        }
    }
    
    private func drawHeart(at position: CGPoint, size: CGFloat, color: UIColor, in context: CGContext) {
        let path = UIBezierPath()
        let scale = size / 20
        
        path.move(to: CGPoint(x: position.x, y: position.y + 8 * scale))
        path.addCurve(to: CGPoint(x: position.x - 10 * scale, y: position.y - 2 * scale),
                     controlPoint1: CGPoint(x: position.x, y: position.y + 4 * scale),
                     controlPoint2: CGPoint(x: position.x - 10 * scale, y: position.y + 2 * scale))
        path.addArc(withCenter: CGPoint(x: position.x - 5 * scale, y: position.y - 4 * scale),
                   radius: 5 * scale,
                   startAngle: .pi,
                   endAngle: 0,
                   clockwise: true)
        path.addArc(withCenter: CGPoint(x: position.x + 5 * scale, y: position.y - 4 * scale),
                   radius: 5 * scale,
                   startAngle: .pi,
                   endAngle: 0,
                   clockwise: true)
        path.addCurve(to: CGPoint(x: position.x, y: position.y + 8 * scale),
                     controlPoint1: CGPoint(x: position.x + 10 * scale, y: position.y + 2 * scale),
                     controlPoint2: CGPoint(x: position.x, y: position.y + 4 * scale))
        path.close()
        
        context.setFillColor(color.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
}
