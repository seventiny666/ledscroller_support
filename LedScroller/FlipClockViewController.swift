import UIKit

// 翻页时钟视图控制器
class FlipClockViewController: UIViewController {

    private var hourTens: FlipDigitView!
    private var hourOnes: FlipDigitView!
    private var minuteTens: FlipDigitView!
    private var minuteOnes: FlipDigitView!
    private var secondTens: FlipDigitView!
    private var secondOnes: FlipDigitView!

    private var timer: Timer?
    private var currentTime: (hour: Int, minute: Int) = (0, 0)
    private var currentTimeSecond: Int = 0

    // Layout state (computed in viewDidLayoutSubviews so safeArea is correct).
    private var clockStack: UIStackView!
    private var colon1: UILabel!
    private var colon2: UILabel!
    private var colon1WidthConstraint: NSLayoutConstraint!
    private var colon2WidthConstraint: NSLayoutConstraint!
    private var digitSizeConstraints: [(w: NSLayoutConstraint, h: NSLayoutConstraint)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTime()
        startTimer()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .landscape
        enforceLandscape()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
        AppDelegate.orientationLock = .portrait
    }

    private func enforceLandscape() {
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        UIViewController.attemptRotationToDeviceOrientation()
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 统一为纯黑色

        // Build the clock row; sizing is computed later (safeArea is not final in viewDidLoad).
        clockStack = UIStackView()
        clockStack.axis = .horizontal
        clockStack.alignment = .center
        // Expand spacing if needed to fill the fixed safe-area width.
        clockStack.distribution = .equalSpacing
        clockStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockStack)

        func makeColonLabel() -> UILabel {
            let l = UILabel()
            l.text = ":"
            l.textColor = .white
            l.textAlignment = .center
            l.setContentHuggingPriority(.required, for: .horizontal)
            l.setContentCompressionResistancePriority(.required, for: .horizontal)
            return l
        }

        hourTens = FlipDigitView()
        hourOnes = FlipDigitView()
        minuteTens = FlipDigitView()
        minuteOnes = FlipDigitView()
        secondTens = FlipDigitView()
        secondOnes = FlipDigitView()

        colon1 = makeColonLabel()
        colon2 = makeColonLabel()

