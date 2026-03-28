import UIKit

final class StopwatchViewController: UIViewController {

    private var stopwatchTimer: Timer?
    private var isRunning = false
    private var startTime: TimeInterval = 0
    private var accumulated: TimeInterval = 0

    private let stopwatchView = DSEGClockView(mode: .live)

    private let progressView = UIProgressView(progressViewStyle: .default)

    private let startStopButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let lapButton = UIButton(type: .system)

    override var prefersStatusBarHidden: Bool { true }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.enforceLandscape()
            self?.updateButtonLayout()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateButtonLayout()
    }

    private func updateButtonLayout() {
        // Keep SF Symbol above title for iOS versions without UIButton.Configuration.
        [resetButton, startStopButton, lapButton].forEach { b in
            guard
                let imageView = b.imageView,
                let titleLabel = b.titleLabel
            else { return }

            // Ensure intrinsic sizes are computed.
            titleLabel.sizeToFit()

            let spacing: CGFloat = 6
            let imageSize = imageView.bounds.size
            let titleSize = titleLabel.bounds.size
            let totalHeight = imageSize.height + spacing + titleSize.height

            b.imageEdgeInsets = UIEdgeInsets(
                top: -(totalHeight - imageSize.height),
                left: 0,
                bottom: 0,
                right: -titleSize.width
            )
            b.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -imageSize.width,
                bottom: -(totalHeight - titleSize.height),
                right: 0
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupProgressView()
        setupStopwatchView()
        setupControls()
        addCloseButton()

        updateDisplay()
    }

    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor.white.withAlphaComponent(0.75)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.18)
        progressView.progress = 0
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -54),
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
    }

    private func setupStopwatchView() {
        stopwatchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopwatchView)

        // Electronic-screen styling, with a full "88" plate behind.
        stopwatchView.plateText = "88:88.88"
        stopwatchView.plateAlpha = 0.15
        stopwatchView.digitColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0)
        stopwatchView.glowOpacity = 0.85
        stopwatchView.glowRadius = 9

        NSLayoutConstraint.activate([
            stopwatchView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -6),
            stopwatchView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stopwatchView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            stopwatchView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.55)
        ])

        // Tap the screen to start/pause.
        let tap = UITapGestureRecognizer(target: self, action: #selector(startStopTapped))
        stopwatchView.addGestureRecognizer(tap)
        stopwatchView.isUserInteractionEnabled = true
    }

    private func setupControls() {
        let controls = UIStackView()
        controls.axis = .horizontal
        controls.alignment = .fill
        controls.distribution = .fillEqually
        controls.spacing = 14
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)

        func styleButton(_ b: UIButton, symbolName: String, title: String) {
            // Avoid UIButton.Configuration/AttributedString so we can support iOS < 15.
            b.setTitle(title, for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            b.titleLabel?.textAlignment = .center
            b.titleLabel?.numberOfLines = 2

            b.setImage(UIImage(systemName: symbolName), for: .normal)
            b.tintColor = .white

            b.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            b.layer.cornerRadius = 14
            b.layer.masksToBounds = true
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor

            // Vertical image above title.
            b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            b.imageView?.contentMode = .scaleAspectFit

            // Use transform-based layout because edgeInsets is unreliable before layout pass.
            // We'll update in viewDidLayoutSubviews.
        }

        styleButton(startStopButton, symbolName: "play.fill", title: "Start")
        styleButton(resetButton, symbolName: "gobackward", title: "Reset")
        styleButton(lapButton, symbolName: "flag.fill", title: "Lap")

        startStopButton.addTarget(self, action: #selector(startStopTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        lapButton.addTarget(self, action: #selector(lapTapped), for: .touchUpInside)

        controls.addArrangedSubview(resetButton)
        controls.addArrangedSubview(startStopButton)
        controls.addArrangedSubview(lapButton)

        NSLayoutConstraint.activate([
            controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            controls.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            controls.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.34),
            controls.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.62)
        ])
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

    private func startTimer() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        if let t = stopwatchTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func stopTimer() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
    }

    private func currentTime() -> TimeInterval {
        let base = accumulated
        guard isRunning else { return base }
        return base + (CACurrentMediaTime() - startTime)
    }

    private func updateDisplay() {
        let t = max(0, currentTime())

        let totalSeconds = Int(t)
        let minutes = (totalSeconds / 60) % 100
        let seconds = totalSeconds % 60
        let centiseconds = Int((t - floor(t)) * 100) % 100

        stopwatchView.setTimeString(String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds))

        // Progress shows the seconds within the current minute.
        progressView.progress = Float(Double(seconds) / 60.0)
    }

    @objc private func startStopTapped() {
        if isRunning {
            accumulated = currentTime()
            isRunning = false
            stopTimer()
            startStopButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            startStopButton.setTitle("Start", for: .normal)
            updateButtonLayout()
            updateDisplay()
        } else {
            isRunning = true
            startTime = CACurrentMediaTime()
            startTimer()
            startStopButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startStopButton.setTitle("Pause", for: .normal)
            updateButtonLayout()
        }
    }

    @objc private func resetTapped() {
        accumulated = 0
        if isRunning {
            startTime = CACurrentMediaTime()
        }
        updateDisplay()
    }

    @objc private func lapTapped() {
        // Placeholder for now; keep UI consistent.
        // Future: record laps and show a list.
    }

    @objc private func closeTapped() {
        AppDelegate.orientationLock = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        dismiss(animated: true)
    }

    deinit {
        stopwatchTimer?.invalidate()
    }
}
