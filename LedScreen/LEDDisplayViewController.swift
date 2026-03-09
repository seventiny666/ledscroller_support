import UIKit

class LEDDisplayViewController: UIViewController {
    
    private let config: LEDConfig
    private let textLabel = UILabel()
    private let effectsRenderer: EffectsRenderer
    
    init(config: LEDConfig) {
        self.config = config
        self.effectsRenderer = EffectsRenderer(effects: config.effects)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        startAnimations()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: config.style.backgroundColor)
        
        // 添加特效层
        effectsRenderer.frame = view.bounds
        view.addSubview(effectsRenderer)
        
        // LED 文字
        textLabel.text = config.text
        textLabel.font = .boldSystemFont(ofSize: config.style.fontSize)
        textLabel.textColor = UIColor(hex: config.style.color)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)
        
        // 霓虹发光效果
        textLabel.layer.shadowColor = UIColor(hex: config.style.color).cgColor
        textLabel.layer.shadowRadius = 20 * config.style.glowIntensity
        textLabel.layer.shadowOpacity = Float(config.style.glowIntensity)
        textLabel.layer.shadowOffset = .zero
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // 屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func startAnimations() {
        effectsRenderer.startAnimating()
        
        switch config.style.animation {
        case .none:
            break
        case .scrollLeft:
            animateScrollLeft()
        case .scrollRight:
            animateScrollRight()
        case .scrollUp:
            animateScrollUp()
        case .scrollDown:
            animateScrollDown()
        case .glitch:
            animateGlitch()
        }
    }
    
    private func animateScrollLeft() {
        textLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(config.style.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
        }
    }
    
    private func animateScrollRight() {
        textLabel.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(config.style.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
        }
    }
    
    private func animateScrollUp() {
        textLabel.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(config.style.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: -self.view.bounds.height)
        }
    }
    
    private func animateScrollDown() {
        textLabel.transform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(config.style.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }
    }
    
    private func animateGlitch() {
        Timer.scheduledTimer(withTimeInterval: 0.1 / Double(config.style.speed), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let randomX = CGFloat.random(in: -5...5)
            let randomY = CGFloat.random(in: -5...5)
            self.textLabel.transform = CGAffineTransform(translationX: randomX, y: randomY)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.textLabel.transform = .identity
            }
        }
    }
    
    @objc private func dismissView() {
        UIApplication.shared.isIdleTimerDisabled = false
        effectsRenderer.stopAnimating()
        dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        effectsRenderer.stopAnimating()
    }
}
