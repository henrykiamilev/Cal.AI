import SwiftUI
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var events: [Event] = []
    @Published var monthEvents: [Date: [Event]] = [:]
    @Published var isLoading = false
    @Published var showingEventForm = false
    @Published var selectedEvent: Event?

    // MARK: - Dependencies
    private let eventRepository: EventRepository
    private let calendarService: CalendarService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var daysInMonth: [Date?] {
        currentMonth.daysForCalendarGrid()
    }

    var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        let symbols = formatter.veryShortWeekdaySymbols!
        if Constants.Calendar.weekStartsOnMonday {
            return Array(symbols[1...]) + [symbols[0]]
        }
        return symbols
    }

    var monthYearString: String {
        currentMonth.monthYearString
    }

    var selectedDateEvents: [Event] {
        eventRepository.fetch(for: selectedDate)
    }

    var todaySummary: TodaySummary {
        calendarService.todaySummary()
    }

    // MARK: - Initialization
    init(
        eventRepository: EventRepository = EventRepository(),
        calendarService: CalendarService = CalendarService()
    ) {
        self.eventRepository = eventRepository
        self.calendarService = calendarService

        setupBindings()
        loadEvents()
    }

    private func setupBindings() {
        eventRepository.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.events = events
                self?.loadMonthEvents()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func loadEvents() {
        isLoading = true
        events = eventRepository.fetchAll()
        loadMonthEvents()
        isLoading = false
    }

    private func loadMonthEvents() {
        monthEvents = eventRepository.eventsForMonth(currentMonth)
    }

    // MARK: - Date Navigation
    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
        loadMonthEvents()
    }

    func previousMonth() {
        currentMonth = currentMonth.adding(.month, value: -1)
        loadMonthEvents()
    }

    func nextMonth() {
        currentMonth = currentMonth.adding(.month, value: 1)
        loadMonthEvents()
    }

    // MARK: - Date Helpers
    func isToday(_ date: Date) -> Bool {
        date.isToday
    }

    func isSelected(_ date: Date) -> Bool {
        date.isSameDay(as: selectedDate)
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        date.isSameMonth(as: currentMonth)
    }

    func events(for date: Date) -> [Event] {
        monthEvents[date.startOfDay] ?? []
    }

    func hasEvents(on date: Date) -> Bool {
        !events(for: date).isEmpty
    }

    // MARK: - Event Management
    func createEvent(_ event: Event) {
        eventRepository.create(event)
        loadMonthEvents()
    }

    func updateEvent(_ event: Event) {
        eventRepository.update(event)
        loadMonthEvents()
    }

    func deleteEvent(_ event: Event) {
        eventRepository.delete(event)
        loadMonthEvents()
    }

    // MARK: - Event Form
    func showNewEventForm() {
        selectedEvent = nil
        showingEventForm = true
    }

    func showEditEventForm(for event: Event) {
        selectedEvent = event
        showingEventForm = true
    }

    func dismissEventForm() {
        showingEventForm = false
        selectedEvent = nil
    }
}
