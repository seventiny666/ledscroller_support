import UIKit

// Fireworks show: rocket launch + bloom bursts.
// This is used by the Animation tab's "fireworks bloom" template preview.
final class FireworksShowViewController: UIViewController {

    private var emitterLayers: [CAEmitterLayer] = []
    private var launchTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startShow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopShow()
        emitterLayers.forEach { $0.removeFromSuperlayer() }
        emitterLayers.removeAll()
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private func setupUI() {
        view.backgroundColor = .black

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func startShow() {
        // Fire a burst immediately, then randomly every ~0.8-1.6s.
        launchOnce()
        launchTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            if Bool.random() {
                self.launchOnce()
            }
        }
    }

    private func stopShow() {
        launchTimer?.invalidate()
        launchTimer = nil
    }

    private func launchOnce() {
        let startX = CGFloat.random(in: view.bounds.width * 0.15...view.bounds.width * 0.85)
        let startY = view.bounds.height + 20

        let apexY = CGFloat.random(in: view.bounds.height * 0.18...view.bounds.height * 0.45)
        let apexX = startX + CGFloat.random(in: -40...40)

        let rocket = CAEmitterLayer()
        rocket.emitterPosition = CGPoint(x: startX, y: startY)
        rocket.emitterShape = .point
        rocket.emitterSize = CGSize(width: 2, height: 2)
        rocket.renderMode = .additive

        let spark = CAEmitterCell()
        spark.contents = particleDot(color: .white).cgImage
        spark.birthRate = 120
        spark.lifetime = 0.7
        spark.lifetimeRange = 0.2
        spark.velocity = 180
        spark.velocityRange = 60
        spark.emissionRange = .pi / 10
        spark.emissionLongitude = -.pi / 2
        spark.yAcceleration = 220
        spark.scale = 0.35
        spark.scaleSpeed = -0.25
        spark.alphaSpeed = -0.9

        rocket.emitterCells = [spark]
        view.layer.addSublayer(rocket)
        emitterLayers.append(rocket)

        // Animate rocket position to the apex.
        let move = CABasicAnimation(keyPath: "emitterPosition")
        move.fromValue = NSValue(cgPoint: CGPoint(x: startX, y: startY))
        move.toValue = NSValue(cgPoint: CGPoint(x: apexX, y: apexY))
        move.duration = 0.9
        move.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rocket.add(move, forKey: "move")
        rocket.emitterPosition = CGPoint(x: apexX, y: apexY)

        // Stop the rocket and create burst at apex.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self else { return }
            rocket.birthRate = 0
            rocket.removeFromSuperlayer()
            self.emitterLayers.removeAll { $0 === rocket }
            self.burst(at: CGPoint(x: apexX, y: apexY))
        }
    }

    private func burst(at position: CGPoint) {
        let layer = CAEmitterLayer()
        layer.emitterPosition = position
        layer.emitterShape = .circle
        layer.emitterSize = CGSize(width: 6, height: 6)
        layer.renderMode = .additive

        let schemes: [[UIColor]] = [
            [UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0), .white],
            [.systemPink, .systemPurple, .white],
            [.systemBlue, .cyan, .white],
            [.systemGreen, .systemYellow, .white]
        ]
        let colors = schemes.randomElement() ?? schemes[0]

        let burstCell = CAEmitterCell()
        burstCell.contents = particleStreak(color: colors[0]).cgImage
        burstCell.birthRate = 600
        burstCell.lifetime = 2.6
        burstCell.lifetimeRange = 0.4
        burstCell.velocity = 220
        burstCell.velocityRange = 90
        burstCell.emissionRange = .pi * 2
        burstCell.scale = 0.55
        burstCell.scaleRange = 0.25
        burstCell.scaleSpeed = -0.25
        burstCell.alphaSpeed = -0.35
        burstCell.yAcceleration = 90
        burstCell.spin = 2
        burstCell.spinRange = 6

        let glitter = CAEmitterCell()
        glitter.contents = particleDot(color: colors.count > 1 ? colors[1] : .white).cgImage
        glitter.birthRate = 220
        glitter.lifetime = 1.6
        glitter.lifetimeRange = 0.3
        glitter.velocity = 120
        glitter.velocityRange = 60
        glitter.emissionRange = .pi * 2
        glitter.scale = 0.25
        glitter.scaleRange = 0.15
        glitter.scaleSpeed = -0.1
        glitter.alphaSpeed = -0.7
        glitter.yAcceleration = 130

        layer.emitterCells = [burstCell, glitter]
        view.layer.addSublayer(layer)
        emitterLayers.append(layer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            layer.removeFromSuperlayer()
            self?.emitterLayers.removeAll { $0 === layer }
        }
    }

    private func particleDot(color: UIColor) -> UIImage {
        let size = CGSize(width: 6, height: 6)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.setShadow(offset: .zero, blur: 6, color: color.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }

    private func particleStreak(color: UIColor) -> UIImage {
        let size = CGSize(width: 4, height: 18)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2)
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.setShadow(offset: .zero, blur: 8, color: color.cgColor)
            ctx.cgContext.addPath(path.cgPath)
            ctx.cgContext.fillPath()
        }
    }
}
