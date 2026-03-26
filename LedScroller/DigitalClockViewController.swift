import UIKit

final class DigitalClockViewController: UIViewController {

    private var timer: Timer?

    private let clockView = SevenSegmentClockView(mode: .live)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        clockView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockView)

        NSLayoutConstraint.activate([
            clockView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            clockView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            clockView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])

        addCloseButton()

        updateTime()
        startTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutMetrics()
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

    private func updateLayoutMetrics() {
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let availableWidth = max(1, safeFrame.width - 20) // 10pt on each side

        // Keep colons/spacing lean to maximize digits.
        let spacing = max(4, min(10, availableWidth * 0.01))

        // Colon is two dots; size it as a ratio of digit width.
        var colonW: CGFloat = 18
        var digitW = (availableWidth - spacing * 5 - colonW * 2) / 6
        var digitH = digitW * 1.6

        colonW = max(14, min(30, digitW * 0.35))
        digitW = (availableWidth - spacing * 5 - colonW * 2) / 6
        digitH = digitW * 1.6

        clockView.applyMetrics(digitW: digitW, digitH: digitH, colonW: colonW, spacing: spacing)
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
            dismiss(animated: true)
            return
        }

        // Debug path: launched as rootViewController (e.g. -debugDigitalClock).
        if let scene = view.window?.windowScene?.delegate as? SceneDelegate {
            AppDelegate.orientationLock = .portrait
            scene.showMainInterfaceFromDebug()
            return
        }

        // Fallbacks.
        if let nav = navigationController {
            nav.popViewController(animated: true)
            return
        }
    }

    deinit {
        timer?.invalidate()
    }
}
