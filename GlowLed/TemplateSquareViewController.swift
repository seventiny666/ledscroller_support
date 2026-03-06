import UIKit

// 模版分类
enum TemplateCategory: String, CaseIterable {
    case neon = "霓虹灯看板"
    case idol = "偶像应援"
    case ledScreen = "LED横幅"
    case clock = "数字时钟"
    case other = "其他分类"
    
    var localizedName: String {
        switch self {
        case .neon: return "neon".localized
        case .idol: return "idol".localized
        case .ledScreen: return "led".localized
        case .clock: return "clock".localized
        case .other: return "other".localized
        }
    }
    
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

// Tab类型
enum TemplateTab: String {
    case popular = "热门模版"
    case animation = "动画模版"
    
    var localizedName: String {
        switch self {
        case .popular: return "popular".localized
        case .animation: return "animation".localized
        }
    }
}

// 模版广场视图控制器
class TemplateSquareViewController: UIViewController {
    
    private var tableView: UITableView!
    private var categories: [TemplateCategory] = []
    private var currentTab: TemplateTab = .popular
    private lazy var segmentedControl: UISegmentedControl = {
        let items = [TemplateTab.popular.localizedName, TemplateTab.animation.localizedName]
        return UISegmentedControl(items: items)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateCategories()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制恢复竖屏
        AppDelegate.orientationLock = .portrait
        
        // 刷新UI以应用语言更改
        refreshUI()
        
        // 强制刷新布局，修复从横屏返回后卡片尺寸异常的问题
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保分段控制器是胶囊形状（圆角为高度的一半）
        if segmentedControl.bounds.height > 0 {
            segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
            segmentedControl.layer.masksToBounds = true
        }
    }
    
    private func updateCategories() {
        switch currentTab {
        case .popular:
            // 热门模版：霓虹灯看板、偶像应援、LED横幅
            categories = [.neon, .idol, .ledScreen]
        case .animation:
            // 动画模版：数字时钟、其他分类
            categories = [.clock, .other]
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 隐藏导航栏标题
        title = ""
        
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 设置分段控制器 - 放在导航栏标题位置
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // 自定义分段控制器样式 - 简单的胶囊背景 + 文字
        segmentedControl.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1) // 深色胶囊背景
        
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用新的API
            // 选中背景颜色（青色胶囊）
            segmentedControl.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        } else {
            // iOS 12 及以下
            segmentedControl.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        }
        
        // 未选中状态：白色半透明文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)
        
        // 选中状态：黑色文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        
        // 将分段控制器设置为导航栏的titleView
        navigationItem.titleView = segmentedControl
        
