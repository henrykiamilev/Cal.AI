import SwiftUI

struct GoalCard: View {
    let goal: Goal
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Category icon
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(goal.category.color)
                        .frame(width: 40, height: 40)
                        .background(goal.category.color.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textDark)
                            .lineLimit(1)

                        Text(goal.category.displayName)
                            .font(.caption)
                            .foregroundColor(.textGray)
                    }

                    Spacer()

                    // Progress ring
                    ProgressRing(
                        progress: goal.progress,
                        lineWidth: 4,
                        size: 40,
                        showPercentage: false,
                        gradientColors: [goal.category.color, goal.category.color.lighter()]
                    )
                }

                // Progress bar
                LinearProgressBar(
                    progress: goal.progress,
                    height: 6,
                    gradientColors: [goal.category.color, goal.category.color.lighter()],
                    showPercentage: false
                )

                // Footer
                HStack {
                    // Milestones
                    Label(
                        "\(goal.completedMilestones.count)/\(goal.milestones.count) milestones",
                        systemImage: "flag.fill"
                    )
                    .font(.caption)
                    .foregroundColor(.textGray)

                    Spacer()

                    // Target date
                    if let daysRemaining = goal.daysRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(daysRemaining > 0 ? "\(daysRemaining) days left" : "Due today")
                        }
                        .font(.caption)
                        .foregroundColor(daysRemaining < 7 ? .warningYellow : .textGray)
                    }

                    // AI badge
                    if goal.hasAIPlan {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("AI Plan")
                        }
                        .font(.caption)
                        .foregroundColor(.primaryBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryBlue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color.cardWhite)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactGoalCard: View {
    let goal: Goal
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Progress ring
                ProgressRing(
                    progress: goal.progress,
                    lineWidth: 4,
                    size: 44,
                    gradientColors: [goal.category.color, goal.category.color.lighter()]
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textDark)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(goal.category.displayName, systemImage: goal.category.icon)
                            .font(.caption)
                            .foregroundColor(.textGray)

                        if goal.hasAIPlan {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.primaryBlue)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
            .padding(12)
            .background(Color.cardWhite)
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    var goalColor: Color = .primaryBlue
    var onToggleComplete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Button(action: {
                HapticManager.shared.taskComplete()
                onToggleComplete?()
            }) {
                ZStack {
                    Circle()
                        .stroke(milestone.isCompleted ? goalColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if milestone.isCompleted {
                        Circle()
                            .fill(goalColor)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(milestone.orderIndex + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textGray)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(milestone.isCompleted ? .textGray : .textDark)
                    .strikethrough(milestone.isCompleted)

                HStack(spacing: 8) {
                    Label(milestone.targetDateFormatted, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(milestone.isOverdue ? .errorRed : .textGray)

                    if milestone.isAIGenerated {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                            Text("AI Generated")
                        }
                        .font(.caption2)
                        .foregroundColor(.primaryBlue)
                    }
                }
            }

            Spacer()

            if milestone.isOverdue && !milestone.isCompleted {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.errorRed)
            }
        }
        .padding(12)
        .background(milestone.isCompleted ? Color.gray.opacity(0.05) : Color.cardWhite)
        .cornerRadius(Constants.UI.smallCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                .stroke(milestone.isCompleted ? goalColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleGoal = Goal(
        title: "Become an Investment Banker",
        description: "Land a job at a top investment bank",
        targetDate: Date().adding(.month, value: 6),
        category: .career,
        progressPercentage: 35,
        milestones: [
            Milestone(title: "Complete Finance Certification", targetDate: Date().adding(.month, value: 1), isCompleted: true, isAIGenerated: true, orderIndex: 0),
            Milestone(title: "Build Financial Models", targetDate: Date().adding(.month, value: 2), isAIGenerated: true, orderIndex: 1),
            Milestone(title: "Network with Professionals", targetDate: Date().adding(.month, value: 3), isAIGenerated: true, orderIndex: 2)
        ]
    )

    ScrollView {
        VStack(spacing: 20) {
            GoalCard(goal: sampleGoal)
            CompactGoalCard(goal: sampleGoal)

            VStack(spacing: 12) {
                ForEach(sampleGoal.milestones) { milestone in
                    MilestoneCard(milestone: milestone, goalColor: sampleGoal.category.color)
                }
            }
        }
        .padding()
    }
}
