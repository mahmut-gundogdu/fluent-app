import Foundation

public protocol SecretStore {
    func secret(for account: String) -> String?
    /// Stores the secret; an empty string removes it.
    func setSecret(_ secret: String, for account: String) throws
}

public final class InMemorySecretStore: SecretStore {
    private var secrets: [String: String]

    public init(secrets: [String: String] = [:]) {
        self.secrets = secrets
    }

    public func secret(for account: String) -> String? {
        secrets[account]
    }

    public func setSecret(_ secret: String, for account: String) throws {
        secrets[account] = secret.isEmpty ? nil : secret
    }
}
