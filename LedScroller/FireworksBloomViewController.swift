import UIKit

// 烟花绽放效果视图控制器（第二种烟花）
class FireworksBloomViewController: UIViewController {
    
    private var emitterLayers: [CAEmitterLayer] = []
    private var autoPlayTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAutoPlay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoPlay()
        // 清理所有烟花效果
        emitterLayers.forEach { $0.removeFromSuperlayer() }
        emitterLayers.removeAll()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 统一为纯黑色
        
        // 添加关闭按钮（改为右上角的✕按钮）
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
    
    // 开始自动播放
    private func startAutoPlay() {
        // 立即播放第一组烟花
        createRandomBloomFirework()
        
        // 设置定时器，每1-2秒随机发射一个烟花
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.createRandomBloomFirework()
        }
    }
    
    // 停止自动播放
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    // 创建随机位置的烟花绽放
    private func createRandomBloomFirework() {
        let randomX = CGFloat.random(in: view.bounds.width * 0.2...view.bounds.width * 0.8)
        let randomY = CGFloat.random(in: view.bounds.height * 0.2...view.bounds.height * 0.5)
        let position = CGPoint(x: randomX, y: randomY)
        createBloomFirework(at: position)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // 创建烟花绽放效果（直接在点击位置绽放）
    private func createBloomFirework(at position: CGPoint) {
        // 固定使用棕榈型烟花
        let type: FireworkType = .palm
        
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = position
        emitterLayer.emitterShape = .point
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)
        emitterLayer.renderMode = .additive
        
        // 随机选择颜色组合
        let colorSchemes: [[UIColor]] = [
            [.systemRed, .systemOrange, .systemYellow],
            [.systemPink, .systemPurple, .magenta],
            [.systemBlue, .cyan, .white],
            [.systemGreen, .systemYellow, .white],
            [.systemOrange, .systemRed, .systemYellow]
        ]
        let colors = colorSchemes.randomElement() ?? colorSchemes[0]
        
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = createFireworkCell(color: color, type: type)
            cells.append(cell)
        }
        
        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)
        emitterLayers.append(emitterLayer)
        
        // 3秒后移除这个发射器
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            emitterLayer.removeFromSuperlayer()
            if let index = self?.emitterLayers.firstIndex(of: emitterLayer) {
                self?.emitterLayers.remove(at: index)
            }
        }
    }
    
    enum FireworkType {
        case burst      // 爆裂型
        case willow     // 柳树型
        case palm       // 棕榈型
        case ring       // 环形
        case chrysanthemum // 菊花型
    }
    
    private func createFireworkCell(color: UIColor, type: FireworkType) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = createParticleImage(color: color).cgImage
        
        switch type {
        case .burst: // 爆裂型 - 360度均匀散开
            cell.birthRate = 100
            cell.lifetime = 2.5
            cell.velocity = 200
            cell.velocityRange = 50
            cell.emissionRange = .pi * 2
            cell.scale = 0.7
            cell.scaleSpeed = -0.3
            cell.alphaSpeed = -0.4
            cell.yAcceleration = 80
            
        case .willow: // 柳树型 - 向下垂落
            cell.birthRate = 80
            cell.lifetime = 3.0
            cell.velocity = 150
            cell.velocityRange = 40
            cell.emissionRange = .pi * 2
            cell.scale = 0.5
            cell.scaleSpeed = -0.2
            cell.alphaSpeed = -0.3
            cell.yAcceleration = 120
            
        case .palm: // 棕榈型 - 向上散开后下落
            cell.birthRate = 60
            cell.lifetime = 2.8
            cell.velocity = 180
            cell.velocityRange = 60
            cell.emissionRange = .pi
            cell.emissionLongitude = -.pi / 2
            cell.scale = 0.8
            cell.scaleSpeed = -0.25
            cell.alphaSpeed = -0.35
            cell.yAcceleration = 100
            
        case .ring: // 环形 - 水平扩散
            cell.birthRate = 120
            cell.lifetime = 2.0
            cell.velocity = 220
            cell.velocityRange = 30
            cell.emissionRange = .pi * 2
            cell.scale = 0.6
            cell.scaleSpeed = -0.35
            cell.alphaSpeed = -0.5
            cell.yAcceleration = 60
            
        case .chrysanthemum: // 菊花型 - 密集绽放
            cell.birthRate = 300 // 增加粒子数量，更密集
            cell.lifetime = 3.0 // 延长持续时间，更饱满
            cell.velocity = 180 // 增加初始速度，扩散更大
            cell.velocityRange = 60 // 适中的速度范围，保持均匀分布
            cell.emissionRange = .pi * 2 // 360度全方向
            cell.scale = 0.6 // 稍大的粒子，更华丽
            cell.scaleSpeed = -0.2 // 缓慢缩小，保持饱满感
            cell.alphaSpeed = -0.3 // 缓慢淡出，延长视觉效果
            cell.yAcceleration = 50 // 轻微重力，保持花团形状
        }
        
        cell.spin = 3
        cell.spinRange = 5
        
        return cell
    }
    
    private func createParticleImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 4, height: 20) // 柳树型用长条形状：宽4，高20
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 创建带弧度的长条形状（下面尖尖的，像水滴或火焰拖尾）
            let path = UIBezierPath()
            
            // 顶部圆弧
            path.move(to: CGPoint(x: 0, y: 2))
            path.addQuadCurve(to: CGPoint(x: size.width, y: 2), 
                            controlPoint: CGPoint(x: size.width / 2, y: 0))
            
            // 右侧边缘（略微向内弯曲）
            path.addQuadCurve(to: CGPoint(x: size.width / 2, y: size.height), 
                            controlPoint: CGPoint(x: size.width * 0.8, y: size.height * 0.6))
            
            // 左侧边缘（略微向内弯曲）
            path.addQuadCurve(to: CGPoint(x: 0, y: 2), 
                            controlPoint: CGPoint(x: size.width * 0.2, y: size.height * 0.6))
            
            path.close()
            
            // 填充颜色
            color.setFill()
            path.fill()
            
            // 添加发光效果
            context.cgContext.setShadow(offset: .zero, blur: 4, color: color.cgColor)
            path.fill()
            
            // 添加渐变效果（顶部亮，底部暗，增强拖尾感）
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: [color.withAlphaComponent(1.0).cgColor,
                                                color.withAlphaComponent(0.6).cgColor] as CFArray,
                                        locations: [0.0, 1.0]) {
                context.cgContext.saveGState()
                context.cgContext.addPath(path.cgPath)
                context.cgContext.clip()
                context.cgContext.drawLinearGradient(gradient,
                                                     start: CGPoint(x: size.width / 2, y: 0),
                                                     end: CGPoint(x: size.width / 2, y: size.height),
                                                     options: [])
                context.cgContext.restoreGState()
            }
        }
    }
}
