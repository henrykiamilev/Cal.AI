import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.primaryColor)

            Text(message)
                .font(Theme.fontCaption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.9))
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.primaryGradient)

            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)

                Text(message)
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(Theme.spacingXL)
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: CalendarEvent
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Theme.spacingM) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(event.eventColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(event.title)
                        .font(Theme.fontSubheadline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(event.formattedTimeRange)
                            .font(Theme.fontSmall)
                    }
                    .foregroundColor(Theme.textSecondary)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: "location")
                                .font(.system(size: 12))
                            Text(location)
                                .font(Theme.fontSmall)
                                .lineLimit(1)
                        }
                        .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                if event.isFromAISchedule {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.primaryGradient)
                }
            }
            .padding(Theme.spacingM)
            .background(Color.white)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(
                color: Theme.shadowSmall.color,
                radius: Theme.shadowSmall.radius,
                x: Theme.shadowSmall.x,
                y: Theme.shadowSmall.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: Task
    var onToggle: (() -> Void)?
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Theme.spacingM) {
                Button(action: { onToggle?() }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? Theme.successColor : Theme.textTertiary)
                }

                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(task.title)
                        .font(Theme.fontSubheadline)
                        .foregroundColor(task.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)

                    HStack(spacing: Theme.spacingM) {
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                Text(dueDate.dateFormatted)
                                    .font(Theme.fontSmall)
                            }
                            .foregroundColor(task.isOverdue ? Theme.errorColor : Theme.textSecondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: task.priority.icon)
                                .font(.system(size: 11))
                            Text(task.priority.rawValue)
                                .font(Theme.fontSmall)
                        }
                        .foregroundColor(task.priority.color)
                    }
                }

                Spacer()

                Image(systemName: task.category.icon)
                    .foregroundColor(task.category.color)
            }
            .padding(Theme.spacingM)
            .background(Color.white)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(
                color: Theme.shadowSmall.color,
                radius: Theme.shadowSmall.radius,
                x: Theme.shadowSmall.x,
                y: Theme.shadowSmall.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack {
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(goal.category.color)

                    Spacer()

                    if goal.aiGeneratedSchedule != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("AI")
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.primaryGradient)
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }
                }

                Text(goal.title)
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack {
                        Text("Progress")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("\(Int(goal.calculatedProgress * 100))%")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textPrimary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.backgroundTertiary)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.primaryGradient)
                                .frame(width: geometry.size.width * goal.calculatedProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }

                HStack {
                    Text("\(goal.completedMilestones)/\(goal.milestones.count) milestones")
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    if let targetDate = goal.targetDate {
                        Text(targetDate.relativeFormatted)
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.spacingM)
            .background(Color.white)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(
                color: Theme.shadowSmall.color,
                radius: Theme.shadowSmall.radius,
                x: Theme.shadowSmall.x,
                y: Theme.shadowSmall.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.fontHeadline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.primaryColor)
                }
            }
        }
        .padding(.horizontal, Theme.spacingM)
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.backgroundSecondary)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
            Text("PREMIUM")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.premiumGradient)
        .cornerRadius(Theme.cornerRadiusSmall)
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGrid: View {
    @Binding var selectedColor: String
    let colors = EventColor.allCases

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.spacingS) {
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .opacity(selectedColor == color.rawValue ? 1 : 0)
                    )
                    .shadow(color: color.color.opacity(0.5), radius: 4)
                    .onTapGesture {
                        selectedColor = color.rawValue
                    }
            }
        }
    }
}

// MARK: - Activity Row (for AI Schedule)

struct ActivityRow: View {
    let activity: ScheduledActivity
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Button(action: { onToggle?() }) {
                Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(activity.isCompleted ? Theme.successColor : Theme.textTertiary)
            }

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(activity.title)
                    .font(Theme.fontSubheadline)
                    .foregroundColor(activity.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                    .strikethrough(activity.isCompleted)

                HStack(spacing: Theme.spacingM) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(activity.startTime)
                            .font(Theme.fontSmall)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 11))
                        Text("\(activity.duration) min")
                            .font(Theme.fontSmall)
                    }
                }
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Color.white)
        .cornerRadius(Theme.cornerRadiusMedium)
        .shadow(
            color: Theme.shadowSmall.color,
            radius: Theme.shadowSmall.radius,
            x: Theme.shadowSmall.x,
            y: Theme.shadowSmall.y
        )
    }
}
