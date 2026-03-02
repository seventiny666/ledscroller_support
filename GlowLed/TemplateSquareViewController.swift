import UIKit

// 模版分类
enum TemplateCategory: String, CaseIterable {
    case neon = "霓虹灯看板"
    case idol = "偶像应援"
    case ledScreen = "LED横幅"
    case clock = "数字时钟"
    case other = "其他分类"
    
    var titleColor: UIColor {
        switch self {
        case .neon:
            return UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0) // #8EFFE6
        case .idol:
            return UIColor(red: 0xFF/255.0, green: 0x6B/255.0, blue: 0xD6/255.0, alpha: 1.0) // #FF6BD6
        case .ledScreen:
            return UIColor(red: 0x6B/255.0, green: 0xFF/255.0, blue: 0xB0/255.0, alpha: 1.0) // #6BFFB0
        case .clock, .other:
            return .white
        }
    }
}

// 模版广场视图控制器
class TemplateSquareViewController: UIViewController {
    
    private var tableView: UITableView!
    private var categories: [TemplateCategory] = TemplateCategory.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制恢复竖屏
        AppDelegate.orientationLock = .portrait
    }
    
    private func setupUI() {
        title = "模版"
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        // 标题居中，字体缩小
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = false // 关闭大标题，使用普通标题居中
        
        // 创建表格视图
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0) // 顶部10px，底部20px
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate & DataSource
extension TemplateSquareViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! TemplateCategoryCell
        let category = categories[indexPath.section]
        cell.configure(with: category)
        cell.onItemTapped = { [weak self] item in
            self?.handleItemTap(item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let category = categories[indexPath.section]
        // 时钟分类只有1个，其他分类有4个（2行×2列）
        // 增加高度确保底部卡片完全显示
        return category == .clock ? 200 : 350
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let category = categories[section]
        
        // 渐变图标（圆角矩形）
        let gradientIcon = UIView()
        gradientIcon.layer.cornerRadius = 10.2
        gradientIcon.clipsToBounds = true
        gradientIcon.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(gradientIcon)
        
        // 添加渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0xC1/255.0, green: 0xFF/255.0, blue: 0xF4/255.0, alpha: 1.0).cgColor,
            UIColor(red: 0xFF/255.0, green: 0x6B/255.0, blue: 0xD6/255.0, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        gradientLayer.cornerRadius = 10.2
        gradientIcon.layer.addSublayer(gradientLayer)
        
        let label = UILabel()
        label.text = category.rawValue
        label.textColor = category.titleColor // 使用分类对应的颜色
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            gradientIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            gradientIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            gradientIcon.widthAnchor.constraint(equalToConstant: 24),
            gradientIcon.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: gradientIcon.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 44 : 54 // 第一个section 44px，其他section 54px（44 + 10间距，再减少15px）
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01 // 最小高度，移除footer间距
    }
    
    private func handleItemTap(_ item: LEDItem) {
        if item.isLoveRain {
            AppDelegate.orientationLock = .landscape
            let loveRainVC = LoveRainViewController()
            loveRainVC.modalPresentationStyle = .fullScreen
            present(loveRainVC, animated: true)
        } else if item.isFlipClock {
            AppDelegate.orientationLock = .landscape
            let clockVC = FlipClockViewController()
            clockVC.modalPresentationStyle = .fullScreen
            present(clockVC, animated: true)
        } else if item.isFireworksBloom {
            let fireworksVC = FireworksBloomViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else if item.isFireworks {
            let fireworksVC = FireworksViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else {
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        }
    }
}

// MARK: - 模版分类Cell
class TemplateCategoryCell: UITableViewCell {
    
    private var collectionView: UICollectionView!
    private var items: [LEDItem] = []
    var onItemTapped: ((LEDItem) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TemplateItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with category: TemplateCategory) {
        items = getItems(for: category)
        collectionView.reloadData()
    }
    
    private func getItems(for category: TemplateCategory) -> [LEDItem] {
        let allItems = LEDDataManager.shared.loadItems()
        
        switch category {
        case .clock:
            // 返回翻页时钟和占位符
            var items = allItems.filter { $0.isFlipClock }
            // 如果没有时钟，创建占位符
            if items.isEmpty {
                let clockItem = LEDItem(
                    id: "clock-placeholder",
                    text: "数字时钟",
                    fontSize: 50,
                    textColor: "#8EFFE6",
                    backgroundColor: "#1a1a2e",
                    glowIntensity: 3.0
                )
                items.append(clockItem)
            }
            return items
        case .other:
            // 返回预设卡片 + 用户创建的卡片
            let presetItems = allItems.filter { $0.isDefaultPreset }
            let userItems = allItems.filter { 
                !$0.isFlipClock && !$0.isNeonTemplate && !$0.isIdolTemplate && 
                !$0.isLEDTemplate && !$0.isDefaultPreset && 
                !$0.isFireworks && !$0.isFireworksBloom && !$0.isLoveRain
            }
            // 预设卡片在前，用户创建的在后
            return presetItems + userItems
        case .neon:
            // 霓虹灯看板模版（占位）- 改为4个
            return createPlaceholderItems(category: "neon", count: 4)
        case .idol:
            // 偶像应援模版（占位）- 改为4个
            return createPlaceholderItems(category: "idol", count: 4)
        case .ledScreen:
            // LED屏幕模版（占位）- 改为4个
            return createPlaceholderItems(category: "led", count: 4)
        }
    }
    
    private func createPlaceholderItems(category: String, count: Int) -> [LEDItem] {
        var items: [LEDItem] = []
        for i in 1...count {
            let item = LEDItem(
                id: "\(category)-\(i)",
                text: "\(category.uppercased()) \(i)",
                fontSize: 50,
                textColor: "#FF69B4",
                backgroundColor: "#1a1a2e",
                glowIntensity: 3.0
            )
            items.append(item)
        }
        return items
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension TemplateCategoryCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! TemplateItemCell
        cell.configure(with: items[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 52) / 2 // 2列，左右各20，中间12
        return CGSize(width: width, height: width * 0.85)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onItemTapped?(items[indexPath.item])
    }
}

// MARK: - 模版项Cell
class TemplateItemCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 容器
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 图片（16:9比例）
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // 标题
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with item: LEDItem) {
        titleLabel.text = item.text
        
        // 尝试加载图片，如果没有则使用占位颜色
        if let imageName = item.imageName, !imageName.isEmpty {
            imageView.image = UIImage(named: imageName)
        } else {
            // 使用占位颜色
            imageView.image = nil
            imageView.backgroundColor = UIColor(hex: item.backgroundColor)
        }
    }
}

// LEDItem扩展：添加模版相关属性
extension LEDItem {
    var isNeonTemplate: Bool {
        return id.hasPrefix("neon-")
    }
    
    var isIdolTemplate: Bool {
        return id.hasPrefix("idol-")
    }
    
    var isLEDTemplate: Bool {
        return id.hasPrefix("led-")
    }
    
    var imageName: String? {
        // 图片命名规则：category_number.png
        // 例如：neon_1.png, idol_2.png, led_3.png, clock_1.png
        if isNeonTemplate {
            return "neon_\(id.replacingOccurrences(of: "neon-", with: ""))"
        } else if isIdolTemplate {
            return "idol_\(id.replacingOccurrences(of: "idol-", with: ""))"
        } else if isLEDTemplate {
            return "led_\(id.replacingOccurrences(of: "led-", with: ""))"
        } else if isFlipClock {
            // 翻页时钟使用 clock_1
            return "clock_1"
        }
        return nil
    }
}
