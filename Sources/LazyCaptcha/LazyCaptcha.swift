import Foundation

/// Public entrypoint for the LazyCaptcha iOS SDK.
///
/// Typical usage (UIKit):
/// ```swift
/// let config = LazyCaptchaConfig(siteKey: "YOUR_SITE_KEY")
/// let vc = LazyCaptcha.presentChallenge(from: self, config: config) { result in
///     switch result {
///     case .success(let token): sendToServer(token)
///     case .failure(let error): print(error)
///     }
/// }
/// ```
///
/// SwiftUI:
/// ```swift
/// .lazyCaptchaSheet(isPresented: $show, config: config) { result in
///     // ...
/// }
/// ```
public enum LazyCaptcha {

    /// The SDK version.
    public static let version = "0.1.0"

    #if canImport(UIKit)
    /// Present the challenge modally from a parent view controller.
    ///
    /// - Parameters:
    ///   - parent: The view controller to present from.
    ///   - config: The captcha configuration.
    ///   - animated: Whether to animate the presentation.
    ///   - completion: Called with the token on success, or an error.
    /// - Returns: The presented view controller (for reference if needed).
    @discardableResult
    public static func presentChallenge(
        from parent: UIViewController,
        config: LazyCaptchaConfig,
        animated: Bool = true,
        completion: @escaping (Result<String, LazyCaptchaError>) -> Void
    ) -> LazyCaptchaViewController {
        let vc = LazyCaptchaViewController(config: config, completion: completion)
        parent.present(vc, animated: animated)
        return vc
    }
    #endif
}

// MARK: - UIKit types bridging
#if canImport(UIKit)
import UIKit
#endif
