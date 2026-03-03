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
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
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
        // 16:9 宽高比计算 + 时间标签高度 + 新的边距
        let screenWidth = UIScreen.main.bounds.width
        // backgroundCard左右边距40px，containerView在backgroundCard内左右边距16px
        let cardWidth = screenWidth - 80 - 32 // 40*2 + 16*2
        let cardHeight = cardWidth * 9 / 16
        // cell上边距29（从38减少9） + 下边距0（从8减少8） + backgroundCard内上边距10 + 下边距20 + 时间标签高度20 + 时间标签上边距16
        return cardHeight + 29 + 0 + 10 + 20 + 20 + 16
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
        editAction.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFD/255.0, blue: 0xE6/255.0, alpha: 1.0)
        
        // 创建白色图标（无背景圆圈）
        let editIconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let editIcon = UIImage(systemName: "pencil.circle.fill", withConfiguration: editIconConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        editAction.image = editIcon
        
        // 删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] _, _, completionHandler in
            self?.confirmDelete(at: indexPath.row)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        // 创建白色图标（无背景圆圈）
        let deleteIconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let deleteIcon = UIImage(systemName: "trash.circle.fill", withConfiguration: deleteIconConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        deleteAction.image = deleteIcon
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
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
        let alert = UIAlertController(title: "confirmDelete".localized, message: "confirmDeleteMessage".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "delete".localized, style: .destructive) { [weak self] _ in
            self?.deleteCreation(at: index)
        })
        
        present(alert, animated: true)
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
        backgroundCard.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
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
        
        // 预览文字
        ledTextLabel.textAlignment = .center
        ledTextLabel.numberOfLines = 2
        ledTextLabel.adjustsFontSizeToFitWidth = true
        ledTextLabel.minimumScaleFactor = 0.5
        ledTextLabel.translatesAutoresizingMaskIntoConstraints = false
        previewView.addSubview(ledTextLabel)
        
        // 时间标签（放在卡片下面，在backgroundCard内）
        timeLabel.textColor = .systemGray
        timeLabel.font = .systemFont(ofSize: 15, weight: .regular) // 从13改为15（增大2px）
        timeLabel.textAlignment = .left
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundCard.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // backgroundCard: 距离屏幕左右边距40px，顶部距离29px（从38减少9），底部距离0px（从-8增加8，总共减少17px，接近18px）
            backgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 29),
            backgroundCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            backgroundCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            backgroundCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            
            // containerView: 在backgroundCard内，上边距10px，下边距20px，左右边距16px
            containerView.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -16),
            
            previewView.topAnchor.constraint(equalTo: containerView.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 9.0/16.0), // 16:9比例
            
            backgroundImageView.topAnchor.constraint(equalTo: previewView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            ledTextLabel.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            ledTextLabel.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
            ledTextLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            ledTextLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: -16),
            
            // 时间标签：放在卡片下面，在backgroundCard内，下边距20px（从30减少10），上边距16px
            timeLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: -20),
            
            // containerView底部约束（确保布局正确）
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: timeLabel.topAnchor, constant: -16)
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
        
        ledTextLabel.text = item.text
        ledTextLabel.font = UIFont(name: item.fontName, size: 20) ?? .boldSystemFont(ofSize: 20)
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
