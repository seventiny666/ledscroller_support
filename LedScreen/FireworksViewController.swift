import UIKit

// 烟花效果视图控制器
class FireworksViewController: UIViewController {
    
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
        launchRandomFirework()
        
        // 设置定时器，每1-2秒随机发射一个烟花
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.launchRandomFirework()
        }
    }
    
    // 停止自动播放
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    // 发射随机位置的烟花
    private func launchRandomFirework() {
        let randomX = CGFloat.random(in: view.bounds.width * 0.2...view.bounds.width * 0.8)
        let randomY = CGFloat.random(in: view.bounds.height * 0.2...view.bounds.height * 0.5)
        let targetPosition = CGPoint(x: randomX, y: randomY)
        launchFirework(at: targetPosition)
    }
    
    // 发射烟花（带上升轨迹）
    private func launchFirework(at targetPosition: CGPoint) {
        // 从屏幕底部随机位置发射
        let startX = CGFloat.random(in: view.bounds.width * 0.2...view.bounds.width * 0.8)
        let startPosition = CGPoint(x: startX, y: view.bounds.height + 20)
        
        // 创建上升的火箭粒子
        let rocketLayer = CAEmitterLayer()
        rocketLayer.emitterPosition = startPosition
        rocketLayer.emitterShape = .point
        rocketLayer.emitterSize = CGSize(width: 1, height: 1)
        rocketLayer.renderMode = .additive
        
        let rocketCell = createRocketCell()
        rocketLayer.emitterCells = [rocketCell]
        view.layer.addSublayer(rocketLayer)
        
        // 计算上升时间和路径
        let distance = startPosition.y - targetPosition.y
        let duration = Double(distance / 300) // 速度约300点/秒
        
        // 动画上升
        let animation = CABasicAnimation(keyPath: "emitterPosition")
        animation.fromValue = startPosition
        animation.toValue = targetPosition
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rocketLayer.add(animation, forKey: "launch")
        
        // 到达顶点后爆炸
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            rocketLayer.removeFromSuperlayer()
            self.createFireworkExplosion(at: targetPosition)
        }
    }
    
    // 创建火箭上升粒子
    private func createRocketCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = createParticleImage(color: .white).cgImage
        
        cell.birthRate = 50
        cell.lifetime = 0.3
        cell.velocity = 0
        cell.velocityRange = 5
        cell.emissionRange = .pi * 2
        
        cell.scale = 0.3
        cell.scaleSpeed = -0.2
        cell.alphaSpeed = -2
        
        cell.color = UIColor.systemYellow.cgColor
        
        return cell
    }
    
    // 创建烟花爆炸效果
    private func createFireworkExplosion(at position: CGPoint) {
        // 随机选择烟花类型
        let types: [FireworkType] = [.burst, .willow, .palm, .ring, .chrysanthemum]
        let type = types.randomElement() ?? .burst
        
        createFirework(at: position, type: type)
    }
    
    enum FireworkType {
        case burst      // 爆裂型
        case willow     // 柳树型
        case palm       // 棕榈型
        case ring       // 环形
        case chrysanthemum // 菊花型
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func createFirework(at position: CGPoint, type: FireworkType = .burst) {
        // 创建烟花爆炸效果
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
            cell.birthRate = 150
            cell.lifetime = 2.2
            cell.velocity = 160
            cell.velocityRange = 80
            cell.emissionRange = .pi * 2
            cell.scale = 0.5
            cell.scaleSpeed = -0.28
            cell.alphaSpeed = -0.45
            cell.yAcceleration = 90
        }
        
        cell.spin = 3
        cell.spinRange = 5
        
        return cell
    }
    
    private func createParticleImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            color.setFill()
            
            // 绘制圆形粒子
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fillEllipse(in: rect)
            
            // 添加发光效果
            context.cgContext.setShadow(offset: .zero, blur: 3, color: color.cgColor)
            context.cgContext.fillEllipse(in: rect)
        }
    }
}
