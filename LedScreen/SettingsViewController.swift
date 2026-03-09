import UIKit

// 设置项
enum SettingItem {
    case language
    case aboutUs
    case version
    case restorePurchase
    case feedback
    case rate
    
    var title: String {
        switch self {
        case .language: return "language".localized
        case .aboutUs: return "about".localized
        case .version: return "version".localized
        case .restorePurchase: return "restorePurchase".localized
        case .feedback: return "feedback".localized
        case .rate: return "rate".localized
        }
    }
    
    var icon: String {
        switch self {
        case .language: return "globe"
        case .aboutUs: return "info.circle"
        case .version: return "app.badge"
        case .restorePurchase: return "arrow.clockwise.circle"
        case .feedback: return "envelope"
        case .rate: return "star"
        }
    }
}

// 设置视图控制器
class SettingsViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private let settings: [SettingItem] = [.language, .aboutUs, .version, .restorePurchase, .feedback, .rate]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "settings".localized
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        
        // 设置导航栏样式 - 统一为纯黑色
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 纯黑背景
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear // 移除阴影
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 创建滚动视图
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // 创建垂直堆栈视图
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 80), // 增加顶部间距，让内容居中
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -80), // 增加底部间距
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        // 添加设置卡片
        for setting in settings {
            let card = createSettingCard(for: setting)
            stackView.addArrangedSubview(card)
        }
    }
    
    private func createSettingCard(for item: SettingItem) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        
        // 图标
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconImageView)
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        
        // 版本号（仅版本项显示）
        if case .version = item {
            let versionLabel = UILabel()
            versionLabel.text = "1.0"
            versionLabel.textColor = .gray
            versionLabel.font = .systemFont(ofSize: 14)
            versionLabel.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(versionLabel)
            
            NSLayoutConstraint.activate([
                versionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                versionLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])
        } else {
            // 箭头
            let arrowImageView = UIImageView()
            arrowImageView.image = UIImage(systemName: "chevron.right")
            arrowImageView.tintColor = .gray
            arrowImageView.contentMode = .scaleAspectFit
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(arrowImageView)
            
            NSLayoutConstraint.activate([
                arrowImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                arrowImageView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                arrowImageView.widthAnchor.constraint(equalToConstant: 12),
                arrowImageView.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(settingCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.tag = settings.firstIndex(of: item) ?? 0
        
        return card
    }
    
    @objc private func settingCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, index < settings.count else { return }
        let item = settings[index]
        handleSettingTap(item)
    }
    
    private func handleSettingTap(_ item: SettingItem) {
        switch item {
        case .language:
            showLanguageSelector()
        case .aboutUs:
            showAlert(title: "about".localized, message: "aboutMessage".localized)
        case .version:
            showAlert(title: "version".localized, message: "versionMessage".localized)
        case .restorePurchase:
            showAlert(title: "restorePurchase".localized, message: "noRestorableItems".localized)
        case .feedback:
            showAlert(title: "feedback".localized, message: "feedbackMessage".localized)
        case .rate:
            showAlert(title: "rate".localized, message: "rateMessage".localized)
        }
    }
    
    private func showLanguageSelector() {
        // 使用自定义暗色弹窗
        let languageSelectorView = LanguageSelectorView()
        languageSelectorView.onLanguageSelected = { [weak self] language in
            self?.confirmLanguageChange(to: language)
        }
        languageSelectorView.show(in: self)
    }
    
    private func confirmLanguageChange(to language: LanguageManager.Language) {
        // 如果选择的是当前语言，不需要确认
        if language == LanguageManager.shared.currentLanguage {
            return
        }
        
        // 显示自定义确认弹窗
        let languageName = language.displayName
        let confirmView = LanguageConfirmView(languageName: languageName)
        confirmView.onConfirm = { [weak self] in
            self?.changeLanguage(to: language)
        }
        confirmView.show(in: self)
    }
    
    private func changeLanguage(to language: LanguageManager.Language) {
        // 保存语言设置
        LanguageManager.shared.currentLanguage = language
        
        // 立即刷新整个应用界面
        reloadApplication()
    }
    
    private func reloadApplication() {
        // 获取window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // 创建新的TabBarController
        let newTabBarController = MainTabBarController()
        
        // 使用动画切换根视图控制器
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = newTabBarController
        }, completion: nil)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "done".localized, style: .default))
        present(alert, animated: true)
    }
}


