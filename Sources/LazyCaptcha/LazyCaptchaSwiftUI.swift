#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// A SwiftUI view that embeds the LazyCaptcha widget inline.
///
/// Use `.lazyCaptchaSheet(...)` modifier (below) for a modal presentation instead.
@available(iOS 14.0, *)
public struct LazyCaptchaView: UIViewRepresentable {
    public typealias UIViewType = UIView

    private let config: LazyCaptchaConfig
    private let onVerify: (String) -> Void
    private let onExpire: () -> Void
    private let onError: (LazyCaptchaError) -> Void

    public init(
        config: LazyCaptchaConfig,
        onVerify: @escaping (String) -> Void,
        onExpire: @escaping () -> Void = {},
        onError: @escaping (LazyCaptchaError) -> Void = { _ in }
    ) {
        self.config = config
        self.onVerify = onVerify
        self.onExpire = onExpire
        self.onError = onError
    }

    public func makeUIView(context: Context) -> UIView {
        LazyCaptchaWebView(config: config) { event in
            switch event {
            case .ready: break
            case .verified(let token): onVerify(token)
            case .expired: onExpire()
            case .error(let msg): onError(.challengeFailed(msg))
            }
        }
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

/// SwiftUI modifier that presents the CAPTCHA in a sheet.
///
/// ```swift
/// @State private var showCaptcha = false
/// @State private var token: String?
///
/// var body: some View {
///     Button("Verify") { showCaptcha = true }
///         .lazyCaptchaSheet(
///             isPresented: $showCaptcha,
///             config: LazyCaptchaConfig(siteKey: "...")
///         ) { result in
///             switch result {
///             case .success(let t): token = t
///             case .failure(let e): print(e)
///             }
///         }
/// }
/// ```
@available(iOS 14.0, *)
public extension View {
    func lazyCaptchaSheet(
        isPresented: Binding<Bool>,
        config: LazyCaptchaConfig,
        onResult: @escaping (Result<String, LazyCaptchaError>) -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            LazyCaptchaSheetContent(
                config: config,
                onResult: { result in
                    isPresented.wrappedValue = false
                    onResult(result)
                }
            )
        }
    }
}

@available(iOS 14.0, *)
private struct LazyCaptchaSheetContent: UIViewControllerRepresentable {
    let config: LazyCaptchaConfig
    let onResult: (Result<String, LazyCaptchaError>) -> Void

    func makeUIViewController(context: Context) -> LazyCaptchaViewController {
        LazyCaptchaViewController(config: config, completion: onResult)
    }

    func updateUIViewController(_ uiViewController: LazyCaptchaViewController, context: Context) {}
}
#endif
