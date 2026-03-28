import UIKit

// Static thumbnail/cover for the Flip Clock card.
final class FlipClockCoverView: UIView {

    private let hourTens = FlipDigitView()
    private let hourOnes = FlipDigitView()
    private let minuteTens = FlipDigitView()
    private let minuteOnes = FlipDigitView()
    private let secondTens = FlipDigitView()
    private let secondOnes = FlipDigitView()

    private let colon1 = UILabel()
    private let colon2 = UILabel()

    private let mainStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setTimeSample()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .black

        [colon1, colon2].forEach { label in
            label.text = ":"
            label.textColor = UIColor.white.withAlphaComponent(0.85)
            label.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
            label.textAlignment = .center
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        mainStack.axis = .horizontal
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        [hourTens, hourOnes, colon1, minuteTens, minuteOnes, colon2, secondTens, secondOnes].forEach { v in
            if let label = v as? UILabel {
                mainStack.addArrangedSubview(label)
            } else {
                mainStack.addArrangedSubview(v)
            }
        }

        // Constrain the digit cards to consistent sizing within the cover.
        [hourTens, hourOnes, minuteTens, minuteOnes, secondTens, secondOnes].forEach { digit in
            digit.translatesAutoresizingMaskIntoConstraints = false
            digit.heightAnchor.constraint(equalTo: mainStack.heightAnchor).isActive = true
            digit.widthAnchor.constraint(equalTo: digit.heightAnchor, multiplier: 0.72).isActive = true
        }

        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            mainStack.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.72)
        ])
    }

    private func setTimeSample() {
        // A recognizable time for the cover.
        let h = 12
        let m = 20
        let s = 35

        hourTens.setStaticDigit(h / 10)
        hourOnes.setStaticDigit(h % 10)
        minuteTens.setStaticDigit(m / 10)
        minuteOnes.setStaticDigit(m % 10)
        secondTens.setStaticDigit(s / 10)
        secondOnes.setStaticDigit(s % 10)
    }
}
