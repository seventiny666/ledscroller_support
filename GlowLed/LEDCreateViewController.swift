import UIKit

// LED创建/编辑页面
class LEDCreateViewController: UIViewController {
    
    var onSave: (() -> Void)?
    private var editingItem: LEDItem?
    private var isTemplateEdit: Bool = false // 是否为模版编辑模式
    private var currentItem: LEDItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let previewContainer = UIView()
    private let previewLabel = UILabel()
    private var textField = UITextField()
    
    // Tab切换
    private let tabSegment = UISegmentedControl(items: ["font".localized, "background".localized, "animation".localized])
    private var fontTabView: UIView!
    private var backgroundTabView: UIView!
    private var animationTabView: UIView!
    
    // 字体Tab控件
    private let fontSizeSlider = UISlider()
    private let fontSizeLabel = UILabel()
    private let fontSegment = UISegmentedControl(items: ["pingfang".localized, "heiti".localized, "songti".localized, "kaiti".localized])
    private let glowSlider = UISlider()
    private let glowLabel = UILabel()
    
    // 动画Tab控件
    private let scrollToggle = UISwitch() // 滚动开关
    private var scrollToggleLabel: UILabel! // 滚动开关标签
    private var scrollTypeLabel: UILabel! // 滚动方式标签
    private let scrollTypeSegment = UISegmentedControl(items: ["scrollLeft".localized, "scrollRight".localized, "scrollUp".localized, "scrollDown".localized])
    private let speedSlider = UISlider()
    private let blinkToggle = UISwitch() // 闪烁开关
    private var blinkToggleLabel: UILabel! // 闪烁开关标签
    private let blinkSegment = UISegmentedControl(items: ["slow".localized, "fast".localized, "superFast".localized])
    private var blinkSectionLabel: UILabel!  // 闪烁速度标签
    
    // 动态约束，用于控制闪烁区域的位置
    private var blinkToggleLabelTopConstraint: NSLayoutConstraint!
    private var scrollTypeHeightConstraint: CGFloat = 0 // 滚动方式区域的总高度
    
    private var selectedTextColorIndex = 0
    private var selectedBgColorIndex = 0
    private var selectedGradientIndex = -1 // -1表示未选择渐变
    private var selectedBackgroundImage: String? = nil // 保存选中的背景图片名称
    private var previewBackgroundImageView: UIImageView! // 预览区域的背景图片视图
    
    // 文字颜色：合并为1行，可滑动（14个颜色）
    private let textColors = [
        "#FF00FF", "#00FFFF", "#FFD700", "#FF1493", "#00FF00", "#FF4500", "#FFFFFF",
        "#FF69B4", "#8B00FF", "#00CED1", "#FFB6C1", "#32CD32", "#FF8C00", "#F0E68C"
    ]
    
    // 渐变颜色：合并为1行，可滑动（14个渐变）
    private let gradientColors = [
        // 经典渐变
        ["#FF0080", "#FF8C00"], ["#00F5FF", "#0080FF"], ["#FFD700", "#FF1493"], 
        ["#00FF00", "#00CED1"], ["#FF00FF", "#8B00FF"], ["#FF4500", "#FFD700"], 
        ["#FF1493", "#00FFFF"],
        // 霓虹渐变
        ["#FF006E", "#8338EC"], ["#06FFA5", "#FFFB00"], ["#F72585", "#7209B7"], 
        ["#4CC9F0", "#4361EE"], ["#FF006E", "#FFBE0B"], ["#06FFA5", "#3A86FF"], 
        ["#F72585", "#4CC9F0"]
    ]
    
    private let bgColors = [
        "#000000", "#1a1a2e", "#0f3460", "#16213e", "#1f1f1f", "#2d2d2d",
        "#0a0a0a", "#1a1a1a", "#2a2a2a", "#0d1117", "#161b22", "#21262d"
    ]
    private let bgTextures = ["stars", "gradient", "dots", "waves", "grid", "noise"] // 纹理名称
    
    // 背景渐变颜色：合并为1行，可滑动（12个渐变）
    private let bgGradientColors = [
        // 深色渐变背景
        ["#1a1a2e", "#16213e"], ["#0f3460", "#16213e"], ["#1f1f1f", "#2d2d2d"], 
        ["#000000", "#1a1a2e"], ["#16213e", "#0f3460"], ["#2d2d2d", "#1a1a2e"],
        // 彩色渐变背景
        ["#1a0033", "#330066"], ["#001a33", "#003366"], ["#331a00", "#663300"], 
        ["#1a3300", "#336600"], ["#33001a", "#660033"], ["#00331a", "#006633"]
    ]
    
    init(editingItem: LEDItem? = nil, isTemplateEdit: Bool = false) {
        self.editingItem = editingItem
        self.isTemplateEdit = isTemplateEdit
        self.currentItem = editingItem ?? LEDItem(text: "") // 默认为空字符串
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentData()
        
        // 监听键盘通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保编辑页面是竖屏
        AppDelegate.orientationLock = .portrait
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 调试信息
        print("📱 View appeared")
        print("   TextField frame: \(textField.frame)")
        print("   TextField superview: \(textField.superview?.description ?? "nil")")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    private func setupUI() {
        title = editingItem == nil ? "createTitle".localized : "editTitle".localized
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.95)
        
        // 导航栏按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "cancel".localized, style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "save".localized, style: .done, target: self, action: #selector(saveTapped))
        navigationItem.leftBarButtonItem?.tintColor = .systemGray
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        
        // 预览容器
        previewContainer.backgroundColor = UIColor(hex: currentItem.backgroundColor)
        previewContainer.layer.cornerRadius = 15
        previewContainer.layer.borderWidth = 3.0 // 加粗边框
        previewContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        previewContainer.clipsToBounds = true
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)
        
        // 预览背景图片视图
        previewBackgroundImageView = UIImageView()
        previewBackgroundImageView.contentMode = .scaleAspectFill
        previewBackgroundImageView.clipsToBounds = true
        previewBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(previewBackgroundImageView)
        
        // 预览文字
        previewLabel.text = currentItem.text.isEmpty ? "previewText".localized : currentItem.text
        previewLabel.font = .boldSystemFont(ofSize: 32)
        previewLabel.textColor = UIColor(hex: currentItem.textColor)
        previewLabel.textAlignment = .center
        previewLabel.numberOfLines = 0
        previewLabel.adjustsFontSizeToFitWidth = true
        previewLabel.minimumScaleFactor = 0.5
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(previewLabel)
        
        // 霓虹效果
        previewLabel.layer.shadowColor = UIColor(hex: currentItem.textColor).cgColor
        previewLabel.layer.shadowRadius = 15 * currentItem.glowIntensity
        previewLabel.layer.shadowOpacity = Float(currentItem.glowIntensity)
        previewLabel.layer.shadowOffset = .zero
        
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // 16:7 比例，基于宽度计算高度
            previewContainer.heightAnchor.constraint(equalTo: previewContainer.widthAnchor, multiplier: 7.0/16.0),
            
            previewBackgroundImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewBackgroundImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewBackgroundImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewBackgroundImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            previewLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 15),
            previewLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -15),
            // 限制预览文字的最大高度为预览容器的90%
            previewLabel.heightAnchor.constraint(lessThanOrEqualTo: previewContainer.heightAnchor, multiplier: 0.9)
        ])
        
        // 滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // 为contentView设置一个足够大的最小高度，确保内容超出scrollView时可以滚动
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1200) // 增加高度以容纳所有内容
        ])
        
        var yOffset: CGFloat = 20
        
        // 文字输入
        addSectionLabel("textContent".localized, yOffset: &yOffset)
        
        // 创建一个简单的文字输入框
        textField = createSimpleTextField()
        contentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
        yOffset += 70
        
        // Tab切换控件 - 胶囊形状
        tabSegment.selectedSegmentIndex = 0
        tabSegment.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        tabSegment.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 14)], for: .selected)
        tabSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        tabSegment.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        tabSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabSegment)
        
        NSLayoutConstraint.activate([
            tabSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            tabSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabSegment.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 设置胶囊形状（高度的一半作为圆角）
        DispatchQueue.main.async {
            self.tabSegment.layer.cornerRadius = 20 // 40/2 = 20，完美胶囊形状
            self.tabSegment.layer.masksToBounds = true
        }
        
        yOffset += 55
        
        // 创建三个Tab视图
        setupFontTab(yOffset: yOffset)
        setupBackgroundTab(yOffset: yOffset)
        setupAnimationTab(yOffset: yOffset)
        
        // 默认显示字体Tab
        showTab(index: 0)
        
        // 设置 contentView 的底部约束（根据最高的Tab视图）
        let maxHeight: CGFloat = 1000 // 增加高度确保内容不被遮挡
        NSLayoutConstraint.activate([
            contentView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset + maxHeight)
        ])
    }
    
    private func addSectionLabel(_ text: String, yOffset: inout CGFloat) {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0) // 柔和的蓝色
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        yOffset += 30
    }
    
    // MARK: - Tab视图设置
    
    private func setupFontTab(yOffset: CGFloat) {
        fontTabView = UIView()
        fontTabView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fontTabView)
        
        NSLayoutConstraint.activate([
            fontTabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            fontTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            fontTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            fontTabView.heightAnchor.constraint(greaterThanOrEqualToConstant: 600)
        ])
        
        var tabYOffset: CGFloat = 0
        
        // 字体大小
        fontSizeLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        fontSizeLabel.font = .boldSystemFont(ofSize: 16)
        addSliderSectionToView(fontTabView, label: fontSizeLabel, slider: fontSizeSlider, yOffset: &tabYOffset)
        fontSizeSlider.minimumValue = 30
        let maxFontSize = UIScreen.main.bounds.height * 0.9
        fontSizeSlider.maximumValue = Float(maxFontSize)
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        
        // 字体选择
        addSectionLabelToView(fontTabView, text: "fontSelection".localized, yOffset: &tabYOffset)
        fontSegment.selectedSegmentTintColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        fontSegment.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 13)], for: .selected)
        fontSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        fontSegment.addTarget(self, action: #selector(fontChanged), for: .valueChanged)
        fontSegment.translatesAutoresizingMaskIntoConstraints = false
        fontTabView.addSubview(fontSegment)
        NSLayoutConstraint.activate([
            fontSegment.topAnchor.constraint(equalTo: fontTabView.topAnchor, constant: tabYOffset),
            fontSegment.leadingAnchor.constraint(equalTo: fontTabView.leadingAnchor, constant: 20),
            fontSegment.trailingAnchor.constraint(equalTo: fontTabView.trailingAnchor, constant: -20)
        ])
        tabYOffset += 50
        
        // 文字颜色（1行，可滑动）
        addSectionLabelToView(fontTabView, text: "textColor".localized, yOffset: &tabYOffset)
        
        let textColorScrollView = UIScrollView()
        textColorScrollView.showsHorizontalScrollIndicator = false
        textColorScrollView.translatesAutoresizingMaskIntoConstraints = false
        fontTabView.addSubview(textColorScrollView)
        
        let textColorStack = createColorStack(colors: textColors, tag: 100)
        textColorScrollView.addSubview(textColorStack)
        
        NSLayoutConstraint.activate([
            textColorScrollView.topAnchor.constraint(equalTo: fontTabView.topAnchor, constant: tabYOffset),
            textColorScrollView.leadingAnchor.constraint(equalTo: fontTabView.leadingAnchor, constant: 20),
            textColorScrollView.trailingAnchor.constraint(equalTo: fontTabView.trailingAnchor, constant: -20),
            textColorScrollView.heightAnchor.constraint(equalToConstant: 45),
            
            textColorStack.topAnchor.constraint(equalTo: textColorScrollView.topAnchor),
            textColorStack.leadingAnchor.constraint(equalTo: textColorScrollView.leadingAnchor),
            textColorStack.trailingAnchor.constraint(equalTo: textColorScrollView.trailingAnchor),
            textColorStack.heightAnchor.constraint(equalToConstant: 45)
        ])
        tabYOffset += 65
        
        // 渐变颜色（1行，可滑动）
        addSectionLabelToView(fontTabView, text: "gradientColor".localized, yOffset: &tabYOffset)
        
        let gradientScrollView = UIScrollView()
        gradientScrollView.showsHorizontalScrollIndicator = false
        gradientScrollView.translatesAutoresizingMaskIntoConstraints = false
        fontTabView.addSubview(gradientScrollView)
        
        let gradientStack = createGradientStack(gradients: gradientColors, tag: 400)
        gradientScrollView.addSubview(gradientStack)
        
        NSLayoutConstraint.activate([
            gradientScrollView.topAnchor.constraint(equalTo: fontTabView.topAnchor, constant: tabYOffset),
            gradientScrollView.leadingAnchor.constraint(equalTo: fontTabView.leadingAnchor, constant: 20),
            gradientScrollView.trailingAnchor.constraint(equalTo: fontTabView.trailingAnchor, constant: -20),
            gradientScrollView.heightAnchor.constraint(equalToConstant: 45),
            
            gradientStack.topAnchor.constraint(equalTo: gradientScrollView.topAnchor),
            gradientStack.leadingAnchor.constraint(equalTo: gradientScrollView.leadingAnchor),
            gradientStack.trailingAnchor.constraint(equalTo: gradientScrollView.trailingAnchor),
            gradientStack.heightAnchor.constraint(equalToConstant: 45)
        ])
        tabYOffset += 65
        
        // 霓虹强度 (0-10)
        glowLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        glowLabel.font = .boldSystemFont(ofSize: 16)
        addSliderSectionToView(fontTabView, label: glowLabel, slider: glowSlider, yOffset: &tabYOffset)
        glowSlider.minimumValue = 0
        glowSlider.maximumValue = 10 // 改为最大10
        glowSlider.addTarget(self, action: #selector(glowChanged), for: .valueChanged)
    }
    
    private func setupBackgroundTab(yOffset: CGFloat) {
        backgroundTabView = UIView()
        backgroundTabView.translatesAutoresizingMaskIntoConstraints = false
        backgroundTabView.isHidden = true
        contentView.addSubview(backgroundTabView)
        
        NSLayoutConstraint.activate([
            backgroundTabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            backgroundTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundTabView.heightAnchor.constraint(greaterThanOrEqualToConstant: 600)
        ])
        
        var tabYOffset: CGFloat = 0
        
        // 背景颜色（1行，可滑动）
        addSectionLabelToView(backgroundTabView, text: "backgroundColor".localized, yOffset: &tabYOffset)
        
        let bgColorScrollView = UIScrollView()
        bgColorScrollView.showsHorizontalScrollIndicator = false
        bgColorScrollView.translatesAutoresizingMaskIntoConstraints = false
        backgroundTabView.addSubview(bgColorScrollView)
        
        let bgColorStack = createBgColorStack(colors: bgColors, tag: 200)
        bgColorScrollView.addSubview(bgColorStack)
        
        NSLayoutConstraint.activate([
            bgColorScrollView.topAnchor.constraint(equalTo: backgroundTabView.topAnchor, constant: tabYOffset),
            bgColorScrollView.leadingAnchor.constraint(equalTo: backgroundTabView.leadingAnchor, constant: 20),
            bgColorScrollView.trailingAnchor.constraint(equalTo: backgroundTabView.trailingAnchor, constant: -20),
            bgColorScrollView.heightAnchor.constraint(equalToConstant: 36),
            
            bgColorStack.topAnchor.constraint(equalTo: bgColorScrollView.topAnchor),
            bgColorStack.leadingAnchor.constraint(equalTo: bgColorScrollView.leadingAnchor),
            bgColorStack.trailingAnchor.constraint(equalTo: bgColorScrollView.trailingAnchor),
            bgColorStack.heightAnchor.constraint(equalToConstant: 36)
        ])
        tabYOffset += 56
        
        // 渐变背景色（1行，可滑动）
        addSectionLabelToView(backgroundTabView, text: "gradientBackground".localized, yOffset: &tabYOffset)
        
        let bgGradientScrollView = UIScrollView()
        bgGradientScrollView.showsHorizontalScrollIndicator = false
        bgGradientScrollView.translatesAutoresizingMaskIntoConstraints = false
        backgroundTabView.addSubview(bgGradientScrollView)
        
        let bgGradientStack = createBgGradientStack(gradients: bgGradientColors, tag: 400)
        bgGradientScrollView.addSubview(bgGradientStack)
        
        NSLayoutConstraint.activate([
            bgGradientScrollView.topAnchor.constraint(equalTo: backgroundTabView.topAnchor, constant: tabYOffset),
            bgGradientScrollView.leadingAnchor.constraint(equalTo: backgroundTabView.leadingAnchor, constant: 20),
            bgGradientScrollView.trailingAnchor.constraint(equalTo: backgroundTabView.trailingAnchor, constant: -20),
            bgGradientScrollView.heightAnchor.constraint(equalToConstant: 36),
            
            bgGradientStack.topAnchor.constraint(equalTo: bgGradientScrollView.topAnchor),
            bgGradientStack.leadingAnchor.constraint(equalTo: bgGradientScrollView.leadingAnchor),
            bgGradientStack.trailingAnchor.constraint(equalTo: bgGradientScrollView.trailingAnchor),
            bgGradientStack.heightAnchor.constraint(equalToConstant: 36)
        ])
        tabYOffset += 56
        
        // 霓虹灯看板
        addSectionLabelToView(backgroundTabView, text: "霓虹灯看板", yOffset: &tabYOffset)
        let neonStack = createTemplateStack(category: "neon", count: 4, tag: 500)
        backgroundTabView.addSubview(neonStack)
        NSLayoutConstraint.activate([
            neonStack.topAnchor.constraint(equalTo: backgroundTabView.topAnchor, constant: tabYOffset),
            neonStack.leadingAnchor.constraint(equalTo: backgroundTabView.leadingAnchor, constant: 30),
            neonStack.trailingAnchor.constraint(equalTo: backgroundTabView.trailingAnchor, constant: -30),
            neonStack.heightAnchor.constraint(equalToConstant: 60)
        ])
        tabYOffset += 80
        
        // 偶像应援
        addSectionLabelToView(backgroundTabView, text: "偶像应援", yOffset: &tabYOffset)
        let idolStack = createTemplateStack(category: "idol", count: 4, tag: 510)
        backgroundTabView.addSubview(idolStack)
        NSLayoutConstraint.activate([
            idolStack.topAnchor.constraint(equalTo: backgroundTabView.topAnchor, constant: tabYOffset),
            idolStack.leadingAnchor.constraint(equalTo: backgroundTabView.leadingAnchor, constant: 30),
            idolStack.trailingAnchor.constraint(equalTo: backgroundTabView.trailingAnchor, constant: -30),
            idolStack.heightAnchor.constraint(equalToConstant: 60)
        ])
        tabYOffset += 80
        
        // LED横幅
        addSectionLabelToView(backgroundTabView, text: "LED横幅", yOffset: &tabYOffset)
        let ledStack = createTemplateStack(category: "led", count: 4, tag: 520)
        backgroundTabView.addSubview(ledStack)
        NSLayoutConstraint.activate([
            ledStack.topAnchor.constraint(equalTo: backgroundTabView.topAnchor, constant: tabYOffset),
            ledStack.leadingAnchor.constraint(equalTo: backgroundTabView.leadingAnchor, constant: 30),
            ledStack.trailingAnchor.constraint(equalTo: backgroundTabView.trailingAnchor, constant: -30),
            ledStack.heightAnchor.constraint(equalToConstant: 60)
        ])
        tabYOffset += 80
    }
    
    private func setupAnimationTab(yOffset: CGFloat) {
        animationTabView = UIView()
        animationTabView.translatesAutoresizingMaskIntoConstraints = false
        animationTabView.isHidden = true
        contentView.addSubview(animationTabView)
        
        NSLayoutConstraint.activate([
            animationTabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            animationTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            animationTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            animationTabView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500)
        ])
        
        var tabYOffset: CGFloat = 0
        
        // 滚动Toggle开关
        scrollToggleLabel = UILabel()
        scrollToggleLabel.text = "scrollToggle".localized
        scrollToggleLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        scrollToggleLabel.font = .boldSystemFont(ofSize: 16)
        scrollToggleLabel.translatesAutoresizingMaskIntoConstraints = false
        animationTabView.addSubview(scrollToggleLabel)
        
        scrollToggle.isOn = false // 默认关闭
        scrollToggle.onTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        scrollToggle.addTarget(self, action: #selector(scrollToggleChanged), for: .valueChanged)
        scrollToggle.translatesAutoresizingMaskIntoConstraints = false
        animationTabView.addSubview(scrollToggle)
        
        NSLayoutConstraint.activate([
            scrollToggleLabel.topAnchor.constraint(equalTo: animationTabView.topAnchor, constant: tabYOffset),
            scrollToggleLabel.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20),
            
            scrollToggle.centerYAnchor.constraint(equalTo: scrollToggleLabel.centerYAnchor),
            scrollToggle.trailingAnchor.constraint(equalTo: animationTabView.trailingAnchor, constant: -20)
        ])
        tabYOffset += 50
        
        // 滚动方式标签（默认隐藏）
        scrollTypeLabel = UILabel()
        scrollTypeLabel.text = "scrollType".localized
        scrollTypeLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        scrollTypeLabel.font = .boldSystemFont(ofSize: 16)
        scrollTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollTypeLabel.isHidden = true
        animationTabView.addSubview(scrollTypeLabel)
        
        NSLayoutConstraint.activate([
            scrollTypeLabel.topAnchor.constraint(equalTo: animationTabView.topAnchor, constant: tabYOffset),
            scrollTypeLabel.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20)
        ])
        tabYOffset += 30
        
        // 滚动方式选择（默认隐藏）
        scrollTypeSegment.selectedSegmentIndex = 0 // 默认左滚
        scrollTypeSegment.selectedSegmentTintColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        scrollTypeSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        scrollTypeSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        scrollTypeSegment.addTarget(self, action: #selector(scrollTypeChanged), for: .valueChanged)
        scrollTypeSegment.translatesAutoresizingMaskIntoConstraints = false
        scrollTypeSegment.isHidden = true
        animationTabView.addSubview(scrollTypeSegment)
        NSLayoutConstraint.activate([
            scrollTypeSegment.topAnchor.constraint(equalTo: animationTabView.topAnchor, constant: tabYOffset),
            scrollTypeSegment.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20),
            scrollTypeSegment.trailingAnchor.constraint(equalTo: animationTabView.trailingAnchor, constant: -20)
        ])
        tabYOffset += 60 // 增加间距
        
        // 播放速度滑块（默认隐藏，无标签）
        speedSlider.value = 1.5 // 默认速度
        speedSlider.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        speedSlider.minimumValue = 0.5
        speedSlider.maximumValue = 3.0
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.isHidden = true
        animationTabView.addSubview(speedSlider)
        
        NSLayoutConstraint.activate([
            speedSlider.topAnchor.constraint(equalTo: animationTabView.topAnchor, constant: tabYOffset),
            speedSlider.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20),
            speedSlider.trailingAnchor.constraint(equalTo: animationTabView.trailingAnchor, constant: -20)
        ])
        
        // 记录滚动方式区域的总高度（标签30 + 滚动方式60 + 速度滑块30 = 120）
        scrollTypeHeightConstraint = 120
        tabYOffset += 40
        
        // 闪烁Toggle开关（使用动态约束）
        blinkToggleLabel = UILabel()
        blinkToggleLabel.text = "blinkToggle".localized
        blinkToggleLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        blinkToggleLabel.font = .boldSystemFont(ofSize: 16)
        blinkToggleLabel.translatesAutoresizingMaskIntoConstraints = false
        animationTabView.addSubview(blinkToggleLabel)
        
        blinkToggle.isOn = false // 默认关闭
        blinkToggle.onTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        blinkToggle.addTarget(self, action: #selector(blinkToggleChanged), for: .valueChanged)
        blinkToggle.translatesAutoresizingMaskIntoConstraints = false
        animationTabView.addSubview(blinkToggle)
        
        // 创建动态约束：默认紧跟在滚动toggle后面（间距20px）
        blinkToggleLabelTopConstraint = blinkToggleLabel.topAnchor.constraint(equalTo: scrollToggleLabel.bottomAnchor, constant: 20)
        
        NSLayoutConstraint.activate([
            blinkToggleLabelTopConstraint,
            blinkToggleLabel.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20),
            
            blinkToggle.centerYAnchor.constraint(equalTo: blinkToggleLabel.centerYAnchor),
            blinkToggle.trailingAnchor.constraint(equalTo: animationTabView.trailingAnchor, constant: -20)
        ])
        tabYOffset += 50
        
        // 闪烁速度标签
        blinkSectionLabel = UILabel()
        blinkSectionLabel.text = "blinkSpeed".localized
        blinkSectionLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        blinkSectionLabel.font = .boldSystemFont(ofSize: 16)
        blinkSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        blinkSectionLabel.isHidden = true
        animationTabView.addSubview(blinkSectionLabel)
        
        NSLayoutConstraint.activate([
            blinkSectionLabel.topAnchor.constraint(equalTo: blinkToggleLabel.bottomAnchor, constant: 20),
            blinkSectionLabel.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20)
        ])
        
        // 闪烁速度选择
        blinkSegment.selectedSegmentIndex = 1 // 默认"快"
        blinkSegment.selectedSegmentTintColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        blinkSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        blinkSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        blinkSegment.addTarget(self, action: #selector(blinkSpeedChanged), for: .valueChanged)
        blinkSegment.translatesAutoresizingMaskIntoConstraints = false
        blinkSegment.isHidden = true
        animationTabView.addSubview(blinkSegment)
        NSLayoutConstraint.activate([
            blinkSegment.topAnchor.constraint(equalTo: blinkSectionLabel.bottomAnchor, constant: 10),
            blinkSegment.leadingAnchor.constraint(equalTo: animationTabView.leadingAnchor, constant: 20),
            blinkSegment.trailingAnchor.constraint(equalTo: animationTabView.trailingAnchor, constant: -20)
        ])
        
        // 初始状态：根据toggle状态显示/隐藏控件
        updateAnimationControls()
    }
    
    private func addSectionLabelToView(_ view: UIView, text: String, yOffset: inout CGFloat) {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        yOffset += 30
    }
    
    private func addSliderSectionToView(_ view: UIView, label: UILabel, slider: UISlider, yOffset: inout CGFloat) {
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        slider.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        yOffset += 70
    }
    
    @objc private func tabChanged() {
        showTab(index: tabSegment.selectedSegmentIndex)
    }
    
    private func showTab(index: Int) {
        fontTabView.isHidden = (index != 0)
        backgroundTabView.isHidden = (index != 1)
        animationTabView.isHidden = (index != 2)
    }
    
    // 创建简单的文字输入框
    private func createSimpleTextField() -> UITextField {
        let field = UITextField()
        
        // 基础样式
        field.backgroundColor = UIColor(white: 0.2, alpha: 1)
        field.textColor = .white
        field.font = .systemFont(ofSize: 18)
        field.placeholder = "textPlaceholder".localized
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // 确保输入框可交互
        field.isUserInteractionEnabled = true
        field.isEnabled = true
        
        // 内边距
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        field.leftView = paddingView
        field.leftViewMode = .always
        
        // 键盘配置 - 确保支持中文输入
        field.keyboardType = .default
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        
        // 设置代理
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }
    
    private func addSliderSection(label: UILabel, slider: UISlider, yOffset: inout CGFloat) {
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        slider.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 70
    }
    
    private func createColorStack(colors: [String], tag: Int) -> UIStackView {
        let buttons = colors.enumerated().map { index, color -> UIButton in
            let btn = UIButton(type: .system)
            btn.backgroundColor = UIColor(hex: color)
            btn.layer.cornerRadius = 14 // 圆形：28/2
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    // 创建渐变颜色按钮
    private func createGradientStack(gradients: [[String]], tag: Int) -> UIStackView {
        let buttons = gradients.enumerated().map { index, colors -> UIButton in
            let btn = UIButton(type: .system)
            
            // 创建渐变层
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = colors.map { UIColor(hex: $0).cgColor }
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            gradientLayer.cornerRadius = 14
            
            // 将渐变层添加到按钮
            btn.layer.insertSublayer(gradientLayer, at: 0)
            
            btn.layer.cornerRadius = 14
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.layer.masksToBounds = true // 确保圆形裁剪
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(gradientButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
            
            // 保存渐变颜色信息到按钮
            btn.accessibilityHint = colors.joined(separator: ",")
            
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    private func createBgColorStack(colors: [String], tag: Int) -> UIStackView {
        let buttons = colors.enumerated().map { index, color -> UIButton in
            let btn = UIButton(type: .system)
            btn.backgroundColor = UIColor(hex: color)
            btn.layer.cornerRadius = 6
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            // 4:3 比例，宽度48，高度36
            btn.widthAnchor.constraint(equalToConstant: 48).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    // 创建纹理背景选择器
    private func createBgTextureStack(textures: [String], tag: Int) -> UIStackView {
        let buttons = textures.enumerated().map { index, texture -> UIButton in
            let btn = UIButton(type: .system)
            btn.backgroundColor = createTextureBackground(type: texture)
            btn.layer.cornerRadius = 6
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(textureButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            // 4:3 比例，宽度48，高度36
            btn.widthAnchor.constraint(equalToConstant: 48).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    // 创建背景渐变颜色按钮（圆角矩形样式，与背景颜色一致）
    private func createBgGradientStack(gradients: [[String]], tag: Int) -> UIStackView {
        let buttons = gradients.enumerated().map { index, colors -> UIButton in
            let btn = UIButton(type: .system)
            
            // 创建渐变层
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = colors.map { UIColor(hex: $0).cgColor }
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.frame = CGRect(x: 0, y: 0, width: 48, height: 36) // 4:3比例，与背景颜色一致
            gradientLayer.cornerRadius = 6 // 圆角矩形
            
            // 将渐变层添加到按钮
            btn.layer.insertSublayer(gradientLayer, at: 0)
            
            btn.layer.cornerRadius = 6 // 圆角矩形
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.layer.masksToBounds = true
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(bgGradientButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 48).isActive = true // 与背景颜色宽度一致
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true // 与背景颜色高度一致
            
            // 保存渐变颜色信息到按钮
            btn.accessibilityHint = colors.joined(separator: ",")
            
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .equalSpacing // 与背景颜色一致
        stack.spacing = 8 // 与背景颜色一致
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    // 创建模版背景选择器（霓虹灯看板、偶像应援、LED横幅）
    private func createTemplateStack(category: String, count: Int, tag: Int) -> UIStackView {
        let buttons = (1...count).map { index -> UIButton in
            let btn = UIButton(type: .system)
            
            // 尝试加载图片，如果没有则使用占位符
            let imageName = "\(category)_\(index)"
            if let image = UIImage(named: imageName) {
                btn.setBackgroundImage(image, for: .normal)
                btn.imageView?.contentMode = .scaleAspectFill
            } else {
                // 占位符：使用渐变色
                let placeholderColor = getPlaceholderColor(category: category, index: index)
                btn.backgroundColor = placeholderColor
                
                // 添加文字标签
                let label = UILabel()
                label.text = "\(index)"
                label.textColor = .white
                label.font = .boldSystemFont(ofSize: 16)
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                btn.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
                ])
            }
            
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.clipsToBounds = true
            btn.tag = tag + index - 1
            btn.addTarget(self, action: #selector(templateButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 为每个按钮设置16:9比例
        buttons.forEach { btn in
            btn.heightAnchor.constraint(equalTo: btn.widthAnchor, multiplier: 9.0/16.0).isActive = true
        }
        
        return stack
    }
    
    // 获取占位符颜色
    private func getPlaceholderColor(category: String, index: Int) -> UIColor {
        switch category {
        case "neon":
            let colors = [
                UIColor(red: 0xFF/255.0, green: 0x00/255.0, blue: 0xFF/255.0, alpha: 1.0),
                UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 1.0),
                UIColor(red: 0xFF/255.0, green: 0xD7/255.0, blue: 0x00/255.0, alpha: 1.0),
                UIColor(red: 0xFF/255.0, green: 0x14/255.0, blue: 0x93/255.0, alpha: 1.0)
            ]
            return colors[(index - 1) % colors.count]
        case "idol":
            let colors = [
                UIColor(red: 0xFF/255.0, green: 0x69/255.0, blue: 0xB4/255.0, alpha: 1.0),
                UIColor(red: 0xFF/255.0, green: 0x6B/255.0, blue: 0xD6/255.0, alpha: 1.0),
                UIColor(red: 0xFF/255.0, green: 0x14/255.0, blue: 0x93/255.0, alpha: 1.0),
                UIColor(red: 0xFF/255.0, green: 0x00/255.0, blue: 0xFF/255.0, alpha: 1.0)
            ]
            return colors[(index - 1) % colors.count]
        case "led":
            let colors = [
                UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0x00/255.0, alpha: 1.0),
                UIColor(red: 0x6B/255.0, green: 0xFF/255.0, blue: 0xB0/255.0, alpha: 1.0),
                UIColor(red: 0x00/255.0, green: 0xFF/255.0, blue: 0xFF/255.0, alpha: 1.0),
                UIColor(red: 0x00/255.0, green: 0xCE/255.0, blue: 0xD1/255.0, alpha: 1.0)
            ]
            return colors[(index - 1) % colors.count]
        default:
            return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
    
    // 创建纹理背景色
    private func createTextureBackground(type: String) -> UIColor {
        switch type {
        case "stars":
            return UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1) // 深蓝星空
        case "gradient":
            return UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1) // 紫色渐变
        case "dots":
            return UIColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 1) // 深蓝点阵
        case "waves":
            return UIColor(red: 0.0, green: 0.2, blue: 0.3, alpha: 1) // 青色波浪
        case "grid":
            return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1) // 灰色网格
        case "noise":
            return UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1) // 噪点背景
        default:
            return .black
        }
    }
    
    private func loadCurrentData() {
        // 只在编辑模式下加载文字，新建模式保持为空
        if editingItem != nil {
            textField.text = currentItem.text
        }
        fontSizeSlider.value = Float(currentItem.fontSize)
        glowSlider.value = Float(currentItem.glowIntensity)
        speedSlider.value = Float(currentItem.speed)
        
        fontSizeLabel.text = "字体大小: \(Int(currentItem.fontSize))"
        glowLabel.text = "霓虹强度: \(String(format: "%.1f", currentItem.glowIntensity))"
        
        // 加载背景图片
        selectedBackgroundImage = currentItem.backgroundImageName
        
        // 查找文字颜色
        if let textColorIndex = textColors.firstIndex(of: currentItem.textColor) {
            selectedTextColorIndex = textColorIndex
            updateColorButtonSelection(tag: 100, selectedIndex: textColorIndex)
        }
        
        // 查找背景颜色
        if let bgColorIndex = bgColors.firstIndex(of: currentItem.backgroundColor) {
            selectedBgColorIndex = bgColorIndex
            updateColorButtonSelection(tag: 200, selectedIndex: bgColorIndex)
        }
        
        // 加载滚动和闪烁状态
        if currentItem.scrollType == .blink {
            // 闪烁类型：滚动toggle关闭，闪烁toggle开启
            scrollToggle.isOn = false
            blinkToggle.isOn = true
            // 根据speed设置闪烁速度档位（慢: 1.5, 快: 1.0, 非常快: 0.5）
            let blinkSpeeds: [CGFloat] = [1.5, 1.0, 0.5]
            if let speedIndex = blinkSpeeds.firstIndex(where: { abs($0 - currentItem.speed) < 0.1 }) {
                blinkSegment.selectedSegmentIndex = speedIndex
            } else {
                blinkSegment.selectedSegmentIndex = 1 // 默认"快"
            }
        } else if currentItem.scrollType == .none {
            // 静止状态：两个toggle都关闭
            scrollToggle.isOn = false
            blinkToggle.isOn = false
        } else {
            // 滚动状态：滚动toggle开启，闪烁toggle关闭
            scrollToggle.isOn = true
            blinkToggle.isOn = false
            // 设置滚动类型
            let scrollTypes: [LEDItem.ScrollType] = [.scrollLeft, .scrollRight, .scrollUp, .scrollDown]
            if let scrollIndex = scrollTypes.firstIndex(of: currentItem.scrollType) {
                scrollTypeSegment.selectedSegmentIndex = scrollIndex
            }
        }
        
        // 加载字体设置
        switch currentItem.fontName {
        case "PingFangSC-Regular":
            fontSegment.selectedSegmentIndex = 0
        case "STHeitiSC-Medium":
            fontSegment.selectedSegmentIndex = 1
        case "STSongti-SC-Regular":
            fontSegment.selectedSegmentIndex = 2
        case "STKaiti":
            fontSegment.selectedSegmentIndex = 3
        default:
            fontSegment.selectedSegmentIndex = 0
        }
        
        // 更新速度控件显示状态
        updateSpeedVisibility()
        
        // 更新预览
        updatePreview()
        
        // 应用滚动动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.applyScrollAnimation()
        }
    }
    
    private func updateColorButtonSelection(tag: Int, selectedIndex: Int) {
        // 根据tag确定要检查的按钮数量
        let maxCount: Int
        if tag == 100 {
            maxCount = textColors.count // 14个文字颜色
        } else if tag == 200 {
            maxCount = bgColors.count // 12个背景颜色
        } else if tag == 400 {
            maxCount = gradientColors.count // 14个渐变
        } else {
            maxCount = 20 // 默认值
        }
        
        for i in 0..<maxCount {
            if let button = contentView.viewWithTag(tag + i) as? UIButton {
                button.layer.borderWidth = i == selectedIndex ? 3 : 2
                button.layer.borderColor = i == selectedIndex ? UIColor.white.cgColor : UIColor.white.withAlphaComponent(0.3).cgColor
            }
        }
    }
    
    @objc private func fontSizeChanged() {
        currentItem.fontSize = CGFloat(fontSizeSlider.value)
        fontSizeLabel.text = "字体大小: \(Int(currentItem.fontSize))"
        updatePreview()
    }
    
    @objc private func glowChanged() {
        currentItem.glowIntensity = CGFloat(glowSlider.value)
        glowLabel.text = "霓虹强度: \(String(format: "%.1f", currentItem.glowIntensity))"
        updatePreview()
    }
    
    @objc private func speedChanged() {
        currentItem.speed = CGFloat(speedSlider.value)
        // 更新滚动动画速度
        applyScrollAnimation()
    }
    
    @objc private func scrollTypeChanged() {
        // 更新预览
        updateCurrentItem()
        updatePreview()
        applyScrollAnimation()
    }
    
    private func updateSpeedVisibility() {
        // 此方法已被updateAnimationControls替代，保留以防其他地方调用
        updateAnimationControls()
    }
    
    private func updateAnimationControls() {
        // 滚动toggle开启：显示滚动方式和速度滑块
        let isScrollEnabled = scrollToggle.isOn
        scrollTypeLabel.isHidden = !isScrollEnabled
        scrollTypeSegment.isHidden = !isScrollEnabled
        speedSlider.isHidden = !isScrollEnabled
        
        // 闪烁toggle开启：显示闪烁速度选择
        let isBlinkEnabled = blinkToggle.isOn
        blinkSectionLabel.isHidden = !isBlinkEnabled
        blinkSegment.isHidden = !isBlinkEnabled
        
        // 动态调整闪烁toggle的位置
        blinkToggleLabelTopConstraint.isActive = false
        if isScrollEnabled {
            // 滚动开启：闪烁toggle在滚动区域下面（间距80px，从50增加30px）
            blinkToggleLabelTopConstraint = blinkToggleLabel.topAnchor.constraint(equalTo: scrollToggleLabel.bottomAnchor, constant: 80 + scrollTypeHeightConstraint)
        } else {
            // 滚动关闭：闪烁toggle紧跟在滚动toggle后面（间距20px）
            blinkToggleLabelTopConstraint = blinkToggleLabel.topAnchor.constraint(equalTo: scrollToggleLabel.bottomAnchor, constant: 20)
        }
        blinkToggleLabelTopConstraint.isActive = true
        
        // 强制更新布局
        UIView.animate(withDuration: 0.3) {
            self.animationTabView.layoutIfNeeded()
        }
    }
    
    @objc private func scrollToggleChanged() {
        updateAnimationControls()
        updateCurrentItem()
        updatePreview()
        if scrollToggle.isOn {
            applyScrollAnimation()
        } else {
            // 关闭滚动时，检查是否需要应用闪烁
            if blinkToggle.isOn {
                applyBlinkAnimation()
            } else {
                // 两个都关闭，移除所有动画
                previewLabel.layer.removeAllAnimations()
                previewLabel.alpha = 1.0
                previewLabel.transform = .identity
            }
        }
    }
    
    @objc private func blinkToggleChanged() {
        updateAnimationControls()
        updateCurrentItem()
        updatePreview()
        if blinkToggle.isOn {
            applyBlinkAnimation()
        } else {
            // 关闭闪烁时，检查是否需要应用滚动
            if scrollToggle.isOn {
                applyScrollAnimation()
            } else {
                // 两个都关闭，移除所有动画
                previewLabel.layer.removeAllAnimations()
                previewLabel.alpha = 1.0
                previewLabel.transform = .identity
            }
        }
    }
    
    @objc private func blinkSpeedChanged() {
        // 根据选择的闪烁速度设置speed值
        // 慢: 1.5, 快: 1.0, 非常快: 0.5（周期越小闪烁越快）
        let blinkSpeeds: [CGFloat] = [1.5, 1.0, 0.5]
        currentItem.speed = blinkSpeeds[blinkSegment.selectedSegmentIndex]
        // 应用闪烁动画
        if blinkToggle.isOn {
            applyBlinkAnimation()
        }
    }
    
    private func applyScrollAnimation() {
        // 移除旧的动画
        previewLabel.layer.removeAllAnimations()
        
        // 如果滚动toggle关闭，不应用滚动动画
        if !scrollToggle.isOn {
            previewLabel.transform = .identity
            previewLabel.alpha = 1.0
            return
        }
        
        // 获取滚动类型（4个选项）
        let scrollTypes: [LEDItem.ScrollType] = [.scrollLeft, .scrollRight, .scrollUp, .scrollDown]
        let scrollType = scrollTypes[scrollTypeSegment.selectedSegmentIndex]
        
        // 计算动画时长（速度越快，时长越短）
        let baseDuration: TimeInterval = 3.0
        let duration = baseDuration / Double(currentItem.speed)
        
        // 根据滚动类型创建动画
        switch scrollType {
        case .scrollLeft:
            animateScrollLeft(duration: duration)
        case .scrollRight:
            animateScrollRight(duration: duration)
        case .scrollUp:
            animateScrollUp(duration: duration)
        case .scrollDown:
            animateScrollDown(duration: duration)
        default:
            break
        }
    }
    
    private func applyBlinkAnimation() {
        // 移除旧的动画
        previewLabel.layer.removeAllAnimations()
        
        // 如果闪烁toggle关闭，不应用闪烁动画
        if !blinkToggle.isOn {
            previewLabel.alpha = 1.0
            previewLabel.transform = .identity
            return
        }
        
        // 确保alpha为1
        previewLabel.alpha = 1.0
        previewLabel.transform = .identity
        
        // 创建闪烁动画（类似首页偶像屏幕的效果）
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = currentItem.speed // 使用speed作为闪烁周期
        animation.autoreverses = true // 自动反转（淡入淡出）
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        previewLabel.layer.add(animation, forKey: "blink")
    }
    
    private func animateScrollLeft(duration: TimeInterval) {
        let containerWidth = previewContainer.bounds.width
        let labelWidth = previewLabel.intrinsicContentSize.width
        
        // 从右侧进入，向左滚动到左侧消失
        let startX = containerWidth / 2 + labelWidth / 2
        let endX = -labelWidth / 2
        
        previewLabel.layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = startX
        animation.toValue = endX
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        previewLabel.layer.add(animation, forKey: "scrollLeft")
    }
    
    private func animateScrollRight(duration: TimeInterval) {
        let containerWidth = previewContainer.bounds.width
        let labelWidth = previewLabel.intrinsicContentSize.width
        
        // 从左侧进入，向右滚动到右侧消失
        let startX = -labelWidth / 2
        let endX = containerWidth / 2 + labelWidth / 2
        
        previewLabel.layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = startX
        animation.toValue = endX
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        previewLabel.layer.add(animation, forKey: "scrollRight")
    }
    
    private func animateScrollUp(duration: TimeInterval) {
        let containerHeight = previewContainer.bounds.height
        let labelHeight = previewLabel.intrinsicContentSize.height
        
        // 从下方进入，向上滚动到上方消失
        let startY = containerHeight / 2 + labelHeight / 2
        let endY = -labelHeight / 2
        
        previewLabel.layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = startY
        animation.toValue = endY
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        previewLabel.layer.add(animation, forKey: "scrollUp")
    }
    
    private func animateScrollDown(duration: TimeInterval) {
        let containerHeight = previewContainer.bounds.height
        let labelHeight = previewLabel.intrinsicContentSize.height
        
        // 从上方进入，向下滚动到下方消失
        let startY = -labelHeight / 2
        let endY = containerHeight / 2 + labelHeight / 2
        
        previewLabel.layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = startY
        animation.toValue = endY
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        previewLabel.layer.add(animation, forKey: "scrollDown")
    }
    
    @objc private func fontChanged() {
        switch fontSegment.selectedSegmentIndex {
        case 0:
            currentItem.fontName = "PingFangSC-Regular" // 苹方
        case 1:
            currentItem.fontName = "STHeitiSC-Medium" // 黑体
        case 2:
            currentItem.fontName = "STSongti-SC-Regular" // 宋体
        case 3:
            currentItem.fontName = "STKaiti" // 楷体
        default:
            currentItem.fontName = "PingFangSC-Regular"
        }
        updatePreview()
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        if sender.tag >= 200 {
            // 背景颜色
            selectedBgColorIndex = sender.tag - 200
            currentItem.backgroundColor = bgColors[selectedBgColorIndex]
            selectedBackgroundImage = nil // 清除背景图片
            updateColorButtonSelection(tag: 200, selectedIndex: selectedBgColorIndex)
            // 清除渐变选择
            updateColorButtonSelection(tag: 400, selectedIndex: -1)
            // 清除模版选择
            updateColorButtonSelection(tag: 500, selectedIndex: -1)
            updateColorButtonSelection(tag: 510, selectedIndex: -1)
            updateColorButtonSelection(tag: 520, selectedIndex: -1)
        } else {
            // 文字颜色
            selectedTextColorIndex = sender.tag - 100
            currentItem.textColor = textColors[selectedTextColorIndex]
            updateColorButtonSelection(tag: 100, selectedIndex: selectedTextColorIndex)
            // 清除渐变选择
            selectedGradientIndex = -1
            updateColorButtonSelection(tag: 400, selectedIndex: -1)
        }
        updatePreview()
    }
    
    @objc private func gradientButtonTapped(_ sender: UIButton) {
        // 清除纯色选择
        updateColorButtonSelection(tag: 100, selectedIndex: -1)
        
        // 更新渐变选择
        selectedGradientIndex = sender.tag - 400
        updateColorButtonSelection(tag: 400, selectedIndex: selectedGradientIndex)
        
        // 获取渐变颜色
        let colors = gradientColors[selectedGradientIndex]
        applyGradientToPreview(colors: colors)
        
        // 保存第一个颜色作为主色（用于保存）
        if let hint = sender.accessibilityHint {
            let colors = hint.split(separator: ",").map { String($0) }
            if let firstColor = colors.first {
                currentItem.textColor = firstColor
            }
        }
    }
    
    private func applyGradientToPreview(colors: [String]) {
        // 移除旧的渐变层
        previewLabel.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        // 创建渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { UIColor(hex: $0).cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // 使用mask实现文字渐变
        DispatchQueue.main.async {
            gradientLayer.frame = self.previewLabel.bounds
            
            // 创建文字mask
            let textLayer = CATextLayer()
            textLayer.string = self.previewLabel.text
            textLayer.font = self.previewLabel.font
            textLayer.fontSize = self.previewLabel.font.pointSize
            textLayer.frame = self.previewLabel.bounds
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            
            gradientLayer.mask = textLayer
            self.previewLabel.layer.addSublayer(gradientLayer)
            
            // 隐藏原文字颜色
            self.previewLabel.textColor = .clear
            
            // 更新发光效果（使用渐变的第一个颜色）- 适配0-10范围
            let glowColor = UIColor(hex: colors[0])
            self.previewLabel.layer.shadowColor = glowColor.cgColor
            self.previewLabel.layer.shadowRadius = 2.5 * self.currentItem.glowIntensity
            self.previewLabel.layer.shadowOpacity = Float(min(self.currentItem.glowIntensity / 10.0, 1.0))
            self.previewLabel.layer.shadowOffset = .zero
        }
    }
    
    @objc private func textureButtonTapped(_ sender: UIButton) {
        let textureIndex = sender.tag - 300
        let textureName = bgTextures[textureIndex]
        
        // 将纹理颜色转换为hex存储
        let textureColor = createTextureBackground(type: textureName)
        currentItem.backgroundColor = textureColor.toHex() ?? "#000000"
        selectedBackgroundImage = nil // 清除背景图片
        
        // 更新选择状态
        updateColorButtonSelection(tag: 300, selectedIndex: textureIndex)
        // 清除纯色选择
        updateColorButtonSelection(tag: 200, selectedIndex: -1)
        // 清除背景渐变选择
        updateColorButtonSelection(tag: 400, selectedIndex: -1)
        updateColorButtonSelection(tag: 410, selectedIndex: -1)
        // 清除模版选择
        updateColorButtonSelection(tag: 500, selectedIndex: -1)
        updateColorButtonSelection(tag: 510, selectedIndex: -1)
        updateColorButtonSelection(tag: 520, selectedIndex: -1)
        
        updatePreview()
    }
    
    @objc private func bgGradientButtonTapped(_ sender: UIButton) {
        // 获取渐变颜色
        guard let hint = sender.accessibilityHint else { return }
        let colors = hint.split(separator: ",").map { String($0) }
        
        // 应用渐变背景到预览容器
        applyGradientToBackground(colors: colors)
        
        // 保存第一个颜色作为背景色（用于保存）
        if let firstColor = colors.first {
            currentItem.backgroundColor = firstColor
        }
        
        // 清除背景图片
        selectedBackgroundImage = nil
        
        // 更新选择状态
        updateColorButtonSelection(tag: 400, selectedIndex: sender.tag - 400)
        
        // 清除其他选择
        updateColorButtonSelection(tag: 200, selectedIndex: -1)
        updateColorButtonSelection(tag: 300, selectedIndex: -1)
        updateColorButtonSelection(tag: 500, selectedIndex: -1)
        updateColorButtonSelection(tag: 510, selectedIndex: -1)
        updateColorButtonSelection(tag: 520, selectedIndex: -1)
    }
    
    private func applyGradientToBackground(colors: [String]) {
        // 移除旧的渐变层
        previewContainer.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer && $0 !== previewBackgroundImageView.layer })
        
        // 创建渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { UIColor(hex: $0).cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = previewContainer.bounds
        
        // 插入到最底层
        previewContainer.layer.insertSublayer(gradientLayer, at: 0)
        previewContainer.backgroundColor = .clear
        
        // 隐藏背景图片
        previewBackgroundImageView.isHidden = true
    }
    
    @objc private func templateButtonTapped(_ sender: UIButton) {
        var category = ""
        var index = 0
        
        if sender.tag >= 520 {
            // LED横幅
            category = "led"
            index = sender.tag - 520 + 1
            updateColorButtonSelection(tag: 520, selectedIndex: sender.tag - 520)
            updateColorButtonSelection(tag: 500, selectedIndex: -1)
            updateColorButtonSelection(tag: 510, selectedIndex: -1)
        } else if sender.tag >= 510 {
            // 偶像应援
            category = "idol"
            index = sender.tag - 510 + 1
            updateColorButtonSelection(tag: 510, selectedIndex: sender.tag - 510)
            updateColorButtonSelection(tag: 500, selectedIndex: -1)
            updateColorButtonSelection(tag: 520, selectedIndex: -1)
        } else {
            // 霓虹灯看板
            category = "neon"
            index = sender.tag - 500 + 1
            updateColorButtonSelection(tag: 500, selectedIndex: sender.tag - 500)
            updateColorButtonSelection(tag: 510, selectedIndex: -1)
            updateColorButtonSelection(tag: 520, selectedIndex: -1)
        }
        
        // 保存选中的背景图片名称
        let imageName = "\(category)_\(index)"
        selectedBackgroundImage = imageName
        
        // 清除其他背景选择
        updateColorButtonSelection(tag: 200, selectedIndex: -1)
        updateColorButtonSelection(tag: 300, selectedIndex: -1)
        
        updatePreview()
    }
    
    private func updatePreview() {
        // 更新预览文字
        let displayText = textField.text?.isEmpty == false ? textField.text! : "预览"
        previewLabel.text = displayText
        
        // 计算预览字体大小：根据实际字体大小按比例缩放
        // 预览容器高度120，最大可用95%即114
        // 字体大小范围30-100，映射到预览区域
        let containerHeight: CGFloat = 120
        let maxTextHeight = containerHeight * 0.95
        let fontSizeRatio = currentItem.fontSize / 100.0 // 归一化到0.3-1.0
        let previewFontSize = maxTextHeight * fontSizeRatio
        
        previewLabel.font = UIFont(name: currentItem.fontName, size: previewFontSize) ?? .boldSystemFont(ofSize: previewFontSize)
        
        // 更新背景（图片或颜色）
        if let imageName = selectedBackgroundImage, let image = UIImage(named: imageName) {
            // 显示背景图片
            previewBackgroundImageView.image = image
            previewBackgroundImageView.isHidden = false
            previewContainer.backgroundColor = .clear
        } else {
            // 显示背景颜色
            previewBackgroundImageView.image = nil
            previewBackgroundImageView.isHidden = true
            previewContainer.backgroundColor = UIColor(hex: currentItem.backgroundColor)
        }
        
        // 如果没有选择渐变，使用纯色
        if selectedGradientIndex == -1 {
            // 移除渐变层
            previewLabel.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            
            // 更新颜色
            previewLabel.textColor = UIColor(hex: currentItem.textColor)
            
            // 更新霓虹效果 (0-10范围，缩放到合适的视觉效果)
            let glowRadius = 2.5 * currentItem.glowIntensity // 0-25的范围
            let glowOpacity = min(currentItem.glowIntensity / 10.0, 1.0) // 归一化到0-1
            
            previewLabel.layer.shadowColor = UIColor(hex: currentItem.textColor).cgColor
            previewLabel.layer.shadowRadius = glowRadius
            previewLabel.layer.shadowOpacity = Float(glowOpacity)
            previewLabel.layer.shadowOffset = .zero
        }
        
        // 应用滚动或闪烁动画，或静止
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.scrollToggle.isOn {
                self.applyScrollAnimation()
            } else if self.blinkToggle.isOn {
                self.applyBlinkAnimation()
            } else {
                // 两个toggle都关闭，移除所有动画（静止状态）
                self.previewLabel.layer.removeAllAnimations()
                self.previewLabel.alpha = 1.0
                self.previewLabel.transform = .identity
            }
        }
    }
    
    @objc private func textFieldDidChange() {
        updatePreview()
    }
    
    @objc private func cancelTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)
        updateCurrentItem()
        
        guard !currentItem.text.isEmpty else {
            showAlert(message: "请输入文字内容")
            return
        }
        
        var items = LEDDataManager.shared.loadItems()
        
        // 如果是模版编辑模式，总是创建新的item
        if isTemplateEdit {
            // 创建新的ID
            let newItem = LEDItem(
                id: UUID().uuidString,
                text: currentItem.text,
                fontSize: currentItem.fontSize,
                textColor: currentItem.textColor,
                backgroundColor: currentItem.backgroundColor,
                backgroundImageName: currentItem.backgroundImageName,
                glowIntensity: currentItem.glowIntensity,
                scrollType: currentItem.scrollType,
                speed: currentItem.speed,
                fontName: currentItem.fontName
            )
            items.insert(newItem, at: 0)
        } else if let editingItem = editingItem,
                  let index = items.firstIndex(where: { $0.id == editingItem.id }) {
            // 普通编辑模式，更新现有item
            items[index] = currentItem
        } else {
            // 新建模式
            items.insert(currentItem, at: 0)
        }
        
        LEDDataManager.shared.saveItems(items)
        
        dismiss(animated: true) {
            self.onSave?()
        }
    }
    
    private func updateCurrentItem() {
        // 确保不会保存默认的"led content"文本
        let text = textField.text ?? ""
        currentItem.text = (text == "led content" && textField.textColor == UIColor.white.withAlphaComponent(0.3)) ? "" : text
        
        // 根据toggle状态设置scrollType
        if scrollToggle.isOn {
            // 滚动toggle开启：使用滚动类型
            let scrollTypes: [LEDItem.ScrollType] = [.scrollLeft, .scrollRight, .scrollUp, .scrollDown]
            currentItem.scrollType = scrollTypes[scrollTypeSegment.selectedSegmentIndex]
        } else if blinkToggle.isOn {
            // 闪烁toggle开启：使用闪烁类型
            currentItem.scrollType = .blink
        } else {
            // 两个toggle都关闭：静止状态
            currentItem.scrollType = .none
        }
        
        // 保存背景图片名称
        currentItem.backgroundImageName = selectedBackgroundImage
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}






// MARK: - UITextFieldDelegate
extension LEDCreateViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
