import Foundation
import Combine

/// Orchestrates AI-powered goal planning and progress tracking
final class GoalPlanningEngine: ObservableObject {
    private let aiService: AIServiceProtocol
    private let goalRepository: GoalRepository
    private let eventRepository: EventRepository
    private let userRepository: UserRepository

    @Published var isGenerating = false
    @Published var isAnalyzing = false
    @Published var lastError: Error?

    init(
        aiService: AIServiceProtocol = OpenAIService(),
        goalRepository: GoalRepository = GoalRepository(),
        eventRepository: EventRepository = EventRepository(),
        userRepository: UserRepository = .shared
    ) {
        self.aiService = aiService
        self.goalRepository = goalRepository
        self.eventRepository = eventRepository
        self.userRepository = userRepository
    }

    // MARK: - Generate Plan for Goal
    @MainActor
    func generatePlan(for goal: Goal) async throws -> AISchedule {
        guard let userProfile = userRepository.currentUser else {
            throw GoalPlanningError.noUserProfile
        }

        isGenerating = true
        lastError = nil

        defer { isGenerating = false }

        do {
            // Get existing commitments for the next 3 months
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
            let existingEvents = eventRepository.fetch(from: Date(), to: endDate)

            // Generate plan using AI
            let schedule = try await aiService.generateGoalPlan(
                goal: goal,
                userProfile: userProfile,
                existingCommitments: existingEvents
            )

            // Save schedule to goal
            var updatedGoal = goal
            updatedGoal.aiSchedule = schedule
            updatedGoal.lastAIUpdateAt = Date()

            // Create milestones from phases
            updatedGoal.milestones = schedule.phases.enumerated().map { index, phase in
                Milestone(
                    title: phase.title,
                    targetDate: phase.endDate,
                    isAIGenerated: true,
                    orderIndex: index
                )
            }

            goalRepository.update(updatedGoal)
            goalRepository.updateAISchedule(schedule, for: goal.id)

            // Schedule notifications for upcoming tasks
            await scheduleTaskNotifications(for: schedule, goalId: goal.id)

            return schedule
        } catch {
            lastError = error
            throw error
        }
    }

    // MARK: - Adjust Schedule Based on Progress
    @MainActor
    func adjustSchedule(for goal: Goal) async throws -> AISchedule {
        guard let currentSchedule = goal.aiSchedule else {
            throw GoalPlanningError.noExistingSchedule
        }

        isGenerating = true
        lastError = nil

        defer { isGenerating = false }

        do {
            let completedTasks = currentSchedule.phases.flatMap { $0.tasks }.filter { $0.isCompleted }
            let missedTasks = currentSchedule.overdueTasks

            let adjustedSchedule = try await aiService.adjustSchedule(
                currentSchedule: currentSchedule,
                goal: goal,
                completedTasks: completedTasks,
                missedTasks: missedTasks
            )

            // Save updated schedule
            goalRepository.updateAISchedule(adjustedSchedule, for: goal.id)

            // Reschedule notifications
            await cancelTaskNotifications(for: currentSchedule, goalId: goal.id)
            await scheduleTaskNotifications(for: adjustedSchedule, goalId: goal.id)

            return adjustedSchedule
        } catch {
            lastError = error
            throw error
        }
    }

    // MARK: - Analyze Progress
    @MainActor
    func analyzeProgress(for goal: Goal) async throws -> ProgressAnalysis {
        guard let schedule = goal.aiSchedule else {
            throw GoalPlanningError.noExistingSchedule
        }

        isAnalyzing = true
        lastError = nil

        defer { isAnalyzing = false }

        do {
            let analysis = try await aiService.analyzeProgress(goal: goal, schedule: schedule)
            return analysis
        } catch {
            lastError = error
            throw error
        }
    }

    // MARK: - Get Suggestions
    @MainActor
    func getSuggestions(for goal: Goal) async throws -> [String] {
        guard let schedule = goal.aiSchedule,
              let userProfile = userRepository.currentUser else {
            return []
        }

        do {
            return try await aiService.getSuggestions(
                goal: goal,
                schedule: schedule,
                userProfile: userProfile
            )
        } catch {
            lastError = error
            return []
        }
    }

