import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        createSampleData(in: viewContext)

        return controller
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Cal_AI")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for encrypted storage
            if let storeDescription = container.persistentStoreDescriptions.first {
                // Enable file protection for data at rest
                storeDescription.setOption(
                    FileProtectionType.complete as NSObject,
                    forKey: NSPersistentStoreFileProtectionKey
                )

                // Enable automatic lightweight migration
                storeDescription.shouldMigrateStoreAutomatically = true
                storeDescription.shouldInferMappingModelAutomatically = true

                // Use application support directory
                let storeURL = Self.storeURL
                storeDescription.url = storeURL
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        // Configure context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Store Location
    private static var storeURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent(Constants.App.bundleId, isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        return appDirectory.appendingPathComponent("Cal_AI.sqlite")
    }

    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save
    func save() {
        let context = viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    // MARK: - Perform Background Task
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // MARK: - Delete All Data
    func deleteAllData() {
        let entities = container.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try container.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }

        save()
    }

    // MARK: - Sample Data for Previews
    private static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample user profile
        let profile = CDUserProfile(context: context)
        profile.id = UUID()
        profile.name = "John Doe"
        profile.email = "john@example.com"
        profile.occupation = "Software Engineer"
        profile.interests = ["Technology", "Fitness", "Reading"] as NSObject
        profile.weeklyAvailableHours = 15
        profile.hasCompletedOnboarding = true
        profile.createdAt = Date()
        profile.updatedAt = Date()

        // Create sample events
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<5 {
            let event = CDEvent(context: context)
            event.id = UUID()
            event.title = "Sample Event \(i + 1)"
            event.notes = "This is a sample event for preview"
            event.startDate = calendar.date(byAdding: .day, value: i, to: today)!
            event.endDate = calendar.date(byAdding: .hour, value: 1, to: event.startDate!)!
            event.isAllDay = false
            event.category = "personal"
            event.colorHex = "4A90E2"
            event.createdAt = Date()
            event.updatedAt = Date()
        }

        // Create sample tasks
        for i in 0..<3 {
            let task = CDTask(context: context)
            task.id = UUID()
            task.title = "Sample Task \(i + 1)"
            task.notes = "This is a sample task"
            task.dueDate = calendar.date(byAdding: .day, value: i + 1, to: today)
            task.priority = Int16(i % 3)
            task.category = "personal"
            task.isCompleted = false
            task.colorHex = "27AE60"
            task.createdAt = Date()
            task.updatedAt = Date()
        }

        // Create sample goal
        let goal = CDGoal(context: context)
        goal.id = UUID()
        goal.title = "Learn Swift"
        goal.goalDescription = "Master Swift programming language"
        goal.targetDate = calendar.date(byAdding: .month, value: 3, to: today)
        goal.category = "education"
        goal.isActive = true
        goal.progressPercentage = 25.0
        goal.createdAt = Date()
        goal.updatedAt = Date()

        // Create sample milestones
        for i in 0..<3 {
            let milestone = CDMilestone(context: context)
            milestone.id = UUID()
            milestone.title = "Milestone \(i + 1)"
            milestone.targetDate = calendar.date(byAdding: .month, value: i + 1, to: today)!
            milestone.isCompleted = i == 0
            milestone.completedAt = i == 0 ? Date() : nil
            milestone.isAIGenerated = true
            milestone.orderIndex = Int16(i)
            milestone.goal = goal
            milestone.createdAt = Date()
        }

        try? context.save()
    }
}
