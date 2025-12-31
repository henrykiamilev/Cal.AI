import Foundation
import CoreData
import Combine

protocol GoalRepositoryProtocol {
    func fetchAll() -> [Goal]
    func fetchActive() -> [Goal]
    func fetchCompleted() -> [Goal]
    func fetch(byId id: UUID) -> Goal?
    func fetch(byCategory category: GoalCategory) -> [Goal]
    func create(_ goal: Goal) -> Goal?
    func update(_ goal: Goal) -> Bool
    func delete(_ goal: Goal) -> Bool
    func addMilestone(_ milestone: Milestone, to goalId: UUID) -> Bool
    func updateMilestone(_ milestone: Milestone, in goalId: UUID) -> Bool
    func deleteMilestone(_ milestoneId: UUID, from goalId: UUID) -> Bool
    func updateAISchedule(_ schedule: AISchedule, for goalId: UUID) -> Bool
}

final class GoalRepository: GoalRepositoryProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    private let persistenceController: PersistenceController

    @Published var goals: [Goal] = []
    @Published var activeGoals: [Goal] = []

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.persistenceController = PersistenceController.shared
        loadGoals()
    }

    // MARK: - Load Goals
    private func loadGoals() {
        goals = fetchAll()
        activeGoals = fetchActive()
    }

    func refresh() {
        loadGoals()
    }

    // MARK: - Fetch All
    func fetchAll() -> [Goal] {
        let request = CDGoal.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDGoal.isActive, ascending: false),
            NSSortDescriptor(keyPath: \CDGoal.targetDate, ascending: true)
        ]

        do {
            let cdGoals = try context.fetch(request)
            return cdGoals.map { Goal(from: $0) }
        } catch {
            print("Failed to fetch goals: \(error)")
            return []
        }
    }

    // MARK: - Fetch Active
    func fetchActive() -> [Goal] {
        let request = CDGoal.fetchActiveRequest()

        do {
            let cdGoals = try context.fetch(request)
            return cdGoals.map { Goal(from: $0) }
        } catch {
            print("Failed to fetch active goals: \(error)")
            return []
        }
    }

    // MARK: - Fetch Completed
    func fetchCompleted() -> [Goal] {
        let request = CDGoal.fetchCompletedRequest()

        do {
            let cdGoals = try context.fetch(request)
            return cdGoals.map { Goal(from: $0) }
        } catch {
            print("Failed to fetch completed goals: \(error)")
            return []
        }
    }

    // MARK: - Fetch by ID
    func fetch(byId id: UUID) -> Goal? {
        let request = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdGoal = try context.fetch(request).first {
                return Goal(from: cdGoal)
            }
        } catch {
            print("Failed to fetch goal by ID: \(error)")
        }
        return nil
    }

    // MARK: - Fetch by Category
    func fetch(byCategory category: GoalCategory) -> [Goal] {
        let request = CDGoal.fetchRequest(forCategory: category.rawValue)

        do {
            let cdGoals = try context.fetch(request)
            return cdGoals.map { Goal(from: $0) }
        } catch {
            print("Failed to fetch goals by category: \(error)")
            return []
        }
    }

    // MARK: - Create
    @discardableResult
    func create(_ goal: Goal) -> Goal? {
        let cdGoal = goal.toCoreData(in: context)

        // Create milestones
        for milestone in goal.milestones {
            let _ = milestone.toCoreData(in: context, goal: cdGoal)
        }

        do {
            try context.save()
            refresh()
            return Goal(from: cdGoal)
        } catch {
            print("Failed to create goal: \(error)")
            context.rollback()
            return nil
        }
    }

    // MARK: - Update
    @discardableResult
    func update(_ goal: Goal) -> Bool {
        let request = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdGoal = try context.fetch(request).first {
                goal.updateCoreData(cdGoal, in: context)
                try context.save()
                refresh()
                return true
            }
        } catch {
            print("Failed to update goal: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Delete
    @discardableResult
    func delete(_ goal: Goal) -> Bool {
        let request = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdGoal = try context.fetch(request).first {
                context.delete(cdGoal)
                try context.save()
                refresh()
                return true
            }
        } catch {
            print("Failed to delete goal: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Milestone Operations
    @discardableResult
    func addMilestone(_ milestone: Milestone, to goalId: UUID) -> Bool {
        let request = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdGoal = try context.fetch(request).first {
                let cdMilestone = milestone.toCoreData(in: context, goal: cdGoal)
                cdGoal.addToMilestones(cdMilestone)
                try context.save()
                refresh()
                return true
            }
        } catch {
            print("Failed to add milestone: \(error)")
            context.rollback()
        }
        return false
    }

    @discardableResult
    func updateMilestone(_ milestone: Milestone, in goalId: UUID) -> Bool {
        let request = CDMilestone.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND goal.id == %@", milestone.id as CVarArg, goalId as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdMilestone = try context.fetch(request).first {
                milestone.updateCoreData(cdMilestone)
                try context.save()

                // Update goal progress
                if let goal = fetch(byId: goalId) {
                    var updatedGoal = goal
                    updatedGoal.updateProgress()
                    update(updatedGoal)
                }

                refresh()
                return true
            }
        } catch {
            print("Failed to update milestone: \(error)")
            context.rollback()
        }
        return false
    }

    @discardableResult
    func deleteMilestone(_ milestoneId: UUID, from goalId: UUID) -> Bool {
        let request = CDMilestone.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND goal.id == %@", milestoneId as CVarArg, goalId as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdMilestone = try context.fetch(request).first {
                context.delete(cdMilestone)
                try context.save()
                refresh()
                return true
            }
        } catch {
            print("Failed to delete milestone: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - AI Schedule
    @discardableResult
    func updateAISchedule(_ schedule: AISchedule, for goalId: UUID) -> Bool {
        let request = CDGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdGoal = try context.fetch(request).first {
                // Encrypt and store AI schedule
                if let jsonData = try? JSONEncoder().encode(schedule) {
                    cdGoal.aiScheduleData = try? EncryptionManager.shared.encryptData(jsonData)
                }
                cdGoal.lastAIUpdateAt = Date()
                cdGoal.updatedAt = Date()

                try context.save()
                refresh()
                return true
            }
        } catch {
            print("Failed to update AI schedule: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Toggle Milestone Complete
    @discardableResult
    func toggleMilestoneComplete(_ milestoneId: UUID, in goalId: UUID) -> Bool {
        let request = CDMilestone.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND goal.id == %@", milestoneId as CVarArg, goalId as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdMilestone = try context.fetch(request).first {
                cdMilestone.isCompleted.toggle()
                cdMilestone.completedAt = cdMilestone.isCompleted ? Date() : nil

                try context.save()

                // Update goal progress
                if let goal = fetch(byId: goalId) {
                    var updatedGoal = goal
                    updatedGoal.updateProgress()
                    update(updatedGoal)
                }

                refresh()
                HapticManager.shared.taskComplete()
                return true
            }
        } catch {
            print("Failed to toggle milestone: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Convenience Methods
    func goalsByCategory() -> [GoalCategory: [Goal]] {
        Dictionary(grouping: activeGoals) { $0.category }
    }

    func activeCount() -> Int {
        activeGoals.count
    }

    func completedCount() -> Int {
        goals.filter { $0.isCompleted }.count
    }

    func goalsWithAIPlan() -> [Goal] {
        activeGoals.filter { $0.hasAIPlan }
    }
}
