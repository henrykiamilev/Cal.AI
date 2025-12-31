import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .welcome
    @Published var name: String = ""
    @Published var occupation: String = ""
    @Published var selectedInterests: Set<String> = []
    @Published var weeklyHours: Double = 10
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let userRepository: UserRepository

    // MARK: - Computed Properties
    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .profile:
            return !name.trimmed.isEmpty
        case .interests:
            return !selectedInterests.isEmpty
        case .availability:
            return weeklyHours > 0
        case .notifications:
            return true
        }
    }

    var isLastStep: Bool {
        currentStep == .notifications
    }

    // MARK: - Initialization
    init(userRepository: UserRepository = .shared) {
        self.userRepository = userRepository
    }

    // MARK: - Navigation
    func next() {
        guard canProceed else { return }

        if let nextStep = currentStep.next {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
        } else {
            completeOnboarding()
        }
    }

    func back() {
        if let previousStep = currentStep.previous {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = previousStep
            }
        }
    }

    func skip() {
        next()
    }

    // MARK: - Interests
    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
        HapticManager.shared.selection()
    }

    // MARK: - Complete Onboarding
    func completeOnboarding() {
        isLoading = true

        let profile = UserProfile(
            name: name.trimmed,
            occupation: occupation.trimmed.isEmpty ? nil : occupation.trimmed,
            interests: Array(selectedInterests),
            weeklyAvailableHours: weeklyHours,
            hasCompletedOnboarding: true
        )

        if userRepository.createUser(profile) == nil {
            errorMessage = "Failed to save profile. Please try again."
        }

        isLoading = false
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profile = 1
    case interests = 2
    case availability = 3
    case notifications = 4

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "Your Profile"
        case .interests: return "Your Interests"
        case .availability: return "Availability"
        case .notifications: return "Stay Updated"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your AI-powered calendar assistant"
        case .profile:
            return "Tell us a bit about yourself"
        case .interests:
            return "Select your areas of interest"
        case .availability:
            return "How much time can you dedicate to goals?"
        case .notifications:
            return "Never miss an important task"
        }
    }
}
