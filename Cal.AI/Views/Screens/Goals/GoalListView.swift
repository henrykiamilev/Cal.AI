import SwiftUI

struct GoalListView: View {
    @StateObject private var viewModel = GoalListViewModel()
    @State private var selectedGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight
                    .ignoresSafeArea()

                if viewModel.activeGoals.isEmpty && viewModel.completedGoals.isEmpty {
                    EmptyGoalsView {
                        viewModel.showNewGoalForm()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Summary card
                            if !viewModel.activeGoals.isEmpty {
                                GoalsSummaryCard(
                                    totalGoals: viewModel.totalActiveGoals,
                                    withAIPlan: viewModel.goalsWithAIPlan,
                                    averageProgress: viewModel.averageProgress
                                )
                                .padding(.horizontal)
                            }

                            // Active goals
                            if !viewModel.activeGoals.isEmpty {
                                SectionHeaderView(title: "Active Goals", count: viewModel.activeGoals.count)
                                    .padding(.horizontal)

                                ForEach(viewModel.activeGoals) { goal in
                                    GoalCard(goal: goal) {
                                        selectedGoal = goal
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Completed goals
                            if !viewModel.completedGoals.isEmpty {
                                SectionHeaderView(title: "Completed", count: viewModel.completedGoals.count)
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                ForEach(viewModel.completedGoals) { goal in
                                    CompactGoalCard(goal: goal) {
                                        selectedGoal = goal
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus") {
                            viewModel.showNewGoalForm()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingGoalForm) {
                GoalFormView { goal in
                    viewModel.createGoal(goal)
                }
            }
            .navigationDestination(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
        }
    }
}

struct GoalsSummaryCard: View {
    let totalGoals: Int
    let withAIPlan: Int
    let averageProgress: Double

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Progress")
                    .font(.headline)
                    .foregroundColor(.textDark)

                Text("\(totalGoals) active goals")
                    .font(.subheadline)
                    .foregroundColor(.textGray)

                if withAIPlan > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("\(withAIPlan) with AI plans")
                    }
                    .font(.caption)
                    .foregroundColor(.primaryBlue)
                }
            }

            Spacer()

            ProgressRing(
                progress: averageProgress,
                lineWidth: 8,
                size: 80,
                gradientColors: [.primaryBlue, .secondaryPurple]
            )
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SectionHeaderView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.textDark)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.primaryBlue)
                .clipShape(Capsule())

            Spacer()
        }
    }
}

struct EmptyGoalsView: View {
    let onAddGoal: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 70))
                .foregroundColor(.primaryBlue.opacity(0.5))

            VStack(spacing: 8) {
                Text("Set Your First Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textDark)

                Text("Define what you want to achieve and let our AI create a personalized plan to get you there.")
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            PrimaryButton("Create Goal", icon: "plus", action: onAddGoal)
                .frame(width: 180)
        }
    }
}

// MARK: - Preview
#Preview {
    GoalListView()
}
