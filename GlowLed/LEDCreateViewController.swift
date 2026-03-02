import UIKit

// LED创建/编辑页面
class LEDCreateViewController: UIViewController {
    
    var onSave: (() -> Void)?
    private var editingItem: LEDItem?
    private var currentItem: LEDItem
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let previewContainer = UIView()
    private let previewLabel = UILabel()
    private var textField = UITextField()
    private let fontSizeSlider = UISlider()
    private let fontSizeLabel = UILabel()
    private let glowSlider = UISlider()
    private let glowLabel = UILabel()
    private let speedSlider = UISlider()
    private let speedLabel = UILabel()
    private let scrollTypeSegment = UISegmentedControl(items: ["静止", "左滚", "右滚", "上滚", "下滚"])
    private let fontSegment = UISegmentedControl(items: ["苹方", "黑体", "宋体", "楷体"])
    
    private var selectedTextColorIndex = 0
    private var selectedBgColorIndex = 0
    
    private let textColors = ["#FF00FF", "#00FFFF", "#FFD700", "#FF1493", "#00FF00", "#FF4500", "#FFFFFF"]
    private let bgColors = ["#000000", "#1a1a2e", "#0f3460", "#16213e", "#1f1f1f", "#2d2d2d"]
    private let bgTextures = ["stars", "gradient", "dots", "waves", "grid", "noise"] // 纹理名称
    
    init(editingItem: LEDItem? = nil) {
        self.editingItem = editingItem
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
        title = editingItem == nil ? "创建LED屏幕" : "编辑LED屏幕"
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.95)
        
        // 导航栏按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveTapped))
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
        
