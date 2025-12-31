import SwiftUI

struct TaskCard: View {
    let task: CalTask
    var showDueDate: Bool = true
    var onTap: (() -> Void)? = nil
    var onToggleComplete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                HapticManager.shared.taskComplete()
                onToggleComplete?()
            }) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? task.swiftUIColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Circle()
                            .fill(task.swiftUIColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            // Task content
            Button(action: {
                HapticManager.shared.buttonTap()
                onTap?()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(task.isCompleted ? .textGray : .textDark)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        // Category
                        Label(task.category.displayName, systemImage: task.category.icon)
                            .font(.caption)
                            .foregroundColor(.textGray)

                        // Due date
                        if showDueDate, let _ = task.dueDate {
                            Text(task.dueDateFormatted)
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .errorRed : .textGray)
                        }

                        // Priority
                        if task.priority != .low {
                            HStack(spacing: 2) {
                                Image(systemName: task.priority.icon)
                                Text(task.priority.displayName)
                            }
                            .font(.caption)
                            .foregroundColor(task.priority.color)
                        }
                    }
                }

                Spacer()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .opacity(task.isCompleted ? 0.7 : 1)
    }
}

struct CompactTaskCard: View {
    let task: CalTask
    var onToggleComplete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticManager.shared.taskComplete()
                onToggleComplete?()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(task.isCompleted ? task.swiftUIColor : .textGray)
            }

            Text(task.title)
                .font(.subheadline)
                .foregroundColor(task.isCompleted ? .textGray : .textDark)
                .strikethrough(task.isCompleted)
                .lineLimit(1)

            Spacer()

            if task.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.errorRed)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.smallCornerRadius)
    }
}

struct TaskListItem: View {
    let task: CalTask
    var onToggleComplete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                HapticManager.shared.taskComplete()
                onToggleComplete?()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .successGreen : .textGray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundColor(task.isCompleted ? .textGray : .textDark)
                    .strikethrough(task.isCompleted)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.textGray)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let _ = task.dueDate {
                    Text(task.dueDateFormatted)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .errorRed : .textGray)
                }

                HStack(spacing: 4) {
                    Image(systemName: task.category.icon)
                        .font(.caption2)
                    if task.priority == .high {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundColor(.errorRed)
                    }
                }
                .foregroundColor(.textGray)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    let sampleTask = CalTask(
        title: "Complete project proposal",
        notes: "Include budget estimates",
        dueDate: Date().adding(.day, value: 1),
        priority: .high,
        category: .work
    )

    let completedTask = CalTask(
        title: "Buy groceries",
        dueDate: Date(),
        priority: .medium,
        category: .grocery,
        isCompleted: true,
        completedAt: Date()
    )

    VStack(spacing: 20) {
        TaskCard(task: sampleTask)
        TaskCard(task: completedTask)
        CompactTaskCard(task: sampleTask)
        TaskListItem(task: sampleTask)
    }
    .padding()
}
