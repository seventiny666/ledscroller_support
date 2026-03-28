import UIKit

final class LegalTextViewController: UIViewController {

    private let contentTitle: String
    private let contentText: String

    private let textView = UITextView()

    init(title: String, text: String) {
        self.contentTitle = title
        self.contentText = text
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = contentTitle
        view.backgroundColor = .black

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .white

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor.white.withAlphaComponent(0.85)
        textView.font = .systemFont(ofSize: 15)
        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        textView.text = contentText

        // Make links (e.g. Apple subscriptions URL) tappable.
        if #available(iOS 10.0, *) {
            textView.dataDetectorTypes = [.link]
        }

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
