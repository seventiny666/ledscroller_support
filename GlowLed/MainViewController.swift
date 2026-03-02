import UIKit

class MainViewController: UIViewController {
    
    private var currentConfig: LEDConfig = LEDConfig(
        text: "GlowLed",
        style: LEDConfig.StyleConfig(
            fontSize: 72,
            color: "#FF00FF",
            glowIntensity: 0.8,
            animation: .none,
            speed: 1.0,
            backgroundColor: "#000000"
        ),
        effects: []
    )
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let textField = UITextField()
    private let fontSizeSlider = UISlider()
    private let glowSlider = UISlider()
    private let speedSlider = UISlider()
    private let animationSegment = UISegmentedControl(items: ["静止", "左滚", "右滚", "上滚", "下滚", "故障"])
    
    private let colorButtons: [UIButton] = [
        "#FF00FF", "#00FFFF", "#FFD700", "#FF1493", "#00FF00", "#FF4500"
    ].map { color in
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(hex: color)
        btn.layer.cornerRadius = 20
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.white.cgColor
        return btn
    }
    
    private let effectButtons: [(String, LEDConfig.EffectConfig.EffectType)] = [
        ("💖 爱心", .cyberHeart),
        ("🎆 烟花", .fireworks),
        ("☄️ 流星", .meteor),
        ("💻 代码雨", .codeRain)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        title = "GlowLed"
        view.backgroundColor = .black
        
        // 滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        var yOffset: CGFloat = 20
        
        // 文字输入
        addSectionLabel("文字内容", yOffset: &yOffset)
        textField.text = currentConfig.text
        textField.textColor = .white
        textField.backgroundColor = UIColor(white: 0.1, alpha: 1)
        textField.layer.cornerRadius = 8
        textField.font = .systemFont(ofSize: 18)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
        yOffset += 70
        
        // 字体大小
        addSectionLabel("字体大小: \(Int(currentConfig.style.fontSize))", yOffset: &yOffset)
        fontSizeSlider.minimumValue = 24
        fontSizeSlider.maximumValue = 120
        fontSizeSlider.value = Float(currentConfig.style.fontSize)
        fontSizeSlider.tintColor = .systemPink
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fontSizeSlider)
        
