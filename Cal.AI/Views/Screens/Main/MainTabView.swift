import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var taskRepository = TaskRepository()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CalendarView()
                .tabItem {
                    Label(
                        AppState.Tab.calendar.title,
                        systemImage: appState.selectedTab == .calendar ?
                        AppState.Tab.calendar.selectedIcon : AppState.Tab.calendar.icon
                    )
                }
                .tag(AppState.Tab.calendar)

            TaskListView()
                .tabItem {
                    Label(
                        AppState.Tab.tasks.title,
                        systemImage: appState.selectedTab == .tasks ?
                        AppState.Tab.tasks.selectedIcon : AppState.Tab.tasks.icon
                    )
                }
                .tag(AppState.Tab.tasks)
                .badge(taskBadgeCount)

            GoalListView()
                .tabItem {
                    Label(
                        AppState.Tab.goals.title,
                        systemImage: appState.selectedTab == .goals ?
                        AppState.Tab.goals.selectedIcon : AppState.Tab.goals.icon
                    )
                }
                .tag(AppState.Tab.goals)

            SettingsView()
                .tabItem {
                    Label(
                        AppState.Tab.settings.title,
                        systemImage: appState.selectedTab == .settings ?
                        AppState.Tab.settings.selectedIcon : AppState.Tab.settings.icon
                    )
                }
                .tag(AppState.Tab.settings)
        }
        .tint(.primaryBlue)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private var taskBadgeCount: Int {
        let overdue = taskRepository.overdueCount()
        return overdue > 0 ? overdue : 0
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppState())
}
