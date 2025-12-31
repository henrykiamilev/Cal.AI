import SwiftUI
import CoreData

struct Goal: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var targetDate: Date?
    var category: GoalCategory
    var isActive: Bool
    var progressPercentage: Double
    var aiSchedule: AISchedule?
    var milestones: [Milestone]
    var createdAt: Date
    var updatedAt: Date
    var lastAIUpdateAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        targetDate: Date? = nil,
        category: GoalCategory = .personal,
        isActive: Bool = true,
        progressPercentage: Double = 0,
        aiSchedule: AISchedule? = nil,
        milestones: [Milestone] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastAIUpdateAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.category = category
        self.isActive = isActive
        self.progressPercentage = progressPercentage
        self.aiSchedule = aiSchedule
        self.milestones = milestones
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastAIUpdateAt = lastAIUpdateAt
    }

    var progress: Double {
        progressPercentage / 100
    }

    var isCompleted: Bool {
        progressPercentage >= 100
    }

    var completedMilestones: [Milestone] {
        milestones.filter { $0.isCompleted }
    }

    var pendingMilestones: [Milestone] {
        milestones.filter { !$0.isCompleted }
    }

    var nextMilestone: Milestone? {
        pendingMilestones.first
    }

    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
    }

    var targetDateFormatted: String {
        guard let targetDate = targetDate else { return "No target date" }
        return targetDate.mediumDateString
    }

    var hasAIPlan: Bool {
        aiSchedule != nil
    }

    mutating func updateProgress() {
        guard !milestones.isEmpty else {
            progressPercentage = 0
            return
        }
        let completed = Double(completedMilestones.count)
        let total = Double(milestones.count)
        progressPercentage = (completed / total) * 100
    }
}

// MARK: - Goal Category
enum GoalCategory: String, CaseIterable, Codable {
    case career = "career"
    case health = "health"
    case education = "education"
    case finance = "finance"
    case personal = "personal"
    case fitness = "fitness"
    case creativity = "creativity"
    case relationships = "relationships"

    var displayName: String {
        switch self {
        case .career: return "Career"
        case .health: return "Health"
        case .education: return "Education"
        case .finance: return "Finance"
        case .personal: return "Personal"
        case .fitness: return "Fitness"
        case .creativity: return "Creativity"
        case .relationships: return "Relationships"
        }
    }

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .finance: return "dollarsign.circle.fill"
        case .personal: return "person.fill"
        case .fitness: return "figure.run"
        case .creativity: return "paintbrush.fill"
        case .relationships: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .career: return .categoryCareer
        case .health: return .categoryHealth
        case .education: return .categoryEducation
        case .finance: return .categoryFinance
        case .personal: return .categoryPersonal
        case .fitness: return Color(hex: "E74C3C")
        case .creativity: return Color(hex: "9B59B6")
        case .relationships: return Color(hex: "E91E63")
        }
    }

    var colorHex: String {
        switch self {
        case .career: return "E74C3C"
        case .health: return "27AE60"
        case .education: return "F39C12"
        case .finance: return "1ABC9C"
        case .personal: return "9B59B6"
        case .fitness: return "E74C3C"
        case .creativity: return "9B59B6"
        case .relationships: return "E91E63"
        }
    }
}

// MARK: - Milestone
struct Milestone: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var targetDate: Date
    var isCompleted: Bool
    var completedAt: Date?
    var isAIGenerated: Bool
    var orderIndex: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isAIGenerated: Bool = false,
        orderIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isAIGenerated = isAIGenerated
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        !isCompleted && targetDate < Date()
    }

    var daysUntilDue: Int? {
        Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
    }

    var targetDateFormatted: String {
        targetDate.mediumDateString
    }

    mutating func markComplete() {
        isCompleted = true
        completedAt = Date()
    }

    mutating func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }
}

// MARK: - Core Data Conversion
extension Goal {
    init(from cdGoal: CDGoal) {
        self.id = cdGoal.id ?? UUID()
        self.title = cdGoal.title ?? ""
        self.description = cdGoal.goalDescription
        self.targetDate = cdGoal.targetDate
        self.category = GoalCategory(rawValue: cdGoal.category ?? "personal") ?? .personal
        self.isActive = cdGoal.isActive
        self.progressPercentage = cdGoal.progressPercentage

        // Decrypt AI schedule if present
        if let aiData = cdGoal.aiScheduleData {
            if let decryptedData = try? EncryptionManager.shared.decryptData(aiData) {
                self.aiSchedule = try? JSONDecoder().decode(AISchedule.self, from: decryptedData)
            } else {
                // Try without decryption (for legacy data)
                self.aiSchedule = try? JSONDecoder().decode(AISchedule.self, from: aiData)
            }
        } else {
            self.aiSchedule = nil
        }

        // Convert milestones
        self.milestones = cdGoal.milestonesArray.map { Milestone(from: $0) }

        self.createdAt = cdGoal.createdAt ?? Date()
        self.updatedAt = cdGoal.updatedAt ?? Date()
        self.lastAIUpdateAt = cdGoal.lastAIUpdateAt
    }

    func toCoreData(in context: NSManagedObjectContext) -> CDGoal {
        let cdGoal = CDGoal(context: context)
        updateCoreData(cdGoal, in: context)
        return cdGoal
    }

    func updateCoreData(_ cdGoal: CDGoal, in context: NSManagedObjectContext) {
        cdGoal.id = id
        cdGoal.title = title
        cdGoal.goalDescription = description
        cdGoal.targetDate = targetDate
        cdGoal.category = category.rawValue
        cdGoal.isActive = isActive
        cdGoal.progressPercentage = progressPercentage

        // Encrypt AI schedule
        if let aiSchedule = aiSchedule,
           let jsonData = try? JSONEncoder().encode(aiSchedule) {
            cdGoal.aiScheduleData = try? EncryptionManager.shared.encryptData(jsonData)
        }

        cdGoal.createdAt = createdAt
        cdGoal.updatedAt = Date()
        cdGoal.lastAIUpdateAt = lastAIUpdateAt
    }
}

extension Milestone {
    init(from cdMilestone: CDMilestone) {
        self.id = cdMilestone.id ?? UUID()
        self.title = cdMilestone.title ?? ""
        self.targetDate = cdMilestone.targetDate ?? Date()
        self.isCompleted = cdMilestone.isCompleted
        self.completedAt = cdMilestone.completedAt
        self.isAIGenerated = cdMilestone.isAIGenerated
        self.orderIndex = Int(cdMilestone.orderIndex)
        self.createdAt = cdMilestone.createdAt ?? Date()
    }

    func toCoreData(in context: NSManagedObjectContext, goal: CDGoal) -> CDMilestone {
        let cdMilestone = CDMilestone(context: context)
        updateCoreData(cdMilestone)
        cdMilestone.goal = goal
        return cdMilestone
    }

    func updateCoreData(_ cdMilestone: CDMilestone) {
        cdMilestone.id = id
        cdMilestone.title = title
        cdMilestone.targetDate = targetDate
        cdMilestone.isCompleted = isCompleted
        cdMilestone.completedAt = completedAt
        cdMilestone.isAIGenerated = isAIGenerated
        cdMilestone.orderIndex = Int16(orderIndex)
        cdMilestone.createdAt = createdAt
    }
}
