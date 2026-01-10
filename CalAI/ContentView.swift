import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: Tab = .calendar

    enum Tab {
        case calendar
        case tasks
        case goals
        case settings
    }

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(Tab.tasks)

            GoalListView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(Tab.goals)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(Theme.primaryColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
        .environmentObject(SubscriptionManager())
}
