import Foundation
import CoreData

@objc(CDGoal)
public class CDGoal: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var goalDescription: String?
    @NSManaged public var targetDate: Date?
    @NSManaged public var category: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var progressPercentage: Double
    @NSManaged public var aiScheduleData: Data? // Encrypted JSON
    @NSManaged public var milestones: NSSet?
    @NSManaged public var tasks: NSSet?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastAIUpdateAt: Date?
}

// MARK: - Relationships
extension CDGoal {
    @objc(addMilestonesObject:)
    @NSManaged public func addToMilestones(_ value: CDMilestone)

    @objc(removeMilestonesObject:)
    @NSManaged public func removeFromMilestones(_ value: CDMilestone)

    @objc(addMilestones:)
    @NSManaged public func addToMilestones(_ values: NSSet)

    @objc(removeMilestones:)
    @NSManaged public func removeFromMilestones(_ values: NSSet)

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: CDTask)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: CDTask)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}

extension CDGoal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDGoal> {
        return NSFetchRequest<CDGoal>(entityName: "CDGoal")
    }

    // Fetch active goals
    static func fetchActiveRequest() -> NSFetchRequest<CDGoal> {
        let request = NSFetchRequest<CDGoal>(entityName: "CDGoal")
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDGoal.targetDate, ascending: true),
            NSSortDescriptor(keyPath: \CDGoal.createdAt, ascending: false)
        ]
        return request
    }

    // Fetch completed goals
    static func fetchCompletedRequest() -> NSFetchRequest<CDGoal> {
        let request = NSFetchRequest<CDGoal>(entityName: "CDGoal")
        request.predicate = NSPredicate(format: "isActive == false AND progressPercentage >= 100")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGoal.updatedAt, ascending: false)]
        return request
    }

    // Fetch goals by category
    static func fetchRequest(forCategory category: String) -> NSFetchRequest<CDGoal> {
        let request = NSFetchRequest<CDGoal>(entityName: "CDGoal")
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGoal.targetDate, ascending: true)]
        return request
    }

    // Computed properties
    var milestonesArray: [CDMilestone] {
        let set = milestones as? Set<CDMilestone> ?? []
        return set.sorted { ($0.orderIndex) < ($1.orderIndex) }
    }

    var tasksArray: [CDTask] {
        let set = tasks as? Set<CDTask> ?? []
        return set.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    var completedMilestonesCount: Int {
        milestonesArray.filter { $0.isCompleted }.count
    }

    var completedTasksCount: Int {
        tasksArray.filter { $0.isCompleted }.count
    }
}

// MARK: - Entity Description
extension CDGoal {
    static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDGoal"
        entity.managedObjectClassName = NSStringFromClass(CDGoal.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let descriptionAttribute = NSAttributeDescription()
        descriptionAttribute.name = "goalDescription"
        descriptionAttribute.attributeType = .stringAttributeType
        descriptionAttribute.isOptional = true

        let targetDateAttribute = NSAttributeDescription()
        targetDateAttribute.name = "targetDate"
        targetDateAttribute.attributeType = .dateAttributeType
        targetDateAttribute.isOptional = true

        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = true

        let isActiveAttribute = NSAttributeDescription()
        isActiveAttribute.name = "isActive"
        isActiveAttribute.attributeType = .booleanAttributeType
        isActiveAttribute.defaultValue = true

        let progressAttribute = NSAttributeDescription()
        progressAttribute.name = "progressPercentage"
        progressAttribute.attributeType = .doubleAttributeType
        progressAttribute.defaultValue = 0.0

        let aiScheduleAttribute = NSAttributeDescription()
        aiScheduleAttribute.name = "aiScheduleData"
        aiScheduleAttribute.attributeType = .binaryDataAttributeType
        aiScheduleAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        let lastAIUpdateAttribute = NSAttributeDescription()
        lastAIUpdateAttribute.name = "lastAIUpdateAt"
        lastAIUpdateAttribute.attributeType = .dateAttributeType
        lastAIUpdateAttribute.isOptional = true

        entity.properties = [
            idAttribute, titleAttribute, descriptionAttribute, targetDateAttribute,
            categoryAttribute, isActiveAttribute, progressAttribute, aiScheduleAttribute,
            createdAtAttribute, updatedAtAttribute, lastAIUpdateAttribute
        ]

        return entity
    }
}