        // 设置分段控制器的固定尺寸（增加高度以显示内边距效果）
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.widthAnchor.constraint(equalToConstant: 220),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40) // 从36增加到40，让选中背景看起来有内边距
        ])
        
        // 创建表格视图
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.contentInset = UIEdgeInsets(top: 14, left: 0, bottom: 20, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // 表格视图直接从顶部开始
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func segmentChanged() {
        currentTab = segmentedControl.selectedSegmentIndex == 0 ? .popular : .animation
        updateCategories()
        tableView.reloadData()
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    private func refreshUI() {
        // 更新分段控制器的标题
        segmentedControl.setTitle(TemplateTab.popular.localizedName, forSegmentAt: 0)
        segmentedControl.setTitle(TemplateTab.animation.localizedName, forSegmentAt: 1)
        
        // 刷新表格视图以更新分类标题
        tableView.reloadData()
    }
    
    func showToast(message: String) {
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
        cell.configure(with: category, tab: currentTab)
        cell.onItemTapped = { [weak self] item in
            self?.handleItemTap(item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let category = categories[indexPath.section]
        // 时钟分类只有1个，其他分类有4个（2行×2列）
        // 增加高度确保底部卡片完全显示，增加额外的20px底部空间
        return category == .clock ? 220 : 380
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let category = categories[section]
        
        // 标题文字（去掉图标）
        let label = UILabel()
        label.text = category.localizedName
        label.textColor = UIColor.white.withAlphaComponent(0.9) // 白色 0.9透明度
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 54 : 44 // 第一个section 54px，其他section 44px
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01 // 最小高度，移除footer间距
    }
    
    private func handleItemTap(_ item: LEDItem) {
        // 特殊效果直接跳转
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
        } else if currentTab == .popular && (item.isNeonTemplate || item.isIdolTemplate || item.isLEDTemplate) {
            // 热门模版：点击封面直接进入全屏预览（无按钮）
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        } else {
            // 其他：普通LED卡片直接全屏预览
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
    private var currentTab: TemplateTab = .popular
    var onItemTapped: ((LEDItem) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 强制刷新CollectionView布局，修复从横屏返回后尺寸异常的问题
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TemplateItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        collectionView.isScrollEnabled = false
        collectionView.clipsToBounds = false // 关闭裁剪，让底部卡片完全显示
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with category: TemplateCategory, tab: TemplateTab) {
        currentTab = tab
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
        
        // 定义每个分类的文字内容
        let texts: [String]
        switch category {
        case "neon":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "idol":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "led":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        default:
            texts = ["TEXT 1", "TEXT 2", "TEXT 3", "TEXT 4"]
        }
        
        // 根据分类设置不同的滚动类型
        let scrollType: LEDItem.ScrollType
        let speed: Double
        switch category {
        case "neon", "idol":
            // 霓虹灯和偶像屏幕：使用闪烁效果
            scrollType = .blink
            speed = 0.5 // 闪烁速度（更快）
        case "led":
            // LED屏幕：从右到左滚动
            scrollType = .scrollLeft
            speed = 2.0 // 滚动速度
        default:
            scrollType = .none
            speed = 1.5
        }
        
        for i in 1...count {
            let text = i <= texts.count ? texts[i - 1] : "TEXT \(i)"
            let imageName = "\(category)_\(i)" // 例如：neon_1, idol_2, led_3
            let item = LEDItem(
                id: "\(category)-\(i)",
                text: text,
                fontSize: 60, // iPhone 14样式
                textColor: "#FFFFFF", // 白色
                backgroundColor: "#1a1a2e",
                backgroundImageName: imageName, // 添加背景图片
                glowIntensity: 3.0,
                scrollType: scrollType,
                speed: speed
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
        let item = items[indexPath.item]
        cell.configure(with: item, tab: currentTab)
        
        if currentTab == .popular {
            // 热门模版：只有试用按钮
            cell.onTryTapped = { [weak self] item in
                // 试用：进入编辑页面
                guard let self = self else { return }
                if let parentVC = self.parentViewController as? TemplateSquareViewController {
                    let createVC = LEDCreateViewController(editingItem: item, isTemplateEdit: true)
                    createVC.onSave = {
                        parentVC.showToast(message: "saved".localized)
                    }
                    let nav = UINavigationController(rootViewController: createVC)
                    nav.modalPresentationStyle = .fullScreen
                    parentVC.present(nav, animated: true)
                }
            }
            
            cell.onPreviewTapped = { [weak self] item in
                // 点击封面：直接进入全屏预览（无按钮）
                self?.onItemTapped?(item)
            }
        } else {
            // 动画模版：点击封面直接进入对应效果
            cell.onPreviewTapped = { [weak self] item in
                self?.onItemTapped?(item)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 54) / 2 // 2列，左右各20，中间14
        return CGSize(width: width, height: width * 0.95) // 增加高度以容纳按钮
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 不再需要，因为点击由cell内部处理
    }
}

// MARK: - 模版项Cell
class TemplateItemCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let overlayTextLabel = UILabel() // 封面图片上的文字
    private let titleLabel = UILabel() // 卡片下方的标题（动画模版用）
    private let containerView = UIView()
    private let buttonStack = UIStackView() // 按钮容器
    private let tryButton = UIButton(type: .system) // 试用按钮
    private let previewButton = UIButton(type: .system) // 预览按钮
    private var currentItem: LEDItem?
    var onTryTapped: ((LEDItem) -> Void)?
    var onPreviewTapped: ((LEDItem) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 容器
        containerView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.18)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = false // 改为false，避免裁剪底部内容
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 图片（16:9比例）
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        containerView.addSubview(imageView)
        
        // 添加点击手势到图片
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tapGesture)
        
        // 封面图片上的文字（霓虹效果）
        overlayTextLabel.textColor = .white
        overlayTextLabel.font = .systemFont(ofSize: 20, weight: .bold)
        overlayTextLabel.textAlignment = .center
        overlayTextLabel.numberOfLines = 2
        overlayTextLabel.adjustsFontSizeToFitWidth = true
        overlayTextLabel.minimumScaleFactor = 0.5
        overlayTextLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayTextLabel)
        
        // 标题（动画模版用）
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 按钮容器
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)
        
        // 试用模版按钮（胶囊形状）
        tryButton.setTitle("try".localized, for: .normal)
        tryButton.setTitleColor(.white, for: .normal)
        tryButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        tryButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.3)
        tryButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        tryButton.layer.masksToBounds = true
        tryButton.layer.borderWidth = 1
        tryButton.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        tryButton.addTarget(self, action: #selector(tryButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(tryButton)
        
        // 预览模版按钮（胶囊形状）
        previewButton.setTitle("preview".localized, for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        previewButton.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        previewButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        previewButton.layer.masksToBounds = true
        previewButton.layer.borderWidth = 1
        previewButton.layer.borderColor = UIColor.systemPink.cgColor
        previewButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(previewButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 9),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -9),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0),
            
            overlayTextLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            overlayTextLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            overlayTextLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            overlayTextLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            buttonStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            buttonStack.heightAnchor.constraint(equalToConstant: 14) // 高度14px
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保按钮始终是胶囊形状（圆角为高度的一半）
        // 使用实际高度来计算，确保完美的胶囊形状
        if tryButton.bounds.height > 0 {
            tryButton.layer.cornerRadius = tryButton.bounds.height / 2
        }
        if previewButton.bounds.height > 0 {
            previewButton.layer.cornerRadius = previewButton.bounds.height / 2
        }
    }
    
    @objc private func imageTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    @objc private func tryButtonTapped() {
        guard let item = currentItem else { return }
        onTryTapped?(item)
    }
    
    @objc private func previewButtonTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    func configure(with item: LEDItem, tab: TemplateTab) {
        currentItem = item
        
        if tab == .popular {
            // 热门模版：只显示试用按钮，隐藏预览按钮和标题
            overlayTextLabel.text = item.text
            overlayTextLabel.isHidden = false
            titleLabel.isHidden = true
            buttonStack.isHidden = false
            tryButton.isHidden = false
            previewButton.isHidden = true
            
            // 调整按钮高度
            buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttonStack.addArrangedSubview(tryButton)
            
            // 强制立即布局并更新按钮圆角
            layoutIfNeeded()
            if tryButton.bounds.height > 0 {
                tryButton.layer.cornerRadius = tryButton.bounds.height / 2
            }
        } else {
            // 动画模版：显示标题，隐藏按钮和封面文字
            overlayTextLabel.isHidden = true
            titleLabel.text = item.text
            titleLabel.isHidden = false
            buttonStack.isHidden = true
        }
        
        // 封面图片上的文字添加霓虹效果
        overlayTextLabel.layer.shadowColor = UIColor(red: 255/255.0, green: 31/255.0, blue: 157/255.0, alpha: 0.75).cgColor
        overlayTextLabel.layer.shadowRadius = 20
        overlayTextLabel.layer.shadowOpacity = 1.0
        overlayTextLabel.layer.shadowOffset = .zero
        overlayTextLabel.layer.masksToBounds = false
        
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

// UIView扩展：获取父视图控制器
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
