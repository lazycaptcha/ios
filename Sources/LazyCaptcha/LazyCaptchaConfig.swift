import Foundation

/// Challenge type to present.
public enum LazyCaptchaChallengeType: String, Sendable {
    case auto
    case imagePuzzle = "image_puzzle"
    case pow
    case behavioral
    case textMath = "text_math"
    case pressHold = "press_hold"
    case rotateAlign = "rotate_align"
}

/// Widget theme. Use `.auto` to follow the host OS / parent-site color scheme.
public enum LazyCaptchaTheme: String, Sendable {
    case light
    case dark
    case auto
}

/// Configuration for the CAPTCHA widget.
public struct LazyCaptchaConfig: Sendable {
    /// Public site key from the LazyCaptcha dashboard.
    public let siteKey: String

    /// Base URL of your LazyCaptcha instance. Defaults to https://lazycaptcha.com.
    public let baseURL: URL

    /// Challenge type to present. Defaults to `.auto`.
    public let type: LazyCaptchaChallengeType

    /// Widget theme. Defaults to `.light`.
    public let theme: LazyCaptchaTheme

    /// The origin domain sent to the widget (must match your site's `allowed_origins` setting).
    /// If `nil`, uses the `baseURL` host.
    public let originDomain: String?

    public init(
        siteKey: String,
        baseURL: URL = URL(string: "https://lazycaptcha.com")!,
        type: LazyCaptchaChallengeType = .auto,
        theme: LazyCaptchaTheme = .light,
        originDomain: String? = nil
    ) {
        self.siteKey = siteKey
        self.baseURL = baseURL
        self.type = type
        self.theme = theme
        self.originDomain = originDomain
    }
}

/// Errors produced by the SDK.
public enum LazyCaptchaError: Error, Sendable, Equatable {
    case userCancelled
    case challengeFailed(String)
    case networkError(String)
    case verificationFailed(String)
    case invalidConfiguration(String)
    case timeout
}
