import Foundation

extension Date {
    // MARK: - Calendar Helpers
    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = Constants.Calendar.weekStartsOnMonday ? 2 : 1
        return calendar
    }

    var startOfDay: Date {
        Self.calendar.startOfDay(for: self)
    }

    var endOfDay: Date {
        Self.calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    var startOfWeek: Date {
        Self.calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }

    var endOfWeek: Date {
        Self.calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        Self.calendar.date(from: Self.calendar.dateComponents([.year, .month], from: self)) ?? self
    }

    var endOfMonth: Date {
        Self.calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    // MARK: - Component Accessors
    var year: Int {
        Self.calendar.component(.year, from: self)
    }

    var month: Int {
        Self.calendar.component(.month, from: self)
    }

    var day: Int {
        Self.calendar.component(.day, from: self)
    }

    var hour: Int {
        Self.calendar.component(.hour, from: self)
    }

    var minute: Int {
        Self.calendar.component(.minute, from: self)
    }

    var weekday: Int {
        Self.calendar.component(.weekday, from: self)
    }

    var weekOfYear: Int {
        Self.calendar.component(.weekOfYear, from: self)
    }

    var isToday: Bool {
        Self.calendar.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Self.calendar.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Self.calendar.isDateInYesterday(self)
    }

    var isWeekend: Bool {
        Self.calendar.isDateInWeekend(self)
    }

    var isPast: Bool {
        self < Date()
    }

    var isFuture: Bool {
        self > Date()
    }

    // MARK: - Date Arithmetic
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        Self.calendar.date(byAdding: component, value: value, to: self) ?? self
    }

    func days(from date: Date) -> Int {
        Self.calendar.dateComponents([.day], from: date.startOfDay, to: self.startOfDay).day ?? 0
    }

    func weeks(from date: Date) -> Int {
        Self.calendar.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }

    func months(from date: Date) -> Int {
        Self.calendar.dateComponents([.month], from: date, to: self).month ?? 0
    }

    func isSameDay(as date: Date) -> Bool {
        Self.calendar.isDate(self, inSameDayAs: date)
    }

    func isSameWeek(as date: Date) -> Bool {
        Self.calendar.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }

    func isSameMonth(as date: Date) -> Bool {
        Self.calendar.isDate(self, equalTo: date, toGranularity: .month)
    }

    // MARK: - Calendar Grid Helpers
    var daysInMonth: Int {
        Self.calendar.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    var firstWeekdayOfMonth: Int {
        Self.calendar.component(.weekday, from: startOfMonth)
    }

    func allDaysInMonth() -> [Date] {
        let range = Self.calendar.range(of: .day, in: .month, for: self)!
        return range.compactMap { day -> Date? in
            Self.calendar.date(bySetting: .day, value: day, of: startOfMonth)
        }
    }

    func daysForCalendarGrid() -> [Date?] {
        var days: [Date?] = []

        // Add empty slots for days before the first day of month
        let firstWeekday = firstWeekdayOfMonth
        let emptySlots = Constants.Calendar.weekStartsOnMonday ?
        (firstWeekday == 1 ? 6 : firstWeekday - 2) :
        (firstWeekday - 1)

        for _ in 0..<emptySlots {
            days.append(nil)
        }

        // Add all days in the month
        days.append(contentsOf: allDaysInMonth())

        return days
    }

    // MARK: - Formatting
    func formatted(as style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.rawValue
        return formatter.string(from: self)
    }

    var timeString: String {
        formatted(as: .time)
    }

    var shortDateString: String {
        formatted(as: .shortDate)
    }

    var mediumDateString: String {
        formatted(as: .mediumDate)
    }

    var fullDateString: String {
        formatted(as: .fullDate)
    }

    var monthYearString: String {
        formatted(as: .monthYear)
    }

    var dayOfWeekString: String {
        formatted(as: .dayOfWeek)
    }

    var relativeDateString: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else if isYesterday {
            return "Yesterday"
        } else if isSameWeek(as: Date()) {
            return dayOfWeekString
        } else {
            return mediumDateString
        }
    }

    enum DateFormatStyle: String {
        case time = "h:mm a"
        case time24 = "HH:mm"
        case shortDate = "M/d/yy"
        case mediumDate = "MMM d, yyyy"
        case fullDate = "EEEE, MMMM d, yyyy"
        case monthYear = "MMMM yyyy"
        case dayOfWeek = "EEEE"
        case shortDayOfWeek = "EEE"
        case dayMonth = "d MMM"
        case iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
}

// MARK: - Date Range
struct DateRange: Hashable {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    var durationInHours: Double {
        duration / 3600
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }

    func overlaps(with other: DateRange) -> Bool {
        start < other.end && end > other.start
    }
}
