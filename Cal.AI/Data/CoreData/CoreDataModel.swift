import CoreData

/// Programmatic Core Data Model definition
/// This creates the data model without requiring an .xcdatamodeld file
final class CoreDataModel {
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create all entities
        let userProfileEntity = createUserProfileEntity()
        let eventEntity = createEventEntity()
        let taskEntity = createTaskEntity()
        let goalEntity = createGoalEntity()
        let milestoneEntity = createMilestoneEntity()

        // Set up relationships
        setupRelationships(
            taskEntity: taskEntity,
            goalEntity: goalEntity,
            milestoneEntity: milestoneEntity
        )

        model.entities = [userProfileEntity, eventEntity, taskEntity, goalEntity, milestoneEntity]

        return model
    }

    // MARK: - User Profile Entity
    private static func createUserProfileEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDUserProfile"
        entity.managedObjectClassName = NSStringFromClass(CDUserProfile.self)

        entity.properties = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("name", type: .stringAttributeType, optional: true),
            createAttribute("email", type: .stringAttributeType, optional: true),
            createAttribute("avatarData", type: .binaryDataAttributeType, optional: true),
            createAttribute("occupation", type: .stringAttributeType, optional: true),
            createAttribute("interests", type: .transformableAttributeType, optional: true),
            createAttribute("weeklyAvailableHours", type: .doubleAttributeType, optional: false, defaultValue: 10.0),
            createAttribute("preferredWorkTimesData", type: .binaryDataAttributeType, optional: true),
            createAttribute("hasCompletedOnboarding", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("createdAt", type: .dateAttributeType, optional: true),
            createAttribute("updatedAt", type: .dateAttributeType, optional: true)
        ]

        return entity
    }

    // MARK: - Event Entity
    private static func createEventEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDEvent"
        entity.managedObjectClassName = NSStringFromClass(CDEvent.self)

        entity.properties = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("title", type: .stringAttributeType, optional: false),
            createAttribute("notes", type: .stringAttributeType, optional: true),
            createAttribute("startDate", type: .dateAttributeType, optional: false),
            createAttribute("endDate", type: .dateAttributeType, optional: false),
            createAttribute("isAllDay", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("category", type: .stringAttributeType, optional: true),
            createAttribute("colorHex", type: .stringAttributeType, optional: true),
            createAttribute("recurrenceRuleData", type: .binaryDataAttributeType, optional: true),
            createAttribute("reminderMinutes", type: .integer16AttributeType, optional: false, defaultValue: 15),
            createAttribute("location", type: .stringAttributeType, optional: true),
            createAttribute("createdAt", type: .dateAttributeType, optional: true),
            createAttribute("updatedAt", type: .dateAttributeType, optional: true)
        ]

        return entity
    }

    // MARK: - Task Entity
    private static func createTaskEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDTask"
        entity.managedObjectClassName = NSStringFromClass(CDTask.self)

        entity.properties = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("title", type: .stringAttributeType, optional: false),
            createAttribute("notes", type: .stringAttributeType, optional: true),
            createAttribute("dueDate", type: .dateAttributeType, optional: true),
            createAttribute("priority", type: .integer16AttributeType, optional: false, defaultValue: 0),
            createAttribute("category", type: .stringAttributeType, optional: true),
            createAttribute("isCompleted", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("completedAt", type: .dateAttributeType, optional: true),
            createAttribute("colorHex", type: .stringAttributeType, optional: true),
            createAttribute("createdAt", type: .dateAttributeType, optional: true),
            createAttribute("updatedAt", type: .dateAttributeType, optional: true)
        ]

        return entity
    }

    // MARK: - Goal Entity
    private static func createGoalEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDGoal"
        entity.managedObjectClassName = NSStringFromClass(CDGoal.self)

        entity.properties = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("title", type: .stringAttributeType, optional: false),
            createAttribute("goalDescription", type: .stringAttributeType, optional: true),
            createAttribute("targetDate", type: .dateAttributeType, optional: true),
            createAttribute("category", type: .stringAttributeType, optional: true),
            createAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            createAttribute("progressPercentage", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            createAttribute("aiScheduleData", type: .binaryDataAttributeType, optional: true),
            createAttribute("createdAt", type: .dateAttributeType, optional: true),
            createAttribute("updatedAt", type: .dateAttributeType, optional: true),
            createAttribute("lastAIUpdateAt", type: .dateAttributeType, optional: true)
        ]

        return entity
    }

    // MARK: - Milestone Entity
    private static func createMilestoneEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDMilestone"
        entity.managedObjectClassName = NSStringFromClass(CDMilestone.self)

        entity.properties = [
            createAttribute("id", type: .UUIDAttributeType, optional: false),
            createAttribute("title", type: .stringAttributeType, optional: false),
            createAttribute("targetDate", type: .dateAttributeType, optional: true),
            createAttribute("isCompleted", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("completedAt", type: .dateAttributeType, optional: true),
            createAttribute("isAIGenerated", type: .booleanAttributeType, optional: false, defaultValue: false),
            createAttribute("orderIndex", type: .integer16AttributeType, optional: false, defaultValue: 0),
            createAttribute("createdAt", type: .dateAttributeType, optional: true)
        ]

        return entity
    }

    // MARK: - Relationships
    private static func setupRelationships(
        taskEntity: NSEntityDescription,
        goalEntity: NSEntityDescription,
        milestoneEntity: NSEntityDescription
    ) {
        // Task -> Goal (many-to-one)
        let taskToGoalRelation = NSRelationshipDescription()
        taskToGoalRelation.name = "parentGoal"
        taskToGoalRelation.destinationEntity = goalEntity
        taskToGoalRelation.minCount = 0
        taskToGoalRelation.maxCount = 1
        taskToGoalRelation.isOptional = true
        taskToGoalRelation.deleteRule = .nullifyDeleteRule

        // Goal -> Tasks (one-to-many)
        let goalToTasksRelation = NSRelationshipDescription()
        goalToTasksRelation.name = "tasks"
        goalToTasksRelation.destinationEntity = taskEntity
        goalToTasksRelation.minCount = 0
        goalToTasksRelation.maxCount = 0 // 0 means unlimited
        goalToTasksRelation.isOptional = true
        goalToTasksRelation.deleteRule = .cascadeDeleteRule

        // Set inverse relationships
        taskToGoalRelation.inverseRelationship = goalToTasksRelation
        goalToTasksRelation.inverseRelationship = taskToGoalRelation

        // Milestone -> Goal (many-to-one)
        let milestoneToGoalRelation = NSRelationshipDescription()
        milestoneToGoalRelation.name = "goal"
        milestoneToGoalRelation.destinationEntity = goalEntity
        milestoneToGoalRelation.minCount = 0
        milestoneToGoalRelation.maxCount = 1
        milestoneToGoalRelation.isOptional = true
        milestoneToGoalRelation.deleteRule = .nullifyDeleteRule

        // Goal -> Milestones (one-to-many)
        let goalToMilestonesRelation = NSRelationshipDescription()
        goalToMilestonesRelation.name = "milestones"
        goalToMilestonesRelation.destinationEntity = milestoneEntity
        goalToMilestonesRelation.minCount = 0
        goalToMilestonesRelation.maxCount = 0
        goalToMilestonesRelation.isOptional = true
        goalToMilestonesRelation.deleteRule = .cascadeDeleteRule

        // Set inverse relationships
        milestoneToGoalRelation.inverseRelationship = goalToMilestonesRelation
        goalToMilestonesRelation.inverseRelationship = milestoneToGoalRelation

        // Add relationships to entities
        var taskProperties = taskEntity.properties
        taskProperties.append(taskToGoalRelation)
        taskEntity.properties = taskProperties

        var goalProperties = goalEntity.properties
        goalProperties.append(goalToTasksRelation)
        goalProperties.append(goalToMilestonesRelation)
        goalEntity.properties = goalProperties

        var milestoneProperties = milestoneEntity.properties
        milestoneProperties.append(milestoneToGoalRelation)
        milestoneEntity.properties = milestoneProperties
    }

    // MARK: - Helper
    private static func createAttribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let defaultValue = defaultValue {
            attribute.defaultValue = defaultValue
        }
        return attribute
    }
}
