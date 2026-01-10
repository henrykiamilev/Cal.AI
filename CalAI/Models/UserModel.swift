import Foundation

struct UserProfile: Codable {
    let id: UUID
    var appleUserId: String?
    var email: String?
    var displayName: String
    var profileInfo: ProfileInfo
    var preferences: UserPreferences
    var subscriptionStatus: SubscriptionStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        appleUserId: String? = nil,
        email: String? = nil,
        displayName: String = "",
        profileInfo: ProfileInfo = ProfileInfo(),
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.email = email
        self.displayName = displayName
        self.profileInfo = profileInfo
        self.preferences = preferences
        self.subscriptionStatus = .free
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct ProfileInfo: Codable {
    var age: Int?
    var occupation: String?
    var workSchedule: WorkSchedule?
    var sleepSchedule: SleepSchedule?
    var fitnessLevel: FitnessLevel?
    var learningStyle: LearningStyle?
    var availableHoursPerWeek: Int?
    var timezone: String

    init(
        age: Int? = nil,
        occupation: String? = nil,
        workSchedule: WorkSchedule? = nil,
        sleepSchedule: SleepSchedule? = nil,
        fitnessLevel: FitnessLevel? = nil,
        learningStyle: LearningStyle? = nil,
        availableHoursPerWeek: Int? = nil
    ) {
        self.age = age
        self.occupation = occupation
        self.workSchedule = workSchedule
        self.sleepSchedule = sleepSchedule
        self.fitnessLevel = fitnessLevel
        self.learningStyle = learningStyle
        self.availableHoursPerWeek = availableHoursPerWeek
        self.timezone = TimeZone.current.identifier
    }
}

struct WorkSchedule: Codable {
    var workDays: [Int] // 1-7, Sunday = 1
    var startTime: String // HH:mm
    var endTime: String // HH:mm

    init(workDays: [Int] = [2, 3, 4, 5, 6], startTime: String = "09:00", endTime: String = "17:00") {
        self.workDays = workDays
        self.startTime = startTime
        self.endTime = endTime
    }
}

struct SleepSchedule: Codable {
    var bedtime: String // HH:mm
    var wakeTime: String // HH:mm

    init(bedtime: String = "23:00", wakeTime: String = "07:00") {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
    }
}

enum FitnessLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case athlete = "Athlete"
}

enum LearningStyle: String, Codable, CaseIterable {
    case visual = "Visual"
    case auditory = "Auditory"
    case readingWriting = "Reading/Writing"
    case kinesthetic = "Hands-on"
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool
    var reminderTime: Int // minutes before
    var theme: AppTheme
    var calendarStartDay: Int // 1 = Sunday, 2 = Monday
    var showWeekNumbers: Bool
    var defaultEventDuration: Int // minutes
    var defaultReminderType: ReminderType

    init(
        notificationsEnabled: Bool = true,
        reminderTime: Int = 15,
        theme: AppTheme = .system,
        calendarStartDay: Int = 1,
        showWeekNumbers: Bool = false,
        defaultEventDuration: Int = 60,
        defaultReminderType: ReminderType = .fifteenMinutes
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.theme = theme
        self.calendarStartDay = calendarStartDay
        self.showWeekNumbers = showWeekNumbers
        self.defaultEventDuration = defaultEventDuration
        self.defaultReminderType = defaultReminderType
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

enum SubscriptionStatus: String, Codable {
    case free = "Free"
    case premium = "Premium"
    case expired = "Expired"

    var canUseAI: Bool {
        self == .premium
    }
}
