import SwiftUI

@main
struct Cal_AIApp: App {
    // Core Data
    let persistenceController = PersistenceController.shared

    // App state
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - App State
final class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var selectedTab: Tab = .calendar

    private let userRepository = UserRepository.shared

    init() {
        isOnboardingComplete = userRepository.hasCompletedOnboarding()
    }

    func completeOnboarding() {
        isOnboardingComplete = true
    }

    enum Tab: Int, CaseIterable {
        case calendar = 0
        case tasks = 1
        case goals = 2
        case settings = 3

        var title: String {
            switch self {
            case .calendar: return "Calendar"
            case .tasks: return "Tasks"
            case .goals: return "Goals"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .tasks: return "checklist"
            case .goals: return "target"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .calendar: return "calendar"
            case .tasks: return "checklist"
            case .goals: return "target"
            case .settings: return "gearshape.fill"
            }
        }
    }
}
