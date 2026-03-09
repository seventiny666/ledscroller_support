import UIKit

// 爱心流星雨视图控制器
class LoveRainViewController: UIViewController {
    
    private var emitterLayers: [CAEmitterLayer] = []
    private var heartShapeLayer: CAShapeLayer?
    private var displayLink: CADisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 添加关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func startAnimation() {
        // 移除代码雨，改为从中心向四周扩散的爱心
        createHeartExplosion()
        
        // 创建实心心形（带高斯模糊）
        createSolidHeartShape()
        
        // 创建持续的爱心扩散效果
        createContinuousHeartExplosion()
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        
        emitterLayers.forEach { $0.removeFromSuperlayer() }
        emitterLayers.removeAll()
        
        heartShapeLayer?.removeFromSuperlayer()
        heartShapeLayer = nil
    }
    
    // 创建从中心向四周扩散的爱心
    private func createHeartExplosion() {
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: centerX, y: centerY)
        emitter.emitterShape = .point
        emitter.emitterSize = CGSize(width: 1, height: 1)
        emitter.renderMode = .additive
        
        // 创建多种大小的爱心粒子
        var cells: [CAEmitterCell] = []
        
        // 大爱心
        let largeCell = createHeartCell(scale: 0.8, birthRate: 3, lifetime: 6.0, velocity: 80)
        cells.append(largeCell)
        
        // 中等爱心
        let mediumCell = createHeartCell(scale: 0.5, birthRate: 5, lifetime: 5.0, velocity: 100)
        cells.append(mediumCell)
        
        // 小爱心
        let smallCell = createHeartCell(scale: 0.3, birthRate: 8, lifetime: 4.0, velocity: 120)
        cells.append(smallCell)
        
