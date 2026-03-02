import UIKit

// LED全屏显示页面
class LEDFullScreenViewController: UIViewController {
    
    private let ledItem: LEDItem
    private let textLabel = UILabel()
    private var displayLink: CADisplayLink?
    
    init(ledItem: LEDItem) {
        self.ledItem = ledItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 停止动画和屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = false
        textLabel.layer.removeAllAnimations()
        
        // 恢复为竖屏
        AppDelegate.orientationLock = .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: ledItem.backgroundColor)
        
        textLabel.text = ledItem.text
        textLabel.font = UIFont(name: ledItem.fontName, size: ledItem.fontSize) ?? .boldSystemFont(ofSize: ledItem.fontSize)
        textLabel.textColor = UIColor(hex: ledItem.textColor)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)
        
        // 霓虹发光效果 (支持0-5范围)
        let glowRadius = 10 * ledItem.glowIntensity // 0-50的范围
        let glowOpacity = min(ledItem.glowIntensity / 5.0, 1.0) // 归一化到0-1
        
        textLabel.layer.shadowColor = UIColor(hex: ledItem.textColor).cgColor
        textLabel.layer.shadowRadius = glowRadius
        textLabel.layer.shadowOpacity = Float(glowOpacity)
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
    
    private func startAnimation() {
        switch ledItem.scrollType {
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
        }
    }
    
    private func animateScrollLeft() {
        textLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
        }
    }
    
    private func animateScrollRight() {
        textLabel.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
        }
    }
    
    private func animateScrollUp() {
        textLabel.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: -self.view.bounds.height)
        }
    }
    
    private func animateScrollDown() {
        textLabel.transform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
}
