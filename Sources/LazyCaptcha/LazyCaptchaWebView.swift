#if canImport(UIKit)
import UIKit
import WebKit

/// Internal UIView that hosts the WKWebView and bridges challenge results to a delegate.
final class LazyCaptchaWebView: UIView, WKScriptMessageHandler, WKNavigationDelegate {

    enum Event {
        case ready
        case verified(token: String)
        case expired
        case error(String)
    }

    private let config: LazyCaptchaConfig
    private(set) var webView: WKWebView!
    private var onEvent: ((Event) -> Void)?

    init(config: LazyCaptchaConfig, onEvent: @escaping (Event) -> Void) {
        self.config = config
        self.onEvent = onEvent
        super.init(frame: .zero)
        setupWebView()
        load()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupWebView() {
        let userContent = WKUserContentController()
        userContent.add(self, name: "lazycaptcha")

        let config = WKWebViewConfiguration()
        config.userContentController = userContent
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        self.webView = webView
    }

    private func load() {
        let html = LazyCaptchaHTML.page(for: config)
        let origin = config.originDomain ?? config.baseURL.host ?? "lazycaptcha.local"
        let baseURL = URL(string: "https://\(origin)/") ?? config.baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "lazycaptcha",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }

        let payload = body["payload"] as? [String: Any]

        switch type {
        case "ready":
            onEvent?(.ready)
        case "verified":
            if let token = payload?["token"] as? String {
                onEvent?(.verified(token: token))
            }
        case "expired":
            onEvent?(.expired)
        case "error":
            let msg = (payload?["message"] as? String) ?? "Unknown error"
            onEvent?(.error(msg))
        default:
            break
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onEvent?(.error("Navigation failed: \(error.localizedDescription)"))
    }
}
#endif
