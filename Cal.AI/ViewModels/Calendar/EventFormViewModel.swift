import SwiftUI
import Combine

@MainActor
final class EventFormViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date().adding(.hour, value: 1)
    @Published var isAllDay: Bool = false
    @Published var category: EventCategory = .personal
    @Published var color: String = EventCategory.personal.defaultColor
    @Published var location: String = ""
    @Published var reminderMinutes: Int? = Constants.Notifications.defaultReminderMinutes
    @Published var recurrenceRule: RecurrenceRule? = nil

    // MARK: - State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation = false

    // MARK: - Mode
    let existingEvent: Event?
    var isEditing: Bool { existingEvent != nil }

    // MARK: - Dependencies
    private let eventRepository: EventRepository
    var onSave: ((Event) -> Void)?
    var onDelete: ((Event) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Validation
    var isValid: Bool {
        !title.trimmed.isEmpty && endDate > startDate
    }

    var titleError: String? {
        title.trimmed.isEmpty ? "Title is required" : nil
    }

    var dateError: String? {
        endDate <= startDate ? "End time must be after start time" : nil
    }

    // MARK: - Reminder Options
    let reminderOptions: [(String, Int?)] = [
        ("None", nil),
        ("At time of event", 0),
        ("5 minutes before", 5),
        ("15 minutes before", 15),
        ("30 minutes before", 30),
        ("1 hour before", 60),
        ("1 day before", 1440)
    ]

    // MARK: - Initialization
    init(
        event: Event? = nil,
        initialDate: Date = Date(),
        eventRepository: EventRepository = EventRepository()
    ) {
        self.existingEvent = event
        self.eventRepository = eventRepository

        if let event = event {
            // Editing existing event
            title = event.title
            notes = event.notes ?? ""
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            category = event.category
            color = event.color
            location = event.location ?? ""
            reminderMinutes = event.reminderMinutes
            recurrenceRule = event.recurrenceRule
        } else {
            // New event - use provided initial date
            startDate = initialDate
            endDate = initialDate.adding(.hour, value: 1)
        }
    }

    // MARK: - Category Selection
    func selectCategory(_ newCategory: EventCategory) {
        category = newCategory
        color = newCategory.defaultColor
    }

    // MARK: - Date Helpers
    func updateStartDate(_ date: Date) {
        startDate = date
        // Adjust end date to maintain duration
        if endDate <= startDate {
            endDate = startDate.adding(.hour, value: 1)
        }
    }

    func updateEndDate(_ date: Date) {
        endDate = date
    }

    // MARK: - Save
    func save() {
        guard isValid else {
            errorMessage = titleError ?? dateError ?? "Please fill in all required fields"
            return
        }

        isLoading = true
        errorMessage = nil

        let event = Event(
            id: existingEvent?.id ?? UUID(),
            title: title.trimmed,
            notes: notes.trimmed.isEmpty ? nil : notes.trimmed,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            category: category,
            color: color,
            recurrenceRule: recurrenceRule,
            reminderMinutes: reminderMinutes,
            location: location.trimmed.isEmpty ? nil : location.trimmed,
            createdAt: existingEvent?.createdAt ?? Date(),
            updatedAt: Date()
        )

        if isEditing {
            eventRepository.update(event)
        } else {
            eventRepository.create(event)
        }

        isLoading = false
        onSave?(event)
        onDismiss?()
    }

    // MARK: - Delete
    func confirmDelete() {
        showingDeleteConfirmation = true
    }

    func delete() {
        guard let event = existingEvent else { return }

        isLoading = true
        eventRepository.delete(event)
        isLoading = false

        onDelete?(event)
        onDismiss?()
    }

    // MARK: - Cancel
    func cancel() {
        onDismiss?()
    }
}
