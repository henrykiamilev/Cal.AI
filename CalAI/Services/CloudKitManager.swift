import Foundation
import CloudKit

actor CloudKitManager {
    static let shared = CloudKitManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private init() {
        container = CKContainer(identifier: "iCloud.com.calai.app")
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Record Types

    private enum RecordType {
        static let event = "CalendarEvent"
        static let task = "Task"
        static let goal = "Goal"
        static let userProfile = "UserProfile"
    }

    // MARK: - Sync

    func syncData(
        events: [CalendarEvent],
        tasks: [Task],
        goals: [Goal],
        userProfile: UserProfile?
    ) async {
        // Batch save all records
        var recordsToSave: [CKRecord] = []

        for event in events {
            recordsToSave.append(createRecord(from: event))
        }

        for task in tasks {
            recordsToSave.append(createRecord(from: task))
        }

        for goal in goals {
            recordsToSave.append(createRecord(from: goal))
        }

        if let profile = userProfile {
            recordsToSave.append(createRecord(from: profile))
        }

        guard !recordsToSave.isEmpty else { return }

        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys

        do {
            try await privateDatabase.modifyRecords(saving: recordsToSave, deleting: [])
        } catch {
            print("CloudKit sync error: \(error.localizedDescription)")
        }
    }

    func fetchAllData() async throws -> CloudData {
        async let eventRecords = fetchRecords(ofType: RecordType.event)
        async let taskRecords = fetchRecords(ofType: RecordType.task)
        async let goalRecords = fetchRecords(ofType: RecordType.goal)
        async let profileRecords = fetchRecords(ofType: RecordType.userProfile)

        let (events, tasks, goals, profiles) = try await (eventRecords, taskRecords, goalRecords, profileRecords)

        return CloudData(
            events: events.compactMap { parseEvent(from: $0) },
            tasks: tasks.compactMap { parseTask(from: $0) },
            goals: goals.compactMap { parseGoal(from: $0) },
            userProfile: profiles.first.flatMap { parseUserProfile(from: $0) }
        )
    }

    private func fetchRecords(ofType type: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)

        return matchResults.compactMap { _, result in
            try? result.get()
        }
    }

    func deleteAllData() async {
        do {
            // Fetch all record IDs
            let eventIDs = try await fetchRecordIDs(ofType: RecordType.event)
            let taskIDs = try await fetchRecordIDs(ofType: RecordType.task)
            let goalIDs = try await fetchRecordIDs(ofType: RecordType.goal)
            let profileIDs = try await fetchRecordIDs(ofType: RecordType.userProfile)

            let allIDs = eventIDs + taskIDs + goalIDs + profileIDs

            guard !allIDs.isEmpty else { return }

            try await privateDatabase.modifyRecords(saving: [], deleting: allIDs)
        } catch {
            print("CloudKit delete error: \(error.localizedDescription)")
        }
    }

    private func fetchRecordIDs(ofType type: String) async throws -> [CKRecord.ID] {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query, desiredKeys: [])

        return matchResults.compactMap { id, _ in id }
    }

    // MARK: - Record Creation

    private func createRecord(from event: CalendarEvent) -> CKRecord {
        let recordID = CKRecord.ID(recordName: event.id.uuidString)
        let record = CKRecord(recordType: RecordType.event, recordID: recordID)

        record["title"] = event.title
        record["description"] = event.description
        record["startDate"] = event.startDate
        record["endDate"] = event.endDate
        record["location"] = event.location
        record["color"] = event.color
        record["isAllDay"] = event.isAllDay
        record["isFromAISchedule"] = event.isFromAISchedule
        record["goalId"] = event.goalId?.uuidString
        record["reminder"] = event.reminder?.rawValue
        record["recurrence"] = event.recurrence?.rawValue

        return record
    }

    private func createRecord(from task: Task) -> CKRecord {
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        let record = CKRecord(recordType: RecordType.task, recordID: recordID)

        record["title"] = task.title
        record["description"] = task.description
        record["dueDate"] = task.dueDate
        record["priority"] = task.priority.rawValue
        record["category"] = task.category.rawValue
        record["isCompleted"] = task.isCompleted
        record["completedAt"] = task.completedAt
        record["isFromAISchedule"] = task.isFromAISchedule
        record["goalId"] = task.goalId?.uuidString

        // Encode subtasks as JSON
        if let subtasksData = try? JSONEncoder().encode(task.subtasks) {
            record["subtasks"] = String(data: subtasksData, encoding: .utf8)
        }

        return record
    }

    private func createRecord(from goal: Goal) -> CKRecord {
        let recordID = CKRecord.ID(recordName: goal.id.uuidString)
        let record = CKRecord(recordType: RecordType.goal, recordID: recordID)

        record["title"] = goal.title
        record["description"] = goal.description
        record["category"] = goal.category.rawValue
        record["targetDate"] = goal.targetDate
        record["isActive"] = goal.isActive
        record["progress"] = goal.progress

        // Encode complex data as JSON
        if let milestonesData = try? JSONEncoder().encode(goal.milestones) {
            record["milestones"] = String(data: milestonesData, encoding: .utf8)
        }

        if let scheduleData = try? JSONEncoder().encode(goal.aiGeneratedSchedule) {
            record["aiGeneratedSchedule"] = String(data: scheduleData, encoding: .utf8)
        }

        return record
    }

    private func createRecord(from profile: UserProfile) -> CKRecord {
        let recordID = CKRecord.ID(recordName: profile.id.uuidString)
        let record = CKRecord(recordType: RecordType.userProfile, recordID: recordID)

        record["displayName"] = profile.displayName
        record["email"] = profile.email
        record["appleUserId"] = profile.appleUserId

        // Encode complex data as JSON
        if let profileInfoData = try? JSONEncoder().encode(profile.profileInfo) {
            record["profileInfo"] = String(data: profileInfoData, encoding: .utf8)
        }

        if let preferencesData = try? JSONEncoder().encode(profile.preferences) {
            record["preferences"] = String(data: preferencesData, encoding: .utf8)
        }

        return record
    }

    // MARK: - Record Parsing

    private func parseEvent(from record: CKRecord) -> CalendarEvent? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date else {
            return nil
        }

        let reminder: ReminderType? = (record["reminder"] as? String).flatMap { ReminderType(rawValue: $0) }
        let recurrence: RecurrenceType? = (record["recurrence"] as? String).flatMap { RecurrenceType(rawValue: $0) }

        return CalendarEvent(
            id: id,
            title: title,
            description: record["description"] as? String ?? "",
            startDate: startDate,
            endDate: endDate,
            location: record["location"] as? String,
            color: record["color"] as? String ?? "blue",
            isAllDay: record["isAllDay"] as? Bool ?? false,
            reminder: reminder,
            recurrence: recurrence,
            isFromAISchedule: record["isFromAISchedule"] as? Bool ?? false,
            goalId: (record["goalId"] as? String).flatMap { UUID(uuidString: $0) }
        )
    }

    private func parseTask(from record: CKRecord) -> Task? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String else {
            return nil
        }

        var subtasks: [Subtask] = []
        if let subtasksString = record["subtasks"] as? String,
           let data = subtasksString.data(using: .utf8) {
            subtasks = (try? JSONDecoder().decode([Subtask].self, from: data)) ?? []
        }

        return Task(
            id: id,
            title: title,
            description: record["description"] as? String ?? "",
            dueDate: record["dueDate"] as? Date,
            priority: Priority(rawValue: record["priority"] as? String ?? "") ?? .medium,
            category: TaskCategory(rawValue: record["category"] as? String ?? "") ?? .general,
            isCompleted: record["isCompleted"] as? Bool ?? false,
            isFromAISchedule: record["isFromAISchedule"] as? Bool ?? false,
            goalId: (record["goalId"] as? String).flatMap { UUID(uuidString: $0) },
            subtasks: subtasks
        )
    }

    private func parseGoal(from record: CKRecord) -> Goal? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String else {
            return nil
        }

        var milestones: [Milestone] = []
        if let milestonesString = record["milestones"] as? String,
           let data = milestonesString.data(using: .utf8) {
            milestones = (try? JSONDecoder().decode([Milestone].self, from: data)) ?? []
        }

        var aiSchedule: AISchedule? = nil
        if let scheduleString = record["aiGeneratedSchedule"] as? String,
           let data = scheduleString.data(using: .utf8) {
            aiSchedule = try? JSONDecoder().decode(AISchedule.self, from: data)
        }

        return Goal(
            id: id,
            title: title,
            description: record["description"] as? String ?? "",
            category: GoalCategory(rawValue: record["category"] as? String ?? "") ?? .personal,
            targetDate: record["targetDate"] as? Date,
            aiGeneratedSchedule: aiSchedule,
            milestones: milestones,
            isActive: record["isActive"] as? Bool ?? true
        )
    }

    private func parseUserProfile(from record: CKRecord) -> UserProfile? {
        guard let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }

        var profileInfo = ProfileInfo()
        if let profileInfoString = record["profileInfo"] as? String,
           let data = profileInfoString.data(using: .utf8) {
            profileInfo = (try? JSONDecoder().decode(ProfileInfo.self, from: data)) ?? ProfileInfo()
        }

        var preferences = UserPreferences()
        if let preferencesString = record["preferences"] as? String,
           let data = preferencesString.data(using: .utf8) {
            preferences = (try? JSONDecoder().decode(UserPreferences.self, from: data)) ?? UserPreferences()
        }

        return UserProfile(
            id: id,
            appleUserId: record["appleUserId"] as? String,
            email: record["email"] as? String,
            displayName: record["displayName"] as? String ?? "",
            profileInfo: profileInfo,
            preferences: preferences
        )
    }
}

struct CloudData {
    let events: [CalendarEvent]
    let tasks: [Task]
    let goals: [Goal]
    let userProfile: UserProfile?
}
