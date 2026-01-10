import Foundation
import SwiftUI
import Combine

@MainActor
class DataManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var tasks: [Task] = []
    @Published var goals: [Goal] = []
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?

    private let cloudKitManager = CloudKitManager.shared
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init() {
        loadLocalData()
    }

    // MARK: - Events

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEvents()
        Task { await syncToCloud() }
    }

    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            var updatedEvent = event
            updatedEvent = CalendarEvent(
                id: event.id,
                title: event.title,
                description: event.description,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                color: event.color,
                isAllDay: event.isAllDay,
                reminder: event.reminder,
                recurrence: event.recurrence,
                isFromAISchedule: event.isFromAISchedule,
                goalId: event.goalId
            )
            events[index] = updatedEvent
            saveEvents()
            Task { await syncToCloud() }
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents()
        Task { await syncToCloud() }
    }

    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date) ||
            (event.startDate <= date && event.endDate >= date)
        }.sorted { $0.startDate < $1.startDate }
    }

    func events(in range: ClosedRange<Date>) -> [CalendarEvent] {
        events.filter { event in
            range.contains(event.startDate) || range.contains(event.endDate) ||
            (event.startDate <= range.lowerBound && event.endDate >= range.upperBound)
        }.sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Tasks

    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        Task { await syncToCloud() }
    }

    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
            Task { await syncToCloud() }
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        Task { await syncToCloud() }
    }

    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.isCompleted.toggle()
            updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
            tasks[index] = updatedTask
            saveTasks()
            Task { await syncToCloud() }
        }
    }

    func tasks(for date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
        Task { await syncToCloud() }
    }

    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
            Task { await syncToCloud() }
        }
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        // Also remove related events and tasks
        events.removeAll { $0.goalId == goal.id }
        tasks.removeAll { $0.goalId == goal.id }
        saveGoals()
        saveEvents()
        saveTasks()
        Task { await syncToCloud() }
    }

    func toggleMilestoneCompletion(goalId: UUID, milestoneId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.id == milestoneId }) else {
            return
        }

        goals[goalIndex].milestones[milestoneIndex].isCompleted.toggle()
        goals[goalIndex].milestones[milestoneIndex].completedAt =
            goals[goalIndex].milestones[milestoneIndex].isCompleted ? Date() : nil

        // Update progress
        goals[goalIndex].progress = goals[goalIndex].calculatedProgress

        saveGoals()
        Task { await syncToCloud() }
    }

    var activeGoals: [Goal] {
        goals.filter { $0.isActive }
    }

    // MARK: - User Profile

    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
        Task { await syncToCloud() }
    }

    func updateSubscriptionStatus(_ status: SubscriptionStatus) {
        guard var profile = userProfile else { return }
        profile = UserProfile(
            id: profile.id,
            appleUserId: profile.appleUserId,
            email: profile.email,
            displayName: profile.displayName,
            profileInfo: profile.profileInfo,
            preferences: profile.preferences
        )
        userProfile = profile
        saveUserProfile()
    }

    // MARK: - AI Schedule Activities

    func markActivityComplete(goalId: UUID, dayOfWeek: Int, activityId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }),
              var schedule = goals[goalIndex].aiGeneratedSchedule,
              let dayIndex = schedule.weeklySchedule.firstIndex(where: { $0.dayOfWeek == dayOfWeek }),
              let activityIndex = schedule.weeklySchedule[dayIndex].activities.firstIndex(where: { $0.id == activityId }) else {
            return
        }

        schedule.weeklySchedule[dayIndex].activities[activityIndex].isCompleted = true
        schedule.weeklySchedule[dayIndex].activities[activityIndex].completedAt = Date()
        goals[goalIndex].aiGeneratedSchedule = schedule

        saveGoals()
        Task { await syncToCloud() }
    }

    func getCompletedActivities(for goalId: UUID) -> [ScheduledActivity] {
        guard let goal = goals.first(where: { $0.id == goalId }),
              let schedule = goal.aiGeneratedSchedule else { return [] }

        return schedule.weeklySchedule.flatMap { $0.activities.filter { $0.isCompleted } }
    }

    func getMissedActivities(for goalId: UUID) -> [ScheduledActivity] {
        guard let goal = goals.first(where: { $0.id == goalId }),
              let schedule = goal.aiGeneratedSchedule else { return [] }

        // Activities from past days that weren't completed
        let calendar = Calendar.current
        let currentDayOfWeek = calendar.component(.weekday, from: Date())

        return schedule.weeklySchedule
            .filter { $0.dayOfWeek < currentDayOfWeek }
            .flatMap { $0.activities.filter { !$0.isCompleted } }
    }

    // MARK: - Local Storage

    private func loadLocalData() {
        loadEvents()
        loadTasks()
        loadGoals()
        loadUserProfile()
    }

    private func loadEvents() {
        let url = documentsURL.appendingPathComponent("events.json")
        guard let data = try? Data(contentsOf: url) else { return }
        events = (try? JSONDecoder().decode([CalendarEvent].self, from: data)) ?? []
    }

    private func saveEvents() {
        let url = documentsURL.appendingPathComponent("events.json")
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: url, options: .atomicWrite)
    }

    private func loadTasks() {
        let url = documentsURL.appendingPathComponent("tasks.json")
        guard let data = try? Data(contentsOf: url) else { return }
        tasks = (try? JSONDecoder().decode([Task].self, from: data)) ?? []
    }

    private func saveTasks() {
        let url = documentsURL.appendingPathComponent("tasks.json")
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: url, options: .atomicWrite)
    }

    private func loadGoals() {
        let url = documentsURL.appendingPathComponent("goals.json")
        guard let data = try? Data(contentsOf: url) else { return }
        goals = (try? JSONDecoder().decode([Goal].self, from: data)) ?? []
    }

    private func saveGoals() {
        let url = documentsURL.appendingPathComponent("goals.json")
        guard let data = try? JSONEncoder().encode(goals) else { return }
        try? data.write(to: url, options: .atomicWrite)
    }

    private func loadUserProfile() {
        let url = documentsURL.appendingPathComponent("user_profile.json")
        guard let data = try? Data(contentsOf: url) else { return }
        userProfile = try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    private func saveUserProfile() {
        let url = documentsURL.appendingPathComponent("user_profile.json")
        guard let data = try? JSONEncoder().encode(userProfile) else { return }
        try? data.write(to: url, options: .atomicWrite)
    }

    // MARK: - Cloud Sync

    private func syncToCloud() async {
        await cloudKitManager.syncData(
            events: events,
            tasks: tasks,
            goals: goals,
            userProfile: userProfile
        )
    }

    func fetchFromCloud() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let cloudData = try await cloudKitManager.fetchAllData()
            events = cloudData.events
            tasks = cloudData.tasks
            goals = cloudData.goals
            if let profile = cloudData.userProfile {
                userProfile = profile
            }

            // Save locally
            saveEvents()
            saveTasks()
            saveGoals()
            saveUserProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Data Export (for user data portability)

    func exportUserData() -> Data? {
        struct ExportData: Codable {
            let events: [CalendarEvent]
            let tasks: [Task]
            let goals: [Goal]
            let userProfile: UserProfile?
            let exportDate: Date
        }

        let exportData = ExportData(
            events: events,
            tasks: tasks,
            goals: goals,
            userProfile: userProfile,
            exportDate: Date()
        )

        return try? JSONEncoder().encode(exportData)
    }

    func deleteAllUserData() {
        events = []
        tasks = []
        goals = []
        userProfile = nil

        saveEvents()
        saveTasks()
        saveGoals()
        saveUserProfile()

        Task {
            await cloudKitManager.deleteAllData()
        }

        // Clear keychain
        KeychainManager.shared.delete(key: "openai_api_key")
    }
}
