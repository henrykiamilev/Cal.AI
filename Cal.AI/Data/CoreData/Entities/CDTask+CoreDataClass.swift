import Foundation
import CoreData

@objc(CDTask)
public class CDTask: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var priority: Int16 // 0=low, 1=medium, 2=high
    @NSManaged public var category: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var colorHex: String?
    @NSManaged public var parentGoal: CDGoal?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension CDTask {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTask> {
        return NSFetchRequest<CDTask>(entityName: "CDTask")
    }

    // Fetch incomplete tasks
    static func fetchIncompleteRequest() -> NSFetchRequest<CDTask> {
        let request = NSFetchRequest<CDTask>(entityName: "CDTask")
        request.predicate = NSPredicate(format: "isCompleted == false")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDTask.priority, ascending: false),
            NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)
        ]
        return request
    }

    // Fetch tasks due today
    static func fetchDueTodayRequest() -> NSFetchRequest<CDTask> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request = NSFetchRequest<CDTask>(entityName: "CDTask")
        request.predicate = NSPredicate(
            format: "isCompleted == false AND dueDate >= %@ AND dueDate < %@",
            startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDTask.priority, ascending: false),
            NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)
        ]
        return request
    }

    // Fetch overdue tasks
    static func fetchOverdueRequest() -> NSFetchRequest<CDTask> {
        let request = NSFetchRequest<CDTask>(entityName: "CDTask")
        request.predicate = NSPredicate(
            format: "isCompleted == false AND dueDate < %@",
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)]
        return request
    }

    // Fetch tasks for a goal
    static func fetchRequest(forGoalId goalId: UUID) -> NSFetchRequest<CDTask> {
        let request = NSFetchRequest<CDTask>(entityName: "CDTask")
        request.predicate = NSPredicate(format: "parentGoal.id == %@", goalId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)]
        return request
    }

    // Fetch completed tasks
    static func fetchCompletedRequest() -> NSFetchRequest<CDTask> {
        let request = NSFetchRequest<CDTask>(entityName: "CDTask")
        request.predicate = NSPredicate(format: "isCompleted == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTask.completedAt, ascending: false)]
        return request
    }
}

// MARK: - Entity Description
extension CDTask {
    static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDTask"
        entity.managedObjectClassName = NSStringFromClass(CDTask.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let notesAttribute = NSAttributeDescription()
        notesAttribute.name = "notes"
        notesAttribute.attributeType = .stringAttributeType
        notesAttribute.isOptional = true

        let dueDateAttribute = NSAttributeDescription()
        dueDateAttribute.name = "dueDate"
        dueDateAttribute.attributeType = .dateAttributeType
        dueDateAttribute.isOptional = true

        let priorityAttribute = NSAttributeDescription()
        priorityAttribute.name = "priority"
        priorityAttribute.attributeType = .integer16AttributeType
        priorityAttribute.defaultValue = 0

        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = true

        let isCompletedAttribute = NSAttributeDescription()
        isCompletedAttribute.name = "isCompleted"
        isCompletedAttribute.attributeType = .booleanAttributeType
        isCompletedAttribute.defaultValue = false

        let completedAtAttribute = NSAttributeDescription()
        completedAtAttribute.name = "completedAt"
        completedAtAttribute.attributeType = .dateAttributeType
        completedAtAttribute.isOptional = true

        let colorHexAttribute = NSAttributeDescription()
        colorHexAttribute.name = "colorHex"
        colorHexAttribute.attributeType = .stringAttributeType
        colorHexAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        entity.properties = [
            idAttribute, titleAttribute, notesAttribute, dueDateAttribute, priorityAttribute,
            categoryAttribute, isCompletedAttribute, completedAtAttribute, colorHexAttribute,
            createdAtAttribute, updatedAtAttribute
        ]

        return entity
    }
}
