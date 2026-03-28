import UIKit

final class AboutViewController: UIViewController {

    private let logoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let versionLabel = UILabel()

    private let privacyRow = AboutRowView(title: "privacyPolicy".localized)
    private let termsRow = AboutRowView(title: "termsOfService".localized)

    private let copyrightLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "about".localized
        view.backgroundColor = .black

        setupHeader()
        setupRows()
        setupFooter()

        privacyRow.onTap = { [weak self] in
            self?.presentLegal(title: "privacyPolicy".localized, text: "privacyContent".localized)
        }
        termsRow.onTap = { [weak self] in
            self?.presentLegal(title: "termsOfService".localized, text: "termsContent".localized)
        }
    }

    private func setupHeader() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.clipsToBounds = true
        logoImageView.layer.cornerRadius = 18

        // Prefer a dedicated logo asset if present.
        logoImageView.image = UIImage(named: "LaunchLogo")

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "LedScroller"
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: isPad ? 24 : 20, weight: .semibold)
        nameLabel.textAlignment = .center

        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        versionLabel.font = .systemFont(ofSize: isPad ? 16 : 14)
        versionLabel.textAlignment = .center
        versionLabel.text = appVersionText()

        view.addSubview(logoImageView)
        view.addSubview(nameLabel)
        view.addSubview(versionLabel)

        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: isPad ? 100 : 84),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),

            nameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            versionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            versionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupRows() {
        let stack = UIStackView(arrangedSubviews: [privacyRow, termsRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 68),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupFooter() {
        let year = Calendar.current.component(.year, from: Date())
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        copyrightLabel.textAlignment = .center
        copyrightLabel.textColor = UIColor.white.withAlphaComponent(0.45)
        copyrightLabel.font = .systemFont(ofSize: 12)
        copyrightLabel.text = "Copyright © \(year) seventiny. All rights reserved."

        view.addSubview(copyrightLabel)

        NSLayoutConstraint.activate([
            copyrightLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            copyrightLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            copyrightLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
    }

    private func appVersionText() -> String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        let v = short ?? "1.0"
        if let build, !build.isEmpty {
            return "Version \(v) (\(build))"
        }
        return "Version \(v)"
    }

    private func presentLegal(title: String, text: String) {
        let legalVC = LegalTextViewController(title: title, text: text)
        let nav = UINavigationController(rootViewController: legalVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
}

private final class AboutRowView: UIControl {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()

    init(title: String) {
        super.init(frame: .zero)

        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        layer.cornerRadius = 16

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)

        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .gray
        arrowImageView.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(arrowImageView)

        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: isPad ? 76 : 60),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: isPad ? 14 : 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: isPad ? 22 : 20)
        ])

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        onTap?()
    }
}
