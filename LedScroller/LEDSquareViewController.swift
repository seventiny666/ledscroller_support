import UIKit

// LED广场主页
class LEDSquareViewController: UIViewController {
    
    private var ledItems: [LEDItem] = []
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("📱 首页 viewWillAppear")
        print("   collectionView.isUserInteractionEnabled: \(collectionView.isUserInteractionEnabled)")
        print("   view.isUserInteractionEnabled: \(view.isUserInteractionEnabled)")
        
        // 强制恢复竖屏
        
        loadData()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    private func setupUI() {
        title = "LED广场"
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 统一为纯黑色
        
        // 确保导航栏样式正确
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // 右侧创建按钮
        let createButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createLED))
        createButton.tintColor = .systemPink
        navigationItem.rightBarButtonItem = createButton
        
        // 集合视图布局
        let layout = UICollectionViewFlowLayout()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        layout.minimumInteritemSpacing = isPad ? 30 : 17 // iPad needs more breathing room
        layout.minimumLineSpacing = isPad ? 30 : 17
        layout.sectionInset = UIEdgeInsets(top: 20, left: 26, bottom: 20, right: 26) // keep existing edge insets
        
        let width = (view.bounds.width - 30) / 2 // 宽度计算：(屏幕宽度 - 30) / 2
        layout.itemSize = CGSize(width: width, height: width * 0.6)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LEDCell.self, forCellWithReuseIdentifier: "LEDCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadData() {
        ledItems = LEDDataManager.shared.loadItems()
        collectionView.reloadData()
    }
    
    @objc private func createLED() {
        print("🔍 点击了创建按钮")
        let createVC = LEDCreateViewController()
        createVC.onSave = { [weak self] in
            self?.loadData()
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension LEDSquareViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ledItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LEDCell", for: indexPath) as! LEDCell
        let item = ledItems[indexPath.item]
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("🔍 点击了卡片: \(indexPath.item)")
        let item = ledItems[indexPath.item]
        
        // 检查是否为爱心流星雨效果
        if item.isLoveRain {
            AppDelegate.orientationLock = .landscape
            let loveRainVC = LoveRainViewController()
            loveRainVC.modalPresentationStyle = .fullScreen
            present(loveRainVC, animated: true)
            return
        }
        
        // 检查是否为翻页时钟效果
        if item.isFlipClock {
            // Set landscape first, then present a tick later to avoid a brief portrait flash.
            AppDelegate.orientationLock = .landscape
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                let clockVC = FlipClockViewController()
                clockVC.modalPresentationStyle = .fullScreen
                self?.present(clockVC, animated: true)
            }
            return
        }

        if item.isDigitalClock {
            // Set landscape first, then present a tick later to avoid a brief portrait flash.
            AppDelegate.orientationLock = .landscape
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                let clockVC = DigitalClockViewController()
                clockVC.modalPresentationStyle = .fullScreen
                self?.present(clockVC, animated: true)
            }
            return
        }

        if item.isStopwatch {
            // Set landscape first, then present a tick later to avoid a brief portrait flash.
            AppDelegate.orientationLock = .landscape
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                let swVC = StopwatchViewController()
                swVC.modalPresentationStyle = .fullScreen
                self?.present(swVC, animated: true)
            }
            return
        }

        if item.isCountdown {
            AppDelegate.orientationLock = .landscape
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                let cdVC = CountdownViewController()
                cdVC.modalPresentationStyle = .fullScreen
                self?.present(cdVC, animated: true)
            }
            return
        }
        
        // 检查是否为烟花绽放效果（第二种）
        if item.isFireworksBloom {
            let fireworksVC = FireworksBloomViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
            return
        }
        
        // 检查是否为烟花效果（第一种）
        if item.isFireworks {
            let fireworksVC = FireworksViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
            return
        }
        
        // 在 present 之前就设置为横屏
        AppDelegate.orientationLock = .landscape
        
        let displayVC = LEDFullScreenViewController(ledItem: item)
        displayVC.modalPresentationStyle = .fullScreen
        present(displayVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = ledItems[indexPath.item]
        
        // 烟花卡片、时钟、秒表/倒计时和爱心流星雨不显示编辑/删除菜单
        if item.isFireworks || item.isFireworksBloom || item.isFlipClock || item.isDigitalClock || item.isStopwatch || item.isCountdown || item.isLoveRain {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "编辑", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.editLED(at: indexPath)
            }
            
            let deleteAction = UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteLED(at: indexPath)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
    
    private func editLED(at indexPath: IndexPath) {
        let item = ledItems[indexPath.item]
        let createVC = LEDCreateViewController(editingItem: item)
        createVC.onSave = { [weak self] in
            self?.loadData()
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func deleteLED(at indexPath: IndexPath) {
        ledItems.remove(at: indexPath.item)
        LEDDataManager.shared.saveItems(ledItems)
        collectionView.deleteItems(at: [indexPath])
    }
}

// MARK: - LED缩略图Cell
class LEDCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let textLabel = UILabel()
    private let clockTitleLabel = UILabel() // 翻页时钟标题标签
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 清理烟花静态粒子，但保留textLabel和clockTitleLabel
        containerView.subviews.forEach { subview in
            if subview != textLabel && subview != clockTitleLabel {
                subview.removeFromSuperview()
            }
        }
        // 隐藏时钟标题
        clockTitleLabel.isHidden = true
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1.5
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor // 40%透明度
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.5
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        // 设置时钟标题标签
        clockTitleLabel.text = "翻页时钟"
        clockTitleLabel.textColor = .white
        clockTitleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        clockTitleLabel.textAlignment = .center
        clockTitleLabel.isHidden = true // 默认隐藏
        clockTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(clockTitleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            textLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // 时钟标题约束
            clockTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            clockTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            clockTitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            clockTitleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with item: LEDItem) {
        containerView.backgroundColor = UIColor(hex: item.backgroundColor)
        textLabel.attributedText = LEDFontRenderer.attributedText(
            item.text,
            fontName: item.fontName,
            size: 24,
            color: UIColor(hex: item.textColor),
            alignment: .center
        )
        
        // 清理旧的效果，但保留textLabel和clockTitleLabel
        containerView.subviews.forEach { subview in
            if subview != textLabel && subview != clockTitleLabel {
                subview.removeFromSuperview()
            }
        }
        
        // 重置时钟标题显示状态
        clockTitleLabel.isHidden = true
        
        // 如果是爱心流星雨卡片 - 显示静态爱心图案
        if item.isLoveRain {
            setupStaticLoveRain()
        }
        // 如果是翻页时钟卡片 - 显示静态时钟预览
        else if item.isFlipClock {
            setupStaticFlipClock()
        }
        else if item.isDigitalClock {
            setupStaticDigitalClock()
        }
        else if item.isStopwatch {
            setupStaticStopwatch()
        }
        else if item.isCountdown {
            setupStaticCountdown()
        }
        // 如果是烟花绽放卡片（第二种）- 显示静态礼花炸开效果
        else if item.isFireworksBloom {
            setupStaticBloomFirework()
        }
        // 如果是烟花卡片（第一种）- 显示静态向上发射效果
        else if item.isFireworks {
            setupStaticLaunchFirework()
        } else {
            // 普通LED的霓虹效果
            textLabel.layer.shadowColor = UIColor(hex: item.textColor).cgColor
            textLabel.layer.shadowRadius = 10 * item.glowIntensity
            textLabel.layer.shadowOpacity = Float(item.glowIntensity)
            textLabel.layer.shadowOffset = .zero
        }
    }
    
    // 爱心流星雨：静态预览效果
    private func setupStaticLoveRain() {
        // 隐藏文字标签
        textLabel.alpha = 0
        
        let centerX = containerView.bounds.width / 2
        let centerY = containerView.bounds.height / 2
        
        // 创建心形路径
        let heartSize: CGFloat = 30
        let heartPath = UIBezierPath()
        
        heartPath.move(to: CGPoint(x: centerX, y: centerY + heartSize * 0.4))
        
        heartPath.addCurve(
            to: CGPoint(x: centerX - heartSize * 0.5, y: centerY - heartSize * 0.3),
            controlPoint1: CGPoint(x: centerX - heartSize * 0.5, y: centerY + heartSize * 0.1),
            controlPoint2: CGPoint(x: centerX - heartSize * 0.5, y: centerY - heartSize * 0.1)
        )
        
        heartPath.addArc(
            withCenter: CGPoint(x: centerX - heartSize * 0.25, y: centerY - heartSize * 0.3),
            radius: heartSize * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        heartPath.addArc(
            withCenter: CGPoint(x: centerX + heartSize * 0.25, y: centerY - heartSize * 0.3),
            radius: heartSize * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        heartPath.addCurve(
            to: CGPoint(x: centerX, y: centerY + heartSize * 0.4),
            controlPoint1: CGPoint(x: centerX + heartSize * 0.5, y: centerY - heartSize * 0.1),
            controlPoint2: CGPoint(x: centerX + heartSize * 0.5, y: centerY + heartSize * 0.1)
        )
        
        heartPath.close()
        
        // 心形轮廓
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = heartPath.cgPath
        shapeLayer.strokeColor = UIColor.systemPink.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 2
        containerView.layer.addSublayer(shapeLayer)
        
        // 添加"爱"字
        let loveLabel = UILabel()
        loveLabel.text = "爱"
        loveLabel.textColor = .systemPink
        loveLabel.font = .systemFont(ofSize: 20, weight: .bold)
        loveLabel.textAlignment = .center
        loveLabel.frame = CGRect(x: centerX - 15, y: centerY - 15, width: 30, height: 30)
        containerView.addSubview(loveLabel)
        
        // 添加周围的小爱心
        let heartCount = 12
        let radius: CGFloat = 50
        for i in 0..<heartCount {
            let angle = (CGFloat(i) / CGFloat(heartCount)) * .pi * 2
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            
            let miniHeart = UILabel()
            miniHeart.text = "💖"
            miniHeart.font = .systemFont(ofSize: 8)
            miniHeart.frame = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
            containerView.addSubview(miniHeart)
        }
    }
    
    // 翻页时钟：静态预览效果（不显示文字）
    private func setupStaticFlipClock() {
        // 隐藏文字标签
        textLabel.alpha = 0
        textLabel.text = "" // 清空文字
        
        // 显示时钟标题
        clockTitleLabel.isHidden = false
        
        // 获取当前时间
        let now = Date()
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        let minuteTens = minute / 10
        let minuteOnes = minute % 10
        let secondTens = second / 10
        let secondOnes = second % 10
        
        let centerX = containerView.bounds.width / 2
        let centerY = containerView.bounds.height / 2 - 10 // 向上移动一点，为底部文字留空间
        
        let digitWidth: CGFloat = 28
        let digitHeight: CGFloat = 42 // 增加高度
        let spacing: CGFloat = 4
        let colonWidth: CGFloat = 8
        
        let totalWidth = digitWidth * 4 + spacing * 3 + colonWidth
        let startX = centerX - totalWidth / 2
        
        // 创建4个翻页数字（单层）
        createSimpleFlipDigit(digit: minuteTens, x: startX, y: centerY - digitHeight / 2, width: digitWidth, height: digitHeight)
        createSimpleFlipDigit(digit: minuteOnes, x: startX + digitWidth + spacing, y: centerY - digitHeight / 2, width: digitWidth, height: digitHeight)
        
        // 冒号
        let colonLabel = UILabel()
        colonLabel.text = ":"
        colonLabel.textColor = .white
        colonLabel.font = .systemFont(ofSize: 20, weight: .bold)
        colonLabel.textAlignment = .center
        colonLabel.frame = CGRect(x: startX + digitWidth * 2 + spacing * 2, y: centerY - 15, width: colonWidth, height: 30)
        containerView.addSubview(colonLabel)
        
        createSimpleFlipDigit(digit: secondTens, x: startX + digitWidth * 2 + spacing * 2 + colonWidth, y: centerY - digitHeight / 2, width: digitWidth, height: digitHeight)
        createSimpleFlipDigit(digit: secondOnes, x: startX + digitWidth * 3 + spacing * 3 + colonWidth, y: centerY - digitHeight / 2, width: digitWidth, height: digitHeight)
        
        print("🕐 时钟数字创建完成，容器尺寸: \(containerView.bounds)")
    }
    
    // 创建简单的单层翻页数字
    private func createSimpleFlipDigit(digit: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let digitView = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        digitView.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        digitView.layer.cornerRadius = 4
        digitView.clipsToBounds = true
        containerView.addSubview(digitView)
        
        let digitLabel = UILabel()
        digitLabel.text = "\(digit)"
        digitLabel.textColor = .white
        digitLabel.font = .systemFont(ofSize: 28, weight: .bold)
        digitLabel.textAlignment = .center
        digitLabel.frame = CGRect(x: 0, y: 0, width: width, height: height)
        digitView.addSubview(digitLabel)
    }

    private func setupStaticDigitalClock() {
        textLabel.alpha = 0
        textLabel.text = ""

        clockTitleLabel.isHidden = false
        clockTitleLabel.text = "Digital Clock"

        let clock = DSEGClockView(mode: .staticPreview)
        clock.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(clock)

        NSLayoutConstraint.activate([
            clock.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            clock.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            clock.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            clock.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28)
        ])

        clock.setTimeString("12:20:35")
    }

    private func setupStaticStopwatch() {
        textLabel.alpha = 0
        textLabel.text = ""

        clockTitleLabel.isHidden = false
        clockTitleLabel.text = "Stopwatch"

        let sw = DSEGClockView(mode: .staticPreview)
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.plateText = "88:88.88"
        sw.digitColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0)
        containerView.addSubview(sw)

        NSLayoutConstraint.activate([
            sw.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            sw.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            sw.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            sw.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28)
        ])

        sw.setTimeString("00:12.34")
    }

    private func setupStaticCountdown() {
        textLabel.alpha = 0
        textLabel.text = ""

        clockTitleLabel.isHidden = false
        clockTitleLabel.text = "Countdown"

        let cover = CountdownCoverView()
        cover.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cover)

        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            cover.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            cover.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            cover.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28)
        ])
    }
    
    // 第二种烟花：静态礼花炸开效果
    private func setupStaticBloomFirework() {
        // 创建静态的礼花炸开图案
        let colors: [UIColor] = [
            .systemPink, .systemPurple, .magenta,
            .systemRed, .systemOrange, .white
        ]
        
        let centerX = containerView.bounds.width / 2
        let centerY = containerView.bounds.height / 2
        let radius: CGFloat = 40
        
        // 创建360度均匀分布的粒子
        let particleCount = 24
        for i in 0..<particleCount {
            let angle = (CGFloat(i) / CGFloat(particleCount)) * .pi * 2
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            
            let particle = createStaticParticle(color: colors[i % colors.count])
            particle.center = CGPoint(x: x, y: y)
            containerView.addSubview(particle)
        }
        
        // 文字发光效果
        textLabel.layer.shadowColor = UIColor.systemPink.cgColor
        textLabel.layer.shadowRadius = 8
        textLabel.layer.shadowOpacity = 0.8
        textLabel.layer.shadowOffset = .zero
    }
    
    // 第一种烟花：静态向上发射效果
    private func setupStaticLaunchFirework() {
        // 创建静态的向上发射轨迹
        let colors: [UIColor] = [
            .systemYellow, .systemOrange, .systemRed
        ]
        
        let centerX = containerView.bounds.width / 2
        let startY = containerView.bounds.height - 10
        
        // 创建向上的轨迹粒子
        for i in 0..<15 {
            let y = startY - CGFloat(i) * 6
            let xOffset = CGFloat.random(in: -8...8)
            let x = centerX + xOffset
            
            let particle = createStaticParticle(color: colors[i % colors.count])
            particle.center = CGPoint(x: x, y: y)
            particle.alpha = 1.0 - (CGFloat(i) / 15.0) * 0.5
            containerView.addSubview(particle)
        }
        
        // 顶部小爆炸
        let topY = startY - 90
        for i in 0..<8 {
            let angle = (CGFloat(i) / 8.0) * .pi * 2
            let radius: CGFloat = 15
            let x = centerX + cos(angle) * radius
            let y = topY + sin(angle) * radius
            
            let particle = createStaticParticle(color: colors[i % colors.count])
            particle.center = CGPoint(x: x, y: y)
            particle.alpha = 0.8
            containerView.addSubview(particle)
        }
        
        // 文字发光效果
        textLabel.layer.shadowColor = UIColor.systemYellow.cgColor
        textLabel.layer.shadowRadius = 8
        textLabel.layer.shadowOpacity = 0.8
        textLabel.layer.shadowOffset = .zero
    }
    
    // 创建静态粒子视图
    private func createStaticParticle(color: UIColor) -> UIView {
        let size: CGFloat = 4
        let particle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        particle.backgroundColor = color
        particle.layer.cornerRadius = size / 2
        
        // 添加发光效果
        particle.layer.shadowColor = color.cgColor
        particle.layer.shadowRadius = 3
        particle.layer.shadowOpacity = 0.8
        particle.layer.shadowOffset = .zero
        
        return particle
    }
    
    private func createMiniParticleImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 6, height: 6)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fillEllipse(in: rect)
            context.cgContext.setShadow(offset: .zero, blur: 2, color: color.cgColor)
            context.cgContext.fillEllipse(in: rect)
        }
    }
}