        emitter.emitterCells = cells
        view.layer.insertSublayer(emitter, at: 0)
        emitterLayers.append(emitter)
    }
    
    // 创建爱心粒子单元
    private func createHeartCell(scale: CGFloat, birthRate: Float, lifetime: Float, velocity: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = createPinkHeartImage(size: 40).cgImage
        cell.birthRate = birthRate
        cell.lifetime = lifetime
        cell.velocity = velocity
        cell.velocityRange = velocity * 0.3
        cell.emissionRange = .pi * 2 // 360度全方向
        cell.scale = scale
        cell.scaleRange = scale * 0.3
        cell.scaleSpeed = -scale * 0.15
        cell.alphaSpeed = -0.2
        cell.spin = 1
        cell.spinRange = 3
        cell.yAcceleration = 20 // 轻微下落
        
        return cell
    }
    
    // 创建实心心形（带高斯模糊和脉动）
    private func createSolidHeartShape() {
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        let size: CGFloat = 200
        
        // 不再创建大的实心心形，改为用小爱心组成心形轮廓
        createHeartShapeWithSmallHearts(center: CGPoint(x: centerX, y: centerY), size: size)
        
        // 添加"I LOVE U"文字
        let loveLabel = UILabel()
        loveLabel.text = "I   LOVE   U"  // 增加单词间距
        loveLabel.textColor = UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 1.0) // 粉色文字
        loveLabel.font = .systemFont(ofSize: 120, weight: .black) // 加粗
        loveLabel.textAlignment = .center
        
        // 粉色发光效果
        loveLabel.layer.shadowColor = UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 1.0).cgColor
        loveLabel.layer.shadowRadius = 15
        loveLabel.layer.shadowOpacity = 0.8
        loveLabel.layer.shadowOffset = .zero
        
        loveLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loveLabel)
        
        NSLayoutConstraint.activate([
            loveLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loveLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // "I LOVE U"文字脉动动画
        UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            loveLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
    }
    
    // 用小爱心组成心形轮廓
    private func createHeartShapeWithSmallHearts(center: CGPoint, size: CGFloat) {
        // 手动计算心形路径上的点，而不是依赖CGPath扩展
        let heartCount = 60
        
        for i in 0..<heartCount {
            let t = CGFloat(i) / CGFloat(heartCount) * 2 * .pi
            
            // 使用参数方程计算心形上的点
            let x = center.x + size * 0.5 * (16 * pow(sin(t), 3))
            let y = center.y - size * 0.5 * (13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t))
            
            // 检查坐标是否有效
            guard !x.isNaN && !y.isNaN && !x.isInfinite && !y.isInfinite else {
                continue
            }
            
            // 创建小爱心视图
            let heartView = UILabel()
            heartView.text = "💖"
            
            // 随机大小和透明度
            let randomSize = CGFloat.random(in: 12...24)
            let randomAlpha = CGFloat.random(in: 0.4...1.0)
            
            heartView.font = .systemFont(ofSize: randomSize)
            heartView.alpha = randomAlpha
            heartView.frame = CGRect(x: x - randomSize/2, y: y - randomSize/2, width: randomSize, height: randomSize)
            
            view.addSubview(heartView)
            
            // 添加脉动动画
            let delay = Double(i) * 0.02 // 错开动画时间
            UIView.animate(withDuration: 1.5, delay: delay, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                heartView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            })
        }
    }
    
    // 创建持续的爱心扩散效果
    private func createContinuousHeartExplosion() {
        // 使用定时器持续创建爆发效果
        displayLink = CADisplayLink(target: self, selector: #selector(createBurst))
        displayLink?.preferredFramesPerSecond = 3 // 每秒3次爆发
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func createBurst() {
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: centerX, y: centerY)
        emitter.emitterShape = .point
        emitter.renderMode = .additive
        
        let cell = CAEmitterCell()
        cell.contents = createPinkHeartImage(size: 30).cgImage
        cell.birthRate = 50
        cell.lifetime = 2.0
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.scale = CGFloat.random(in: 0.3...0.7)
        cell.scaleSpeed = -0.2
        cell.alphaSpeed = -0.5
        cell.spin = 2
        cell.spinRange = 4
        cell.yAcceleration = 30
        
        emitter.emitterCells = [cell]
        view.layer.insertSublayer(emitter, at: 0)
        emitterLayers.append(emitter)
        
        // 0.3秒后停止发射，2秒后移除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            emitter.birthRate = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            emitter.removeFromSuperlayer()
            if let index = self?.emitterLayers.firstIndex(of: emitter) {
                self?.emitterLayers.remove(at: index)
            }
        }
    }
    
    // 创建心形路径
    private func createHeartPath(center: CGPoint, size: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        
        let topY = center.y - size * 0.3
        path.move(to: CGPoint(x: center.x, y: center.y + size * 0.4))
        
        // 左半边
        path.addCurve(
            to: CGPoint(x: center.x - size * 0.5, y: topY),
            controlPoint1: CGPoint(x: center.x - size * 0.5, y: center.y + size * 0.1),
            controlPoint2: CGPoint(x: center.x - size * 0.5, y: topY + size * 0.2)
        )
        
        path.addArc(
            withCenter: CGPoint(x: center.x - size * 0.25, y: topY),
            radius: size * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        // 右半边
        path.addArc(
            withCenter: CGPoint(x: center.x + size * 0.25, y: topY),
            radius: size * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + size * 0.4),
            controlPoint1: CGPoint(x: center.x + size * 0.5, y: topY + size * 0.2),
            controlPoint2: CGPoint(x: center.x + size * 0.5, y: center.y + size * 0.1)
        )
        
        path.close()
        return path
    }
    
    // 创建粉色爱心图片
    private func createPinkHeartImage(size: CGFloat) -> UIImage {
        let imageSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            // 粉色渐变
            let pinkColor = UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 1.0)
            pinkColor.setFill()
            
            let centerX = size / 2
            let centerY = size / 2
            let heartSize = size * 0.4
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: centerX, y: centerY + heartSize * 0.4))
            
            path.addCurve(
                to: CGPoint(x: centerX - heartSize * 0.5, y: centerY - heartSize * 0.3),
                controlPoint1: CGPoint(x: centerX - heartSize * 0.5, y: centerY + heartSize * 0.1),
                controlPoint2: CGPoint(x: centerX - heartSize * 0.5, y: centerY - heartSize * 0.1)
            )
            
            path.addArc(
                withCenter: CGPoint(x: centerX - heartSize * 0.25, y: centerY - heartSize * 0.3),
                radius: heartSize * 0.25,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            
            path.addArc(
                withCenter: CGPoint(x: centerX + heartSize * 0.25, y: centerY - heartSize * 0.3),
                radius: heartSize * 0.25,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            
            path.addCurve(
                to: CGPoint(x: centerX, y: centerY + heartSize * 0.4),
                controlPoint1: CGPoint(x: centerX + heartSize * 0.5, y: centerY - heartSize * 0.1),
                controlPoint2: CGPoint(x: centerX + heartSize * 0.5, y: centerY + heartSize * 0.1)
            )
            
            path.close()
            path.fill()
            
            // 添加发光效果
            context.cgContext.setShadow(offset: .zero, blur: 5, color: pinkColor.cgColor)
            path.fill()
        }
    }
}
