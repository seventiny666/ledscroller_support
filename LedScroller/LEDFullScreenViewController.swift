import UIKit

// Access VIP status.
// PurchaseManager lives in TemplateSquareViewController.swift, but it's part of the app module.


// LED全屏显示页面
class LEDFullScreenViewController: UIViewController {
    
    private let ledItem: LEDItem
    private let backgroundImageView = UIImageView() // 背景图片视图
    private var ledCardView: LEDScreenCardView? // LED卡片背景视图
    private let borderView = MarqueeBorderView(displayMode: .fullScreen) // 跑马灯边框视图
    private let lightBoardView = LightBoardBorderView(displayMode: .fullScreen) // 灯牌边框视图
    private let linearBorderView = LinearBorderView(displayMode: .fullscreen) // 线性边框视图
    private let textLabel = UILabel()
    private var displayLink: CADisplayLink?

    // Top-right close button (tap to dismiss)
    private let closeButton = UIButton(type: .system)

    // VIP template action
    private let useTemplateButton = UIButton(type: .system)
    
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
        setupUseTemplateButtonIfNeeded()
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
        
        if let imageName = imageNameToUse, !imageName.isEmpty {
            // 检查是否是LED屏幕背景
            if imageName.hasPrefix("led_") {
                // 显示LED卡片背景
                if let indexStr = imageName.split(separator: "_").last,
                   let index = Int(indexStr),
                   index >= 1 && index <= 8 {
                    let styleIndex = index - 1
                    if let style = LEDScreenCardView.LEDScreenStyle(rawValue: styleIndex) {
                        let ledCard = LEDScreenCardView(style: style)
                        ledCard.translatesAutoresizingMaskIntoConstraints = false
                        view.addSubview(ledCard)
                        
                        NSLayoutConstraint.activate([
                            ledCard.topAnchor.constraint(equalTo: view.topAnchor),
                            ledCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                            ledCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                            ledCard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                        ])
                        
                        ledCardView = ledCard
                        view.backgroundColor = .clear
                    }
                }
            } else if let image = UIImage(named: imageName) {
                // 显示普通背景图片
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
                // 图片不存在，使用背景颜色
                view.backgroundColor = UIColor(hex: ledItem.backgroundColor)
            }
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
        
        // 线性边框视图
        linearBorderView.translatesAutoresizingMaskIntoConstraints = false
        linearBorderView.isHidden = true // 默认隐藏
        view.addSubview(linearBorderView)
        
        if let borderStyleIndex = ledItem.borderStyle,
           borderStyleIndex >= 0 && borderStyleIndex < MarqueeBorderStyle.allCases.count {
            let style = MarqueeBorderStyle.allCases[borderStyleIndex]
            borderView.setStyle(style)
            borderView.isHidden = false
            lightBoardView.isHidden = true
            linearBorderView.isHidden = true
        } else if let lightBoardStyleIndex = ledItem.lightBoardStyle,
                  lightBoardStyleIndex >= 0 && lightBoardStyleIndex < LightBoardBorderStyle.allCases.count {
            let style = LightBoardBorderStyle.allCases[lightBoardStyleIndex]
            lightBoardView.setStyle(style)
            lightBoardView.isHidden = false
            borderView.isHidden = true
            linearBorderView.isHidden = true
        } else if let linearBorderStyleIndex = ledItem.linearBorderStyle,
                  linearBorderStyleIndex >= 0 && linearBorderStyleIndex < LinearBorderStyle.allCases.count {
            let style = LinearBorderStyle.allCases[linearBorderStyleIndex]
            linearBorderView.setStyle(style)
            linearBorderView.isHidden = false
            borderView.isHidden = true
            lightBoardView.isHidden = true
        } else {
            borderView.isHidden = true
            lightBoardView.isHidden = true
            linearBorderView.isHidden = true
        }
        
        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: view.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            lightBoardView.topAnchor.constraint(equalTo: view.topAnchor),
            lightBoardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lightBoardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lightBoardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            linearBorderView.topAnchor.constraint(equalTo: view.topAnchor),
            linearBorderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            linearBorderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            linearBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.3
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)

        // 直接使用fontSize值，这就是全屏横屏时的实际大小
        let adjustedFontSize = ledItem.fontSize
        textLabel.attributedText = LEDFontRenderer.attributedText(
            ledItem.text,
            fontName: ledItem.fontName,
            size: adjustedFontSize,
            color: UIColor(hex: ledItem.textColor),
            alignment: .center
        )
        
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
        
        // Close button (top-right)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        view.addSubview(closeButton)
        view.bringSubviewToFront(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // 屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        tapGesture.cancelsTouchesInView = false // don't swallow button taps
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
    
    private func setupUseTemplateButtonIfNeeded() {
        // Show for templates (home/template square). Do NOT show for user creations.
        // Templates are identified by known preset flags/prefixes; user creations use UUID ids.
        let isTemplateItem =
            ledItem.isNeonTemplate || ledItem.isIdolTemplate || ledItem.isLEDTemplate ||
            ledItem.isFlipClock || ledItem.isDigitalClock ||
            ledItem.isHeartGrid || ledItem.isILoveU || ledItem.is520 ||
            ledItem.isLoveRain || ledItem.isFireworks || ledItem.isFireworksBloom

        guard isTemplateItem else {
            useTemplateButton.isHidden = true
            return
        }

        // VIP-required templates only show the button for VIP users.
        if ledItem.isVIPRequired && !PurchaseManager.shared.isVIP() {
            useTemplateButton.isHidden = true
            return
        }

        useTemplateButton.setTitle("useThisTemplateLower".localized, for: .normal)
        useTemplateButton.setTitleColor(.white, for: .normal)
        useTemplateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        useTemplateButton.layer.cornerRadius = 22
        useTemplateButton.layer.masksToBounds = false
        useTemplateButton.addTarget(self, action: #selector(useTemplateTapped), for: .touchUpInside)
        useTemplateButton.translatesAutoresizingMaskIntoConstraints = false

        // Pink glow style (solid pink + inner-ish glow)
        let pink = UIColor(red: 1.0, green: 0.45, blue: 0.75, alpha: 1.0)
        useTemplateButton.backgroundColor = pink
        useTemplateButton.layer.shadowColor = pink.cgColor
        useTemplateButton.layer.shadowOpacity = 0.9
        useTemplateButton.layer.shadowRadius = 10
        useTemplateButton.layer.shadowOffset = .zero

        view.addSubview(useTemplateButton)
        view.bringSubviewToFront(useTemplateButton)

        NSLayoutConstraint.activate([
            useTemplateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            useTemplateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            useTemplateButton.heightAnchor.constraint(equalToConstant: 44),
            useTemplateButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 170)
        ])
    }

    @objc private func useTemplateTapped() {
        // Dismiss preview first, then open editor from the presenting VC.
        let item = ledItem
        let opener = presentingViewController
        dismiss(animated: true) {
            guard let opener else { return }
            let createVC = LEDCreateViewController(editingItem: item, isTemplateEdit: true)
            createVC.onSave = {
                if let opener = opener as? TemplateSquareViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        opener.showToast(message: "saved".localized)
                    }
                }
            }
            let nav = UINavigationController(rootViewController: createVC)
            nav.modalPresentationStyle = .fullScreen
            opener.present(nav, animated: true)
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
