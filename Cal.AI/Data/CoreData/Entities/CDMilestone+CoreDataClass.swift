import Foundation
import CoreData

@objc(CDMilestone)
public class CDMilestone: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var targetDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var isAIGenerated: Bool
    @NSManaged public var orderIndex: Int16
    @NSManaged public var goal: CDGoal?
    @NSManaged public var createdAt: Date?
}

extension CDMilestone {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMilestone> {
        return NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
    }

    // Fetch milestones for a goal
    static func fetchRequest(forGoalId goalId: UUID) -> NSFetchRequest<CDMilestone> {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(format: "goal.id == %@", goalId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.orderIndex, ascending: true)]
        return request
    }

    // Fetch upcoming milestones
    static func fetchUpcomingRequest() -> NSFetchRequest<CDMilestone> {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(
            format: "isCompleted == false AND targetDate >= %@",
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.targetDate, ascending: true)]
        return request
    }

    // Fetch overdue milestones
    static func fetchOverdueRequest() -> NSFetchRequest<CDMilestone> {
        let request = NSFetchRequest<CDMilestone>(entityName: "CDMilestone")
        request.predicate = NSPredicate(
            format: "isCompleted == false AND targetDate < %@",
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMilestone.targetDate, ascending: true)]
        return request
    }

    // Status check
    var isOverdue: Bool {
        guard !isCompleted, let targetDate = targetDate else { return false }
        return targetDate < Date()
    }

    var daysUntilDue: Int? {
        guard let targetDate = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
    }
}

// MARK: - Entity Description
extension CDMilestone {
    static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDMilestone"
        entity.managedObjectClassName = NSStringFromClass(CDMilestone.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let targetDateAttribute = NSAttributeDescription()
        targetDateAttribute.name = "targetDate"
        targetDateAttribute.attributeType = .dateAttributeType
        targetDateAttribute.isOptional = true

        let isCompletedAttribute = NSAttributeDescription()
        isCompletedAttribute.name = "isCompleted"
        isCompletedAttribute.attributeType = .booleanAttributeType
        isCompletedAttribute.defaultValue = false

        let completedAtAttribute = NSAttributeDescription()
        completedAtAttribute.name = "completedAt"
        completedAtAttribute.attributeType = .dateAttributeType
        completedAtAttribute.isOptional = true

        let isAIGeneratedAttribute = NSAttributeDescription()
        isAIGeneratedAttribute.name = "isAIGenerated"
        isAIGeneratedAttribute.attributeType = .booleanAttributeType
        isAIGeneratedAttribute.defaultValue = false

        let orderIndexAttribute = NSAttributeDescription()
        orderIndexAttribute.name = "orderIndex"
        orderIndexAttribute.attributeType = .integer16AttributeType
        orderIndexAttribute.defaultValue = 0

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        entity.properties = [
            idAttribute, titleAttribute, targetDateAttribute, isCompletedAttribute,
            completedAtAttribute, isAIGeneratedAttribute, orderIndexAttribute, createdAtAttribute
        ]

        return entity
    }
}
