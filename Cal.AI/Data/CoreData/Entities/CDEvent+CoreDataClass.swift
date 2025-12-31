import Foundation
import CoreData

@objc(CDEvent)
public class CDEvent: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var isAllDay: Bool
    @NSManaged public var category: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var recurrenceRuleData: Data? // Encoded RecurrenceRule
    @NSManaged public var reminderMinutes: Int16
    @NSManaged public var location: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension CDEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEvent> {
        return NSFetchRequest<CDEvent>(entityName: "CDEvent")
    }

    // Fetch events for a specific date range
    static func fetchRequest(from startDate: Date, to endDate: Date) -> NSFetchRequest<CDEvent> {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(
            format: "(startDate >= %@ AND startDate <= %@) OR (endDate >= %@ AND endDate <= %@) OR (startDate <= %@ AND endDate >= %@)",
            startDate as NSDate, endDate as NSDate,
            startDate as NSDate, endDate as NSDate,
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.startDate, ascending: true)]
        return request
    }

    // Fetch events for a specific day
    static func fetchRequest(for date: Date) -> NSFetchRequest<CDEvent> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchRequest(from: startOfDay, to: endOfDay)
    }
}

// MARK: - Entity Description
extension CDEvent {
    static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDEvent"
        entity.managedObjectClassName = NSStringFromClass(CDEvent.self)

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

        let startDateAttribute = NSAttributeDescription()
        startDateAttribute.name = "startDate"
        startDateAttribute.attributeType = .dateAttributeType
        startDateAttribute.isOptional = false

        let endDateAttribute = NSAttributeDescription()
        endDateAttribute.name = "endDate"
        endDateAttribute.attributeType = .dateAttributeType
        endDateAttribute.isOptional = false

        let isAllDayAttribute = NSAttributeDescription()
        isAllDayAttribute.name = "isAllDay"
        isAllDayAttribute.attributeType = .booleanAttributeType
        isAllDayAttribute.defaultValue = false

        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = true

        let colorHexAttribute = NSAttributeDescription()
        colorHexAttribute.name = "colorHex"
        colorHexAttribute.attributeType = .stringAttributeType
        colorHexAttribute.isOptional = true

        let recurrenceAttribute = NSAttributeDescription()
        recurrenceAttribute.name = "recurrenceRuleData"
        recurrenceAttribute.attributeType = .binaryDataAttributeType
        recurrenceAttribute.isOptional = true

        let reminderAttribute = NSAttributeDescription()
        reminderAttribute.name = "reminderMinutes"
        reminderAttribute.attributeType = .integer16AttributeType
        reminderAttribute.defaultValue = 15

        let locationAttribute = NSAttributeDescription()
        locationAttribute.name = "location"
        locationAttribute.attributeType = .stringAttributeType
        locationAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        entity.properties = [
            idAttribute, titleAttribute, notesAttribute, startDateAttribute, endDateAttribute,
            isAllDayAttribute, categoryAttribute, colorHexAttribute, recurrenceAttribute,
            reminderAttribute, locationAttribute, createdAtAttribute, updatedAtAttribute
        ]

        return entity
    }
}
