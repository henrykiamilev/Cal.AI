import SwiftUI

struct GoalProgressView: View {
    @EnvironmentObject var dataManager: DataManager

    let goal: Goal

    private var completedActivities: [ScheduledActivity] {
        dataManager.getCompletedActivities(for: goal.id)
    }

    private var missedActivities: [ScheduledActivity] {
        dataManager.getMissedActivities(for: goal.id)
    }

    private var completionRate: Double {
        let total = completedActivities.count + missedActivities.count
        guard total > 0 else { return 0 }
        return Double(completedActivities.count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            // Stats Overview
            HStack(spacing: Theme.spacingM) {
                StatCard(
                    title: "Completion Rate",
                    value: "\(Int(completionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: Theme.primaryColor
                )

                StatCard(
                    title: "Activities Done",
                    value: "\(completedActivities.count)",
                    icon: "checkmark.circle.fill",
                    color: Theme.successColor
                )
            }

            HStack(spacing: Theme.spacingM) {
                StatCard(
                    title: "Missed",
                    value: "\(missedActivities.count)",
                    icon: "xmark.circle.fill",
                    color: Theme.errorColor
                )

                StatCard(
                    title: "Milestones",
                    value: "\(goal.completedMilestones)/\(goal.milestones.count)",
                    icon: "flag.fill",
                    color: Theme.warningColor
                )
            }

            // Weekly Progress Chart
            if let schedule = goal.aiGeneratedSchedule {
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    Text("This Week's Progress")
                        .font(Theme.fontSubheadline)

                    HStack(spacing: Theme.spacingS) {
                        ForEach(schedule.weeklySchedule.sorted { $0.dayOfWeek < $1.dayOfWeek }) { day in
                            let completed = day.activities.filter { $0.isCompleted }.count
                            let total = day.activities.count

                            VStack(spacing: 4) {
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.backgroundTertiary)
                                        .frame(width: 30, height: 80)

                                    if total > 0 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Theme.primaryGradient)
                                            .frame(width: 30, height: 80 * CGFloat(completed) / CGFloat(total))
                                    }
                                }

                                Text(String(day.dayName.prefix(1)))
                                    .font(Theme.fontSmall)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Theme.spacingM)
                .background(Theme.backgroundSecondary)
                .cornerRadius(Theme.cornerRadiusMedium)
            }

            // Recent Activity
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Recent Completed Activities")
                    .font(Theme.fontSubheadline)

                if completedActivities.isEmpty {
                    Text("No activities completed yet")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusSmall)
                } else {
                    ForEach(completedActivities.prefix(5)) { activity in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.successColor)

                            VStack(alignment: .leading) {
                                Text(activity.title)
                                    .font(Theme.fontBody)

                                if let completedAt = activity.completedAt {
                                    Text(completedAt.relativeFormatted)
                                        .font(Theme.fontSmall)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(Theme.spacingS)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }
                }
            }

            // Streak info (if applicable)
            if completedActivities.count > 0 {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Keep it up!")
                            .font(Theme.fontSubheadline)
                    }

                    Text("You're making great progress on your goal. Consistency is key!")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.orange.opacity(0.1), .red.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(Theme.cornerRadiusMedium)
            }
        }
        .padding(Theme.spacingM)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(Theme.fontSmall)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundSecondary)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

#Preview {
    GoalProgressView(goal: Goal(
        title: "Test Goal",
        category: .career
    ))
    .environmentObject(DataManager())
}
