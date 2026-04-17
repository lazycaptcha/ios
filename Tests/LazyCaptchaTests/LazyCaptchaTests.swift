import XCTest
@testable import LazyCaptcha

final class LazyCaptchaTests: XCTestCase {

    func testConfigDefaults() {
        let config = LazyCaptchaConfig(siteKey: "test-key")
        XCTAssertEqual(config.siteKey, "test-key")
        XCTAssertEqual(config.baseURL.absoluteString, "https://lazycaptcha.com")
        XCTAssertEqual(config.type, .auto)
        XCTAssertEqual(config.theme, .light)
    }

    func testConfigCustom() {
        let config = LazyCaptchaConfig(
            siteKey: "abc",
            baseURL: URL(string: "https://captcha.example.com")!,
            type: .imagePuzzle,
            theme: .dark
        )
        XCTAssertEqual(config.type.rawValue, "image_puzzle")
        XCTAssertEqual(config.theme.rawValue, "dark")
    }

    func testHTMLContainsSiteKey() {
        let config = LazyCaptchaConfig(siteKey: "my-site-key")
        let html = LazyCaptchaHTML.page(for: config)
        XCTAssertTrue(html.contains("\"my-site-key\""))
        XCTAssertTrue(html.contains("lazycaptcha.js"))
    }

    func testHTMLEscapesSiteKey() {
        let config = LazyCaptchaConfig(siteKey: "a\"b</script>c")
        let html = LazyCaptchaHTML.page(for: config)
        // Ensure we didn't accidentally inject unescaped script-breaking characters
        XCTAssertFalse(html.contains("a\"b</script>c"))
        XCTAssertTrue(html.contains("a\\\"b"))
    }

    func testClientBuildsCorrectURL() {
        let client = LazyCaptchaClient(
            secretKey: "secret",
            baseURL: URL(string: "https://captcha.example.com")!
        )
        XCTAssertEqual(client.baseURL.absoluteString, "https://captcha.example.com")
    }

    func testErrorEquality() {
        XCTAssertEqual(LazyCaptchaError.userCancelled, LazyCaptchaError.userCancelled)
        XCTAssertEqual(LazyCaptchaError.challengeFailed("x"), LazyCaptchaError.challengeFailed("x"))
        XCTAssertNotEqual(LazyCaptchaError.challengeFailed("a"), LazyCaptchaError.challengeFailed("b"))
    }
}
