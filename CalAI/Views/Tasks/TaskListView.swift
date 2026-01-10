import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedTask: Task?

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)

                if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: emptyStateTitle,
                        message: emptyStateMessage,
                        buttonTitle: selectedFilter == .all ? "Add Task" : nil,
                        action: selectedFilter == .all ? { showingAddTask = true } : nil
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingS) {
                            ForEach(filteredTasks) { task in
                                TaskRow(
                                    task: task,
                                    onToggle: { dataManager.toggleTaskCompletion(task) },
                                    onTap: { selectedTask = task }
                                )
                            }
                        }
                        .padding(Theme.spacingM)
                    }
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
        }
    }

    private var filteredTasks: [Task] {
        switch selectedFilter {
        case .all:
            return dataManager.tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .pending:
            return dataManager.pendingTasks
        case .completed:
            return dataManager.tasks.filter { $0.isCompleted }
        case .overdue:
            return dataManager.overdueTasks
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Tasks Yet"
        case .pending: return "All Done!"
        case .completed: return "No Completed Tasks"
        case .overdue: return "No Overdue Tasks"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Add your first task to get started"
        case .pending: return "You've completed all your tasks"
        case .completed: return "Complete some tasks to see them here"
        case .overdue: return "Great job staying on schedule!"
        }
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let task: Task

    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    // Status and Priority
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(task.isCompleted ? "Completed" : "Pending")
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(task.isCompleted ? Theme.successColor : Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.isCompleted ? Theme.successColor.opacity(0.1) : Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusSmall)

                        HStack(spacing: 4) {
                            Image(systemName: task.priority.icon)
                            Text(task.priority.rawValue)
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.priority.color.opacity(0.1))
                        .cornerRadius(Theme.cornerRadiusSmall)

                        HStack(spacing: 4) {
                            Image(systemName: task.category.icon)
                            Text(task.category.rawValue)
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(task.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.category.color.opacity(0.1))
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }

                    // Title
                    Text(task.title)
                        .font(Theme.fontTitle)
                        .foregroundColor(Theme.textPrimary)

                    // Due Date
                    if let dueDate = task.dueDate {
                        DetailRow(
                            icon: "calendar",
                            title: dueDate.dateFormatted,
                            subtitle: task.isOverdue ? "Overdue" : dueDate.relativeFormatted
                        )
                    }

                    // Description
                    if !task.description.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Notes")
                                .font(Theme.fontCaption)
                                .foregroundColor(Theme.textSecondary)

                            Text(task.description)
                                .font(Theme.fontBody)
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Subtasks
                    if !task.subtasks.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            HStack {
                                Text("Subtasks")
                                    .font(Theme.fontCaption)
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("\(task.subtasks.filter { $0.isCompleted }.count)/\(task.subtasks.count)")
                                    .font(Theme.fontSmall)
                                    .foregroundColor(Theme.textSecondary)
                            }

                            ForEach(task.subtasks) { subtask in
                                HStack {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? Theme.successColor : Theme.textTertiary)
                                    Text(subtask.title)
                                        .font(Theme.fontBody)
                                        .foregroundColor(subtask.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                                        .strikethrough(subtask.isCompleted)
                                    Spacer()
                                }
                                .padding(.vertical, Theme.spacingXS)
                            }
                        }
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Toggle completion button
                    Button(action: {
                        dataManager.toggleTaskCompletion(task)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                            Text(task.isCompleted ? "Mark as Pending" : "Mark as Complete")
                        }
                        .font(Theme.fontSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingM)
                        .background(task.isCompleted ? Theme.textSecondary : Theme.successColor)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .font(Theme.fontSubheadline)
                        .foregroundColor(Theme.errorColor)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingM)
                        .background(Theme.errorColor.opacity(0.1))
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    dataManager.deleteTask(task)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(DataManager())
}
