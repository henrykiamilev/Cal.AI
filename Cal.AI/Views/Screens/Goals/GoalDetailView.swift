import SwiftUI

struct GoalDetailView: View {
    @StateObject private var viewModel: GoalDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    init(goal: Goal) {
        _viewModel = StateObject(wrappedValue: GoalDetailViewModel(goal: goal))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                GoalHeaderCard(goal: viewModel.goal)

                // AI Plan section
                if viewModel.hasAIPlan, let schedule = viewModel.goal.aiSchedule {
                    AIScheduleCard(
                        schedule: schedule,
                        goal: viewModel.goal,
                        onViewDetails: {
                            viewModel.showingAISchedule = true
                        },
                        onTaskTap: { task in
                            if task.isCompleted {
                                viewModel.markTaskIncomplete(task.id)
                            } else {
                                viewModel.markTaskComplete(task.id)
                            }
                        }
                    )
                    .padding(.horizontal)
                } else {
                    GeneratePlanCard(
                        isGenerating: viewModel.isGeneratingPlan,
                        isEnabled: viewModel.canGeneratePlan
                    ) {
                        Task {
                            await viewModel.generateAIPlan()
                        }
                    }
                    .padding(.horizontal)
                }

                // Milestones
                MilestonesSection(
                    milestones: viewModel.goal.milestones,
                    goalColor: viewModel.goal.category.color,
                    onToggle: { milestone in
                        viewModel.toggleMilestoneComplete(milestone.id)
                    }
                )
                .padding(.horizontal)

                // Actions
                GoalActionsSection(
                    hasAIPlan: viewModel.hasAIPlan,
                    shouldAdjust: viewModel.shouldShowAdjustButton,
                    isLoading: viewModel.isGeneratingPlan,
                    onAdjust: {
                        Task {
                            await viewModel.adjustSchedule()
                        }
                    },
                    onAnalyze: {
                        Task {
                            await viewModel.analyzeProgress()
                        }
                    },
                    onEdit: {
                        viewModel.showingEditForm = true
                    },
                    onDelete: {
                        showingDeleteConfirmation = true
                    }
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.backgroundLight)
        .navigationTitle(viewModel.goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(viewModel.isGeneratingPlan, message: "Generating AI Plan...")
        .sheet(isPresented: $viewModel.showingAISchedule) {
            if let schedule = viewModel.goal.aiSchedule {
                AIScheduleDetailView(
                    schedule: schedule,
                    goal: viewModel.goal,
                    onTaskComplete: { taskId in
                        viewModel.markTaskComplete(taskId)
                    },
                    onTaskIncomplete: { taskId in
                        viewModel.markTaskIncomplete(taskId)
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingEditForm) {
            GoalFormView(goal: viewModel.goal) { updatedGoal in
                // Handle update
            }
        }
        .alert("Delete Goal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteGoal()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this goal? All milestones and AI plans will be removed.")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct GoalHeaderCard: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Category icon
                Image(systemName: goal.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(goal.category.color)
                    .frame(width: 56, height: 56)
                    .background(goal.category.color.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.category.displayName)
                        .font(.caption)
                        .foregroundColor(.textGray)

                    if let description = goal.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.textDark)
                            .lineLimit(2)
                    }
                }

                Spacer()

                ProgressRing(
                    progress: goal.progress,
                    lineWidth: 6,
                    size: 70,
                    gradientColors: [goal.category.color, goal.category.color.lighter()]
                )
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                LinearProgressBar(
                    progress: goal.progress,
                    height: 8,
                    gradientColors: [goal.category.color, goal.category.color.lighter()]
                )

                HStack {
                    Text("\(goal.completedMilestones.count) of \(goal.milestones.count) milestones")
                        .font(.caption)
                        .foregroundColor(.textGray)

                    Spacer()

                    if let daysRemaining = goal.daysRemaining {
                        Text("\(daysRemaining) days left")
                            .font(.caption)
                            .foregroundColor(daysRemaining < 7 ? .warningYellow : .textGray)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct GeneratePlanCard: View {
    let isGenerating: Bool
    let isEnabled: Bool
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.primaryBlue)

            VStack(spacing: 8) {
                Text("AI-Powered Planning")
                    .font(.headline)
                    .foregroundColor(.textDark)

                Text("Let our AI create a personalized schedule to help you achieve this goal faster.")
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                "Generate AI Plan",
                icon: "sparkles",
                isLoading: isGenerating,
                isDisabled: !isEnabled,
                action: onGenerate
            )
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MilestonesSection: View {
    let milestones: [Milestone]
    let goalColor: Color
    var onToggle: ((Milestone) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.headline)
                .foregroundColor(.textDark)

            if milestones.isEmpty {
                Text("No milestones yet. Generate an AI plan to get started.")
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.backgroundLight)
                    .cornerRadius(Constants.UI.smallCornerRadius)
            } else {
                ForEach(milestones) { milestone in
                    MilestoneCard(
                        milestone: milestone,
                        goalColor: goalColor
                    ) {
                        onToggle?(milestone)
                    }
                }
            }
        }
    }
}

struct GoalActionsSection: View {
    let hasAIPlan: Bool
    let shouldAdjust: Bool
    let isLoading: Bool
    let onAdjust: () -> Void
    let onAnalyze: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if hasAIPlan && shouldAdjust {
                SecondaryButton("Adjust Schedule", icon: "arrow.triangle.2.circlepath", action: onAdjust)
            }

            HStack(spacing: 12) {
                SecondaryButton("Edit", icon: "pencil", action: onEdit)
                DestructiveButton("Delete", icon: "trash", action: onDelete)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GoalDetailView(goal: Goal(
            title: "Become Investment Banker",
            description: "Land a job at a top investment bank",
            targetDate: Date().adding(.month, value: 6),
            category: .career,
            progressPercentage: 25,
            milestones: [
                Milestone(title: "Complete Finance Course", targetDate: Date().adding(.month, value: 1), isCompleted: true, orderIndex: 0),
                Milestone(title: "Build Network", targetDate: Date().adding(.month, value: 2), orderIndex: 1)
            ]
        ))
    }
}