    // MARK: - Mark Task Complete
    @MainActor
    func markTaskComplete(taskId: UUID, in goal: Goal) -> Bool {
        guard var schedule = goal.aiSchedule else { return false }

        schedule.markTaskComplete(taskId: taskId)

        // Update goal progress
        var updatedGoal = goal
        updatedGoal.aiSchedule = schedule
        updatedGoal.progressPercentage = schedule.overallProgress * 100

        // Check if any milestones should be marked complete
        for (index, phase) in schedule.phases.enumerated() {
            if phase.isCompleted && index < updatedGoal.milestones.count {
                updatedGoal.milestones[index].markComplete()
            }
        }

        let success = goalRepository.update(updatedGoal) &&
                     goalRepository.updateAISchedule(schedule, for: goal.id)

        if success {
            HapticManager.shared.taskComplete()

            // Cancel notification for completed task
            NotificationManager.shared.cancelAITaskNotification(
                goalId: goal.id.uuidString,
                taskId: taskId.uuidString
            )
        }

        return success
    }

    // MARK: - Mark Task Incomplete
    @MainActor
    func markTaskIncomplete(taskId: UUID, in goal: Goal) -> Bool {
        guard var schedule = goal.aiSchedule else { return false }

        schedule.markTaskIncomplete(taskId: taskId)

        var updatedGoal = goal
        updatedGoal.aiSchedule = schedule
        updatedGoal.progressPercentage = schedule.overallProgress * 100

        return goalRepository.update(updatedGoal) &&
               goalRepository.updateAISchedule(schedule, for: goal.id)
    }

    // MARK: - Check if Adjustment Needed
    func shouldAdjustSchedule(for goal: Goal) -> Bool {
        guard let schedule = goal.aiSchedule else { return false }

        // Adjust if:
        // 1. There are overdue tasks
        // 2. It's been more than a week since last adjustment
        // 3. Progress is significantly behind or ahead

        let hasOverdueTasks = !schedule.overdueTasks.isEmpty
        let daysSinceLastUpdate = goal.lastAIUpdateAt.map {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
        } ?? Constants.AI.minimumAdjustmentDays + 1

        let significantDeviation: Bool = {
            let expectedProgress = calculateExpectedProgress(for: schedule)
            let actualProgress = schedule.overallProgress
            return abs(expectedProgress - actualProgress) > 0.2 // 20% deviation
        }()

        return hasOverdueTasks ||
               daysSinceLastUpdate >= Constants.AI.minimumAdjustmentDays ||
               significantDeviation
    }

    // MARK: - Calculate Expected Progress
    private func calculateExpectedProgress(for schedule: AISchedule) -> Double {
        let totalDuration = schedule.estimatedCompletionDate.timeIntervalSince(schedule.generatedAt)
        let elapsedDuration = Date().timeIntervalSince(schedule.generatedAt)

        guard totalDuration > 0 else { return 1.0 }
        return min(1.0, max(0, elapsedDuration / totalDuration))
    }

    // MARK: - Notification Management
    private func scheduleTaskNotifications(for schedule: AISchedule, goalId: UUID) async {
        for phase in schedule.phases {
            for task in phase.tasks where !task.isCompleted {
                await NotificationManager.shared.scheduleAITaskReminder(
                    goalId: goalId.uuidString,
                    taskId: task.id.uuidString,
                    title: task.title,
                    scheduledDate: task.scheduledDate
                )
            }
        }
    }

    private func cancelTaskNotifications(for schedule: AISchedule, goalId: UUID) async {
        for phase in schedule.phases {
            for task in phase.tasks {
                NotificationManager.shared.cancelAITaskNotification(
                    goalId: goalId.uuidString,
                    taskId: task.id.uuidString
                )
            }
        }
    }
}

// MARK: - Goal Planning Errors
enum GoalPlanningError: LocalizedError {
    case noUserProfile
    case noExistingSchedule
    case generationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noUserProfile:
            return "Please complete your profile before generating a plan."
        case .noExistingSchedule:
            return "No AI schedule exists for this goal."
        case .generationFailed(let error):
            return "Failed to generate plan: \(error.localizedDescription)"
        }
    }
}

// MARK: - Singleton Access
extension GoalPlanningEngine {
    static let shared = GoalPlanningEngine()
}
