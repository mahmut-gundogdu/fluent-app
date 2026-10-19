import FluentCore
import Foundation
import Security

public struct KeychainError: Error, LocalizedError {
    public let status: OSStatus

    public var errorDescription: String? {
        SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)"
    }
}

/// Stores API keys as generic-password items in the login keychain,
/// one item per provider (account = provider id).
public struct KeychainSecretStore: SecretStore {
    private let service: String

    public init(service: String = Bundle.main.bundleIdentifier ?? "com.alfonsobries.fluent") {
        self.service = service
    }

    public func secret(for account: String) -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard
            SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    public func setSecret(_ secret: String, for account: String) throws {
        // Skip unchanged values so settings saves don't touch the keychain needlessly.
        guard secret != (self.secret(for: account) ?? "") else { return }

        let query = baseQuery(for: account)

        if secret.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError(status: status)
            }
            return
        }

        let data = Data(secret.utf8)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var attributes = query
            attributes[kSecValueData as String] = data
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
        default:
            throw KeychainError(status: updateStatus)
        }
    }

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