        // 预览文字
        previewLabel.text = currentItem.text.isEmpty ? "预览" : currentItem.text
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
        scrollView.delaysContentTouches = false // 减少触摸延迟，提高响应速度
        scrollView.canCancelContentTouches = true // 允许取消内容触摸，实现更自然的滑动
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
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 800)
        ])
        
        var yOffset: CGFloat = 20
        
        // 文字输入
        addSectionLabel("文字内容", yOffset: &yOffset)
        
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
        
        // 字体大小
        fontSizeLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        fontSizeLabel.font = .boldSystemFont(ofSize: 16)
        addSliderSection(label: fontSizeLabel, slider: fontSizeSlider, yOffset: &yOffset)
        fontSizeSlider.minimumValue = 30
        // 计算手机屏幕高度的90%作为最大字体大小
        let maxFontSize = UIScreen.main.bounds.height * 0.9
        fontSizeSlider.maximumValue = Float(maxFontSize)
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        
        // 字体选择
        addSectionLabel("字体选择", yOffset: &yOffset)
        fontSegment.selectedSegmentTintColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        fontSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        fontSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        fontSegment.addTarget(self, action: #selector(fontChanged), for: .valueChanged)
        fontSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fontSegment)
        NSLayoutConstraint.activate([
            fontSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            fontSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fontSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 文字颜色
        addSectionLabel("文字颜色", yOffset: &yOffset)
        let textColorStack = createColorStack(colors: textColors, tag: 100)
        contentView.addSubview(textColorStack)
        NSLayoutConstraint.activate([
            textColorStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            textColorStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textColorStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textColorStack.heightAnchor.constraint(equalToConstant: 45)
        ])
        yOffset += 65
        
        // 霓虹强度 (0-5)
        glowLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        glowLabel.font = .boldSystemFont(ofSize: 16)
        addSliderSection(label: glowLabel, slider: glowSlider, yOffset: &yOffset)
        glowSlider.minimumValue = 0
        glowSlider.maximumValue = 5
        glowSlider.addTarget(self, action: #selector(glowChanged), for: .valueChanged)
        
        // 选择背景
        addSectionLabel("选择背景", yOffset: &yOffset)
        
        // 第一行：纯色背景
        let bgColorStack = createBgColorStack(colors: bgColors, tag: 200)
        contentView.addSubview(bgColorStack)
        NSLayoutConstraint.activate([
            bgColorStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            bgColorStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bgColorStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bgColorStack.heightAnchor.constraint(equalToConstant: 36)
        ])
        yOffset += 48
        
        // 第二行：纹理背景
        let bgTextureStack = createBgTextureStack(textures: bgTextures, tag: 300)
        contentView.addSubview(bgTextureStack)
        NSLayoutConstraint.activate([
            bgTextureStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            bgTextureStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bgTextureStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bgTextureStack.heightAnchor.constraint(equalToConstant: 36)
        ])
        yOffset += 56
        
        // 滚动方式
        addSectionLabel("滚动方式", yOffset: &yOffset)
        scrollTypeSegment.selectedSegmentTintColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        scrollTypeSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        scrollTypeSegment.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        scrollTypeSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollTypeSegment)
        NSLayoutConstraint.activate([
            scrollTypeSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            scrollTypeSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollTypeSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 滚动速度
        speedLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        speedLabel.font = .boldSystemFont(ofSize: 16)
        addSliderSection(label: speedLabel, slider: speedSlider, yOffset: &yOffset)
        speedSlider.minimumValue = 0.5
        speedSlider.maximumValue = 3.0
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        
        // 设置 contentView 的底部约束
        NSLayoutConstraint.activate([
            contentView.bottomAnchor.constraint(equalTo: speedSlider.bottomAnchor, constant: 30)
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
    
    // 创建简单的文字输入框
    private func createSimpleTextField() -> UITextField {
        let field = UITextField()
        
        // 基础样式
        field.backgroundColor = UIColor(white: 0.2, alpha: 1)
        field.textColor = .white
        field.font = .systemFont(ofSize: 18)
        field.placeholder = "输入LED文字"
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // 内边距
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        field.leftView = paddingView
        field.leftViewMode = .always
        
        // 键盘配置
        field.returnKeyType = .done
        field.enablesReturnKeyAutomatically = true
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        
        // 设置代理和事件
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
            btn.layer.cornerRadius = 18 // 圆形：36/2
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            btn.tag = tag + index
            btn.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 36).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
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
        speedLabel.text = "滚动速度: \(String(format: "%.1f", currentItem.speed))"
        
        if let textColorIndex = textColors.firstIndex(of: currentItem.textColor) {
            selectedTextColorIndex = textColorIndex
            updateColorButtonSelection(tag: 100, selectedIndex: textColorIndex)
        }
        if let bgColorIndex = bgColors.firstIndex(of: currentItem.backgroundColor) {
            selectedBgColorIndex = bgColorIndex
            updateColorButtonSelection(tag: 200, selectedIndex: bgColorIndex)
        }
        
        let scrollTypes: [LEDItem.ScrollType] = [.none, .scrollLeft, .scrollRight, .scrollUp, .scrollDown]
        if let index = scrollTypes.firstIndex(of: currentItem.scrollType) {
            scrollTypeSegment.selectedSegmentIndex = index
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
        
        // 更新预览
        updatePreview()
    }
    
    private func updateColorButtonSelection(tag: Int, selectedIndex: Int) {
        for i in 0..<7 {
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
        speedLabel.text = "滚动速度: \(String(format: "%.1f", currentItem.speed))"
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
            updateColorButtonSelection(tag: 200, selectedIndex: selectedBgColorIndex)
            // 清除纹理选择
            updateColorButtonSelection(tag: 300, selectedIndex: -1)
        } else {
            // 文字颜色
            selectedTextColorIndex = sender.tag - 100
            currentItem.textColor = textColors[selectedTextColorIndex]
            updateColorButtonSelection(tag: 100, selectedIndex: selectedTextColorIndex)
        }
        updatePreview()
    }
    
    @objc private func textureButtonTapped(_ sender: UIButton) {
        let textureIndex = sender.tag - 300
        let textureName = bgTextures[textureIndex]
        
        // 将纹理颜色转换为hex存储
        let textureColor = createTextureBackground(type: textureName)
        currentItem.backgroundColor = textureColor.toHex() ?? "#000000"
        
        // 更新选择状态
        updateColorButtonSelection(tag: 300, selectedIndex: textureIndex)
        // 清除纯色选择
        updateColorButtonSelection(tag: 200, selectedIndex: -1)
        
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
        
        // 更新颜色
        previewLabel.textColor = UIColor(hex: currentItem.textColor)
        previewContainer.backgroundColor = UIColor(hex: currentItem.backgroundColor)
        
        // 更新霓虹效果 (0-5范围，缩放到合适的视觉效果)
        let glowRadius = 5 * currentItem.glowIntensity // 0-25的范围
        let glowOpacity = min(currentItem.glowIntensity / 5.0, 1.0) // 归一化到0-1
        
        previewLabel.layer.shadowColor = UIColor(hex: currentItem.textColor).cgColor
        previewLabel.layer.shadowRadius = glowRadius
        previewLabel.layer.shadowOpacity = Float(glowOpacity)
        previewLabel.layer.shadowOffset = .zero
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
        
        if let editingItem = editingItem,
           let index = items.firstIndex(where: { $0.id == editingItem.id }) {
            items[index] = currentItem
        } else {
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
        
        let scrollTypes: [LEDItem.ScrollType] = [.none, .scrollLeft, .scrollRight, .scrollUp, .scrollDown]
        currentItem.scrollType = scrollTypes[scrollTypeSegment.selectedSegmentIndex]
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LEDCreateViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // 当用户开始输入时，清除默认的"led content"文本并将文字颜色设置为完全不透明的白色
        if textField.text == "led content" && textField.textColor == UIColor.white.withAlphaComponent(0.3) {
            textField.text = ""
            textField.textColor = .white
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 计算新的文字
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // 实时更新预览
        DispatchQueue.main.async {
            self.previewLabel.text = updatedText.isEmpty ? "预览" : updatedText
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // 当输入框失去焦点且为空时，恢复默认的"led content"文本和30%透明度
        if textField.text?.isEmpty == true {
            textField.text = "led content"
            textField.textColor = UIColor.white.withAlphaComponent(0.3)
        }
    }
}



