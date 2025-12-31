import Foundation
import CryptoKit

final class EncryptionManager {
    static let shared = EncryptionManager()

    private var symmetricKey: SymmetricKey?

    private init() {
        loadOrCreateKey()
    }

    // MARK: - Key Management
    private func loadOrCreateKey() {
        if let keyData = KeychainManager.shared.retrieve(forKey: Constants.StorageKeys.encryptionKey) {
            symmetricKey = SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            if KeychainManager.shared.store(data: keyData, forKey: Constants.StorageKeys.encryptionKey) {
                symmetricKey = newKey
            }
        }
    }

    private func getKey() throws -> SymmetricKey {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotFound
        }
        return key
    }

    // MARK: - Encrypt String
    func encrypt(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.encodingFailed
        }
        return try encryptData(data)
    }

    // MARK: - Decrypt String
    func decrypt(_ data: Data) throws -> String {
        let decryptedData = try decryptData(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decodingFailed
        }
        return string
    }

    // MARK: - Encrypt Data
    func encryptData(_ data: Data) throws -> Data {
        let key = try getKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    // MARK: - Decrypt Data
    func decryptData(_ data: Data) throws -> Data {
        let key = try getKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Encrypt Codable
    func encrypt<T: Encodable>(_ object: T) throws -> Data {
        let data = try JSONEncoder().encode(object)
        return try encryptData(data)
    }

    // MARK: - Decrypt Codable
    func decrypt<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decryptedData = try decryptData(data)
        return try JSONDecoder().decode(type, from: decryptedData)
    }

    // MARK: - Hash Data
    func hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Secure Random
    static func generateSecureRandomData(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, length, pointer.baseAddress!)
        }
        return data
    }

    static func generateSecureRandomString(length: Int) -> String {
        let data = generateSecureRandomData(length: length)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
            .description
    }

    // MARK: - Reset Key (Use with caution)
    func resetEncryptionKey() {
        KeychainManager.shared.delete(forKey: Constants.StorageKeys.encryptionKey)
        loadOrCreateKey()
    }
}

// MARK: - Encryption Errors
enum EncryptionError: LocalizedError {
    case keyNotFound
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "Encryption key not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        }
    }
}

// MARK: - Secure String Wrapper
@propertyWrapper
struct Encrypted {
    private var encryptedData: Data?

    var wrappedValue: String {
        get {
            guard let data = encryptedData else { return "" }
            return (try? EncryptionManager.shared.decrypt(data)) ?? ""
        }
        set {
            encryptedData = try? EncryptionManager.shared.encrypt(newValue)
        }
    }

    init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
}
