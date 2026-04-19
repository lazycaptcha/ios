# LazyCaptcha iOS SDK

> Native iOS SDK for [LazyCaptcha](https://github.com/yourusername/lazycaptcha) — privacy-friendly CAPTCHA for iOS apps. Supports UIKit and SwiftUI.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-lightgrey.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies…** and enter:

```
https://github.com/yourusername/lazycaptcha-ios-sdk
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/lazycaptcha-ios-sdk", from: "0.1.0")
]
```

## Usage

### SwiftUI (recommended)

```swift
import SwiftUI
import LazyCaptcha

struct ContentView: View {
    @State private var showCaptcha = false
    @State private var token: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Button("Verify I'm human") { showCaptcha = true }

            if let token {
                Text("Got token: \(token.prefix(16))…")
            }
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
        }
        .lazyCaptchaSheet(
            isPresented: $showCaptcha,
            config: LazyCaptchaConfig(
                siteKey: "YOUR_SITE_KEY",
                baseURL: URL(string: "https://your-lazycaptcha-instance.com")!
            )
        ) { result in
            switch result {
            case .success(let t):
                token = t
                errorMessage = nil
            case .failure(let err):
                errorMessage = String(describing: err)
            }
        }
    }
}
```

### UIKit

```swift
import UIKit
import LazyCaptcha

class ViewController: UIViewController {
    @IBAction func verifyTapped() {
        let config = LazyCaptchaConfig(siteKey: "YOUR_SITE_KEY")

        LazyCaptcha.presentChallenge(from: self, config: config) { result in
            switch result {
            case .success(let token):
                self.sendToServer(token)
            case .failure(.userCancelled):
                break
            case .failure(let error):
                self.showError(error)
            }
        }
    }
}
```

### Inline SwiftUI view (no sheet)

```swift
LazyCaptchaView(
    config: LazyCaptchaConfig(siteKey: "YOUR_SITE_KEY"),
    onVerify: { token in print(token) },
    onExpire: { print("expired") },
    onError: { err in print(err) }
)
.frame(height: 420)
```

## Configuration

```swift
LazyCaptchaConfig(
    siteKey: "YOUR_SITE_KEY",                                   // required
    baseURL: URL(string: "https://captcha.yourdomain.com")!,    // default: https://lazycaptcha.com
    type: .auto,                                                 // .auto, .imagePuzzle, .pow, .behavioral, .textMath
    theme: .light,                                               // .light, .dark, or .auto
    originDomain: nil                                            // override Origin header if needed
)
```

## Server-side verification

After receiving a token in the app, send it to your backend, which then calls the verification API:

```bash
curl -X POST https://your-lazycaptcha-instance.com/api/captcha/v1/verify \
    -H "Content-Type: application/json" \
    -d '{"secret": "YOUR_SECRET_KEY", "token": "token-from-app"}'
```

If you're using this SDK on a server (e.g., Vapor), the bundled `LazyCaptchaClient` handles this:

```swift
let client = LazyCaptchaClient(secretKey: Environment.get("LAZYCAPTCHA_SECRET")!)
let result = try await client.verify(token: token, remoteIP: request.peerAddress?.ipAddress)
guard result.success else { throw Abort(.badRequest) }
```

**Never bundle your secret key in the iOS app binary.** Keep it server-side only.

## How it works

The SDK presents a `WKWebView` that loads a minimal HTML page. That page loads your LazyCaptcha instance's widget script (`/api/captcha/v1/lazycaptcha.js`) and calls `LazyCaptcha.render()` to mount the challenge. When the user solves it, a JavaScript bridge (`window.webkit.messageHandlers.lazycaptcha`) posts the token back to native code, which resolves the completion handler.

The widget script is served from your instance — no extra third-party connections.

## Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## License

[MIT](LICENSE)
