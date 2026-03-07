import UIKit

// LED全屏显示页面
class LEDFullScreenViewController: UIViewController {
    
    private let ledItem: LEDItem
    private let backgroundImageView = UIImageView() // 背景图片视图
    private let borderView = MarqueeBorderView(displayMode: .fullScreen) // 跑马灯边框视图
    private let lightBoardView = LightBoardBorderView(displayMode: .fullScreen) // 灯牌边框视图
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
        
        // 立即停止所有动画
        textLabel.layer.removeAllAnimations()
        view.layer.removeAllAnimations()
        
        // 停止屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 在视图完全消失后再恢复竖屏，避免卡顿
        DispatchQueue.main.async {
            AppDelegate.orientationLock = .portrait
        }
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
        // 设置背景（优先使用backgroundImageName，如果没有则使用imageName，最后才用颜色）
        let imageNameToUse = ledItem.backgroundImageName ?? ledItem.imageName
        
        if let imageName = imageNameToUse, !imageName.isEmpty, let image = UIImage(named: imageName) {
            // 显示背景图片
            backgroundImageView.image = image
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.clipsToBounds = true
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(backgroundImageView)
            
            NSLayoutConstraint.activate([
                backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            view.backgroundColor = .clear
        } else {
            // 显示背景颜色
            view.backgroundColor = UIColor(hex: ledItem.backgroundColor)
        }
        
        // 设置边框
        borderView.setAnimated(true) // 全屏页面的边框启用动画
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.isHidden = true // 默认隐藏
        view.addSubview(borderView)
        
        // 灯牌边框视图
        lightBoardView.translatesAutoresizingMaskIntoConstraints = false
        lightBoardView.isHidden = true // 默认隐藏
        view.addSubview(lightBoardView)
        
        if let borderStyleIndex = ledItem.borderStyle,
           borderStyleIndex >= 0 && borderStyleIndex < MarqueeBorderStyle.allCases.count {
            let style = MarqueeBorderStyle.allCases[borderStyleIndex]
            borderView.setStyle(style)
            borderView.isHidden = false
            lightBoardView.isHidden = true
        } else if let lightBoardStyleIndex = ledItem.lightBoardStyle,
                  lightBoardStyleIndex >= 0 && lightBoardStyleIndex < LightBoardBorderStyle.allCases.count {
            let style = LightBoardBorderStyle.allCases[lightBoardStyleIndex]
            lightBoardView.setStyle(style)
            lightBoardView.isHidden = false
            borderView.isHidden = true
        } else {
            borderView.isHidden = true
            lightBoardView.isHidden = true
        }
        
        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: view.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            lightBoardView.topAnchor.constraint(equalTo: view.topAnchor),
            lightBoardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lightBoardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lightBoardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        textLabel.text = ledItem.text
        
        // 统一字体大小计算：基于全屏横屏尺寸等比缩放
        // 全屏横屏基准：852px宽度（iPhone 14 Pro横屏）
        // fontSize值对应全屏横屏时的实际pt大小
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let _ = max(screenWidth, screenHeight) // 横屏宽度（未使用，保留注释说明）
        
        // 直接使用fontSize值，这就是全屏横屏时的实际大小
        let adjustedFontSize = ledItem.fontSize
        
        textLabel.font = UIFont(name: ledItem.fontName, size: adjustedFontSize) ?? .boldSystemFont(ofSize: adjustedFontSize)
        textLabel.textColor = UIColor(hex: ledItem.textColor)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.3
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)
        
        // 霓虹发光效果 (支持0-20范围)
        let glowRadius = 10 * ledItem.glowIntensity // 0-200的范围
        let glowOpacity = min(ledItem.glowIntensity / 20.0, 1.0) // 归一化到0-1
        
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
            // 静止状态：不添加任何动画
            break
        case .blink:
            // 闪烁效果
            animateBlink()
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
    
    // 闪烁动画
    private func animateBlink() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = ledItem.speed // 使用用户设置的闪烁速度
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        textLabel.layer.add(animation, forKey: "blinkAnimation")
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
        // 先停止动画，再dismiss，减少卡顿
        textLabel.layer.removeAllAnimations()
        view.layer.removeAllAnimations()
        
        dismiss(animated: true) {
            // dismiss完成后恢复竖屏
            AppDelegate.orientationLock = .portrait
        }
    }
}
