import SwiftUI

struct GoalListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal?
    @State private var showingSubscription = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if dataManager.goals.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "Set Your Goals",
                        message: "Define your goals and let our AI create a personalized schedule to help you achieve them",
                        buttonTitle: "Add Goal",
                        action: { showingAddGoal = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Theme.spacingM) {
                            // AI Feature Banner (if not premium)
                            if !subscriptionManager.isPremium {
                                aiBanner
                            }

                            // Active Goals
                            if !dataManager.activeGoals.isEmpty {
                                SectionHeader(title: "Active Goals")

                                ForEach(dataManager.activeGoals) { goal in
                                    GoalCard(goal: goal) {
                                        selectedGoal = goal
                                    }
                                }
                            }

                            // Completed Goals
                            let completedGoals = dataManager.goals.filter { !$0.isActive }
                            if !completedGoals.isEmpty {
                                SectionHeader(title: "Completed")

                                ForEach(completedGoals) { goal in
                                    GoalCard(goal: goal) {
                                        selectedGoal = goal
                                    }
                                    .opacity(0.7)
                                }
                            }
                        }
                        .padding(Theme.spacingM)
                    }
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }

    private var aiBanner: some View {
        Button(action: { showingSubscription = true }) {
            HStack(spacing: Theme.spacingM) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.premiumGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock AI Schedule Maker")
                        .font(Theme.fontSubheadline)
                        .foregroundColor(Theme.textPrimary)

                    Text("Get personalized schedules to achieve your goals faster")
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(Theme.spacingM)
            .background(
                LinearGradient(
                    colors: [Theme.primaryColor.opacity(0.1), Theme.secondaryColor.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(Theme.primaryColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalListView()
        .environmentObject(DataManager())
        .environmentObject(SubscriptionManager())
}
