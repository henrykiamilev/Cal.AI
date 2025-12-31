import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                MainTabView()
            } else {
                OnboardingContainerView(isComplete: $appState.isOnboardingComplete)
            }
        }
        .animation(.easeInOut, value: appState.isOnboardingComplete)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppState())
}
