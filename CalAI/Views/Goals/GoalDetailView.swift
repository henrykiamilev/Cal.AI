import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var showingDeleteAlert = false
    @State private var showingAdjustSchedule = false
    @State private var selectedTab: GoalTab = .overview

    enum GoalTab: String, CaseIterable {
        case overview = "Overview"
        case schedule = "Schedule"
        case progress = "Progress"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                if goal.aiGeneratedSchedule != nil {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(GoalTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                }

                ScrollView {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .schedule:
                        scheduleContent
                    case .progress:
                        progressContent
                    }
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if goal.aiGeneratedSchedule != nil {
                            Button(action: { showingAdjustSchedule = true }) {
                                Label("Adjust Schedule", systemImage: "slider.horizontal.3")
                            }
                        }

                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
            .alert("Delete Goal", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    dataManager.deleteGoal(goal)
                    dismiss()
                }
            } message: {
                Text("This will also delete all associated events and tasks. This action cannot be undone.")
            }
        }
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            // Header
            HStack {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(goal.category.color)

                VStack(alignment: .leading) {
                    Text(goal.category.rawValue)
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    if let schedule = goal.aiGeneratedSchedule {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("AI-Powered")
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.primaryColor)
                    }
                }

                Spacer()

                if goal.isActive {
                    Text("Active")
                        .font(Theme.fontSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.successColor)
                        .cornerRadius(Theme.cornerRadiusSmall)
                }
            }

            // Progress
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Text("Overall Progress")
                        .font(Theme.fontSubheadline)
                    Spacer()
                    Text("\(Int(goal.calculatedProgress * 100))%")
                        .font(Theme.fontSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primaryColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.backgroundTertiary)
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.primaryGradient)
                            .frame(width: geometry.size.width * goal.calculatedProgress, height: 16)
                    }
                }
                .frame(height: 16)
            }
            .padding(Theme.spacingM)
            .background(Theme.backgroundSecondary)
            .cornerRadius(Theme.cornerRadiusMedium)

            // Description
            if !goal.description.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Description")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    Text(goal.description)
                        .font(Theme.fontBody)
                }
                .padding(Theme.spacingM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.backgroundSecondary)
                .cornerRadius(Theme.cornerRadiusMedium)
            }

            // Target Date
            if let targetDate = goal.targetDate {
                DetailRow(
                    icon: "flag",
                    title: "Target Date",
                    subtitle: targetDate.dateFormatted
                )
            }

            // Milestones
            if !goal.milestones.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    HStack {
                        Text("Milestones")
                            .font(Theme.fontSubheadline)
                        Spacer()
                        Text("\(goal.completedMilestones)/\(goal.milestones.count)")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)
                    }

                    ForEach(goal.milestones.sorted { $0.order < $1.order }) { milestone in
                        Button(action: {
                            dataManager.toggleMilestoneCompletion(goalId: goal.id, milestoneId: milestone.id)
                        }) {
                            HStack {
                                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(milestone.isCompleted ? Theme.successColor : Theme.textTertiary)

                                VStack(alignment: .leading) {
                                    Text(milestone.title)
                                        .font(Theme.fontBody)
                                        .foregroundColor(milestone.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                                        .strikethrough(milestone.isCompleted)

                                    if let date = milestone.targetDate {
                                        Text(date.dateFormatted)
                                            .font(Theme.fontSmall)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(Theme.spacingS)
                        .background(Color.white)
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }
                }
                .padding(Theme.spacingM)
                .background(Theme.backgroundSecondary)
                .cornerRadius(Theme.cornerRadiusMedium)
            }

            // AI Schedule info
            if let schedule = goal.aiGeneratedSchedule {
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.primaryGradient)
                        Text("AI Schedule")
                            .font(Theme.fontSubheadline)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Estimated Time")
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.textSecondary)
                            Text(schedule.estimatedTimeToGoal)
                                .font(Theme.fontBody)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Intensity")
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.textSecondary)
                            Text(schedule.difficultyLevel.rawValue)
                                .font(Theme.fontBody)
                        }
                    }
                }
                .padding(Theme.spacingM)
                .background(Theme.primaryColor.opacity(0.1))
                .cornerRadius(Theme.cornerRadiusMedium)
            }
        }
        .padding(Theme.spacingM)
    }

    private var scheduleContent: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            if let schedule = goal.aiGeneratedSchedule {
                ForEach(schedule.weeklySchedule.sorted { $0.dayOfWeek < $1.dayOfWeek }) { day in
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text(day.dayName)
                            .font(Theme.fontSubheadline)
                            .foregroundColor(Theme.primaryColor)

                        if day.activities.isEmpty {
                            Text("Rest day")
                                .font(Theme.fontCaption)
                                .foregroundColor(Theme.textSecondary)
                                .padding(Theme.spacingM)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(Theme.cornerRadiusSmall)
                        } else {
                            ForEach(day.activities) { activity in
                                ActivityRow(activity: activity) {
                                    dataManager.markActivityComplete(
                                        goalId: goal.id,
                                        dayOfWeek: day.dayOfWeek,
                                        activityId: activity.id
                                    )
                                }
                            }
                        }
                    }
                }

                // Recommendations
                if !schedule.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Tips for Success")
                            .font(Theme.fontSubheadline)

                        ForEach(schedule.recommendations, id: \.self) { rec in
                            HStack(alignment: .top, spacing: Theme.spacingS) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Theme.warningColor)
                                Text(rec)
                                    .font(Theme.fontCaption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.warningColor.opacity(0.1))
                    .cornerRadius(Theme.cornerRadiusMedium)
                }
            } else {
                EmptyStateView(
                    icon: "sparkles",
                    title: "No AI Schedule",
                    message: "Generate an AI schedule to get personalized activities"
                )
            }
        }
        .padding(Theme.spacingM)
    }

    private var progressContent: some View {
        GoalProgressView(goal: goal)
    }
}

#Preview {
    GoalDetailView(goal: Goal(
        title: "Become an Investment Banker",
        description: "Break into investment banking within the next year",
        category: .career,
        targetDate: Date().adding(months: 12),
        milestones: [
            Milestone(title: "Complete finance certifications", order: 0),
            Milestone(title: "Network with IB professionals", order: 1),
            Milestone(title: "Prepare for technical interviews", order: 2)
        ]
    ))
    .environmentObject(DataManager())
    .environmentObject(SubscriptionManager())
}
