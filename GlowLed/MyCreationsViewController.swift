import UIKit

// 我的创作页面
class MyCreationsViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var creations: [LEDItem] = []
    
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
        title = "创作"
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 集合视图布局
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CreationCell.self, forCellWithReuseIdentifier: "CreationCell")
        collectionView.register(AddCreationCell.self, forCellWithReuseIdentifier: "AddCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadCreations() {
        let allItems = LEDDataManager.shared.loadItems()
        // 只加载用户创建的LED（排除特殊效果和模版）
        creations = allItems.filter { 
            !$0.isFlipClock && !$0.isFireworks && !$0.isFireworksBloom && 
            !$0.isLoveRain && !$0.isNeonTemplate && !$0.isIdolTemplate && !$0.isLEDTemplate 
        }
        collectionView.reloadData()
    }
    
    @objc private func createNewLED() {
        let createVC = LEDCreateViewController()
        createVC.onSave = { [weak self] in
            self?.loadCreations()
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension MyCreationsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return creations.count + 1 // +1 for add button
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            // 第一个是添加按钮
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCell", for: indexPath) as! AddCreationCell
            return cell
        } else {
            // 其他是创作内容
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreationCell", for: indexPath) as! CreationCell
            cell.configure(with: creations[indexPath.item - 1])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 48) / 2 // 2列，左右各16，中间16
        return CGSize(width: width, height: width * 0.65) // 减小高度比例从0.85到0.65
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            // 点击添加按钮
            createNewLED()
        } else {
            // 点击创作内容
            let item = creations[indexPath.item - 1]
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // 添加按钮不显示菜单
        guard indexPath.item > 0 else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "编辑", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.editCreation(at: indexPath.item - 1)
            }
            
            let deleteAction = UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteCreation(at: indexPath.item - 1)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
    
    private func editCreation(at index: Int) {
        let item = creations[index]
        let createVC = LEDCreateViewController(editingItem: item)
        createVC.onSave = { [weak self] in
            self?.loadCreations()
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func deleteCreation(at index: Int) {
        creations.remove(at: index)
        let allItems = LEDDataManager.shared.loadItems()
        let filteredItems = allItems.filter { item in
            !creations.contains(where: { $0.id == item.id }) || 
            item.isFlipClock || item.isFireworks || item.isFireworksBloom || 
            item.isLoveRain || item.isNeonTemplate || item.isIdolTemplate || item.isLEDTemplate
        }
        LEDDataManager.shared.saveItems(filteredItems)
        collectionView.reloadData()
    }
}

// MARK: - 添加创作Cell
class AddCreationCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 虚线边框容器
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray3.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 添加虚线效果
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = UIColor.systemGray3.cgColor
        dashedBorder.lineDashPattern = [6, 4]
        dashedBorder.frame = containerView.bounds
        dashedBorder.fillColor = nil
        dashedBorder.path = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
        containerView.layer.addSublayer(dashedBorder)
        
        // 加号图标
        iconImageView.image = UIImage(systemName: "plus")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // 标题
        titleLabel.text = "创建LED"
        titleLabel.textColor = .systemGray
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -15),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 更新虚线边框
        if let dashedBorder = containerView.layer.sublayers?.first as? CAShapeLayer {
            dashedBorder.frame = containerView.bounds
            dashedBorder.path = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
        }
    }
}

// MARK: - 创作内容Cell
class CreationCell: UICollectionViewCell {
    
    private let previewView = UIView()
    private let textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 预览区域（直接作为cell的背景）
        previewView.layer.cornerRadius = 16
        previewView.layer.borderWidth = 2
        previewView.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        previewView.clipsToBounds = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewView)
        
        // 预览文字
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 2
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.5
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        previewView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: contentView.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            textLabel.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: -12)
        ])
    }
    
    func configure(with item: LEDItem) {
        previewView.backgroundColor = UIColor(hex: item.backgroundColor)
        textLabel.text = item.text
        textLabel.font = UIFont(name: item.fontName, size: 24) ?? .boldSystemFont(ofSize: 24)
        textLabel.textColor = UIColor(hex: item.textColor)
        
        // 霓虹效果
        textLabel.layer.shadowColor = UIColor(hex: item.textColor).cgColor
        textLabel.layer.shadowRadius = 8 * item.glowIntensity
        textLabel.layer.shadowOpacity = Float(item.glowIntensity * 0.3)
        textLabel.layer.shadowOffset = .zero
    }
}
