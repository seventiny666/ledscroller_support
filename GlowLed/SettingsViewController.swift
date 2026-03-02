import UIKit

// 设置项
enum SettingItem {
    case aboutUs
    case version
    case restorePurchase
    case feedback
    case rate
    
    var title: String {
        switch self {
        case .aboutUs: return "关于我们"
        case .version: return "版本"
        case .restorePurchase: return "恢复购买"
        case .feedback: return "反馈意见"
        case .rate: return "评价应用"
        }
    }
    
    var icon: String {
        switch self {
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
    private let settings: [SettingItem] = [.aboutUs, .version, .restorePurchase, .feedback, .rate]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "设置"
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
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
        case .aboutUs:
            showAlert(title: "关于我们", message: "GlowLed - 让你的文字发光\n\n一款专业的LED显示屏模拟应用")
        case .version:
            showAlert(title: "版本信息", message: "当前版本：1.0\n\n感谢您的使用！")
        case .restorePurchase:
            showAlert(title: "恢复购买", message: "暂无可恢复的购买项目")
        case .feedback:
            showAlert(title: "反馈意见", message: "请发送邮件至：\n784430005@qq.com")
        case .rate:
            showAlert(title: "评价应用", message: "感谢您的支持！\n请前往App Store为我们评分")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
