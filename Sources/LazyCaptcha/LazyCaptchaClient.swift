import Foundation

/// Client for verifying tokens against your LazyCaptcha instance's server-side API.
///
/// **Important:** The `secretKey` must come from your backend or a secure store — never
/// bundle it in the app binary. This client is intended for use in server-side Swift
/// (e.g., Vapor) or trusted environments where the secret is managed securely.
public struct LazyCaptchaClient: Sendable {

    public struct VerifyResponse: Sendable, Decodable {
        public let success: Bool
        public let score: Double?
        public let hostname: String?
        public let challengeTimestamp: String?
        public let error: String?

        enum CodingKeys: String, CodingKey {
            case success
            case score
            case hostname
            case challengeTimestamp = "challenge_ts"
            case error
        }
    }

    public let secretKey: String
    public let baseURL: URL
    public let session: URLSession
    public let timeout: TimeInterval

    public init(
        secretKey: String,
        baseURL: URL = URL(string: "https://lazycaptcha.com")!,
        session: URLSession = .shared,
        timeout: TimeInterval = 5
    ) {
        self.secretKey = secretKey
        self.baseURL = baseURL
        self.session = session
        self.timeout = timeout
    }

    public func verify(token: String, remoteIP: String? = nil) async throws -> VerifyResponse {
        guard !token.isEmpty else {
            throw LazyCaptchaError.invalidConfiguration("token is empty")
        }

        let url = baseURL.appendingPathComponent("api/captcha/v1/verify")

        var body: [String: String] = ["secret": secretKey, "token": token]
        if let remoteIP { body["remote_ip"] = remoteIP }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw LazyCaptchaError.networkError("non-HTTP response")
            }
            guard (200...299).contains(http.statusCode) else {
                throw LazyCaptchaError.networkError("HTTP \(http.statusCode)")
            }
            return try JSONDecoder().decode(VerifyResponse.self, from: data)
        } catch let error as LazyCaptchaError {
            throw error
        } catch {
            throw LazyCaptchaError.networkError(error.localizedDescription)
        }
    }
}
