import Foundation
import CoreData

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var avatarData: Data?
    @NSManaged public var occupation: String?
    @NSManaged public var interests: NSObject? // Transformable [String]
    @NSManaged public var weeklyAvailableHours: Double
    @NSManaged public var preferredWorkTimesData: Data? // Encoded TimeRange array
    @NSManaged public var hasCompletedOnboarding: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension CDUserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }

    var interestsArray: [String] {
        get { interests as? [String] ?? [] }
        set { interests = newValue as NSObject }
    }
}

// MARK: - Entity Description
extension CDUserProfile {
    static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDUserProfile"
        entity.managedObjectClassName = NSStringFromClass(CDUserProfile.self)

        // Attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = true

        let emailAttribute = NSAttributeDescription()
        emailAttribute.name = "email"
        emailAttribute.attributeType = .stringAttributeType
        emailAttribute.isOptional = true

        let avatarDataAttribute = NSAttributeDescription()
        avatarDataAttribute.name = "avatarData"
        avatarDataAttribute.attributeType = .binaryDataAttributeType
        avatarDataAttribute.isOptional = true

        let occupationAttribute = NSAttributeDescription()
        occupationAttribute.name = "occupation"
        occupationAttribute.attributeType = .stringAttributeType
        occupationAttribute.isOptional = true

        let interestsAttribute = NSAttributeDescription()
        interestsAttribute.name = "interests"
        interestsAttribute.attributeType = .transformableAttributeType
        interestsAttribute.isOptional = true

        let weeklyHoursAttribute = NSAttributeDescription()
        weeklyHoursAttribute.name = "weeklyAvailableHours"
        weeklyHoursAttribute.attributeType = .doubleAttributeType
        weeklyHoursAttribute.defaultValue = 10.0

        let preferredTimesAttribute = NSAttributeDescription()
        preferredTimesAttribute.name = "preferredWorkTimesData"
        preferredTimesAttribute.attributeType = .binaryDataAttributeType
        preferredTimesAttribute.isOptional = true

        let onboardingAttribute = NSAttributeDescription()
        onboardingAttribute.name = "hasCompletedOnboarding"
        onboardingAttribute.attributeType = .booleanAttributeType
        onboardingAttribute.defaultValue = false

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        entity.properties = [
            idAttribute, nameAttribute, emailAttribute, avatarDataAttribute,
            occupationAttribute, interestsAttribute, weeklyHoursAttribute,
            preferredTimesAttribute, onboardingAttribute, createdAtAttribute, updatedAtAttribute
        ]

        return entity
    }
}
