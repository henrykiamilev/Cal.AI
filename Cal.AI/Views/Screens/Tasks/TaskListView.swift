import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter tabs
                    FilterTabsView(
                        currentFilter: viewModel.currentFilter,
                        overdueCount: viewModel.overdueCount,
                        todayCount: viewModel.todayCount,
                        onFilterChange: viewModel.setFilter
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search bar
                    SearchBar(text: $viewModel.searchText)
                        .padding()

                    // Task list
                    if viewModel.filteredTasks.isEmpty {
                        EmptyTasksView(filter: viewModel.currentFilter) {
                            viewModel.showNewTaskForm()
                        }
                    } else {
                        TaskListContent(
                            tasks: viewModel.filteredTasks,
                            onTaskTap: { task in
                                viewModel.showEditTaskForm(for: task)
                            },
                            onToggleComplete: { task in
                                viewModel.toggleComplete(task)
                            },
                            onDelete: { task in
                                viewModel.deleteTask(task)
                            }
                        )
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus") {
                            viewModel.showNewTaskForm()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.refresh) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingTaskForm) {
                TaskFormView(
                    task: viewModel.selectedTask,
                    onSave: { task in
                        if viewModel.selectedTask != nil {
                            viewModel.updateTask(task)
                        } else {
                            viewModel.createTask(task)
                        }
                    },
                    onDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )
            }
        }
    }
}

struct FilterTabsView: View {
    let currentFilter: TaskFilter
    let overdueCount: Int
    let todayCount: Int
    let onFilterChange: (TaskFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: currentFilter == filter,
                        badgeCount: badgeCount(for: filter)
                    ) {
                        onFilterChange(filter)
                    }
                }
            }
        }
    }

    private func badgeCount(for filter: TaskFilter) -> Int? {
        switch filter {
        case .overdue: return overdueCount > 0 ? overdueCount : nil
        case .today: return todayCount > 0 ? todayCount : nil
        default: return nil
        }
    }
}

struct FilterTab: View {
    let filter: TaskFilter
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))

                Text(filter.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = badgeCount {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.errorRed)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .textDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryBlue : Color.cardWhite)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct TaskListContent: View {
    let tasks: [CalTask]
    var onTaskTap: ((CalTask) -> Void)?
    var onToggleComplete: ((CalTask) -> Void)?
    var onDelete: ((CalTask) -> Void)?

    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskListItem(task: task) {
                    onToggleComplete?(task)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTaskTap?(task)
                }
                .listRowBackground(Color.cardWhite)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDelete?(task)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        onToggleComplete?(task)
                    } label: {
                        Label(
                            task.isCompleted ? "Undo" : "Complete",
                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(.successGreen)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct EmptyTasksView: View {
    let filter: TaskFilter
    let onAddTask: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: emptyIcon)
                .font(.system(size: 60))
                .foregroundColor(.textGray.opacity(0.5))

            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.headline)
                    .foregroundColor(.textDark)

                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .multilineTextAlignment(.center)
            }

            if filter == .all {
                PrimaryButton("Add Task", icon: "plus", action: onAddTask)
                    .frame(width: 160)
            }

            Spacer()
        }
        .padding()
    }

    private var emptyIcon: String {
        switch filter {
        case .all: return "checklist"
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        case .overdue: return "checkmark.circle"
        case .completed: return "tray"
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all: return "No Tasks"
        case .today: return "Nothing Due Today"
        case .upcoming: return "No Upcoming Tasks"
        case .overdue: return "All Caught Up!"
        case .completed: return "No Completed Tasks"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .all: return "Add your first task to get started"
        case .today: return "You have no tasks due today"
        case .upcoming: return "No tasks scheduled for the future"
        case .overdue: return "You have no overdue tasks"
        case .completed: return "Completed tasks will appear here"
        }
    }
}

// MARK: - Preview
#Preview {
    TaskListView()
}
