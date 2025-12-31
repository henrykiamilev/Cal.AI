import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var apiKey: String = ""
    @Published var showingAPIKeyInput = false
    @Published var showingDeleteConfirmation = false
    @Published var isLoading = false

    // MARK: - Dependencies
    private let userRepository: UserRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var hasAPIKey: Bool {
        !AppConfiguration.openAIKey.isEmpty
    }

    var maskedAPIKey: String {
        let key = AppConfiguration.openAIKey
        guard key.count > 8 else { return key.isEmpty ? "Not set" : "****" }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
    }

    // MARK: - Initialization
    init(userRepository: UserRepository = .shared) {
        self.userRepository = userRepository

        loadProfile()
        setupBindings()
    }

    private func setupBindings() {
        userRepository.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$userProfile)
    }

    // MARK: - Profile Management
    func loadProfile() {
        userProfile = userRepository.getCurrentUser()
    }

    func updateProfile(_ profile: UserProfile) {
        userRepository.updateUser(profile)
        loadProfile()
    }

    // MARK: - API Key Management
    func saveAPIKey() {
        guard !apiKey.trimmed.isEmpty else { return }
        AppConfiguration.openAIKey = apiKey.trimmed
        apiKey = ""
        showingAPIKeyInput = false
        HapticManager.shared.success()
    }

    func removeAPIKey() {
        AppConfiguration.openAIKey = ""
        HapticManager.shared.warning()
    }

    // MARK: - Data Management
    func exportData() -> URL? {
        guard let data = userRepository.exportUserData() else { return nil }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("calai_export_\(Date().timeIntervalSince1970).json")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    func deleteAllData() {
        isLoading = true

        // Delete all Core Data
        PersistenceController.shared.deleteAllData()

        // Clear Keychain
        KeychainManager.shared.clearAll()

        // Clear user defaults
        UserDefaults.standard.removePersistentDomain(forName: Constants.App.bundleId)

        isLoading = false

        // Reload
        loadProfile()
    }
}
