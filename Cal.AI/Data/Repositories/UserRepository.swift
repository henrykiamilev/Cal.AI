import Foundation
import CoreData
import Combine

protocol UserRepositoryProtocol {
    func getCurrentUser() -> UserProfile?
    func createUser(_ profile: UserProfile) -> UserProfile?
    func updateUser(_ profile: UserProfile) -> Bool
    func deleteUser() -> Bool
    func hasCompletedOnboarding() -> Bool
    func markOnboardingComplete() -> Bool
}

final class UserRepository: UserRepositoryProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    private let persistenceController: PersistenceController

    @Published var currentUser: UserProfile?

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.persistenceController = PersistenceController.shared
        loadCurrentUser()
    }

    // MARK: - Load Current User
    private func loadCurrentUser() {
        currentUser = getCurrentUser()
    }

    func refresh() {
        loadCurrentUser()
    }

    // MARK: - Get Current User
    func getCurrentUser() -> UserProfile? {
        let request = CDUserProfile.fetchRequest()
        request.fetchLimit = 1

        do {
            if let cdProfile = try context.fetch(request).first {
                return UserProfile(from: cdProfile)
            }
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
        return nil
    }

    // MARK: - Create User
    @discardableResult
    func createUser(_ profile: UserProfile) -> UserProfile? {
        // Delete existing profile first (only one user)
        deleteUser()

        let cdProfile = profile.toCoreData(in: context)

        do {
            try context.save()
            refresh()
            return UserProfile(from: cdProfile)
        } catch {
            print("Failed to create user profile: \(error)")
            context.rollback()
            return nil
        }
    }

    // MARK: - Update User
    @discardableResult
    func updateUser(_ profile: UserProfile) -> Bool {
        let request = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdProfile = try context.fetch(request).first {
                profile.updateCoreData(cdProfile)
                try context.save()
                refresh()
                return true
            } else {
                // Profile doesn't exist, create it
                return createUser(profile) != nil
            }
        } catch {
            print("Failed to update user profile: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Delete User
    @discardableResult
    func deleteUser() -> Bool {
        let request = CDUserProfile.fetchRequest()

        do {
            let profiles = try context.fetch(request)
            for profile in profiles {
                context.delete(profile)
            }
            try context.save()
            currentUser = nil
            return true
        } catch {
            print("Failed to delete user profile: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Onboarding Status
    func hasCompletedOnboarding() -> Bool {
        currentUser?.hasCompletedOnboarding ?? false
    }

    @discardableResult
    func markOnboardingComplete() -> Bool {
        guard var user = currentUser else { return false }
        user.hasCompletedOnboarding = true
        return updateUser(user)
    }

    // MARK: - Avatar Management
    func updateAvatar(_ imageData: Data?) -> Bool {
        guard var user = currentUser else { return false }
        user.avatarData = imageData
        return updateUser(user)
    }

    func removeAvatar() -> Bool {
        updateAvatar(nil)
    }

    // MARK: - Interests Management
    func addInterest(_ interest: String) -> Bool {
        guard var user = currentUser else { return false }
        user.addInterest(interest)
        return updateUser(user)
    }

    func removeInterest(_ interest: String) -> Bool {
        guard var user = currentUser else { return false }
        user.removeInterest(interest)
        return updateUser(user)
    }

    func updateInterests(_ interests: [String]) -> Bool {
        guard var user = currentUser else { return false }
        user.interests = interests
        return updateUser(user)
    }

    // MARK: - Availability Management
    func updateWeeklyHours(_ hours: Double) -> Bool {
        guard var user = currentUser else { return false }
        user.weeklyAvailableHours = hours
        return updateUser(user)
    }

    func updatePreferredTimes(_ times: [TimeRange]) -> Bool {
        guard var user = currentUser else { return false }
        user.preferredWorkTimes = times
        return updateUser(user)
    }

    // MARK: - Profile Validation
    func isProfileComplete() -> Bool {
        guard let user = currentUser else { return false }
        return !user.name.isEmpty
    }

    // MARK: - Data Export (for privacy)
    func exportUserData() -> Data? {
        guard let user = currentUser else { return nil }
        return try? JSONEncoder().encode(user)
    }
}

// MARK: - Singleton Access
extension UserRepository {
    static let shared = UserRepository()
}
