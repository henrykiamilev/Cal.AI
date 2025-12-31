import SwiftUI
import Combine

@MainActor
final class TaskListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [CalTask] = []
    @Published var filteredTasks: [CalTask] = []
    @Published var currentFilter: TaskFilter = .all
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var showingTaskForm = false
    @Published var selectedTask: CalTask?

    // MARK: - Dependencies
    private let taskRepository: TaskRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var incompleteCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var overdueCount: Int {
        tasks.filter { $0.isOverdue }.count
    }

    var todayCount: Int {
        tasks.filter { $0.isDueToday && !$0.isCompleted }.count
    }

    var tasksByCategory: [TaskCategory: [CalTask]] {
        Dictionary(grouping: filteredTasks.filter { !$0.isCompleted }) { $0.category }
    }

    // MARK: - Initialization
    init(taskRepository: TaskRepository = TaskRepository()) {
        self.taskRepository = taskRepository

        setupBindings()
        loadTasks()
    }

    private func setupBindings() {
        // Update filtered tasks when filter or search changes
        $currentFilter
            .combineLatest($searchText, $tasks)
            .map { [weak self] filter, search, tasks in
                self?.applyFilter(filter, search: search, to: tasks) ?? []
            }
            .assign(to: &$filteredTasks)

        // Listen to repository changes
        taskRepository.$tasks
            .receive(on: DispatchQueue.main)
            .assign(to: &$tasks)
    }

    // MARK: - Data Loading
    func loadTasks() {
        isLoading = true
        tasks = taskRepository.fetchAll()
        isLoading = false
    }

    func refresh() {
        taskRepository.refresh()
    }

    // MARK: - Filtering
    private func applyFilter(_ filter: TaskFilter, search: String, to tasks: [CalTask]) -> [CalTask] {
        var result = tasks

        // Apply filter
        switch filter {
        case .all:
            result = tasks.filter { !$0.isCompleted }
        case .today:
            result = tasks.filter { $0.isDueToday && !$0.isCompleted }
        case .upcoming:
            result = tasks.filter {
                guard let dueDate = $0.dueDate else { return false }
                return dueDate > Date() && !$0.isCompleted
            }
        case .overdue:
            result = tasks.filter { $0.isOverdue }
        case .completed:
            result = tasks.filter { $0.isCompleted }
        }

        // Apply search
        if !search.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(search) ||
                ($0.notes?.localizedCaseInsensitiveContains(search) ?? false)
            }
        }

        // Sort
        return result.sorted { task1, task2 in
            // Sort by priority first, then by due date
            if task1.priority != task2.priority {
                return task1.priority > task2.priority
            }
            let date1 = task1.dueDate ?? Date.distantFuture
            let date2 = task2.dueDate ?? Date.distantFuture
            return date1 < date2
        }
    }

    func setFilter(_ filter: TaskFilter) {
        currentFilter = filter
        HapticManager.shared.selection()
    }

    // MARK: - Task Management
    func createTask(_ task: CalTask) {
        taskRepository.create(task)
        loadTasks()
    }

    func updateTask(_ task: CalTask) {
        taskRepository.update(task)
        loadTasks()
    }

    func deleteTask(_ task: CalTask) {
        taskRepository.delete(task)
        loadTasks()
    }

    func toggleComplete(_ task: CalTask) {
        taskRepository.toggleComplete(task)
        loadTasks()
    }

    // MARK: - Task Form
    func showNewTaskForm() {
        selectedTask = nil
        showingTaskForm = true
    }

    func showEditTaskForm(for task: CalTask) {
        selectedTask = task
        showingTaskForm = true
    }

    func dismissTaskForm() {
        showingTaskForm = false
        selectedTask = nil
    }
}
