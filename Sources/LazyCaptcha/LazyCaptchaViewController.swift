#if canImport(UIKit)
import UIKit

/// A view controller that presents the LazyCaptcha challenge modally and returns the result.
public final class LazyCaptchaViewController: UIViewController {

    public typealias Completion = (Result<String, LazyCaptchaError>) -> Void

    private let config: LazyCaptchaConfig
    private let completion: Completion
    private var captchaView: LazyCaptchaWebView!
    private var hasFinished = false

    public init(config: LazyCaptchaConfig, completion: @escaping Completion) {
        self.config = config
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = config.theme == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)
            : .systemBackground

        let nav = UINavigationBar()
        nav.translatesAutoresizingMaskIntoConstraints = false
        let item = UINavigationItem(title: "Verify")
        item.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didCancel)
        )
        nav.items = [item]
        view.addSubview(nav)

        captchaView = LazyCaptchaWebView(config: config) { [weak self] event in
            guard let self else { return }
            switch event {
            case .ready:
                break
            case .verified(let token):
                self.finish(.success(token))
            case .expired:
                // Widget handles its own retry internally
                break
            case .error(let message):
                self.finish(.failure(.challengeFailed(message)))
            }
        }
        captchaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captchaView)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nav.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            captchaView.topAnchor.constraint(equalTo: nav.bottomAnchor),
            captchaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captchaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captchaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didCancel() {
        finish(.failure(.userCancelled))
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // If the user dismissed by pulling down, treat as cancellation.
        finish(.failure(.userCancelled))
    }

    private func finish(_ result: Result<String, LazyCaptchaError>) {
        guard !hasFinished else { return }
        hasFinished = true
        let completion = self.completion
        if presentingViewController != nil {
            dismiss(animated: true) {
                completion(result)
            }
        } else {
            completion(result)
        }
    }
}
#endif
