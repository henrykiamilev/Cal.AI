import Foundation
import SwiftUI

struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var dueDate: Date?
    var priority: Priority
    var category: TaskCategory
    var isCompleted: Bool
    var completedAt: Date?
    var isFromAISchedule: Bool
    var goalId: UUID?
    var subtasks: [Subtask]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        category: TaskCategory = .general,
        isCompleted: Bool = false,
        isFromAISchedule: Bool = false,
        goalId: UUID? = nil,
        subtasks: [Subtask] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.completedAt = nil
        self.isFromAISchedule = isFromAISchedule
        self.goalId = goalId
        self.subtasks = subtasks
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }

    var completionPercentage: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completed = subtasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(subtasks.count)
    }
}

struct Subtask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case general = "General"
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case education = "Education"
    case finance = "Finance"
    case shopping = "Shopping"
    case home = "Home"

    var icon: String {
        switch self {
        case .general: return "list.bullet"
        case .work: return "briefcase"
        case .personal: return "person"
        case .health: return "heart"
        case .education: return "book"
        case .finance: return "dollarsign.circle"
        case .shopping: return "cart"
        case .home: return "house"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .work: return .blue
        case .personal: return .purple
        case .health: return .red
        case .education: return .orange
        case .finance: return .green
        case .shopping: return .pink
        case .home: return .brown
        }
    }
}