        let allViews: [UIView] = [hourTens!, hourOnes!, colon1, minuteTens!, minuteOnes!, colon2, secondTens!, secondOnes!]
        allViews.forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            clockStack.addArrangedSubview(v)
        }

        // Layout position; fixed 10pt safety margin on both sides (hard requirement).
        NSLayoutConstraint.activate([
            clockStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            clockStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            clockStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])

        // Store constraints; constants are filled in viewDidLayoutSubviews when safeArea is final.
        colon1WidthConstraint = colon1.widthAnchor.constraint(equalToConstant: 24)
        colon2WidthConstraint = colon2.widthAnchor.constraint(equalToConstant: 24)
        colon1WidthConstraint.isActive = true
        colon2WidthConstraint.isActive = true

        let digitViews: [FlipDigitView] = [hourTens!, hourOnes!, minuteTens!, minuteOnes!, secondTens!, secondOnes!]
        digitSizeConstraints = digitViews.map { d in
            let h = d.heightAnchor.constraint(equalToConstant: 100)
            let w = d.widthAnchor.constraint(equalToConstant: 60)
            h.isActive = true
            w.isActive = true
            return (w: w, h: h)
        }
        
        // 添加关闭按钮（统一为首页预览的 xmark 样式：左上角）
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.enforceLandscape()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateClockLayoutMetrics()
    }

    private func updateClockLayoutMetrics() {
        // This must run after layout so safeAreaLayoutGuide.layoutFrame is correct.
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let availableWidth = max(1, safeFrame.width - 20) // 10pt on each side

        // Keep minimum spacing; UIStackView(.equalSpacing) will expand it to fill.
        let spacing = max(4, min(10, availableWidth * 0.01))

        func colonFont(for digitH: CGFloat) -> UIFont {
            UIFont.monospacedDigitSystemFont(ofSize: max(10, digitH * 0.55 - 4), weight: .bold)
        }

        func colonWidth(for font: UIFont) -> CGFloat {
            // Add a bit of padding so it never touches the cards.
            ceil(":".size(withAttributes: [.font: font]).width) + 4
        }

        // First pass.
        var colonW: CGFloat = 24
        var digitW = (availableWidth - spacing * 5 - colonW * 2) / 6
        var digitH = digitW * 1.6

        // Second pass using measured colon width.
        let font = colonFont(for: digitH)
        colonW = max(18, min(40, colonWidth(for: font)))
        digitW = (availableWidth - spacing * 5 - colonW * 2) / 6
        digitH = digitW * 1.6

        // Apply.
        clockStack.spacing = spacing
        colon1WidthConstraint.constant = colonW
        colon2WidthConstraint.constant = colonW
        colon1.font = font
        colon2.font = font

        for c in digitSizeConstraints {
            c.w.constant = digitW
            c.h.constant = digitH
        }

        // Ensure updated constraint constants take effect immediately.
        view.layoutIfNeeded()
    }

    @objc private func closeTapped() {
        if presentingViewController != nil {
            AppDelegate.orientationLock = .portrait
            dismiss(animated: true)
            return
        }

        // Debug path / unexpected presentation.
        if let scene = view.window?.windowScene?.delegate as? SceneDelegate {
            AppDelegate.orientationLock = .portrait
            scene.showMainInterfaceFromDebug()
            return
        }

        if let nav = navigationController {
            AppDelegate.orientationLock = .portrait
            nav.popViewController(animated: true)
            return
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func updateTime() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        let newTime = (hour: hour, minute: minute)
        let newSecond = second

        let oldSecondTens = (currentTimeSecond / 10)
        let oldSecondOnes = (currentTimeSecond % 10)
        let newSecondTens = newSecond / 10
        let newSecondOnes = newSecond % 10
        
        // 检查哪些数字需要更新
        let oldHourTens = currentTime.hour / 10
        let oldHourOnes = currentTime.hour % 10
        let oldMinuteTens = currentTime.minute / 10
        let oldMinuteOnes = currentTime.minute % 10

        let newHourTens = hour / 10
        let newHourOnes = hour % 10
        let newMinuteTens = minute / 10
        let newMinuteOnes = minute % 10

        if oldHourTens != newHourTens {
            hourTens.flipToDigit(newHourTens)
        }
        if oldHourOnes != newHourOnes {
            hourOnes.flipToDigit(newHourOnes)
        }
        if oldMinuteTens != newMinuteTens {
            minuteTens.flipToDigit(newMinuteTens)
        }
        if oldMinuteOnes != newMinuteOnes {
            minuteOnes.flipToDigit(newMinuteOnes)
        }

        if oldSecondTens != newSecondTens {
            secondTens.flipToDigit(newSecondTens)
        }
        if oldSecondOnes != newSecondOnes {
            secondOnes.flipToDigit(newSecondOnes)
        }

        currentTime = newTime
        currentTimeSecond = newSecond
    }
}

// 翻页数字视图（简化版 - 单层显示）
class FlipDigitView: UIView {
    
    private var currentDigit: Int = 0
    private var digitView: UIView!
    private var ghostLabel: UILabel!
    private var digitLabel: UILabel!
    private var foldGradient: CAGradientLayer?
    
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

