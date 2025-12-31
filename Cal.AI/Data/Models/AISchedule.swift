import Foundation
import SwiftUI

/// AI-generated schedule for achieving a goal
struct AISchedule: Codable, Hashable {
    let id: UUID
    let generatedAt: Date
    var phases: [Phase]
    let weeklyCommitmentHours: Double
    let estimatedCompletionDate: Date
    var adjustmentHistory: [Adjustment]

    init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        phases: [Phase],
        weeklyCommitmentHours: Double,
        estimatedCompletionDate: Date,
        adjustmentHistory: [Adjustment] = []
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.phases = phases
        self.weeklyCommitmentHours = weeklyCommitmentHours
        self.estimatedCompletionDate = estimatedCompletionDate
        self.adjustmentHistory = adjustmentHistory
    }

    // MARK: - Computed Properties
    var totalTasks: Int {
        phases.reduce(0) { $0 + $1.tasks.count }
    }

    var completedTasks: Int {
        phases.reduce(0) { $0 + $1.completedTasks.count }
    }

    var overallProgress: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }

    var currentPhase: Phase? {
        phases.first { !$0.isCompleted }
    }

    var nextTask: ScheduledTask? {
        currentPhase?.tasks.first { !$0.isCompleted }
    }

    var upcomingTasks: [ScheduledTask] {
        phases.flatMap { $0.tasks }
            .filter { !$0.isCompleted && $0.scheduledDate >= Date() }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var overdueTasks: [ScheduledTask] {
        phases.flatMap { $0.tasks }
            .filter { !$0.isCompleted && $0.scheduledDate < Date() }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var tasksForToday: [ScheduledTask] {
        let today = Date()
        return phases.flatMap { $0.tasks }
            .filter { $0.scheduledDate.isSameDay(as: today) }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var isOnTrack: Bool {
        overdueTasks.isEmpty
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: estimatedCompletionDate).day ?? 0
    }

    // MARK: - Mutations
    mutating func markTaskComplete(taskId: UUID) {
        for phaseIndex in phases.indices {
            if let taskIndex = phases[phaseIndex].tasks.firstIndex(where: { $0.id == taskId }) {
                phases[phaseIndex].tasks[taskIndex].isCompleted = true
                phases[phaseIndex].tasks[taskIndex].completedAt = Date()

                // Check if phase is now complete
                if phases[phaseIndex].tasks.allSatisfy({ $0.isCompleted }) {
                    phases[phaseIndex].isCompleted = true
                }
                break
            }
        }
    }

    mutating func markTaskIncomplete(taskId: UUID) {
        for phaseIndex in phases.indices {
            if let taskIndex = phases[phaseIndex].tasks.firstIndex(where: { $0.id == taskId }) {
                phases[phaseIndex].tasks[taskIndex].isCompleted = false
                phases[phaseIndex].tasks[taskIndex].completedAt = nil
                phases[phaseIndex].isCompleted = false
                break
            }
        }
    }

    mutating func addAdjustment(_ adjustment: Adjustment) {
        adjustmentHistory.append(adjustment)
    }
}

// MARK: - Phase
extension AISchedule {
    struct Phase: Codable, Hashable, Identifiable {
        let id: UUID
        var title: String
        var description: String
        var startDate: Date
        var endDate: Date
        var tasks: [ScheduledTask]
        var isCompleted: Bool

        init(
            id: UUID = UUID(),
            title: String,
            description: String,
            startDate: Date,
            endDate: Date,
            tasks: [ScheduledTask],
            isCompleted: Bool = false
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.startDate = startDate
            self.endDate = endDate
            self.tasks = tasks
            self.isCompleted = isCompleted
        }

        var completedTasks: [ScheduledTask] {
            tasks.filter { $0.isCompleted }
        }

        var pendingTasks: [ScheduledTask] {
            tasks.filter { !$0.isCompleted }
        }

        var progress: Double {
            guard !tasks.isEmpty else { return 0 }
            return Double(completedTasks.count) / Double(tasks.count)
        }

        var durationInDays: Int {
            Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        var dateRangeFormatted: String {
            "\(startDate.formatted(as: .dayMonth)) - \(endDate.formatted(as: .dayMonth))"
        }

        var isActive: Bool {
            let now = Date()
            return now >= startDate && now <= endDate && !isCompleted
        }

        var isFuture: Bool {
            startDate > Date()
        }

        var isPast: Bool {
            endDate < Date()
        }
    }
}

// MARK: - Scheduled Task
extension AISchedule {
    struct ScheduledTask: Codable, Hashable, Identifiable {
        let id: UUID
        var title: String
        var description: String?
        var scheduledDate: Date
        var durationMinutes: Int
        var isCompleted: Bool
        var completedAt: Date?
        var resources: [String]? // Links, books, etc.

        init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            scheduledDate: Date,
            durationMinutes: Int = 60,
            isCompleted: Bool = false,
            completedAt: Date? = nil,
            resources: [String]? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.scheduledDate = scheduledDate
            self.durationMinutes = durationMinutes
            self.isCompleted = isCompleted
            self.completedAt = completedAt
            self.resources = resources
        }

        var isOverdue: Bool {
            !isCompleted && scheduledDate < Date()
        }

        var isDueToday: Bool {
            scheduledDate.isToday
        }

        var durationFormatted: String {
            let hours = durationMinutes / 60
            let minutes = durationMinutes % 60

            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        }

        var scheduledDateFormatted: String {
            scheduledDate.relativeDateString
        }
    }
}

// MARK: - Adjustment
extension AISchedule {
    struct Adjustment: Codable, Hashable, Identifiable {
        let id: UUID
        let date: Date
        let reason: AdjustmentReason
        let description: String
        let changes: String

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            reason: AdjustmentReason,
            description: String,
            changes: String
        ) {
            self.id = id
            self.date = date
            self.reason = reason
            self.description = description
            self.changes = changes
        }

        enum AdjustmentReason: String, Codable {
            case missedTasks = "missed_tasks"
            case aheadOfSchedule = "ahead_of_schedule"
            case userRequested = "user_requested"
            case timeConflict = "time_conflict"
            case goalChanged = "goal_changed"

            var displayName: String {
                switch self {
                case .missedTasks: return "Missed Tasks"
                case .aheadOfSchedule: return "Ahead of Schedule"
                case .userRequested: return "User Requested"
                case .timeConflict: return "Time Conflict"
                case .goalChanged: return "Goal Changed"
                }
            }
        }
    }
}

// MARK: - Progress Analysis
struct ProgressAnalysis: Codable {
    let analyzedAt: Date
    let overallScore: Double // 0-100
    let onTrack: Bool
    let strengths: [String]
    let areasForImprovement: [String]
    let recommendations: [String]
    let estimatedNewCompletionDate: Date?

    var scoreDescription: String {
        switch overallScore {
        case 90...100: return "Excellent"
        case 75..<90: return "Good"
        case 50..<75: return "Fair"
        case 25..<50: return "Needs Improvement"
        default: return "Critical"
        }
    }

    var scoreColor: Color {
        switch overallScore {
        case 75...100: return .successGreen
        case 50..<75: return .warningYellow
        default: return .errorRed
        }
    }
}
