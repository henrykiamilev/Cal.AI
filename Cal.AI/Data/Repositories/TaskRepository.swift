import Foundation
import CoreData
import Combine

protocol TaskRepositoryProtocol {
    func fetchAll() -> [CalTask]
    func fetchIncomplete() -> [CalTask]
    func fetchCompleted() -> [CalTask]
    func fetchDueToday() -> [CalTask]
    func fetchOverdue() -> [CalTask]
    func fetch(byId id: UUID) -> CalTask?
    func fetch(forGoalId goalId: UUID) -> [CalTask]
    func create(_ task: CalTask) -> CalTask?
    func update(_ task: CalTask) -> Bool
    func delete(_ task: CalTask) -> Bool
    func toggleComplete(_ task: CalTask) -> CalTask?
}

final class TaskRepository: TaskRepositoryProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    private let persistenceController: PersistenceController

    @Published var tasks: [CalTask] = []
    @Published var incompleteTasks: [CalTask] = []

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.persistenceController = PersistenceController.shared
        loadTasks()
    }

    // MARK: - Load Tasks
    private func loadTasks() {
        tasks = fetchAll()
        incompleteTasks = fetchIncomplete()
    }

    func refresh() {
        loadTasks()
    }

    // MARK: - Fetch All
    func fetchAll() -> [CalTask] {
        let request = CDTask.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \CDTask.priority, ascending: false),
            NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)
        ]

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }

    // MARK: - Fetch Incomplete
    func fetchIncomplete() -> [CalTask] {
        let request = CDTask.fetchIncompleteRequest()

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch incomplete tasks: \(error)")
            return []
        }
    }

    // MARK: - Fetch Completed
    func fetchCompleted() -> [CalTask] {
        let request = CDTask.fetchCompletedRequest()

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch completed tasks: \(error)")
            return []
        }
    }

    // MARK: - Fetch Due Today
    func fetchDueToday() -> [CalTask] {
        let request = CDTask.fetchDueTodayRequest()

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch today's tasks: \(error)")
            return []
        }
    }

    // MARK: - Fetch Overdue
    func fetchOverdue() -> [CalTask] {
        let request = CDTask.fetchOverdueRequest()

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch overdue tasks: \(error)")
            return []
        }
    }

    // MARK: - Fetch by ID
    func fetch(byId id: UUID) -> CalTask? {
        let request = CDTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdTask = try context.fetch(request).first {
                return CalTask(from: cdTask)
            }
        } catch {
            print("Failed to fetch task by ID: \(error)")
        }
        return nil
    }

    // MARK: - Fetch for Goal
    func fetch(forGoalId goalId: UUID) -> [CalTask] {
        let request = CDTask.fetchRequest(forGoalId: goalId)

        do {
            let cdTasks = try context.fetch(request)
            return cdTasks.map { CalTask(from: $0) }
        } catch {
            print("Failed to fetch tasks for goal: \(error)")
            return []
        }
    }

    // MARK: - Create
    @discardableResult
    func create(_ task: CalTask) -> CalTask? {
        let cdTask = task.toCoreData(in: context)

        // Link to goal if specified
        if let goalId = task.parentGoalId {
            let goalRequest = CDGoal.fetchRequest()
            goalRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
            goalRequest.fetchLimit = 1

            if let goal = try? context.fetch(goalRequest).first {
                cdTask.parentGoal = goal
            }
        }

        do {
            try context.save()
            refresh()

            // Schedule notification if due date is set
            if let dueDate = task.dueDate {
                Task {
                    await NotificationManager.shared.scheduleTaskReminder(
                        id: task.id.uuidString,
                        title: task.title,
                        dueDate: dueDate
                    )
                }
            }

            return CalTask(from: cdTask)
        } catch {
            print("Failed to create task: \(error)")
            context.rollback()
            return nil
        }
    }

    // MARK: - Update
    @discardableResult
    func update(_ task: CalTask) -> Bool {
        let request = CDTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdTask = try context.fetch(request).first {
                task.updateCoreData(cdTask)
                try context.save()
                refresh()

                // Update notification
                NotificationManager.shared.cancelTaskNotification(taskId: task.id.uuidString)
                if let dueDate = task.dueDate, !task.isCompleted {
                    Task {
                        await NotificationManager.shared.scheduleTaskReminder(
                            id: task.id.uuidString,
                            title: task.title,
                            dueDate: dueDate
                        )
                    }
                }

                return true
            }
        } catch {
            print("Failed to update task: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Delete
    @discardableResult
    func delete(_ task: CalTask) -> Bool {
        let request = CDTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdTask = try context.fetch(request).first {
                context.delete(cdTask)
                try context.save()
                refresh()

                // Cancel notification
                NotificationManager.shared.cancelTaskNotification(taskId: task.id.uuidString)

                return true
            }
        } catch {
            print("Failed to delete task: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Toggle Complete
    @discardableResult
    func toggleComplete(_ task: CalTask) -> CalTask? {
        var updatedTask = task
        if task.isCompleted {
            updatedTask.markIncomplete()
        } else {
            updatedTask.markComplete()
        }

        if update(updatedTask) {
            HapticManager.shared.taskComplete()
            return updatedTask
        }
        return nil
    }

    // MARK: - Convenience Methods
    func tasksByCategory() -> [TaskCategory: [CalTask]] {
        Dictionary(grouping: incompleteTasks) { $0.category }
    }

    func tasksByDueDate() -> [Date?: [CalTask]] {
        Dictionary(grouping: incompleteTasks) { $0.dueDate?.startOfDay }
    }

    func incompleteCount() -> Int {
        incompleteTasks.count
    }

    func overdueCount() -> Int {
        incompleteTasks.filter { $0.isOverdue }.count
    }

    func dueTodayCount() -> Int {
        incompleteTasks.filter { $0.isDueToday }.count
    }
}
