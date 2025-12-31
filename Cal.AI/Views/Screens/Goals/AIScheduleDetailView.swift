import SwiftUI

struct AIScheduleDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let schedule: AISchedule
    let goal: Goal
    var onTaskComplete: ((UUID) -> Void)?
    var onTaskIncomplete: ((UUID) -> Void)?

    @State private var expandedPhaseId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview card
                    ScheduleOverviewCard(schedule: schedule, goal: goal)
                        .padding(.horizontal)

                    // Progress chart
                    ProgressOverviewSection(schedule: schedule, goal: goal)
                        .padding(.horizontal)

                    // Phases
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Phases")
                            .font(.headline)
                            .foregroundColor(.textDark)
                            .padding(.horizontal)

                        ForEach(schedule.phases) { phase in
                            AIPhaseCard(
                                phase: phase,
                                goalColor: goal.category.color,
                                isExpanded: expandedPhaseId == phase.id
                            ) { task in
                                if task.isCompleted {
                                    onTaskIncomplete?(task.id)
                                } else {
                                    onTaskComplete?(task.id)
                                }
                            }
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    if expandedPhaseId == phase.id {
                                        expandedPhaseId = nil
                                    } else {
                                        expandedPhaseId = phase.id
                                    }
                                }
                            }
                        }
                    }

                    // Adjustment history
                    if !schedule.adjustmentHistory.isEmpty {
                        AdjustmentHistorySection(adjustments: schedule.adjustmentHistory)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.backgroundLight)
            .navigationTitle("AI Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScheduleOverviewCard: View {
    let schedule: AISchedule
    let goal: Goal

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Progress")
                        .font(.headline)
                        .foregroundColor(.textDark)

                    Text("\(schedule.completedTasks) of \(schedule.totalTasks) tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.textGray)
                }

                Spacer()

                ProgressRing(
                    progress: schedule.overallProgress,
                    lineWidth: 8,
                    size: 70,
                    gradientColors: [goal.category.color, goal.category.color.lighter()]
                )
            }

            // Stats row
            HStack(spacing: 0) {
                StatItem(
                    icon: "clock",
                    value: "\(Int(schedule.weeklyCommitmentHours))h",
                    label: "Weekly"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "calendar",
                    value: "\(schedule.daysRemaining)",
                    label: "Days Left"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "flag",
                    value: "\(schedule.phases.count)",
                    label: "Phases"
                )

                if !schedule.isOnTrack {
                    Divider()
                        .frame(height: 40)

                    StatItem(
                        icon: "exclamationmark.triangle",
                        value: "\(schedule.overdueTasks.count)",
                        label: "Overdue",
                        valueColor: .errorRed
                    )
                }
            }
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    var valueColor: Color = .textDark

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.textGray)

            Text(value)
                .font(.headline)
                .foregroundColor(valueColor)

            Text(label)
                .font(.caption2)
                .foregroundColor(.textGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProgressOverviewSection: View {
    let schedule: AISchedule
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(.textDark)

            if schedule.tasksForToday.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)

                    Text("No tasks scheduled for today")
                        .font(.subheadline)
                        .foregroundColor(.textGray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.successGreen.opacity(0.1))
                .cornerRadius(Constants.UI.smallCornerRadius)
            } else {
                ForEach(schedule.tasksForToday) { task in
                    AITaskRow(task: task, goalColor: goal.category.color)
                }
            }

            // Upcoming tasks
            if !schedule.upcomingTasks.isEmpty {
                Text("Coming Up")
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .padding(.top, 8)

                ForEach(schedule.upcomingTasks.prefix(3)) { task in
                    AITaskRow(task: task, goalColor: goal.category.color)
                }
            }
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct AdjustmentHistorySection: View {
    let adjustments: [AISchedule.Adjustment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule Adjustments")
                .font(.headline)
                .foregroundColor(.textDark)

            ForEach(adjustments) { adjustment in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryBlue)
                        .frame(width: 24, height: 24)
                        .background(Color.primaryBlue.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(adjustment.reason.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textDark)

                        Text(adjustment.description)
                            .font(.caption)
                            .foregroundColor(.textGray)

                        Text(adjustment.date.relativeDateString)
                            .font(.caption2)
                            .foregroundColor(.textGray)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Preview
#Preview {
    let sampleSchedule = AISchedule(
        phases: [
            AISchedule.Phase(
                title: "Foundation",
                description: "Build core knowledge",
                startDate: Date(),
                endDate: Date().adding(.month, value: 1),
                tasks: [
                    AISchedule.ScheduledTask(title: "Complete course", scheduledDate: Date(), durationMinutes: 60),
                    AISchedule.ScheduledTask(title: "Read book", scheduledDate: Date().adding(.day, value: 2), durationMinutes: 45)
                ]
            )
        ],
        weeklyCommitmentHours: 10,
        estimatedCompletionDate: Date().adding(.month, value: 3)
    )

    AIScheduleDetailView(
        schedule: sampleSchedule,
        goal: Goal(title: "Test Goal", category: .career)
    )
}
