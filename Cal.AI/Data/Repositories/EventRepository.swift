import Foundation
import CoreData
import Combine

protocol EventRepositoryProtocol {
    func fetchAll() -> [Event]
    func fetch(for date: Date) -> [Event]
    func fetch(from startDate: Date, to endDate: Date) -> [Event]
    func fetch(byId id: UUID) -> Event?
    func create(_ event: Event) -> Event?
    func update(_ event: Event) -> Bool
    func delete(_ event: Event) -> Bool
    func deleteById(_ id: UUID) -> Bool
}

final class EventRepository: EventRepositoryProtocol, ObservableObject {
    private let context: NSManagedObjectContext
    private let persistenceController: PersistenceController

    @Published var events: [Event] = []

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.persistenceController = PersistenceController.shared
        loadEvents()
    }

    // MARK: - Load Events
    private func loadEvents() {
        events = fetchAll()
    }

    func refresh() {
        loadEvents()
    }

    // MARK: - Fetch All
    func fetchAll() -> [Event] {
        let request = CDEvent.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.startDate, ascending: true)]

        do {
            let cdEvents = try context.fetch(request)
            return cdEvents.map { Event(from: $0) }
        } catch {
            print("Failed to fetch events: \(error)")
            return []
        }
    }

    // MARK: - Fetch for Date
    func fetch(for date: Date) -> [Event] {
        let request = CDEvent.fetchRequest(for: date)

        do {
            let cdEvents = try context.fetch(request)
            return cdEvents.map { Event(from: $0) }
        } catch {
            print("Failed to fetch events for date: \(error)")
            return []
        }
    }

    // MARK: - Fetch Date Range
    func fetch(from startDate: Date, to endDate: Date) -> [Event] {
        let request = CDEvent.fetchRequest(from: startDate, to: endDate)

        do {
            let cdEvents = try context.fetch(request)
            return cdEvents.map { Event(from: $0) }
        } catch {
            print("Failed to fetch events in range: \(error)")
            return []
        }
    }

    // MARK: - Fetch by ID
    func fetch(byId id: UUID) -> Event? {
        let request = CDEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdEvent = try context.fetch(request).first {
                return Event(from: cdEvent)
            }
        } catch {
            print("Failed to fetch event by ID: \(error)")
        }
        return nil
    }

    // MARK: - Create
    @discardableResult
    func create(_ event: Event) -> Event? {
        let cdEvent = event.toCoreData(in: context)

        do {
            try context.save()
            refresh()

            // Schedule notification if reminder is set
            if let reminderMinutes = event.reminderMinutes {
                Task {
                    await NotificationManager.shared.scheduleEventReminder(
                        id: event.id.uuidString,
                        title: event.title,
                        body: event.notes ?? "Event starting soon",
                        date: event.startDate,
                        minutesBefore: reminderMinutes
                    )
                }
            }

            return Event(from: cdEvent)
        } catch {
            print("Failed to create event: \(error)")
            context.rollback()
            return nil
        }
    }

    // MARK: - Update
    @discardableResult
    func update(_ event: Event) -> Bool {
        let request = CDEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdEvent = try context.fetch(request).first {
                event.updateCoreData(cdEvent)
                try context.save()
                refresh()

                // Update notification
                NotificationManager.shared.cancelEventNotification(eventId: event.id.uuidString)
                if let reminderMinutes = event.reminderMinutes {
                    Task {
                        await NotificationManager.shared.scheduleEventReminder(
                            id: event.id.uuidString,
                            title: event.title,
                            body: event.notes ?? "Event starting soon",
                            date: event.startDate,
                            minutesBefore: reminderMinutes
                        )
                    }
                }

                return true
            }
        } catch {
            print("Failed to update event: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Delete
    @discardableResult
    func delete(_ event: Event) -> Bool {
        deleteById(event.id)
    }

    @discardableResult
    func deleteById(_ id: UUID) -> Bool {
        let request = CDEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            if let cdEvent = try context.fetch(request).first {
                context.delete(cdEvent)
                try context.save()
                refresh()

                // Cancel notification
                NotificationManager.shared.cancelEventNotification(eventId: id.uuidString)

                return true
            }
        } catch {
            print("Failed to delete event: \(error)")
            context.rollback()
        }
        return false
    }

    // MARK: - Convenience Methods
    func eventsForMonth(_ date: Date) -> [Date: [Event]] {
        let monthEvents = fetch(from: date.startOfMonth, to: date.endOfMonth)
        var grouped: [Date: [Event]] = [:]

        for event in monthEvents {
            let dayStart = event.startDate.startOfDay
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(event)
        }

        return grouped
    }

    func hasEvents(on date: Date) -> Bool {
        !fetch(for: date).isEmpty
    }

    func upcomingEvents(limit: Int = 10) -> [Event] {
        let request = CDEvent.fetchRequest()
        request.predicate = NSPredicate(format: "startDate >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEvent.startDate, ascending: true)]
        request.fetchLimit = limit

        do {
            let cdEvents = try context.fetch(request)
            return cdEvents.map { Event(from: $0) }
        } catch {
            print("Failed to fetch upcoming events: \(error)")
            return []
        }
    }
}
