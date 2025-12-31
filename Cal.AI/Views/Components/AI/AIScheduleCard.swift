import SwiftUI

struct AIScheduleCard: View {
    let schedule: AISchedule
    let goal: Goal
    var onViewDetails: (() -> Void)? = nil
    var onTaskTap: ((AISchedule.ScheduledTask) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryBlue)

                    Text("AI Schedule")
                        .font(.headline)
                        .foregroundColor(.textDark)
                }

                Spacer()

                if let onViewDetails = onViewDetails {
                    Button(action: onViewDetails) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.primaryBlue)
                    }
                }
            }

            // Progress overview
            HStack(spacing: 20) {
                ProgressRing(
                    progress: schedule.overallProgress,
                    lineWidth: 6,
                    size: 60,
                    gradientColors: [goal.category.color, goal.category.color.lighter()]
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(schedule.completedTasks) of \(schedule.totalTasks) tasks")
                        .font(.subheadline)
                        .foregroundColor(.textDark)

                    Text("\(schedule.daysRemaining) days remaining")
                        .font(.caption)
                        .foregroundColor(.textGray)

                    if !schedule.isOnTrack {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("\(schedule.overdueTasks.count) overdue")
                        }
                        .font(.caption)
                        .foregroundColor(.warningYellow)
                    }
                }

                Spacer()
            }

            // Current phase
            if let currentPhase = schedule.currentPhase {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Phase")
                        .font(.caption)
                        .foregroundColor(.textGray)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentPhase.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textDark)

                            LinearProgressBar(
                                progress: currentPhase.progress,
                                height: 4,
                                gradientColors: [goal.category.color, goal.category.color.lighter()]
                            )
                        }

                        Text("\(Int(currentPhase.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.textGray)
                    }
                }
                .padding(12)
                .background(Color.backgroundLight)
                .cornerRadius(Constants.UI.smallCornerRadius)
            }

            // Today's tasks
            if !schedule.tasksForToday.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Tasks")
                        .font(.caption)
                        .foregroundColor(.textGray)

                    ForEach(schedule.tasksForToday.prefix(3)) { task in
                        AITaskRow(task: task, goalColor: goal.category.color) {
                            onTaskTap?(task)
                        }
                    }
                }
            } else if let nextTask = schedule.nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Task")
                        .font(.caption)
                        .foregroundColor(.textGray)

                    AITaskRow(task: nextTask, goalColor: goal.category.color) {
                        onTaskTap?(nextTask)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct AITaskRow: View {
    let task: AISchedule.ScheduledTask
    let goalColor: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? goalColor : .textGray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(task.isCompleted ? .textGray : .textDark)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(task.durationFormatted, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.textGray)

                        if task.isOverdue {
                            Text("Overdue")
                                .font(.caption)
                                .foregroundColor(.errorRed)
                        }
                    }
                }

                Spacer()

                Text(task.scheduledDateFormatted)
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
            .padding(10)
            .background(task.isCompleted ? Color.gray.opacity(0.05) : goalColor.opacity(0.05))
            .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIPhaseCard: View {
    let phase: AISchedule.Phase
    let goalColor: Color
    var isExpanded: Bool = false
    var onTaskTap: ((AISchedule.ScheduledTask) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if phase.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                        } else if phase.isActive {
                            Circle()
                                .fill(goalColor)
                                .frame(width: 10, height: 10)
                        } else {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 10, height: 10)
                        }

                        Text(phase.title)
                            .font(.headline)
                            .foregroundColor(phase.isCompleted ? .textGray : .textDark)
                    }

                    Text(phase.dateRangeFormatted)
                        .font(.caption)
                        .foregroundColor(.textGray)
                }

                Spacer()

                Text("\(Int(phase.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(goalColor)
            }

            // Progress bar
            LinearProgressBar(
                progress: phase.progress,
                height: 4,
                gradientColors: [goalColor, goalColor.lighter()]
            )

            // Description
            Text(phase.description)
                .font(.subheadline)
                .foregroundColor(.textGray)
                .lineLimit(isExpanded ? nil : 2)

            // Tasks (if expanded)
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(phase.tasks) { task in
                        AITaskRow(task: task, goalColor: goalColor) {
                            onTaskTap?(task)
                        }
                    }
                }
            } else {
                // Task summary
                HStack {
                    Label(
                        "\(phase.completedTasks.count)/\(phase.tasks.count) tasks",
                        systemImage: "checklist"
                    )
                    .font(.caption)
                    .foregroundColor(.textGray)

                    Spacer()

                    if phase.isActive {
                        Text("In Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(goalColor)
                    }
                }
            }
        }
        .padding()
        .background(phase.isActive ? goalColor.opacity(0.05) : Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(phase.isActive ? goalColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleSchedule = AISchedule(
        phases: [
            AISchedule.Phase(
                title: "Foundation",
                description: "Build fundamental knowledge and skills",
                startDate: Date(),
                endDate: Date().adding(.month, value: 1),
                tasks: [
                    AISchedule.ScheduledTask(title: "Complete online course", scheduledDate: Date(), durationMinutes: 120),
                    AISchedule.ScheduledTask(title: "Read industry book", scheduledDate: Date().adding(.day, value: 2), durationMinutes: 60)
                ]
            )
        ],
        weeklyCommitmentHours: 10,
        estimatedCompletionDate: Date().adding(.month, value: 3)
    )

    let sampleGoal = Goal(
        title: "Become Investment Banker",
        category: .career,
        progressPercentage: 25,
        aiSchedule: sampleSchedule
    )

    ScrollView {
        VStack(spacing: 20) {
            AIScheduleCard(schedule: sampleSchedule, goal: sampleGoal)

            AIPhaseCard(
                phase: sampleSchedule.phases[0],
                goalColor: sampleGoal.category.color,
                isExpanded: true
            )
        }
        .padding()
    }
}
