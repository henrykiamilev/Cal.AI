import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var color: String
    var isAllDay: Bool
    var reminder: ReminderType?
    var recurrence: RecurrenceType?
    var isFromAISchedule: Bool
    var goalId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        color: String = "blue",
        isAllDay: Bool = false,
        reminder: ReminderType? = nil,
        recurrence: RecurrenceType? = nil,
        isFromAISchedule: Bool = false,
        goalId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.color = color
        self.isAllDay = isAllDay
        self.reminder = reminder
        self.recurrence = recurrence
        self.isFromAISchedule = isFromAISchedule
        self.goalId = goalId
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var eventColor: Color {
        switch color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return Theme.primaryColor
        }
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMinutes = "5 minutes before"
    case fifteenMinutes = "15 minutes before"
    case thirtyMinutes = "30 minutes before"
    case oneHour = "1 hour before"
    case oneDay = "1 day before"
    case oneWeek = "1 week before"

    var timeInterval: TimeInterval? {
        switch self {
        case .none: return nil
        case .atTime: return 0
        case .fiveMinutes: return -5 * 60
        case .fifteenMinutes: return -15 * 60
        case .thirtyMinutes: return -30 * 60
        case .oneHour: return -60 * 60
        case .oneDay: return -24 * 60 * 60
        case .oneWeek: return -7 * 24 * 60 * 60
        }
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case none = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 weeks"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum EventColor: String, CaseIterable {
    case red, orange, yellow, green, blue, purple, pink

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}
