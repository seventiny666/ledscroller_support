import UIKit

// 翻页时钟视图控制器
class FlipClockViewController: UIViewController {
    
    private var hourTens: FlipDigitView!
    private var hourOnes: FlipDigitView!
    private var minuteTens: FlipDigitView!
    private var minuteOnes: FlipDigitView!
    
    private var timer: Timer?
    private var currentTime: (hour: Int, minute: Int) = (0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTime()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        // 创建时钟容器 - 占据整个屏幕
        let clockContainer = UIView()
        clockContainer.backgroundColor = .clear
        clockContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockContainer)
        
        // 创建4个翻页数字
        hourTens = FlipDigitView()
        hourOnes = FlipDigitView()
        minuteTens = FlipDigitView()
        minuteOnes = FlipDigitView()
        
        let digits = [hourTens!, hourOnes!, minuteTens!, minuteOnes!]
        digits.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            clockContainer.addSubview($0)
        }
        
        // 计算屏幕尺寸
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        // 留出边距：上下左右各2px
        let margin: CGFloat = 2
        let availableWidth = screenWidth - margin * 2
        let availableHeight = screenHeight - margin * 2
        
        // 先根据宽度计算，确保4位数字+间距+冒号能完整显示
        let spacing: CGFloat = 20
        let colonWidth: CGFloat = 40
        
        // 从宽度反推数字宽度
        let digitWidthFromWidth = (availableWidth - spacing * 3 - colonWidth) / 4
        
        // 数字高度是宽度的1.6倍
        let digitHeightFromWidth = digitWidthFromWidth * 1.6
        
        // 确保高度不超过可用高度
        let digitHeight = min(digitHeightFromWidth, availableHeight)
        let digitWidth = digitHeight / 1.6
        
        // 计算实际需要的总宽度
        let totalWidth = digitWidth * 4 + spacing * 3 + colonWidth
        
        print("🕐 全屏时钟尺寸:")
        print("   屏幕: \(screenWidth) x \(screenHeight)")
        print("   可用空间: \(availableWidth) x \(availableHeight)")
        print("   数字尺寸: \(digitWidth) x \(digitHeight)")
        print("   总宽度: \(totalWidth)")
        print("   间距: \(spacing), 冒号: \(colonWidth)")
        
        // 创建冒号分隔符
        let colonLabel = UILabel()
        colonLabel.text = ":"
        colonLabel.textColor = .white
        colonLabel.font = .systemFont(ofSize: digitHeight * 0.35, weight: .bold) // 字体大小根据高度计算
        colonLabel.textAlignment = .center
        colonLabel.translatesAutoresizingMaskIntoConstraints = false
        clockContainer.addSubview(colonLabel)
        
        // 添加关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("完成", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 28
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            clockContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clockContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            clockContainer.widthAnchor.constraint(equalToConstant: totalWidth),
            clockContainer.heightAnchor.constraint(equalToConstant: digitHeight),
            
            // 小时十位
            hourTens.leadingAnchor.constraint(equalTo: clockContainer.leadingAnchor),
            hourTens.centerYAnchor.constraint(equalTo: clockContainer.centerYAnchor),
            hourTens.widthAnchor.constraint(equalToConstant: digitWidth),
            hourTens.heightAnchor.constraint(equalToConstant: digitHeight),
            
            // 小时个位
            hourOnes.leadingAnchor.constraint(equalTo: hourTens.trailingAnchor, constant: spacing),
            hourOnes.centerYAnchor.constraint(equalTo: clockContainer.centerYAnchor),
            hourOnes.widthAnchor.constraint(equalToConstant: digitWidth),
            hourOnes.heightAnchor.constraint(equalToConstant: digitHeight),
            
            // 冒号
            colonLabel.leadingAnchor.constraint(equalTo: hourOnes.trailingAnchor),
            colonLabel.centerYAnchor.constraint(equalTo: clockContainer.centerYAnchor),
            colonLabel.widthAnchor.constraint(equalToConstant: colonWidth),
            
            // 分钟十位
            minuteTens.leadingAnchor.constraint(equalTo: colonLabel.trailingAnchor),
            minuteTens.centerYAnchor.constraint(equalTo: clockContainer.centerYAnchor),
            minuteTens.widthAnchor.constraint(equalToConstant: digitWidth),
            minuteTens.heightAnchor.constraint(equalToConstant: digitHeight),
            
            // 分钟个位
            minuteOnes.leadingAnchor.constraint(equalTo: minuteTens.trailingAnchor, constant: spacing),
            minuteOnes.centerYAnchor.constraint(equalTo: clockContainer.centerYAnchor),
            minuteOnes.widthAnchor.constraint(equalToConstant: digitWidth),
            minuteOnes.heightAnchor.constraint(equalToConstant: digitHeight),
            
            // 关闭按钮
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            closeButton.widthAnchor.constraint(equalToConstant: 120),
            closeButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func updateTime() {
        let now = Date()
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        let newTime = (hour: minute, minute: second)
        
        // 检查哪些数字需要更新
        let oldMinuteTens = currentTime.hour / 10
        let oldMinuteOnes = currentTime.hour % 10
        let oldSecondTens = currentTime.minute / 10
        let oldSecondOnes = currentTime.minute % 10
        
        let newMinuteTens = minute / 10
        let newMinuteOnes = minute % 10
        let newSecondTens = second / 10
        let newSecondOnes = second % 10
        
        if oldMinuteTens != newMinuteTens {
            hourTens.flipToDigit(newMinuteTens)
        }
        if oldMinuteOnes != newMinuteOnes {
            hourOnes.flipToDigit(newMinuteOnes)
        }
        if oldSecondTens != newSecondTens {
            minuteTens.flipToDigit(newSecondTens)
        }
        if oldSecondOnes != newSecondOnes {
            minuteOnes.flipToDigit(newSecondOnes)
        }
        
        currentTime = newTime
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// 翻页数字视图（简化版 - 单层显示）
class FlipDigitView: UIView {
    
    private var currentDigit: Int = 0
    private var digitView: UIView!
    private var digitLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 数字背景卡片
        digitView = UIView()
        digitView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8) // 半透明深灰
        digitView.layer.cornerRadius = 16
        digitView.clipsToBounds = true
        digitView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(digitView)
        
        // 数字标签
        digitLabel = UILabel()
        digitLabel.textColor = .white
        digitLabel.font = .systemFont(ofSize: 400, weight: .bold) // 大字体
        digitLabel.textAlignment = .center
        digitLabel.adjustsFontSizeToFitWidth = true
        digitLabel.minimumScaleFactor = 0.2
        digitLabel.translatesAutoresizingMaskIntoConstraints = false
        digitView.addSubview(digitLabel)
        
        NSLayoutConstraint.activate([
            digitView.topAnchor.constraint(equalTo: topAnchor),
            digitView.leadingAnchor.constraint(equalTo: leadingAnchor),
            digitView.trailingAnchor.constraint(equalTo: trailingAnchor),
            digitView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            digitLabel.centerXAnchor.constraint(equalTo: digitView.centerXAnchor),
            digitLabel.centerYAnchor.constraint(equalTo: digitView.centerYAnchor),
            digitLabel.leadingAnchor.constraint(equalTo: digitView.leadingAnchor, constant: 8),
            digitLabel.trailingAnchor.constraint(equalTo: digitView.trailingAnchor, constant: -8)
        ])
        
        setDigit(0, animated: false)
    }
    
    func flipToDigit(_ digit: Int) {
        guard digit != currentDigit else { return }
        setDigit(digit, animated: true)
    }
    
    private func setDigit(_ digit: Int, animated: Bool) {
        let digitText = "\(digit)"
        
        if animated {
            performFlipAnimation(to: digitText)
        } else {
            digitLabel.text = digitText
        }
        
        currentDigit = digit
    }
    
    private func performFlipAnimation(to newDigit: String) {
        // 简单的缩放+淡入淡出动画
        UIView.animate(withDuration: 0.15, animations: {
            self.digitLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.digitLabel.alpha = 0.3
        }) { _ in
            self.digitLabel.text = newDigit
            UIView.animate(withDuration: 0.15) {
                self.digitLabel.transform = .identity
                self.digitLabel.alpha = 1.0
            }
        }
    }
}
