import UIKit

final class CountdownViewController: UIViewController {

    override var prefersStatusBarHidden: Bool { true }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

    private enum State {
        case idle
        case running(endDate: Date, total: TimeInterval)
        case paused(remaining: TimeInterval, total: TimeInterval)
    }

    private let ringTrack = CAShapeLayer()
    private let ringProgress = CAShapeLayer()
    private let timeLabel = UILabel()

    private let leftPanel = UIView()
    private let rightPanel = UIView()
    private let mainStack = UIStackView()

    private let controlsStack = UIStackView()
    private let startPauseButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let setButton = UIButton(type: .system)

    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    private var displayLink: CADisplayLink?
    private var state: State = .idle

    // Reasonable default.
    private let defaultDuration: TimeInterval = 5 * 60

    // User-selected duration when idle.
    private var selectedDuration: TimeInterval = 5 * 60

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        setupRing()
        setupControls()
        addCloseButton()
        selectedDuration = defaultDuration
        setDuration(selectedDuration)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .landscape
        enforceLandscape()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enforceLandscape()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutForCurrentBounds()
        layoutRingPath()
    }

    private func setupLayout() {
        leftPanel.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.translatesAutoresizingMaskIntoConstraints = false

        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        mainStack.addArrangedSubview(leftPanel)
        mainStack.addArrangedSubview(rightPanel)
        view.addSubview(mainStack)

        // Keep the content visually centered in landscape.
        // Use an explicit height so the stack view has a determined size.
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, constant: -32)
        ])

        // Portrait: controls sit at the bottom.
        portraitConstraints = [
            rightPanel.heightAnchor.constraint(equalToConstant: 72)
        ]

        // Landscape: controls get a fixed-ish width panel on the right.
        landscapeConstraints = [
            rightPanel.widthAnchor.constraint(equalTo: mainStack.widthAnchor, multiplier: 0.34)
        ]
    }

    private func setupRing() {
        ringTrack.fillColor = UIColor.clear.cgColor
        ringTrack.strokeColor = UIColor.white.withAlphaComponent(0.10).cgColor
        ringTrack.lineWidth = 22
        ringTrack.lineCap = .round
        leftPanel.layer.addSublayer(ringTrack)

        ringProgress.fillColor = UIColor.clear.cgColor
        ringProgress.strokeColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        ringProgress.lineWidth = 22
        ringProgress.lineCap = .round
        ringProgress.strokeEnd = 1
        leftPanel.layer.addSublayer(ringProgress)

        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 88, weight: .bold)
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.5
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        leftPanel.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: leftPanel.centerYAnchor),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftPanel.leadingAnchor, constant: 24),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: leftPanel.trailingAnchor, constant: -24)
        ])
    }

    private func setupControls() {
        controlsStack.axis = .horizontal
        controlsStack.alignment = .fill
        controlsStack.distribution = .fillEqually
        controlsStack.spacing = 14
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.addSubview(controlsStack)

        func styleButton(_ b: UIButton, title: String, symbolName: String) {
            b.setTitle(title, for: .normal)
            b.setTitleColor(.black, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)

            b.setImage(UIImage(systemName: symbolName), for: .normal)
            b.tintColor = .black
            b.semanticContentAttribute = .forceLeftToRight

            // Space between icon and title.
            b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)

            b.backgroundColor = UIColor.white.withAlphaComponent(0.92)
            b.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
            b.layer.cornerRadius = 22
        }

        styleButton(startPauseButton, title: "Start", symbolName: "play")
        styleButton(resetButton, title: "Reset", symbolName: "arrow.counterclockwise")
        styleButton(setButton, title: "Set", symbolName: "gearshape")

        startPauseButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(setTapped), for: .touchUpInside)

        controlsStack.addArrangedSubview(setButton)
        controlsStack.addArrangedSubview(resetButton)
        controlsStack.addArrangedSubview(startPauseButton)

        NSLayoutConstraint.activate([
            controlsStack.centerXAnchor.constraint(equalTo: rightPanel.centerXAnchor),
            controlsStack.centerYAnchor.constraint(equalTo: rightPanel.centerYAnchor),
            controlsStack.leadingAnchor.constraint(greaterThanOrEqualTo: rightPanel.leadingAnchor),
            controlsStack.trailingAnchor.constraint(lessThanOrEqualTo: rightPanel.trailingAnchor)
        ])
    }

    private func layoutRingPath() {
        // Align the ring center to the label center so the circle and digits look perfectly centered.
        leftPanel.layoutIfNeeded()
        let bounds = leftPanel.bounds
        let center = CGPoint(x: bounds.midX, y: timeLabel.center.y)
        let minSide = min(bounds.width, bounds.height)

        // Make the ring diameter clearly larger than the time label, while avoiding clipping.
        let maxRadius = (minSide / 2) - (ringTrack.lineWidth / 2) - 8
        let radius = min(maxRadius, minSide * 0.42)
        let start = -CGFloat.pi / 2
        let end = start + 2 * CGFloat.pi
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
        ringTrack.path = path.cgPath
        ringProgress.path = path.cgPath
    }

    private func updateLayoutForCurrentBounds() {
        let isLandscape = view.bounds.width > view.bounds.height

        if isLandscape {
            mainStack.axis = .horizontal
            mainStack.spacing = 20

            controlsStack.axis = .vertical
            controlsStack.distribution = .fillEqually
            controlsStack.spacing = 14
            controlsStack.alignment = .fill

            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            mainStack.axis = .vertical
            mainStack.spacing = 16

            controlsStack.axis = .horizontal
            controlsStack.distribution = .fillEqually
            controlsStack.spacing = 14
            controlsStack.alignment = .fill

            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }

        // Ensure the right panel hugs its content in landscape.
        rightPanel.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightPanel.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func addCloseButton() {
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

    @objc private func closeTapped() {
        stopDisplayLink()
        AppDelegate.orientationLock = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        dismiss(animated: true)
    }

    @objc private func startPauseTapped() {
        switch state {
        case .idle:
            start(duration: selectedDuration)
        case .running:
            pause()
        case .paused(let remaining, let total):
            resume(remaining: remaining, total: total)
        }
    }

    @objc private func resetTapped() {
        stopDisplayLink()
        state = .idle
        setDuration(selectedDuration)
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        ringProgress.strokeColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
    }

    @objc private func setTapped() {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.countDownDuration = currentRemaining() ?? defaultDuration
        picker.translatesAutoresizingMaskIntoConstraints = false

        let alert = UIAlertController(title: "Set", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        alert.view.addSubview(picker)

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
        ])

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.stopDisplayLink()
            self?.state = .idle
            self?.selectedDuration = picker.countDownDuration
            self?.setDuration(picker.countDownDuration)
            self?.startPauseButton.setTitle("Start", for: .normal)
            self?.startPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        })

        present(alert, animated: true)
    }

    private func start(duration: TimeInterval) {
        let end = Date().addingTimeInterval(duration)
        state = .running(endDate: end, total: duration)
        startPauseButton.setTitle("Pause", for: .normal)
        startPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        startDisplayLink()
        tick()
    }

    private func pause() {
        guard let remaining = currentRemaining(), let total = currentTotal() else { return }
        stopDisplayLink()
        state = .paused(remaining: remaining, total: total)
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
    }

    private func resume(remaining: TimeInterval, total: TimeInterval) {
        let end = Date().addingTimeInterval(remaining)
        state = .running(endDate: end, total: total)
        startPauseButton.setTitle("Pause", for: .normal)
        startPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        startDisplayLink()
        tick()
    }

    private func setDuration(_ duration: TimeInterval) {
        selectedDuration = duration
        updateUI(remaining: duration, total: duration)
    }

    private func currentRemaining() -> TimeInterval? {
        switch state {
        case .idle:
            return nil
        case .running(let endDate, _):
            return max(0, endDate.timeIntervalSinceNow)
        case .paused(let remaining, _):
            return remaining
        }
    }

    private func currentTotal() -> TimeInterval? {
        switch state {
        case .idle:
            return nil
        case .running(_, let total):
            return total
        case .paused(_, let total):
            return total
        }
    }

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkTick() {
        tick()
    }

    private func tick() {
        guard case .running(let endDate, let total) = state else { return }
        let remaining = max(0, endDate.timeIntervalSinceNow)
        updateUI(remaining: remaining, total: total)

        if remaining <= 0.001 {
            stopDisplayLink()
            state = .idle
            startPauseButton.setTitle("Start", for: .normal)
            flashFinished()
        }
    }

    private func updateUI(remaining: TimeInterval, total: TimeInterval) {
        timeLabel.text = format(remaining)
        let progress = total <= 0 ? 0 : CGFloat(remaining / total)
        ringProgress.strokeEnd = progress
    }

    private func format(_ t: TimeInterval) -> String {
        let sec = max(0, Int(round(t)))
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func flashFinished() {
        let normal = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        let alert = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0).cgColor

        let anim = CABasicAnimation(keyPath: "strokeColor")
        anim.fromValue = normal
        anim.toValue = alert
        anim.duration = 0.25
        anim.autoreverses = true
        anim.repeatCount = 4
        ringProgress.add(anim, forKey: "flash")

        // Ensure it ends back on normal color.
        ringProgress.strokeColor = normal

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
}