        NSLayoutConstraint.activate([
            fontSizeSlider.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            fontSizeSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fontSizeSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 霓虹强度
        addSectionLabel("霓虹强度: \(String(format: "%.1f", currentConfig.style.glowIntensity))", yOffset: &yOffset)
        glowSlider.minimumValue = 0
        glowSlider.maximumValue = 1
        glowSlider.value = Float(currentConfig.style.glowIntensity)
        glowSlider.tintColor = .systemPink
        glowSlider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(glowSlider)
        
        NSLayoutConstraint.activate([
            glowSlider.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            glowSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            glowSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 颜色选择
        addSectionLabel("霓虹颜色", yOffset: &yOffset)
        let colorStack = UIStackView(arrangedSubviews: colorButtons)
        colorStack.axis = .horizontal
        colorStack.distribution = .fillEqually
        colorStack.spacing = 10
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(colorStack)
        
        NSLayoutConstraint.activate([
            colorStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            colorStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            colorStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            colorStack.heightAnchor.constraint(equalToConstant: 40)
        ])
        yOffset += 60
        
        // 动画类型
        addSectionLabel("动画效果", yOffset: &yOffset)
        animationSegment.selectedSegmentIndex = 0
        animationSegment.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(animationSegment)
        
        NSLayoutConstraint.activate([
            animationSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            animationSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            animationSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 速度
        addSectionLabel("动画速度: \(String(format: "%.1f", currentConfig.style.speed))", yOffset: &yOffset)
        speedSlider.minimumValue = 0.5
        speedSlider.maximumValue = 5.0
        speedSlider.value = Float(currentConfig.style.speed)
        speedSlider.tintColor = .systemPink
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(speedSlider)
        
        NSLayoutConstraint.activate([
            speedSlider.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            speedSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            speedSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        yOffset += 50
        
        // 特效按钮
        addSectionLabel("赛博特效", yOffset: &yOffset)
        for (title, effectType) in effectButtons {
            let btn = createEffectButton(title: title, effectType: effectType)
            btn.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(btn)
            
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
                btn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                btn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                btn.heightAnchor.constraint(equalToConstant: 50)
            ])
            yOffset += 60
        }
        
        // 预设模板
        addSectionLabel("预设模板", yOffset: &yOffset)
        for template in PresetTemplate.templates {
            let btn = createPresetButton(template: template)
            btn.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(btn)
            
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
                btn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                btn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                btn.heightAnchor.constraint(equalToConstant: 50)
            ])
            yOffset += 60
        }
        
        // 底部按钮
        let previewBtn = createActionButton(title: "🚀 全屏预览", color: .systemPink)
        previewBtn.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
        previewBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewBtn)
        
        let codeBtn = createActionButton(title: "💻 生成代码", color: .systemCyan)
        codeBtn.addTarget(self, action: #selector(generateCodeTapped), for: .touchUpInside)
        codeBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeBtn)
        
        NSLayoutConstraint.activate([
            previewBtn.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            previewBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            previewBtn.heightAnchor.constraint(equalToConstant: 60),
            
            codeBtn.topAnchor.constraint(equalTo: previewBtn.bottomAnchor, constant: 15),
            codeBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            codeBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            codeBtn.heightAnchor.constraint(equalToConstant: 60),
            codeBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func addSectionLabel(_ text: String, yOffset: inout CGFloat) {
        let label = UILabel()
        label.text = text
        label.textColor = .systemPink
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        yOffset += 30
    }
    
    private func createEffectButton(title: String, effectType: LEDConfig.EffectConfig.EffectType) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(white: 0.15, alpha: 1)
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemPink.cgColor
        btn.tag = effectType.hashValue
        btn.addTarget(self, action: #selector(effectButtonTapped(_:)), for: .touchUpInside)
        return btn
    }
    
    private func createPresetButton(template: PresetTemplate) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(template.name, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(white: 0.15, alpha: 1)
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemCyan.cgColor
        btn.addTarget(self, action: #selector(presetButtonTapped(_:)), for: .touchUpInside)
        return btn
    }
    
    private func createActionButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 20)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 15
        return btn
    }
    
    private func setupActions() {
        for (index, button) in colorButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        let colors = ["#FF00FF", "#00FFFF", "#FFD700", "#FF1493", "#00FF00", "#FF4500"]
        currentConfig.style.color = colors[sender.tag]
        updateColorButtonSelection(selectedIndex: sender.tag)
    }
    
    private func updateColorButtonSelection(selectedIndex: Int) {
        for (index, button) in colorButtons.enumerated() {
            button.layer.borderWidth = index == selectedIndex ? 3 : 2
            button.layer.borderColor = index == selectedIndex ? UIColor.white.cgColor : UIColor.gray.cgColor
        }
    }
    
    @objc private func effectButtonTapped(_ sender: UIButton) {
        // 切换特效开关
        let effectTypes: [LEDConfig.EffectConfig.EffectType] = [.cyberHeart, .fireworks, .meteor, .codeRain]
        guard sender.tag < effectTypes.count else { return }
        
        let effectType = effectTypes[sender.tag]
        if let index = currentConfig.effects.firstIndex(where: { $0.type == effectType }) {
            currentConfig.effects.remove(at: index)
            sender.backgroundColor = UIColor(white: 0.15, alpha: 1)
        } else {
            currentConfig.effects.append(LEDConfig.EffectConfig(type: effectType, density: 0.5))
            sender.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        }
    }
    
    @objc private func presetButtonTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text,
              let template = PresetTemplate.templates.first(where: { $0.name == title }) else { return }
        
        currentConfig = template.config
        updateUIFromConfig()
    }
    
    private func updateUIFromConfig() {
        textField.text = currentConfig.text
        fontSizeSlider.value = Float(currentConfig.style.fontSize)
        glowSlider.value = Float(currentConfig.style.glowIntensity)
        speedSlider.value = Float(currentConfig.style.speed)
    }
    
    @objc private func previewTapped() {
        updateConfigFromUI()
        let displayVC = LEDDisplayViewController(config: currentConfig)
        displayVC.modalPresentationStyle = .fullScreen
        present(displayVC, animated: true)
    }
    
    @objc private func generateCodeTapped() {
        updateConfigFromUI()
        
        let code = CodeGenerator.generatePseudoCode(from: currentConfig)
        
        let alert = UIAlertController(title: "🎉 代码生成成功", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "复制伪代码", style: .default) { _ in
            UIPasteboard.general.string = code
            self.showToast("伪代码已复制")
        })
        
        alert.addAction(UIAlertAction(title: "复制 JSON", style: .default) { _ in
            if let json = CodeGenerator.generateJSON(from: self.currentConfig) {
                UIPasteboard.general.string = json
                self.showToast("JSON 已复制")
            }
        })
        
        alert.addAction(UIAlertAction(title: "查看代码", style: .default) { _ in
            self.showCodePreview(code: code)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showCodePreview(code: String) {
        let codeVC = UIViewController()
        codeVC.view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        
        let textView = UITextView()
        textView.text = code
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .systemGreen
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        codeVC.view.addSubview(textView)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("关闭", for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.backgroundColor = .systemPink
        closeBtn.layer.cornerRadius = 10
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(dismissCodePreview), for: .touchUpInside)
        codeVC.view.addSubview(closeBtn)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: codeVC.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: codeVC.view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: codeVC.view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: closeBtn.topAnchor, constant: -20),
            
            closeBtn.leadingAnchor.constraint(equalTo: codeVC.view.leadingAnchor, constant: 20),
            closeBtn.trailingAnchor.constraint(equalTo: codeVC.view.trailingAnchor, constant: -20),
            closeBtn.bottomAnchor.constraint(equalTo: codeVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        present(codeVC, animated: true)
    }
    
    @objc private func dismissCodePreview() {
        dismiss(animated: true)
    }
    
    private func updateConfigFromUI() {
        currentConfig.text = textField.text ?? "GlowLed"
        currentConfig.style.fontSize = CGFloat(fontSizeSlider.value)
        currentConfig.style.glowIntensity = CGFloat(glowSlider.value)
        currentConfig.style.speed = CGFloat(speedSlider.value)
        
        let animations: [LEDConfig.StyleConfig.AnimationType] = [.none, .scrollLeft, .scrollRight, .scrollUp, .scrollDown, .glitch]
        currentConfig.style.animation = animations[animationSegment.selectedSegmentIndex]
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
