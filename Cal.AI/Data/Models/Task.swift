import SwiftUI
import CoreData

struct CalTask: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var priority: Priority
    var category: TaskCategory
    var isCompleted: Bool
    var completedAt: Date?
    var color: String // Hex color
    var parentGoalId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        category: TaskCategory = .personal,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        color: String = "27AE60",
        parentGoalId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.color = color
        self.parentGoalId = parentGoalId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var swiftUIColor: Color {
        Color(hex: color)
    }

    var isOverdue: Bool {
        guard !isCompleted, let dueDate = dueDate else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate.isToday
    }

    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate.isTomorrow
    }

    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date().startOfDay, to: dueDate.startOfDay).day
    }

    var dueDateFormatted: String {
        guard let dueDate = dueDate else { return "No due date" }
        return dueDate.relativeDateString
    }

    mutating func markComplete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }

    mutating func markIncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
}

// MARK: - Priority
enum Priority: Int, CaseIterable, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .low: return .textGray
        case .medium: return .warningYellow
        case .high: return .errorRed
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Task Category
enum TaskCategory: String, CaseIterable, Codable {
    case homework = "homework"
    case grocery = "grocery"
    case work = "work"
    case personal = "personal"
    case health = "health"
    case finance = "finance"
    case errands = "errands"
    case chores = "chores"

    var displayName: String {
        switch self {
        case .homework: return "Homework"
        case .grocery: return "Grocery"
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .finance: return "Finance"
        case .errands: return "Errands"
        case .chores: return "Chores"
        }
    }

    var icon: String {
        switch self {
        case .homework: return "book.fill"
        case .grocery: return "cart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .errands: return "car.fill"
        case .chores: return "house.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .homework: return "F39C12"
        case .grocery: return "27AE60"
        case .work: return "3498DB"
        case .personal: return "9B59B6"
        case .health: return "E74C3C"
        case .finance: return "1ABC9C"
        case .errands: return "E67E22"
        case .chores: return "95A5A6"
        }
    }
}

// MARK: - Core Data Conversion
extension CalTask {
    init(from cdTask: CDTask) {
        self.id = cdTask.id ?? UUID()
        self.title = cdTask.title ?? ""
        self.notes = cdTask.notes
        self.dueDate = cdTask.dueDate
        self.priority = Priority(rawValue: Int(cdTask.priority)) ?? .medium
        self.category = TaskCategory(rawValue: cdTask.category ?? "personal") ?? .personal
        self.isCompleted = cdTask.isCompleted
        self.completedAt = cdTask.completedAt
        self.color = cdTask.colorHex ?? "27AE60"
        self.parentGoalId = cdTask.parentGoal?.id
        self.createdAt = cdTask.createdAt ?? Date()
        self.updatedAt = cdTask.updatedAt ?? Date()
    }

    func toCoreData(in context: NSManagedObjectContext) -> CDTask {
        let cdTask = CDTask(context: context)
        updateCoreData(cdTask)
        return cdTask
    }

    func updateCoreData(_ cdTask: CDTask) {
        cdTask.id = id
        cdTask.title = title
        cdTask.notes = notes
        cdTask.dueDate = dueDate
        cdTask.priority = Int16(priority.rawValue)
        cdTask.category = category.rawValue
        cdTask.isCompleted = isCompleted
        cdTask.completedAt = completedAt
        cdTask.colorHex = color
        cdTask.createdAt = createdAt
        cdTask.updatedAt = Date()
    }
}

// MARK: - Task Filters
enum TaskFilter: CaseIterable {
    case all
    case today
    case upcoming
    case overdue
    case completed

    var displayName: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "sun.max.fill"
        case .upcoming: return "calendar"
        case .overdue: return "exclamationmark.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}
