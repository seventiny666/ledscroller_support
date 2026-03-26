import UIKit

final class SevenSegmentClockView: UIView {
    enum Mode {
        case live
        case staticPreview
    }

    private let mode: Mode

    private let stack = UIStackView()

    private let hT = SevenSegmentDigitView()
    private let hO = SevenSegmentDigitView()
    private let mT = SevenSegmentDigitView()
    private let mO = SevenSegmentDigitView()
    private let sT = SevenSegmentDigitView()
    private let sO = SevenSegmentDigitView()

    private let colon1 = SevenSegmentColonView()
    private let colon2 = SevenSegmentColonView()

    private var colon1Width: NSLayoutConstraint!
    private var colon2Width: NSLayoutConstraint!
    private var colon1Height: NSLayoutConstraint!
    private var colon2Height: NSLayoutConstraint!
    private var digitSizeConstraints: [(w: NSLayoutConstraint, h: NSLayoutConstraint)] = []

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

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        let views: [UIView] = [hT, hO, colon1, mT, mO, colon2, sT, sO]
        views.forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(v)
        }

        colon1Width = colon1.widthAnchor.constraint(equalToConstant: 20)
        colon2Width = colon2.widthAnchor.constraint(equalToConstant: 20)
        colon1Height = colon1.heightAnchor.constraint(equalToConstant: 64)
        colon2Height = colon2.heightAnchor.constraint(equalToConstant: 64)
        colon1Width.isActive = true
        colon2Width.isActive = true
        colon1Height.isActive = true
        colon2Height.isActive = true

        let digits: [SevenSegmentDigitView] = [hT, hO, mT, mO, sT, sO]
        digitSizeConstraints = digits.map { d in
            let w = d.widthAnchor.constraint(equalToConstant: 40)
            let h = d.heightAnchor.constraint(equalToConstant: 64)
            w.isActive = true
            h.isActive = true
            return (w: w, h: h)
        }
    }

    func applyMetrics(digitW: CGFloat, digitH: CGFloat, colonW: CGFloat, spacing: CGFloat) {
        stack.spacing = spacing
        colon1Width.constant = colonW
        colon2Width.constant = colonW
        colon1Height.constant = digitH
        colon2Height.constant = digitH
        for c in digitSizeConstraints {
            c.w.constant = digitW
            c.h.constant = digitH
        }
        setNeedsLayout()
    }

    func setTimeString(_ time: String) {
        // Expected: HH:MM:SS
        let cleaned = time.replacingOccurrences(of: ":", with: "")
        guard cleaned.count >= 6 else { return }
        let chars = Array(cleaned.prefix(6))
        func d(_ i: Int) -> Int { Int(String(chars[i])) ?? 0 }

        hT.setDigit(d(0))
        hO.setDigit(d(1))
        mT.setDigit(d(2))
        mO.setDigit(d(3))
        sT.setDigit(d(4))
        sO.setDigit(d(5))
    }

    func setTime(h: Int, m: Int, s: Int) {
        let hh = String(format: "%02d", h)
        let mm = String(format: "%02d", m)
        let ss = String(format: "%02d", s)
        setTimeString("\(hh):\(mm):\(ss)")
    }
}

final class SevenSegmentDigitView: UIView {
    // Segment order: a b c d e f g
    private var seg: [CAShapeLayer] = []

    private let onColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
    private let offColor = UIColor(red: 0.25, green: 0.0, blue: 0.0, alpha: 0.55).cgColor

    private static let map: [[Bool]] = [
        // a, b, c, d, e, f, g
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true ], // 2
        [true,  true,  true,  true,  false, false, true ], // 3
        [false, true,  true,  false, false, true,  true ], // 4
        [true,  false, true,  true,  false, true,  true ], // 5
        [true,  false, true,  true,  true,  true,  true ], // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true ], // 8
        [true,  true,  true,  true,  false, true,  true ]  // 9
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        for _ in 0..<7 {
            let l = CAShapeLayer()
            l.fillColor = offColor
            layer.addSublayer(l)
            seg.append(l)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = bounds.width
        let h = bounds.height

        // Segment thickness; tuned to resemble a classic digital clock.
        let t = max(2, min(w, h) * 0.16)
        let inset = max(1, t * 0.20)
        let r = t * 0.35

        // Horizontal segments.
        let a = segmentPath(x: inset, y: 0, width: w - inset * 2, height: t, corner: r)
        let g = segmentPath(x: inset, y: (h - t) / 2, width: w - inset * 2, height: t, corner: r)
        let d = segmentPath(x: inset, y: h - t, width: w - inset * 2, height: t, corner: r)

        // Vertical segments.
        let vh = (h - t * 3) / 2
        let b = segmentPath(x: w - t, y: inset, width: t, height: vh, corner: r)
        let c = segmentPath(x: w - t, y: h / 2 + t / 2, width: t, height: vh - inset, corner: r)
        let f = segmentPath(x: 0, y: inset, width: t, height: vh, corner: r)
        let e = segmentPath(x: 0, y: h / 2 + t / 2, width: t, height: vh - inset, corner: r)

        let paths = [a, b, c, d, e, f, g]
        for (i, p) in paths.enumerated() {
            seg[i].path = p
        }
    }

    private func segmentPath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, corner: CGFloat) -> CGPath {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        return UIBezierPath(roundedRect: rect, cornerRadius: corner).cgPath
    }

    func setDigit(_ digit: Int) {
        let d = max(0, min(9, digit))
        let mask = SevenSegmentDigitView.map[d]
        for i in 0..<7 {
            seg[i].fillColor = mask[i] ? onColor : offColor
        }
    }
}

final class SevenSegmentColonView: UIView {
    private let topDot = CAShapeLayer()
    private let bottomDot = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false

        topDot.fillColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        bottomDot.fillColor = UIColor(red: 1.0, green: 0.12, blue: 0.12, alpha: 1.0).cgColor

        layer.addSublayer(topDot)
        layer.addSublayer(bottomDot)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = bounds.width
        let h = bounds.height

        let d = max(2, min(w, h) * 0.18)
        let x = (w - d) / 2

        let y1 = h * 0.32 - d / 2
        let y2 = h * 0.68 - d / 2

        topDot.path = UIBezierPath(roundedRect: CGRect(x: x, y: y1, width: d, height: d), cornerRadius: d / 2).cgPath
        bottomDot.path = UIBezierPath(roundedRect: CGRect(x: x, y: y2, width: d, height: d), cornerRadius: d / 2).cgPath
    }
}
