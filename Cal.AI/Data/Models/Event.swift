import SwiftUI

struct Event: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var category: EventCategory
    var color: String // Hex color
    var recurrenceRule: RecurrenceRule?
    var reminderMinutes: Int?
    var location: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        category: EventCategory = .personal,
        color: String = "4A90E2",
        recurrenceRule: RecurrenceRule? = nil,
        reminderMinutes: Int? = Constants.Notifications.defaultReminderMinutes,
        location: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.category = category
        self.color = color
        self.recurrenceRule = recurrenceRule
        self.reminderMinutes = reminderMinutes
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var swiftUIColor: Color {
        Color(hex: color)
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    var durationFormatted: String {
        let hours = durationInMinutes / 60
        let minutes = durationInMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var timeRangeFormatted: String {
        if isAllDay {
            return "All Day"
        }
        return "\(startDate.timeString) - \(endDate.timeString)"
    }

    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var isPast: Bool {
        endDate < Date()
    }
}

// MARK: - Event Category
enum EventCategory: String, CaseIterable, Codable {
    case event = "event"
    case classSession = "class"
    case meeting = "meeting"
    case personal = "personal"
    case work = "work"
    case health = "health"
    case social = "social"

    var displayName: String {
        switch self {
        case .event: return "Event"
        case .classSession: return "Class"
        case .meeting: return "Meeting"
        case .personal: return "Personal"
        case .work: return "Work"
        case .health: return "Health"
        case .social: return "Social"
        }
    }

    var icon: String {
        switch self {
        case .event: return "calendar"
        case .classSession: return "book.fill"
        case .meeting: return "person.3.fill"
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .health: return "heart.fill"
        case .social: return "person.2.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .event: return "4A90E2"
        case .classSession: return "F39C12"
        case .meeting: return "3498DB"
        case .personal: return "9B59B6"
        case .work: return "1ABC9C"
        case .health: return "27AE60"
        case .social: return "E74C3C"
        }
    }
}

// MARK: - Recurrence Rule
struct RecurrenceRule: Codable, Hashable {
    var frequency: Frequency
    var interval: Int
    var endDate: Date?
    var count: Int?
    var daysOfWeek: [Int]? // 1-7 for Sun-Sat

    enum Frequency: String, Codable, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }

    var description: String {
        var text = ""

        if interval == 1 {
            text = frequency.displayName
        } else {
            switch frequency {
            case .daily: text = "Every \(interval) days"
            case .weekly: text = "Every \(interval) weeks"
            case .monthly: text = "Every \(interval) months"
            case .yearly: text = "Every \(interval) years"
            }
        }

        if let endDate = endDate {
            text += " until \(endDate.shortDateString)"
        } else if let count = count {
            text += ", \(count) times"
        }

        return text
    }

    init(
        frequency: Frequency,
        interval: Int = 1,
        endDate: Date? = nil,
        count: Int? = nil,
        daysOfWeek: [Int]? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.count = count
        self.daysOfWeek = daysOfWeek
    }
}

// MARK: - Core Data Conversion
extension Event {
    init(from cdEvent: CDEvent) {
        self.id = cdEvent.id ?? UUID()
        self.title = cdEvent.title ?? ""
        self.notes = cdEvent.notes
        self.startDate = cdEvent.startDate ?? Date()
        self.endDate = cdEvent.endDate ?? Date()
        self.isAllDay = cdEvent.isAllDay
        self.category = EventCategory(rawValue: cdEvent.category ?? "personal") ?? .personal
        self.color = cdEvent.colorHex ?? "4A90E2"

        if let ruleData = cdEvent.recurrenceRuleData {
            self.recurrenceRule = try? JSONDecoder().decode(RecurrenceRule.self, from: ruleData)
        } else {
            self.recurrenceRule = nil
        }

        self.reminderMinutes = cdEvent.reminderMinutes > 0 ? Int(cdEvent.reminderMinutes) : nil
        self.location = cdEvent.location
        self.createdAt = cdEvent.createdAt ?? Date()
        self.updatedAt = cdEvent.updatedAt ?? Date()
    }

    func toCoreData(in context: NSManagedObjectContext) -> CDEvent {
        let cdEvent = CDEvent(context: context)
        updateCoreData(cdEvent)
        return cdEvent
    }

    func updateCoreData(_ cdEvent: CDEvent) {
        cdEvent.id = id
        cdEvent.title = title
        cdEvent.notes = notes
        cdEvent.startDate = startDate
        cdEvent.endDate = endDate
        cdEvent.isAllDay = isAllDay
        cdEvent.category = category.rawValue
        cdEvent.colorHex = color
        cdEvent.recurrenceRuleData = try? JSONEncoder().encode(recurrenceRule)
        cdEvent.reminderMinutes = Int16(reminderMinutes ?? 0)
        cdEvent.location = location
        cdEvent.createdAt = createdAt
        cdEvent.updatedAt = Date()
    }
}

import CoreData
