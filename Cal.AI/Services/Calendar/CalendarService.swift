import Foundation
import Combine

/// Calendar business logic service
final class CalendarService: ObservableObject {
    private let eventRepository: EventRepository
    private let taskRepository: TaskRepository

    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()

    init(
        eventRepository: EventRepository = EventRepository(),
        taskRepository: TaskRepository = TaskRepository()
    ) {
        self.eventRepository = eventRepository
        self.taskRepository = taskRepository
    }

    // MARK: - Date Navigation
    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
    }

    func previousMonth() {
        currentMonth = currentMonth.adding(.month, value: -1)
    }

    func nextMonth() {
        currentMonth = currentMonth.adding(.month, value: 1)
    }

    func setMonth(_ date: Date) {
        currentMonth = date
    }

    // MARK: - Calendar Data
    func daysForCurrentMonth() -> [Date?] {
        currentMonth.daysForCalendarGrid()
    }

    func weekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        let symbols = formatter.veryShortWeekdaySymbols!

        if Constants.Calendar.weekStartsOnMonday {
            return Array(symbols[1...]) + [symbols[0]]
        }
        return symbols
    }

    func monthYearString() -> String {
        currentMonth.monthYearString
    }

    // MARK: - Events for Dates
    func eventsForSelectedDate() -> [Event] {
        eventRepository.fetch(for: selectedDate)
    }

    func eventsForDate(_ date: Date) -> [Event] {
        eventRepository.fetch(for: date)
    }

    func eventCountForDate(_ date: Date) -> Int {
        eventsForDate(date).count
    }

    func hasEventsOnDate(_ date: Date) -> Bool {
        !eventsForDate(date).isEmpty
    }

    // MARK: - Tasks for Dates
    func tasksForSelectedDate() -> [CalTask] {
        taskRepository.fetchDueToday().filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate.isSameDay(as: selectedDate)
        }
    }

    func tasksForDate(_ date: Date) -> [CalTask] {
        taskRepository.fetchAll().filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate.isSameDay(as: date)
        }
    }

    // MARK: - Combined Schedule
    func scheduleForSelectedDate() -> DaySchedule {
        DaySchedule(
            date: selectedDate,
            events: eventsForSelectedDate(),
            tasks: tasksForSelectedDate()
        )
    }

    func scheduleForDate(_ date: Date) -> DaySchedule {
        DaySchedule(
            date: date,
            events: eventsForDate(date),
            tasks: tasksForDate(date)
        )
    }

    // MARK: - Month Overview
    func monthOverview() -> MonthOverview {
        let allDays = currentMonth.allDaysInMonth()
        var eventCounts: [Date: Int] = [:]
        var taskCounts: [Date: Int] = [:]

        for day in allDays {
            eventCounts[day.startOfDay] = eventCountForDate(day)
            taskCounts[day.startOfDay] = tasksForDate(day).count
        }

        return MonthOverview(
            month: currentMonth,
            eventCounts: eventCounts,
            taskCounts: taskCounts
        )
    }

    // MARK: - Today Summary
    func todaySummary() -> TodaySummary {
        let today = Date()
        let events = eventsForDate(today)
        let tasks = tasksForDate(today)
        let upcomingEvent = events.first { !$0.isPast }

        return TodaySummary(
            date: today,
            totalEvents: events.count,
            totalTasks: tasks.count,
            completedTasks: tasks.filter { $0.isCompleted }.count,
            upcomingEvent: upcomingEvent,
            currentEvent: events.first { $0.isHappeningNow }
        )
    }
}

// MARK: - Supporting Types
struct DaySchedule {
    let date: Date
    let events: [Event]
    let tasks: [CalTask]

    var isEmpty: Bool {
        events.isEmpty && tasks.isEmpty
    }

    var totalItems: Int {
        events.count + tasks.count
    }

    // Timeline items sorted by time
    var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        for event in events {
            items.append(TimelineItem(
                id: event.id,
                title: event.title,
                time: event.startDate,
                endTime: event.endDate,
                type: .event,
                color: event.color,
                isCompleted: false
            ))
        }

        for task in tasks {
            items.append(TimelineItem(
                id: task.id,
                title: task.title,
                time: task.dueDate ?? date.endOfDay,
                endTime: nil,
                type: .task,
                color: task.color,
                isCompleted: task.isCompleted
            ))
        }

        return items.sorted { $0.time < $1.time }
    }
}

struct TimelineItem: Identifiable {
    let id: UUID
    let title: String
    let time: Date
    let endTime: Date?
    let type: ItemType
    let color: String
    let isCompleted: Bool

    enum ItemType {
        case event
        case task
    }

    var timeString: String {
        time.timeString
    }

    var durationString: String? {
        guard let endTime = endTime else { return nil }
        let duration = endTime.timeIntervalSince(time)
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct MonthOverview {
    let month: Date
    let eventCounts: [Date: Int]
    let taskCounts: [Date: Int]

    func hasItems(on date: Date) -> Bool {
        (eventCounts[date.startOfDay] ?? 0) > 0 ||
        (taskCounts[date.startOfDay] ?? 0) > 0
    }

    func itemCount(on date: Date) -> Int {
        (eventCounts[date.startOfDay] ?? 0) + (taskCounts[date.startOfDay] ?? 0)
    }
}

struct TodaySummary {
    let date: Date
    let totalEvents: Int
    let totalTasks: Int
    let completedTasks: Int
    let upcomingEvent: Event?
    let currentEvent: Event?

    var pendingTasks: Int {
        totalTasks - completedTasks
    }

    var hasCurrentEvent: Bool {
        currentEvent != nil
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }
}
