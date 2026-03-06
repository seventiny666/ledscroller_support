import UIKit

// 我的创作页面
class MyCreationsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var creations: [LEDItem] = []
    private var emptyStateView: UIView!
    private var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCreations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .portrait
        loadCreations()
    }
    
    private func setupUI() {
        title = "creations".localized // 从"创作"改为"我的创作"
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 导航栏样式 - 标题和按钮在同一高度（关闭大标题）
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold) // 标准导航栏标题字体
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = false // 关闭大标题，标题和按钮同高度
        
        // 右上角添加新增按钮
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewLED))
        addButton.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        navigationItem.rightBarButtonItem = addButton
        
        // 表格视图
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CreationTableCell.self, forCellReuseIdentifier: "CreationCell")
        // tableView.register(AddCreationTableCell.self, forCellReuseIdentifier: "AddCell") // 注释掉添加按钮
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // 空状态视图
        setupEmptyStateView()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20), // 整个卡片区往下移动20px
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyStateView() {
        emptyStateView = UIView()
        emptyStateView.backgroundColor = .clear
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        
        // 图标（邮件堆叠图标）
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "mail.stack.fill")
        iconImageView.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(iconImageView)
        
        // 创建按钮（胶囊形状）
        createButton = UIButton(type: .system)
        createButton.setTitle("createLED".localized, for: .normal)
        createButton.setTitleColor(.black, for: .normal) // 黑色文字
        createButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        createButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        createButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        createButton.addTarget(self, action: #selector(createNewLED), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(createButton)
        
        // 提示文字（放在按钮下面）
        let hintLabel = UILabel()
        hintLabel.text = "createFirstLED".localized
        hintLabel.textColor = .systemGray
        hintLabel.font = .systemFont(ofSize: 14, weight: .regular)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // 居中显示
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            iconImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            createButton.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 32),
            createButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 200),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
            hintLabel.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 16),
            hintLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func loadCreations() {
        let allItems = LEDDataManager.shared.loadItems()
        // 只加载用户创建的LED（排除特殊效果、模版和预设卡片）
        creations = allItems.filter { 
            !$0.isFlipClock && !$0.isFireworks && !$0.isFireworksBloom && 
            !$0.isLoveRain && !$0.isNeonTemplate && !$0.isIdolTemplate && !$0.isLEDTemplate &&
            !$0.isDefaultPreset // 排除预设卡片
        }
        
        // 按创建时间倒序排列（最新的在最上面）
        creations.sort { $0.createdAt > $1.createdAt }
        
        // 更新UI
        if creations.isEmpty {
            // 空状态：显示空状态视图
            emptyStateView.isHidden = false
            tableView.isHidden = true
        } else {
            // 有内容：显示表格（包含添加按钮）
            emptyStateView.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()
    }
    
    @objc private func createNewLED() {
        let createVC = LEDCreateViewController()
        createVC.onSave = { [weak self] in
            self?.loadCreations()
            self?.showToast(message: "addSuccess".localized)
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
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
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            toast.heightAnchor.constraint(equalToConstant: 40)
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
extension MyCreationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creations.count // 不再+1，移除添加按钮
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 直接返回创作内容
        let cell = tableView.dequeueReusableCell(withIdentifier: "CreationCell", for: indexPath) as! CreationTableCell
        cell.configure(with: creations[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 19.5:9 宽高比计算 + 时间标签高度 + 优化后的边距
        let screenWidth = UIScreen.main.bounds.width
        // backgroundCard左右边距40px，containerView在backgroundCard内左右边距14px
        let cardWidth = screenWidth - 80 - 28 // 40*2 + 14*2
        let cardHeight = cardWidth * 9 / 19.5 // 19.5:9比例
        // backgroundCard顶部边距0 + containerView内上边距14 + 封面到时间间距8 + 时间标签高度20 + 时间到底部间距8 + backgroundCard底部间距20px
        return cardHeight + 0 + 14 + 8 + 20 + 8 + 20 // 减少时间区域上下间距，总共减少20px
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 点击创作内容 - 优化方向切换，减少卡顿
        let item = creations[indexPath.row]
        
        // 先切换方向
        AppDelegate.orientationLock = .landscape
        
        // 延迟一点再present，让方向切换更流畅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            displayVC.modalTransitionStyle = .crossDissolve // 使用淡入淡出过渡，更流畅
            self.present(displayVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 编辑操作
        let editAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completionHandler in
            self?.editCreation(at: indexPath.row)
            completionHandler(true)
        }
        // 设置为黑色背景（与页面背景一致）
        editAction.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // 创建编辑图标：白色图标 + 绿色圆形背景 (#26C363)
        editAction.image = createCustomIcon(
            symbolName: "pencil",
            iconColor: .white,
            backgroundColor: UIColor(red: 0x26/255.0, green: 0xC3/255.0, blue: 0x63/255.0, alpha: 1.0),
            size: 44
        )
        
        // 删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] _, _, completionHandler in
            self?.confirmDelete(at: indexPath.row)
            completionHandler(true)
        }
        // 设置为黑色背景（与页面背景一致）
        deleteAction.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // 创建删除图标：白色图标 + 红色圆形背景
        deleteAction.image = createCustomIcon(
            symbolName: "trash",
            iconColor: .white,
            backgroundColor: .systemRed,
            size: 44
        )
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    // 创建自定义圆形图标
    private func createCustomIcon(symbolName: String, iconColor: UIColor, backgroundColor: UIColor, size: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            // 绘制圆形背景
            let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            backgroundColor.setFill()
            circle.fill()
            
            // 绘制图标
            let iconConfig = UIImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
            if let icon = UIImage(systemName: symbolName, withConfiguration: iconConfig) {
                let iconSize = icon.size
                let iconRect = CGRect(
                    x: (size - iconSize.width) / 2,
                    y: (size - iconSize.height) / 2,
                    width: iconSize.width,
                    height: iconSize.height
                )
                icon.withTintColor(iconColor, renderingMode: .alwaysOriginal).draw(in: iconRect)
            }
        }
    }
    
    private func editCreation(at index: Int) {
        let item = creations[index]
        let createVC = LEDCreateViewController(editingItem: item)
        createVC.onSave = { [weak self] in
            self?.loadCreations()
            self?.showToast(message: "updateSuccess".localized)
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func confirmDelete(at index: Int) {
        let deleteConfirmView = DeleteConfirmView()
        deleteConfirmView.onDelete = { [weak self] in
            self?.deleteCreation(at: index)
        }
        deleteConfirmView.show(in: self)
    }
    
    private func deleteCreation(at index: Int) {
        let itemToDelete = creations[index]
        creations.remove(at: index)
        
        // 从数据库中删除
        var allItems = LEDDataManager.shared.loadItems()
        allItems.removeAll { $0.id == itemToDelete.id }
        LEDDataManager.shared.saveItems(allItems)
        
        // 更新UI（带动画）
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        
        // 如果删除后为空，显示空状态视图
        if creations.isEmpty {
            emptyStateView.isHidden = false
            tableView.isHidden = true
        }
    }
}

// MARK: - 添加创作TableCell（已注释，不再使用）
/*
class AddCreationTableCell: UITableViewCell {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
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
        
        // 容器视图
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray3.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 加号图标
        iconImageView.image = UIImage(systemName: "plus")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // 标题
        titleLabel.text = "创作LED屏幕"
        titleLabel.textColor = .systemGray
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}
*/

// MARK: - 创作内容TableCell
class CreationTableCell: UITableViewCell {
    
    private let backgroundCard = UIView() // 深色圆角背景
    private let containerView = UIView()
    private let previewView = UIView()
    private let backgroundImageView = UIImageView()
    private let borderView = MarqueeBorderView() // 跑马灯边框视图
    private let lightBoardView = LightBoardBorderView() // 灯牌边框视图
    private let ledTextLabel = UILabel() // 改名避免与UITableViewCell的textLabel冲突
    private let timeLabel = UILabel() // 时间标签（放在卡片下面）
    
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
        
        // 深色圆角背景卡片（类似设置页面的卡片样式）
        backgroundCard.backgroundColor = UIColor(red: 0x20/255.0, green: 0x1F/255.0, blue: 0x1F/255.0, alpha: 1) // #201F1F
        backgroundCard.layer.cornerRadius = 16
        backgroundCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundCard)
        
        // 容器视图（放在backgroundCard内）
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        backgroundCard.addSubview(containerView)
        
        // 预览区域
        previewView.layer.cornerRadius = 18 // 增大圆角从12到18
        previewView.layer.borderWidth = 2
        previewView.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        previewView.clipsToBounds = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(previewView)
        
        // 背景图片视图
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        previewView.addSubview(backgroundImageView)
        
        // 边框视图
        borderView.setAnimated(false) // 卡片中的边框静态显示
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.isHidden = true // 默认隐藏
        previewView.addSubview(borderView)
        
        // 灯牌边框视图
        lightBoardView.translatesAutoresizingMaskIntoConstraints = false
        lightBoardView.isHidden = true // 默认隐藏
        previewView.addSubview(lightBoardView)
        
        // 预览文字
        ledTextLabel.textAlignment = .center
        ledTextLabel.numberOfLines = 2
        ledTextLabel.adjustsFontSizeToFitWidth = true
        ledTextLabel.minimumScaleFactor = 0.5
        ledTextLabel.translatesAutoresizingMaskIntoConstraints = false
        previewView.addSubview(ledTextLabel)
        
        // 时间标签（放在卡片下面，在backgroundCard内）
        timeLabel.textColor = .systemGray
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular) // 从15减少到13，适配紧凑布局
        timeLabel.textAlignment = .center // 改为居中对齐
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundCard.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // backgroundCard: 顶部边距0px，紧贴内容区域
            backgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0), // 设为0px
            backgroundCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            backgroundCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            backgroundCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20), // 卡片间距20px
            
            // containerView: 在backgroundCard内，统一使用14px边距
            containerView.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: 14), // 设为14px
            containerView.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: 14), // 设为14px
            containerView.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -14), // 设为14px
            
            previewView.topAnchor.constraint(equalTo: containerView.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 9.0/19.5), // 19.5:9比例
            
            backgroundImageView.topAnchor.constraint(equalTo: previewView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            borderView.topAnchor.constraint(equalTo: previewView.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            lightBoardView.topAnchor.constraint(equalTo: previewView.topAnchor),
            lightBoardView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            lightBoardView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            lightBoardView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            ledTextLabel.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            ledTextLabel.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
            ledTextLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            ledTextLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: -16),
            
            // 时间标签：减少上下间距，水平居中显示
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor), // 水平居中
            timeLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 8), // 距离封面底部8px
            timeLabel.bottomAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: -8), // 距离卡片底部8px
            
            // containerView不需要底部约束，由previewView的高度和时间标签的位置决定布局
        ])
    }
    
    func configure(with item: LEDItem) {
        // 更新背景（图片或颜色）
        if let imageName = item.backgroundImageName, let image = UIImage(named: imageName) {
            backgroundImageView.image = image
            backgroundImageView.isHidden = false
            previewView.backgroundColor = .clear
        } else {
            backgroundImageView.image = nil
            backgroundImageView.isHidden = true
            previewView.backgroundColor = UIColor(hex: item.backgroundColor)
        }
        
        // 更新边框
        if let borderStyleIndex = item.borderStyle,
           borderStyleIndex >= 0 && borderStyleIndex < MarqueeBorderStyle.allCases.count {
            let style = MarqueeBorderStyle.allCases[borderStyleIndex]
            borderView.setStyle(style)
            borderView.isHidden = false
            lightBoardView.isHidden = true
        } else if let lightBoardStyleIndex = item.lightBoardStyle,
                  lightBoardStyleIndex >= 0 && lightBoardStyleIndex < LightBoardBorderStyle.allCases.count {
            let style = LightBoardBorderStyle.allCases[lightBoardStyleIndex]
            lightBoardView.setStyle(style)
            lightBoardView.isHidden = false
            borderView.isHidden = true
        } else {
            borderView.isHidden = true
            lightBoardView.isHidden = true
        }
        
        ledTextLabel.text = item.text
        
        // 统一字体大小计算：基于全屏横屏尺寸等比缩放
        // 全屏横屏基准：852px宽度（iPhone 14 Pro横屏）
        // fontSize值对应全屏横屏时的实际pt大小
        let containerWidth = previewView.bounds.width > 0 ? previewView.bounds.width : 285
        let landscapeWidth: CGFloat = 852 // 全屏横屏基准宽度
        
        // 按容器宽度比例缩放字体
        let scaleFactor = containerWidth / landscapeWidth
        let calculatedFontSize = item.fontSize * scaleFactor
        
        ledTextLabel.font = UIFont(name: item.fontName, size: calculatedFontSize) ?? .boldSystemFont(ofSize: calculatedFontSize)
        ledTextLabel.textColor = UIColor(hex: item.textColor)
        
        // 霓虹效果
        ledTextLabel.layer.shadowColor = UIColor(hex: item.textColor).cgColor
        ledTextLabel.layer.shadowRadius = 6 * item.glowIntensity
        ledTextLabel.layer.shadowOpacity = Float(item.glowIntensity * 0.3)
        ledTextLabel.layer.shadowOffset = .zero
        
        // 格式化时间显示（放在卡片下面）
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        timeLabel.text = formatter.string(from: item.createdAt)
    }
}

