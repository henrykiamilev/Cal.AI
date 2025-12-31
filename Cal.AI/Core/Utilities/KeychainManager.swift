import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let serviceName = Constants.App.bundleId

    private init() {}

    // MARK: - Store Data
    func store(data: Data, forKey key: String) -> Bool {
        // Delete existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func store(string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return store(data: data, forKey: key)
    }

    // MARK: - Retrieve Data
    func retrieve(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func retrieveString(forKey key: String) -> String? {
        guard let data = retrieve(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete Data
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check Existence
    func exists(forKey key: String) -> Bool {
        retrieve(forKey: key) != nil
    }

    // MARK: - Update Data
    func update(data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            return store(data: data, forKey: key)
        }

        return status == errSecSuccess
    }
}

// MARK: - Codable Support
extension KeychainManager {
    func store<T: Encodable>(_ object: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(object) else { return false }
        return store(data: data, forKey: key)
    }

    func retrieve<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = retrieve(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
