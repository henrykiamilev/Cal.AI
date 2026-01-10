import Foundation
import SwiftUI

struct Goal: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var category: GoalCategory
    var targetDate: Date?
    var aiGeneratedSchedule: AISchedule?
    var milestones: [Milestone]
    var isActive: Bool
    var progress: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: GoalCategory = .career,
        targetDate: Date? = nil,
        aiGeneratedSchedule: AISchedule? = nil,
        milestones: [Milestone] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.targetDate = targetDate
        self.aiGeneratedSchedule = aiGeneratedSchedule
        self.milestones = milestones
        self.isActive = isActive
        self.progress = 0.0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var completedMilestones: Int {
        milestones.filter { $0.isCompleted }.count
    }

    var calculatedProgress: Double {
        guard !milestones.isEmpty else { return progress }
        return Double(completedMilestones) / Double(milestones.count)
    }
}

struct Milestone: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        targetDate: Date? = nil,
        isCompleted: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = nil
        self.order = order
    }
}

struct AISchedule: Codable, Hashable {
    let id: UUID
    var weeklySchedule: [ScheduleDay]
    var recommendations: [String]
    var estimatedTimeToGoal: String
    var difficultyLevel: DifficultyLevel
    var generatedAt: Date
    var lastAdjustedAt: Date

    init(
        id: UUID = UUID(),
        weeklySchedule: [ScheduleDay] = [],
        recommendations: [String] = [],
        estimatedTimeToGoal: String = "",
        difficultyLevel: DifficultyLevel = .moderate
    ) {
        self.id = id
        self.weeklySchedule = weeklySchedule
        self.recommendations = recommendations
        self.estimatedTimeToGoal = estimatedTimeToGoal
        self.difficultyLevel = difficultyLevel
        self.generatedAt = Date()
        self.lastAdjustedAt = Date()
    }
}

struct ScheduleDay: Codable, Hashable, Identifiable {
    let id: UUID
    var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    var activities: [ScheduledActivity]

    init(id: UUID = UUID(), dayOfWeek: Int, activities: [ScheduledActivity] = []) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.activities = activities
    }

    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard dayOfWeek >= 1 && dayOfWeek <= 7 else { return "" }
        return days[dayOfWeek - 1]
    }
}

struct ScheduledActivity: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var startTime: String // HH:mm format
    var duration: Int // in minutes
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        startTime: String,
        duration: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startTime = startTime
        self.duration = duration
        self.isCompleted = isCompleted
        self.completedAt = nil
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case career = "Career"
    case health = "Health & Fitness"
    case education = "Education"
    case finance = "Finance"
    case personal = "Personal Development"
    case relationships = "Relationships"
    case hobby = "Hobbies"
    case travel = "Travel"

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .finance: return "dollarsign.circle.fill"
        case .personal: return "person.fill"
        case .relationships: return "person.2.fill"
        case .hobby: return "paintpalette.fill"
        case .travel: return "airplane"
        }
    }

    var color: Color {
        switch self {
        case .career: return .blue
        case .health: return .red
        case .education: return .orange
        case .finance: return .green
        case .personal: return .purple
        case .relationships: return .pink
        case .hobby: return .yellow
        case .travel: return .cyan
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case intense = "Intense"

    var description: String {
        switch self {
        case .easy: return "Light commitment, flexible schedule"
        case .moderate: return "Regular effort, balanced approach"
        case .challenging: return "Significant dedication required"
        case .intense: return "Maximum effort, strict schedule"
        }
    }
}