// 移除旧的CollectionView Cell类

// MARK: - 删除确认弹窗视图
class DeleteConfirmView: UIView {
    
    var onDelete: (() -> Void)?
    var onCancel: (() -> Void)?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
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
        titleLabel.text = "confirmDelete".localized
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 消息
        messageLabel.text = "confirmDeleteMessage".localized
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // 取消按钮（左侧，胶囊形状）
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        // 删除按钮（右侧，红色，胶囊形状）
        deleteButton.setTitle("delete".localized, for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        deleteButton.backgroundColor = UIColor.systemRed
        deleteButton.layer.cornerRadius = 25 // 胶囊形状（高度50的一半）
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 210),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // 取消按钮在左侧
            cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            
            // 删除按钮在右侧
            deleteButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -34),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        // 添加点击背景关闭手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func deleteTapped() {
        hide {
            self.onDelete?()
        }
    }
    
    @objc private func cancelTapped() {
        hide {
            self.onCancel?()
        }
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !containerView.frame.contains(location) {
            cancelTapped()
        }
    }
    
    func show(in viewController: UIViewController) {
        self.presentingVC = viewController
        
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: viewController.view.topAnchor),
            leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        // 动画显示
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            self.alpha = 1
            self.containerView.transform = .identity
        })
    }
    
    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension DeleteConfirmView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}