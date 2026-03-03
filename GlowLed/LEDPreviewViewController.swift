import UIKit

// LED预览页面（带编辑和预览按钮）
class LEDPreviewViewController: UIViewController {
    
    private let ledItem: LEDItem
    private let backgroundImageView = UIImageView()
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
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 背景图片
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // 设置背景（图片或颜色）
        if let imageName = ledItem.imageName, !imageName.isEmpty, let image = UIImage(named: imageName) {
            backgroundImageView.image = image
        } else {
            backgroundImageView.backgroundColor = UIColor(hex: ledItem.backgroundColor)
        }
        
        // LED文字 - 动态计算字体大小（屏幕高度的70%）
        let screenHeight = UIScreen.main.bounds.height
        let fontSize = screenHeight * 0.7 / 1.2 // 除以1.2是因为字体实际高度约为fontSize的1.2倍
        
        textLabel.text = ledItem.text
        textLabel.font = .boldSystemFont(ofSize: fontSize)
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.3
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)

        // 粉色霓虹效果
        textLabel.layer.shadowColor = UIColor(red: 255/255.0, green: 31/255.0, blue: 157/255.0, alpha: 0.75).cgColor
        textLabel.layer.shadowRadius = 27
        textLabel.layer.shadowOpacity = 1.0
        textLabel.layer.shadowOffset = .zero
        textLabel.layer.masksToBounds = false
        
        // 添加闪动动画
        startBlinkAnimation()
        
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
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
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
    
    // 闪动动画
    private func startBlinkAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.3
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        textLabel.layer.add(animation, forKey: "blinkAnimation")
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
