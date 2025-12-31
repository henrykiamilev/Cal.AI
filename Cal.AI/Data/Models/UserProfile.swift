import Foundation
import SwiftUI
import CoreData

struct UserProfile: Codable, Hashable {
    var id: UUID
    var name: String
    var email: String?
    var avatarData: Data?
    var occupation: String?
    var interests: [String]
    var weeklyAvailableHours: Double
    var preferredWorkTimes: [TimeRange]
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String? = nil,
        avatarData: Data? = nil,
        occupation: String? = nil,
        interests: [String] = [],
        weeklyAvailableHours: Double = 10.0,
        preferredWorkTimes: [TimeRange] = [],
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarData = avatarData
        self.occupation = occupation
        self.interests = interests
        self.weeklyAvailableHours = weeklyAvailableHours
        self.preferredWorkTimes = preferredWorkTimes
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var initials: String {
        name.initials
    }

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }

    var dailyAvailableHours: Double {
        weeklyAvailableHours / 7
    }

    var hasAvatar: Bool {
        avatarData != nil
    }

    var interestsFormatted: String {
        interests.joined(separator: ", ")
    }

    mutating func addInterest(_ interest: String) {
        if !interests.contains(interest) {
            interests.append(interest)
            updatedAt = Date()
        }
    }

    mutating func removeInterest(_ interest: String) {
        interests.removeAll { $0 == interest }
        updatedAt = Date()
    }

    // MARK: - Greeting
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String

        switch hour {
        case 5..<12:
            timeOfDay = "Good morning"
        case 12..<17:
            timeOfDay = "Good afternoon"
        case 17..<22:
            timeOfDay = "Good evening"
        default:
            timeOfDay = "Hello"
        }

        if name.isNotEmpty {
            return "\(timeOfDay), \(firstName)"
        }
        return timeOfDay
    }
}

// MARK: - Time Range
struct TimeRange: Codable, Hashable {
    let dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    let startHour: Int // 0-23
    let endHour: Int   // 0-23

    init(dayOfWeek: Int, startHour: Int, endHour: Int) {
        self.dayOfWeek = dayOfWeek
        self.startHour = max(0, min(23, startHour))
        self.endHour = max(0, min(23, endHour))
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        guard let date = Calendar.current.date(bySetting: .weekday, value: dayOfWeek, of: Date()) else {
            return ""
        }
        return formatter.string(from: date)
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        guard let date = Calendar.current.date(bySetting: .weekday, value: dayOfWeek, of: Date()) else {
            return ""
        }
        return formatter.string(from: date)
    }

    var timeRangeFormatted: String {
        let startFormatted = formatHour(startHour)
        let endFormatted = formatHour(endHour)
        return "\(startFormatted) - \(endFormatted)"
    }

    var durationHours: Int {
        endHour - startHour
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    func contains(hour: Int) -> Bool {
        hour >= startHour && hour < endHour
    }
}

// MARK: - Core Data Conversion
extension UserProfile {
    init(from cdProfile: CDUserProfile) {
        self.id = cdProfile.id ?? UUID()
        self.name = cdProfile.name ?? ""
        self.email = cdProfile.email
        self.avatarData = cdProfile.avatarData
        self.occupation = cdProfile.occupation
        self.interests = cdProfile.interestsArray
        self.weeklyAvailableHours = cdProfile.weeklyAvailableHours

        if let timesData = cdProfile.preferredWorkTimesData {
            self.preferredWorkTimes = (try? JSONDecoder().decode([TimeRange].self, from: timesData)) ?? []
        } else {
            self.preferredWorkTimes = []
        }

        self.hasCompletedOnboarding = cdProfile.hasCompletedOnboarding
        self.createdAt = cdProfile.createdAt ?? Date()
        self.updatedAt = cdProfile.updatedAt ?? Date()
    }

    func toCoreData(in context: NSManagedObjectContext) -> CDUserProfile {
        let cdProfile = CDUserProfile(context: context)
        updateCoreData(cdProfile)
        return cdProfile
    }

    func updateCoreData(_ cdProfile: CDUserProfile) {
        cdProfile.id = id
        cdProfile.name = name
        cdProfile.email = email
        cdProfile.avatarData = avatarData
        cdProfile.occupation = occupation
        cdProfile.interestsArray = interests
        cdProfile.weeklyAvailableHours = weeklyAvailableHours
        cdProfile.preferredWorkTimesData = try? JSONEncoder().encode(preferredWorkTimes)
        cdProfile.hasCompletedOnboarding = hasCompletedOnboarding
        cdProfile.createdAt = createdAt
        cdProfile.updatedAt = Date()
    }
}

// MARK: - Interest Suggestions
extension UserProfile {
    static let suggestedInterests: [String] = [
        "Technology",
        "Fitness",
        "Reading",
        "Cooking",
        "Travel",
        "Music",
        "Art",
        "Photography",
        "Gaming",
        "Sports",
        "Writing",
        "Learning Languages",
        "Meditation",
        "Investing",
        "Entrepreneurship",
        "Science",
        "Nature",
        "Movies",
        "Fashion",
        "DIY Projects"
    ]

    static let occupationSuggestions: [String] = [
        "Student",
        "Software Engineer",
        "Designer",
        "Marketing",
        "Sales",
        "Finance",
        "Healthcare",
        "Education",
        "Entrepreneur",
        "Freelancer",
        "Manager",
        "Consultant",
        "Artist",
        "Writer",
        "Other"
    ]
}
