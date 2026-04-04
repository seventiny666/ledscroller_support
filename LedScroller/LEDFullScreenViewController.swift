import UIKit

// Access VIP status.
// PurchaseManager lives in TemplateSquareViewController.swift, but it's part of the app module.


// LED全屏显示页面
class LEDFullScreenViewController: UIViewController {
    
    enum CloseInteractionMode {
        case tapToDismiss
        case tapToRevealActions
    }
    
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
    private let closeInteractionMode: CloseInteractionMode
    private let actionOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let exitPreviewButton = UIButton(type: .system)
    private let continuePreviewButton = UIButton(type: .system)
    private let topMaskView = UIView() // 顶部半透明黑色遮罩

    // VIP template action
    private let useTemplateButton = UIButton(type: .system)
    
    init(ledItem: LEDItem, closeInteractionMode: CloseInteractionMode = .tapToDismiss) {
        self.ledItem = ledItem
        self.closeInteractionMode = closeInteractionMode
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
        
        // iPad端进入时强制横屏
        if UIDevice.current.userInterfaceIdiom == .pad {
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
        
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新渐变层的frame
        if let gradientLayer = useTemplateButton.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = useTemplateButton.bounds
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // iPad和iPhone都强制横屏
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        // 强制横屏（向右）
        return .landscapeRight
    }
    
    /// iPad端字体放大系数（降低到1.3，与创建LED预览区更一致）
    private var iPadFontScaleFactor: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 1.3 : 1.0
    }
    
