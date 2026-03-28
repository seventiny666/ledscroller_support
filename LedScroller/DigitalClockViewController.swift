import UIKit

final class DigitalClockViewController: UIViewController {

    private var timer: Timer?

    private let clockView = DSEGClockView(mode: .live)

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
        // iOS can briefly present in portrait if the system has not rotated yet.
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
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupClockView()
        addCloseButton()

        updateTime()
        startTimer()
    }

    private func setupClockView() {
        clockView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockView)

        clockView.plateText = "88:88:88"
        clockView.plateAlpha = 0.15
        // Match the cover's cyan tone.
        clockView.digitColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        clockView.glowOpacity = 0.9
        clockView.glowRadius = 10

        NSLayoutConstraint.activate([
            clockView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            clockView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            clockView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            clockView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.60)
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
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }

    private func updateTime() {
        let now = Date()
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: now)
        let m = calendar.component(.minute, from: now)
        let s = calendar.component(.second, from: now)
        clockView.setTime(h: h, m: m, s: s)
    }

    @objc private func closeTapped() {
        // Normal path: presented full-screen from a card.
        if presentingViewController != nil {
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            dismiss(animated: true)
            return
        }

        // Debug path: launched as rootViewController (e.g. -debugDigitalClock).
        if let scene = view.window?.windowScene?.delegate as? SceneDelegate {
            AppDelegate.orientationLock = .portrait
            scene.showMainInterfaceFromDebug()
            return
        }

        // Fallback.
        if let nav = navigationController {
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            nav.popViewController(animated: true)
            return
        }
    }

    deinit {
        timer?.invalidate()
    }
}
