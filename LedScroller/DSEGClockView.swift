import UIKit
import CoreText

final class DSEGClockView: UIView {

    enum Mode {
        case live
        case staticPreview
    }

    // Public styling knobs (used by digital-clock + stopwatch).
    var digitColor: UIColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0) { didSet { applyColorsAndGlow() } }
    var plateText: String = "88:88:88" { didSet { backgroundLabel.text = plateText } }
    var plateAlpha: CGFloat = 0.15 { didSet { applyColorsAndGlow() } }
    var glowOpacity: Float = 0.9 { didSet { applyColorsAndGlow() } }
    var glowRadius: CGFloat = 10 { didSet { applyColorsAndGlow() } }

    private let mode: Mode
    private let backgroundLabel = UILabel() // shows plateText faintly behind to mimic inactive segments
    private let label = UILabel()

    init(mode: Mode) {
        self.mode = mode
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .black

        func configureCommon(_ l: UILabel) {
            l.textAlignment = .center
            l.numberOfLines = 1
            l.adjustsFontSizeToFitWidth = true
            l.minimumScaleFactor = 0.2
            l.baselineAdjustment = .alignCenters
            l.translatesAutoresizingMaskIntoConstraints = false
        }

        // "Full" digit plate behind: 8 lights all segments in 7-seg fonts.
        configureCommon(backgroundLabel)
        backgroundLabel.text = plateText
        backgroundLabel.layer.shadowOpacity = 0.0
        addSubview(backgroundLabel)

        configureCommon(label)
        addSubview(label)
        
        // 设置初始字体，避免首次布局时跳动
        // 在layoutSubviews中会根据实际尺寸重新计算
        let initialFontSize: CGFloat = 100
        let initialFont = UIFont(name: "DSEG7Classic-Bold", size: initialFontSize) ?? UIFont.monospacedDigitSystemFont(ofSize: initialFontSize, weight: .bold)
        label.font = initialFont
        backgroundLabel.font = initialFont

        applyColorsAndGlow()

        NSLayoutConstraint.activate([
            backgroundLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Default preview time.
        if mode == .staticPreview {
            setTimeString("12:20:35")
        }
    }

    private static var didRegisterFont = false

    private static func ensureFontRegistered() {
        guard !didRegisterFont else { return }
        defer { didRegisterFont = true }

        // Fonts may not load if the UIAppFonts path mismatches how resources are copied.
        // Register explicitly as a safety net.
        if let url = Bundle.main.url(forResource: "DSEG7Classic-Bold", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    // 标记是否已经完成首次布局，避免重复设置字体导致跳动
    private var hasPerformedInitialLayout = false

    override func layoutSubviews() {
        super.layoutSubviews()

        DSEGClockView.ensureFontRegistered()

        // 计算目标字体大小
        let targetFontSize = max(10, bounds.height * 0.70)

        // 只在字体大小变化时更新（避免不必要的跳动）
        let currentFontSize = label.font?.pointSize ?? 0
        guard abs(currentFontSize - targetFontSize) > 1 else { return }

        let font = UIFont(name: "DSEG7Classic-Bold", size: targetFontSize) ?? UIFont.monospacedDigitSystemFont(ofSize: targetFontSize, weight: .bold)
        label.font = font
        backgroundLabel.font = font

        // Ensure glow tracks size changes too.
        applyColorsAndGlow()
    }

    private func applyColorsAndGlow() {
        label.textColor = digitColor
        backgroundLabel.textColor = digitColor.withAlphaComponent(plateAlpha)

        // Glow (foreground only)
        label.layer.shadowColor = digitColor.cgColor
        label.layer.shadowOpacity = glowOpacity
        label.layer.shadowRadius = glowRadius
        label.layer.shadowOffset = .zero
    }

    func setTimeString(_ time: String) {
        label.text = time
    }

    func setTime(h: Int, m: Int, s: Int) {
        let hh = String(format: "%02d", h)
        let mm = String(format: "%02d", m)
        let ss = String(format: "%02d", s)
        setTimeString("\(hh):\(mm):\(ss)")
    }
}