        // 折页质感：中间一条暗线（最上层）+ 上半部渐暗（覆盖到文字上）
        let foldLine = UIView()
        foldLine.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        foldLine.translatesAutoresizingMaskIntoConstraints = false
        digitView.addSubview(foldLine)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.5).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        foldGradient = gradient
        
        // 数字后面的浅浅数字（叠一层低透明度的同号，制造纵深感）
        ghostLabel = UILabel()
        ghostLabel.textColor = UIColor.white.withAlphaComponent(0.14)
        ghostLabel.font = .monospacedDigitSystemFont(ofSize: 100, weight: .bold) // 设置较大初始字体，避免跳动
        ghostLabel.textAlignment = .center
        ghostLabel.adjustsFontSizeToFitWidth = false
        ghostLabel.baselineAdjustment = .alignCenters
        ghostLabel.minimumScaleFactor = 0.2
        ghostLabel.translatesAutoresizingMaskIntoConstraints = false
        digitView.addSubview(ghostLabel)

        // 数字标签（前景主数字）
        digitLabel = UILabel()
        digitLabel.textColor = .white
        digitLabel.font = .monospacedDigitSystemFont(ofSize: 100, weight: .bold) // 设置较大初始字体，避免跳动
        digitLabel.textAlignment = .center
        digitLabel.adjustsFontSizeToFitWidth = false
        digitLabel.baselineAdjustment = .alignCenters
        digitLabel.minimumScaleFactor = 0.2
        digitLabel.translatesAutoresizingMaskIntoConstraints = false
        digitView.addSubview(digitLabel)

        if let gradient = foldGradient {
            digitView.layer.addSublayer(gradient)
        }

        digitView.bringSubviewToFront(foldLine)
        
        NSLayoutConstraint.activate([
            digitView.topAnchor.constraint(equalTo: topAnchor),
            digitView.leadingAnchor.constraint(equalTo: leadingAnchor),
            digitView.trailingAnchor.constraint(equalTo: trailingAnchor),
            digitView.bottomAnchor.constraint(equalTo: bottomAnchor),

            foldLine.centerYAnchor.constraint(equalTo: digitView.centerYAnchor),
            foldLine.leadingAnchor.constraint(equalTo: digitView.leadingAnchor),
            foldLine.trailingAnchor.constraint(equalTo: digitView.trailingAnchor),
            foldLine.heightAnchor.constraint(equalToConstant: 4),
            
            ghostLabel.centerXAnchor.constraint(equalTo: digitView.centerXAnchor, constant: 1.0),
            ghostLabel.centerYAnchor.constraint(equalTo: digitView.centerYAnchor, constant: 1.0),
            ghostLabel.leadingAnchor.constraint(equalTo: digitView.leadingAnchor, constant: 8),
            ghostLabel.trailingAnchor.constraint(equalTo: digitView.trailingAnchor, constant: -8),
            ghostLabel.topAnchor.constraint(greaterThanOrEqualTo: digitView.topAnchor, constant: 10),
            ghostLabel.bottomAnchor.constraint(lessThanOrEqualTo: digitView.bottomAnchor, constant: -10),

            digitLabel.centerXAnchor.constraint(equalTo: digitView.centerXAnchor),
            digitLabel.centerYAnchor.constraint(equalTo: digitView.centerYAnchor),
            digitLabel.leadingAnchor.constraint(equalTo: digitView.leadingAnchor, constant: 8),
            digitLabel.trailingAnchor.constraint(equalTo: digitView.trailingAnchor, constant: -8),
            digitLabel.topAnchor.constraint(greaterThanOrEqualTo: digitView.topAnchor, constant: 10),
            digitLabel.bottomAnchor.constraint(lessThanOrEqualTo: digitView.bottomAnchor, constant: -10)
        ])
        
        setDigit(0, animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Size the digit font from height so it never clips vertically.
        let h = digitView.bounds.height
        // Empirically, ~70% of card height fills well with this font and avoids clipping at top/bottom.
        let targetFontSize = max(10, h * 0.66)
        
        // 只在字体大小变化时更新（避免不必要的跳动）
        let currentFontSize = digitLabel.font?.pointSize ?? 0
        guard abs(currentFontSize - targetFontSize) > 1 else { return }
        
        let font = UIFont.monospacedDigitSystemFont(ofSize: targetFontSize, weight: .bold)
        digitLabel.font = font
        ghostLabel.font = font

        if let gradient = foldGradient {
            // Keep it between the digit text and the fold line so the line stays crisp.
            if gradient.superlayer == nil {
                digitView.layer.addSublayer(gradient)
            }
            gradient.frame = CGRect(x: 0, y: 0, width: digitView.bounds.width, height: digitView.bounds.height / 2)
        }
    }

    func flipToDigit(_ digit: Int) {
        guard digit != currentDigit else { return }
        setDigit(digit, animated: true)
    }

    // Used by static cover views / thumbnails.
    func setStaticDigit(_ digit: Int) {
        setDigit(digit, animated: false)
    }
    
    private func setDigit(_ digit: Int, animated: Bool) {
        let digitText = "\(digit)"
        
        if animated {
            performFlipAnimation(to: digitText)
        } else {
            ghostLabel.text = digitText
            digitLabel.text = digitText
        }
        
        currentDigit = digit
    }
    
    private func performFlipAnimation(to newDigit: String) {
        // 简单的缩放+淡入淡出动画（后景浅浅数字保持在背后，不参与缩放）
        UIView.animate(withDuration: 0.15, animations: {
            self.digitLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.digitLabel.alpha = 0.3
        }) { _ in
            self.ghostLabel.text = newDigit
            self.digitLabel.text = newDigit
            UIView.animate(withDuration: 0.15) {
                self.digitLabel.transform = .identity
                self.digitLabel.alpha = 1.0
            }
        }
    }
}
