import Foundation

enum AppConfiguration {
    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production
    }

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    // MARK: - API Configuration
    static var openAIBaseURL: String {
        "https://api.openai.com/v1"
    }

    static var openAIModel: String {
        "gpt-4"
    }

    // API key should be stored in Keychain, this is a fallback for setup
    static var openAIKey: String {
        get {
            KeychainManager.shared.retrieveString(forKey: Constants.StorageKeys.apiKey) ?? ""
        }
        set {
            KeychainManager.shared.store(string: newValue, forKey: Constants.StorageKeys.apiKey)
        }
    }

    // MARK: - Feature Flags
    static var isAIEnabled: Bool {
        !openAIKey.isEmpty
    }

    static var isDebugModeEnabled: Bool {
        current == .development
    }

    static var shouldLogNetworkRequests: Bool {
        current == .development
    }

    // MARK: - App Settings
    static var defaultWeeklyAvailableHours: Double {
        10.0
    }

    static var minimumAppVersion: String {
        "1.0.0"
    }
}

// MARK: - API Endpoints
extension AppConfiguration {
    enum Endpoints {
        static var chatCompletions: String {
            "\(openAIBaseURL)/chat/completions"
        }
    }
}
