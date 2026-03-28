import UIKit

// Static thumbnail/cover for the Countdown card.
final class CountdownCoverView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .black

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        trackLayer.lineWidth = 8
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.65
        layer.addSublayer(progressLayer)

        timeLabel.text = "05:00"
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let minSide = min(bounds.width, bounds.height)
        let radius = minSide * 0.32
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let start = -CGFloat.pi / 2
        let end = start + 2 * CGFloat.pi

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
}