// MARK: - 语言选择弹窗视图
class LanguageSelectorView: UIView {
    
    var onLanguageSelected: ((LanguageManager.Language) -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private weak var presentingVC: UIViewController?
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 半透明背景
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 容器视图
        containerView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 标题
        titleLabel.text = "language".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 滚动视图
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        // 语言列表堆栈
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // 添加语言选项
        let currentLanguage = LanguageManager.shared.currentLanguage
        for language in LanguageManager.Language.allCases {
            let button = createLanguageButton(language: language, isSelected: language == currentLanguage)
            stackView.addArrangedSubview(button)
        }
        
        // 取消按钮（胶囊形状）
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 620),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            scrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 440),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 添加点击背景关闭手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    private func createLanguageButton(language: LanguageManager.Language, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(language.displayName, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: isSelected ? .semibold : .regular)
        button.contentHorizontalAlignment = .left
        
        // 使用iOS 15+的新方式设置内边距
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            config.title = language.displayName
            config.baseForegroundColor = .white
            button.configuration = config
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
        button.backgroundColor = isSelected ? UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.2) : .clear
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // 添加选中标记
        if isSelected {
            let checkmark = UILabel()
            checkmark.text = "✓"
            checkmark.textColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
            checkmark.font = .systemFont(ofSize: 18, weight: .bold)
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(checkmark)
            
            NSLayoutConstraint.activate([
                checkmark.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
                checkmark.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
        }
        
        button.tag = LanguageManager.Language.allCases.firstIndex(of: language) ?? 0
        button.addTarget(self, action: #selector(languageButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    func show(in viewController: UIViewController) {
        presentingVC = viewController
        
        guard let window = viewController.view.window else { return }
        
        frame = window.bounds
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor),
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // 动画显示
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func languageButtonTapped(_ sender: UIButton) {
        let languages = LanguageManager.Language.allCases
        guard sender.tag < languages.count else { return }
        let selectedLanguage = languages[sender.tag]
        
        dismiss()
        onLanguageSelected?(selectedLanguage)
    }
    
    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }
    
    @objc private func backgroundTapped() {
        dismiss()
        onCancel?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension LanguageSelectorView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 只有点击背景时才触发，点击容器内部不触发
        return touch.view == self
    }
}

// MARK: - 语言确认弹窗视图
class LanguageConfirmView: UIView {
    
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private weak var presentingVC: UIViewController?
    
    init(languageName: String) {
        super.init(frame: .zero)
        setupUI(languageName: languageName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(languageName: String) {
        // 半透明背景
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 容器视图
        containerView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 标题
        titleLabel.text = "selectLanguage".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 确认按钮（胶囊形状）
        let useLanguageText = String(format: "useLanguage".localized, languageName)
        confirmButton.setTitle(useLanguageText, for: .normal)
        confirmButton.setTitleColor(.black, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        confirmButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(confirmButton)
        
        // 取消按钮（胶囊形状）
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            confirmButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34)
        ])
        
        // 添加点击背景关闭手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    func show(in viewController: UIViewController) {
        presentingVC = viewController
        
        guard let window = viewController.view.window else { return }
        
        frame = window.bounds
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor),
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // 动画显示
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func confirmTapped() {
        dismiss()
        onConfirm?()
    }
    
    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }
    
    @objc private func backgroundTapped() {
        dismiss()
        onCancel?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension LanguageConfirmView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 只有点击背景时才触发，点击容器内部不触发
        return touch.view == self
    }
}
