import UIKit
import MessageUI

final class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let feedbackTitleLabel = UILabel()
    private let feedbackTextView = UITextView()

    private let emailTitleLabel = UILabel()
    private let emailTextField = UITextField()

    private let submitButton = UIButton(type: .system)

    private let supportEmail = "seventiny007@126.com"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "feedback".localized
        view.backgroundColor = .black

        setupNavBar()
        setupUI()
        registerKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNavBar() {
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

        // If this screen is pushed in a navigation stack, the system back button already exists.
        // Only show an explicit close button when presented modally.
        let isModal = navigationController?.presentingViewController != nil && navigationController?.viewControllers.first == self
        if isModal {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
            navigationItem.rightBarButtonItem?.tintColor = .white
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        feedbackTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackTitleLabel.text = "feedbackContentTitle".localized
        feedbackTitleLabel.textColor = .white
        feedbackTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        feedbackTextView.translatesAutoresizingMaskIntoConstraints = false
        feedbackTextView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        feedbackTextView.textColor = UIColor.white.withAlphaComponent(0.9)
        feedbackTextView.font = .systemFont(ofSize: 15)
        feedbackTextView.layer.cornerRadius = 14
        feedbackTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        feedbackTextView.keyboardDismissMode = .interactive

        // Simple placeholder behavior.
        feedbackTextView.text = "feedbackPlaceholder".localized
        feedbackTextView.textColor = UIColor.white.withAlphaComponent(0.35)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidBeginEditingNotification),
            name: UITextView.textDidBeginEditingNotification,
            object: feedbackTextView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidEndEditingNotification),
            name: UITextView.textDidEndEditingNotification,
            object: feedbackTextView
        )

        emailTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTitleLabel.text = "feedbackEmailTitle".localized
        emailTitleLabel.textColor = .white
        emailTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        emailTextField.textColor = UIColor.white.withAlphaComponent(0.9)
        emailTextField.font = .systemFont(ofSize: 15)
        emailTextField.layer.cornerRadius = 14
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        emailTextField.leftViewMode = .always
        emailTextField.placeholder = "feedbackEmailPlaceholder".localized
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .done
        emailTextField.addTarget(self, action: #selector(emailReturnKey), for: .editingDidEndOnExit)

        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("feedbackSubmit".localized, for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        if #available(iOS 15.0, *) {
            submitButton.backgroundColor = .systemCyan
        } else {
            submitButton.backgroundColor = .cyan
        }
        submitButton.layer.cornerRadius = 22
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        contentView.addSubview(feedbackTitleLabel)
        contentView.addSubview(feedbackTextView)
        contentView.addSubview(emailTitleLabel)
        contentView.addSubview(emailTextField)
        contentView.addSubview(submitButton)

        NSLayoutConstraint.activate([
            feedbackTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            feedbackTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            feedbackTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            feedbackTextView.topAnchor.constraint(equalTo: feedbackTitleLabel.bottomAnchor, constant: 10),
            feedbackTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            feedbackTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            feedbackTextView.heightAnchor.constraint(equalToConstant: 160),

            emailTitleLabel.topAnchor.constraint(equalTo: feedbackTextView.bottomAnchor, constant: 18),
            emailTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            emailTextField.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 10),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emailTextField.heightAnchor.constraint(equalToConstant: 48),

            submitButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 22),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    @objc private func closeTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func emailReturnKey() {
        view.endEditing(true)
    }

    @objc private func submitTapped() {
        let feedbackText = currentFeedbackText().trimmingCharacters(in: .whitespacesAndNewlines)
        if feedbackText.isEmpty {
            showAlert(title: "tip".localized, message: "feedbackEmpty".localized)
            return
        }

        presentMailComposer(feedback: feedbackText, userEmail: emailTextField.text ?? "")
    }

    private func currentFeedbackText() -> String {
        let placeholder = "feedbackPlaceholder".localized
        if feedbackTextView.text == placeholder && feedbackTextView.textColor?.cgColor.alpha ?? 1 < 0.5 {
            return ""
        }
        return feedbackTextView.text ?? ""
    }

    private func presentMailComposer(feedback: String, userEmail: String) {
        let subject = "LedScroller Feedback"

        var body = ""
        body += "Feedback:\n\(feedback)\n\n"
        body += "User Email:\n\(userEmail.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        body += "---\n"

        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        body += "App Version: \(shortVersion) (\(buildVersion))\n"
        body += "iOS: \(UIDevice.current.systemVersion)\n"
        body += "Device: \(UIDevice.current.model)\n"

        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            vc.setToRecipients([supportEmail])
            vc.setSubject(subject)
            vc.setMessageBody(body, isHTML: false)
            present(vc, animated: true)
            return
        }

        // Fallback when Mail is not configured.
        // 1) Try to open the Mail app via mailto:
        // 2) If that fails, provide copy-to-clipboard options so feedback can still be sent.
        if let mailURL = makeMailtoURL(subject: subject, body: body) {
            UIApplication.shared.open(mailURL, options: [:]) { [weak self] ok in
                guard let self else { return }
                if ok {
                    self.showAlert(title: "tip".localized, message: "feedbackOpenMailTip".localized)
                } else {
                    self.showMailFallbackAlert(body: body)
                }
            }
        } else {
            showMailFallbackAlert(body: body)
        }
    }

    private func makeMailtoURL(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    private func showMailFallbackAlert(body: String) {
        let alert = UIAlertController(
            title: "feedbackMailSetupTitle".localized,
            message: String(format: "feedbackMailSetupMessage".localized, supportEmail),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "feedbackCopyEmail".localized, style: .default) { _ in
            UIPasteboard.general.string = self.supportEmail
            self.showAlert(title: "success".localized, message: "copied".localized)
        })

        alert.addAction(UIAlertAction(title: "feedbackCopyContent".localized, style: .default) { _ in
            UIPasteboard.general.string = body
            self.showAlert(title: "success".localized, message: "copied".localized)
        })

        alert.addAction(UIAlertAction(title: "confirm".localized, style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            if result == .sent {
                self.showAlert(title: "success".localized, message: "feedbackThanks".localized)
            }
        }
    }

    // MARK: - Keyboard

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        let endInView = view.convert(endFrame, from: nil)
        let keyboardHeight = max(0, view.bounds.maxY - endInView.minY)
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    // MARK: - Placeholder notifications

    @objc private func textViewDidBeginEditingNotification() {
        let placeholder = "feedbackPlaceholder".localized
        if feedbackTextView.text == placeholder {
            feedbackTextView.text = ""
            feedbackTextView.textColor = UIColor.white.withAlphaComponent(0.9)
        }
    }

    @objc private func textViewDidEndEditingNotification() {
        let placeholder = "feedbackPlaceholder".localized
        let t = feedbackTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            feedbackTextView.text = placeholder
            feedbackTextView.textColor = UIColor.white.withAlphaComponent(0.35)
        }
    }

    // MARK: - Alerts

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default))
        present(alert, animated: true)
    }
}
