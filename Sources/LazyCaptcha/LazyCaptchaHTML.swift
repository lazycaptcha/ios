import Foundation

/// Generates the HTML page loaded inside the WKWebView that renders the LazyCaptcha widget
/// and forwards results back to native code via window.webkit.messageHandlers.
enum LazyCaptchaHTML {
    static func page(for config: LazyCaptchaConfig) -> String {
        let scriptURL = config.baseURL
            .appendingPathComponent("api/captcha/v1/lazycaptcha.js")
            .absoluteString

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background: \(config.theme == .dark ? "#1a1a2e" : "#ffffff");
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                }
                body {
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 16px;
                    box-sizing: border-box;
                }
                .wrapper {
                    width: 100%;
                    max-width: 500px;
                }
            </style>
        </head>
        <body>
            <div class="wrapper">
                <div id="captcha-target"></div>
            </div>
            <script src="\(scriptURL)" async defer></script>
            <script>
                function post(type, payload) {
                    try {
                        window.webkit.messageHandlers.lazycaptcha.postMessage({ type: type, payload: payload });
                    } catch (e) {
                        // Bridge not available
                    }
                }

                (function waitForWidget() {
                    if (window.LazyCaptcha && typeof window.LazyCaptcha.render === 'function') {
                        try {
                            window.LazyCaptcha.render('#captcha-target', {
                                sitekey: \(jsString(config.siteKey)),
                                type: \(jsString(config.type.rawValue)),
                                theme: \(jsString(config.theme.rawValue)),
                                widget: \(jsString(config.widget.rawValue)),
                                width: \(jsOptionalString(config.width)),
                                callback: function(token) { post('verified', { token: token }); },
                                'expired-callback': function() { post('expired', null); },
                                'error-callback': function(err) {
                                    post('error', { message: (err && err.message) || String(err) });
                                }
                            });
                            post('ready', null);
                        } catch (e) {
                            post('error', { message: e.message || String(e) });
                        }
                    } else {
                        setTimeout(waitForWidget, 50);
                    }
                })();

                setTimeout(function() {
                    if (!window.LazyCaptcha) {
                        post('error', { message: 'Widget script failed to load' });
                    }
                }, 10000);
            </script>
        </body>
        </html>
        """
    }

    /// Safely escape a string for embedding in JavaScript.
    private static func jsString(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: [value],
            options: [.fragmentsAllowed]
        ),
        let json = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        // Strip the array brackets to get just the quoted string
        let trimmed = json.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        return trimmed
    }

    private static func jsOptionalString(_ value: String?) -> String {
        guard let value else { return "null" }
        return jsString(value)
    }
}
