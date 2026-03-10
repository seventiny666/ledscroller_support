import UIKit

// LED预览页面（带编辑和预览按钮）
class LEDPreviewViewController: UIViewController {
    
    private let ledItem: LEDItem
    private let backgroundImageView = UIImageView()
    private let borderView = MarqueeBorderView(displayMode: .preview) // 跑马灯边框视图
    private let lightBoardView = LightBoardBorderView(displayMode: .preview) // 灯牌边框视图
    private let textLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .landscape
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 停止所有动画
        textLabel.layer.removeAllAnimations()
        view.layer.removeAllAnimations()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 创建19.5:9比例的预览容器
        let previewContainer = UIView()
        previewContainer.backgroundColor = .clear
        previewContainer.layer.cornerRadius = 15
        previewContainer.layer.borderWidth = 3
        previewContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        previewContainer.clipsToBounds = true
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)
        
        // 背景图片
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(backgroundImageView)
        
        // 边框视图
        borderView.setAnimated(true) // 预览页面的边框启用动画
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.isHidden = true // 默认隐藏
        previewContainer.addSubview(borderView)
        
        // 灯牌边框视图
        lightBoardView.translatesAutoresizingMaskIntoConstraints = false
        lightBoardView.isHidden = true // 默认隐藏
        previewContainer.addSubview(lightBoardView)
        
        // 设置背景（图片或颜色）
        if let imageName = ledItem.imageName, !imageName.isEmpty, let image = UIImage(named: imageName) {
            backgroundImageView.image = image
        } else {
            backgroundImageView.backgroundColor = UIColor(hex: ledItem.backgroundColor)
        }
        
        // 设置边框
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
        
        // LED文字 - 统一字体大小计算：基于全屏横屏尺寸等比缩放
        // 全屏横屏基准：852px宽度（iPhone 14 Pro横屏）
        // fontSize值对应全屏横屏时的实际pt大小
        let containerWidth = UIScreen.main.bounds.width - 120 // 左右各60px边距
        let _ = containerWidth * (9.0/19.5) // 19.5:9比例
        let landscapeWidth: CGFloat = 852 // 全屏横屏基准宽度
        
        // 按容器宽度比例缩放字体
        let scaleFactor = containerWidth / landscapeWidth
        let calculatedFontSize = ledItem.fontSize * scaleFactor
        
        textLabel.text = ledItem.text
        textLabel.textColor = UIColor(hex: ledItem.textColor)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.adjustsFontSizeToFitWidth = false  // 禁用自动调整字体大小
        textLabel.lineBreakMode = .byWordWrapping     // 按单词换行
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建带行间距的属性字符串
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = calculatedFontSize * 0.1  // 行间距为字体大小的0.1倍 (1.1倍行高)
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let font = UIFont(name: ledItem.fontName, size: calculatedFontSize) ?? .boldSystemFont(ofSize: calculatedFontSize)
        let attributedString = NSMutableAttributedString(string: ledItem.text)
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: ledItem.text.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: ledItem.textColor), range: NSRange(location: 0, length: ledItem.text.count))
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: ledItem.text.count))
        
        textLabel.attributedText = attributedString
        previewContainer.addSubview(textLabel)

        // 霓虹发光效果 (支持0-20范围)
        let glowRadius = 10 * ledItem.glowIntensity // 0-200的范围
        let glowOpacity = min(ledItem.glowIntensity / 20.0, 1.0) // 归一化到0-1
        
        textLabel.layer.shadowColor = UIColor(hex: ledItem.textColor).cgColor
        textLabel.layer.shadowRadius = glowRadius
        textLabel.layer.shadowOpacity = Float(glowOpacity)
        textLabel.layer.shadowOffset = .zero
        
        // 添加动画效果
        startAnimation()
        
        // 按钮容器
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // 编辑按钮改为"试用模版"
        editButton.setTitle("试用模版", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        editButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.3)
        editButton.layer.cornerRadius = 25
        editButton.layer.borderWidth = 1.5
        editButton.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(editButton)
        
        // 预览按钮改为"预览模版"
        previewButton.setTitle("预览模版", for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        previewButton.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        previewButton.layer.cornerRadius = 25
        previewButton.layer.borderWidth = 1.5
        previewButton.layer.borderColor = UIColor.systemPink.cgColor
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(previewButton)
        
        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // 预览容器约束 - 19.5:9比例，居中显示
            previewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            previewContainer.heightAnchor.constraint(equalTo: previewContainer.widthAnchor, multiplier: 9.0/19.5),
            
            // 背景图片填满预览容器
            backgroundImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            // 边框视图填满预览容器
            borderView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            // 灯牌边框视图填满预览容器
            lightBoardView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            lightBoardView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            lightBoardView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            lightBoardView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            // 文字居中显示
            textLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previewContainer.leadingAnchor, constant: 15),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: previewContainer.trailingAnchor, constant: -15),
            textLabel.heightAnchor.constraint(lessThanOrEqualTo: previewContainer.heightAnchor, multiplier: 0.9),
            
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            buttonStack.widthAnchor.constraint(equalToConstant: 280),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func editTapped() {
        let createVC = LEDCreateViewController(editingItem: ledItem, isTemplateEdit: true)
        createVC.onSave = { [weak self] in
            self?.showToast(message: "新页面已保存到我的创作页面")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.dismiss(animated: true)
            }
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc private func previewTapped() {
        let displayVC = LEDFullScreenViewController(ledItem: ledItem)
        displayVC.modalPresentationStyle = .fullScreen
        present(displayVC, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // 动画处理
    private func startAnimation() {
        switch ledItem.scrollType {
        case .none:
            // 静止状态：不添加任何动画
            break
        case .blink:
            // 闪烁效果
            startBlinkAnimation()
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
    
    // 闪动动画
    private func startBlinkAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.3
        animation.duration = ledItem.speed // 使用用户设置的闪烁速度
        animation.autoreverses = true
        animation.repeatCount = .infinity
        textLabel.layer.add(animation, forKey: "blinkAnimation")
    }
    
    private func animateScrollLeft() {
        guard let previewContainer = textLabel.superview else { return }
        textLabel.transform = CGAffineTransform(translationX: previewContainer.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: -previewContainer.bounds.width, y: 0)
        }
    }
    
    private func animateScrollRight() {
        guard let previewContainer = textLabel.superview else { return }
        textLabel.transform = CGAffineTransform(translationX: -previewContainer.bounds.width, y: 0)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: previewContainer.bounds.width, y: 0)
        }
    }
    
    private func animateScrollUp() {
        guard let previewContainer = textLabel.superview else { return }
        textLabel.transform = CGAffineTransform(translationX: 0, y: previewContainer.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: -previewContainer.bounds.height)
        }
    }
    
    private func animateScrollDown() {
        guard let previewContainer = textLabel.superview else { return }
        textLabel.transform = CGAffineTransform(translationX: 0, y: -previewContainer.bounds.height)
        UIView.animate(withDuration: 5.0 / Double(ledItem.speed), delay: 0, options: [.repeat, .curveLinear]) {
            self.textLabel.transform = CGAffineTransform(translationX: 0, y: previewContainer.bounds.height)
        }
    }

    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