    private func setupUI() {
        // 设置背景（优先使用backgroundImageName，如果没有则使用imageName，最后才用颜色）
        let imageNameToUse = ledItem.backgroundImageName ?? ledItem.imageName
        
        if let imageName = imageNameToUse, !imageName.isEmpty {
            // 尝试加载图片（包括 led_ 背景也使用图片）
            if let image = UIImage(named: imageName) {
                // 显示背景图片
                backgroundImageView.image = image
                backgroundImageView.contentMode = .scaleToFill // 拉伸填满整个屏幕，不裁剪
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
        
        // LED边框图片视图
        let ledBorderImageView = UIImageView()
        ledBorderImageView.contentMode = .scaleToFill // 拉伸填满整个屏幕，不裁剪
        ledBorderImageView.clipsToBounds = true
        ledBorderImageView.translatesAutoresizingMaskIntoConstraints = false
        ledBorderImageView.isHidden = true // 默认隐藏
        view.addSubview(ledBorderImageView)
        
        if let borderStyleIndex = ledItem.borderStyle,
           borderStyleIndex >= 0 && borderStyleIndex < MarqueeBorderStyle.allCases.count {
            let style = MarqueeBorderStyle.allCases[borderStyleIndex]
            borderView.setStyle(style)
            borderView.isHidden = false
            lightBoardView.isHidden = true
            linearBorderView.isHidden = true
            ledBorderImageView.isHidden = true
        } else if let lightBoardStyleIndex = ledItem.lightBoardStyle,
                  lightBoardStyleIndex >= 0 && lightBoardStyleIndex < LightBoardBorderStyle.allCases.count {
            let style = LightBoardBorderStyle.allCases[lightBoardStyleIndex]
            lightBoardView.setStyle(style)
            lightBoardView.isHidden = false
            borderView.isHidden = true
            linearBorderView.isHidden = true
            ledBorderImageView.isHidden = true
        } else if let linearBorderStyleIndex = ledItem.linearBorderStyle,
                  linearBorderStyleIndex >= 0 && linearBorderStyleIndex < LinearBorderStyle.allCases.count {
            let style = LinearBorderStyle.allCases[linearBorderStyleIndex]
            linearBorderView.setStyle(style)
            linearBorderView.isHidden = false
            borderView.isHidden = true
            lightBoardView.isHidden = true
            ledBorderImageView.isHidden = true
        } else if let ledBorderImageIndex = ledItem.ledBorderImageIndex,
                  ledBorderImageIndex >= 1 && ledBorderImageIndex <= 8 {
            // LED边框图片
            let imageName = "line_\(ledBorderImageIndex)"
            if let image = UIImage(named: imageName) {
                ledBorderImageView.image = image
                ledBorderImageView.isHidden = false
                borderView.isHidden = true
                lightBoardView.isHidden = true
                linearBorderView.isHidden = true
            }
        } else {
            borderView.isHidden = true
            lightBoardView.isHidden = true
            linearBorderView.isHidden = true
            ledBorderImageView.isHidden = true
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
            linearBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ledBorderImageView.topAnchor.constraint(equalTo: view.topAnchor),
            ledBorderImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ledBorderImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ledBorderImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        textLabel.textAlignment = .center
        let wrapEnabled = ledItem.isTextWrapEnabled
        textLabel.numberOfLines = wrapEnabled ? 0 : 1
        textLabel.lineBreakMode = wrapEnabled ? .byWordWrapping : .byClipping
        // Do NOT auto-scale text; font size strictly follows the slider.
        textLabel.adjustsFontSizeToFitWidth = false
        textLabel.minimumScaleFactor = 1.0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)

        // 直接使用fontSize值，iPad端放大1.5倍
        let baseFontSize = ledItem.fontSize
        let adjustedFontSize = baseFontSize * iPadFontScaleFactor
        textLabel.attributedText = LEDFontRenderer.attributedText(
            ledItem.text,
            fontName: ledItem.fontName,
            size: adjustedFontSize,
            color: UIColor(hex: ledItem.textColor),
            alignment: .center,
            lineBreakMode: wrapEnabled ? .byWordWrapping : .byClipping,
            lineSpacing: wrapEnabled ? (adjustedFontSize * 0.008) : nil
        )
        
        // 霓虹发光效果（与文字颜色一致，强度0-20）
        LEDFontRenderer.applyNeonGlow(
            to: textLabel.layer,
            color: UIColor(hex: ledItem.textColor),
            intensity: ledItem.glowIntensity,
            fontSize: adjustedFontSize
        )
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        if closeInteractionMode == .tapToDismiss {
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
        } else {
            setupActionOverlay()
        }

        // 屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        tapGesture.cancelsTouchesInView = false // don't swallow button taps
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupActionOverlay() {
        // 全屏半透明黑色遮罩（0.5透明度）
        topMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        topMaskView.translatesAutoresizingMaskIntoConstraints = false
        topMaskView.isHidden = true
        topMaskView.alpha = 0
        view.addSubview(topMaskView)
        
        NSLayoutConstraint.activate([
            topMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            topMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // 覆盖整个屏幕
        ])
        
        // 按钮容器（横排居中显示）- 直接放在遮罩上
        let stack = UIStackView(arrangedSubviews: [exitPreviewButton, continuePreviewButton])
        stack.axis = .horizontal
        stack.spacing = 20 // 两个按钮间隔20pt
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        configureOverlayButton(exitPreviewButton, title: "退出预览", isPrimary: false, action: #selector(exitPreviewTapped))
        configureOverlayButton(continuePreviewButton, title: "继续预览", isPrimary: true, action: #selector(continuePreviewTapped))

        topMaskView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: topMaskView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: topMaskView.centerYAnchor), // 居中显示
            stack.heightAnchor.constraint(equalToConstant: 50),

            exitPreviewButton.widthAnchor.constraint(equalToConstant: 140),
            continuePreviewButton.widthAnchor.constraint(equalToConstant: 140)
        ])
    }

    private func configureOverlayButton(_ button: UIButton, title: String, isPrimary: Bool, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        button.backgroundColor = isPrimary
            ? UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.25)
            : UIColor.white.withAlphaComponent(0.12)
        button.layer.borderWidth = 1
        button.layer.borderColor = isPrimary
            ? UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.9).cgColor
            : UIColor.white.withAlphaComponent(0.2).cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
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
            ledItem.isLoveRain || ledItem.isFireworks || ledItem.isFireworksBloom ||
            ledItem.id == "happy-birthday-default" || ledItem.id == "happy-new-year-default" || ledItem.id == "marry-me-default"

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
        useTemplateButton.layer.masksToBounds = true // 裁剪渐变层
        useTemplateButton.addTarget(self, action: #selector(useTemplateTapped), for: .touchUpInside)
        useTemplateButton.translatesAutoresizingMaskIntoConstraints = false

        // 玫红到紫色渐变背景，去掉外发光
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0).cgColor, // 玫红色
            UIColor(red: 0.6, green: 0.0, blue: 1.0, alpha: 1.0).cgColor  // 紫色
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 22
        useTemplateButton.layer.insertSublayer(gradientLayer, at: 0)

        view.addSubview(useTemplateButton)
        view.bringSubviewToFront(useTemplateButton)

        NSLayoutConstraint.activate([
            useTemplateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor), // 水平居中
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

    @objc private func handleScreenTap() {
        switch closeInteractionMode {
        case .tapToDismiss:
            dismissView()
        case .tapToRevealActions:
            setActionOverlayVisible(topMaskView.isHidden)
        }
    }

    @objc private func exitPreviewTapped() {
        dismissView()
    }

    @objc private func continuePreviewTapped() {
        setActionOverlayVisible(false)
    }

    private func setActionOverlayVisible(_ visible: Bool) {
        if visible {
            topMaskView.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.topMaskView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.topMaskView.alpha = 0
            }) { _ in
                self.topMaskView.isHidden = true
            }
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
