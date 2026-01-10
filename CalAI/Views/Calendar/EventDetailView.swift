import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    // Header with color and title
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        HStack {
                            Circle()
                                .fill(event.eventColor)
                                .frame(width: 16, height: 16)

                            if event.isFromAISchedule {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("AI Generated")
                                }
                                .font(Theme.fontSmall)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.primaryGradient)
                                .cornerRadius(Theme.cornerRadiusSmall)
                            }
                        }

                        Text(event.title)
                            .font(Theme.fontTitle)
                            .foregroundColor(Theme.textPrimary)
                    }

                    // Time
                    DetailRow(
                        icon: "clock",
                        title: event.isAllDay ? "All Day" : event.formattedTimeRange,
                        subtitle: formatDateRange()
                    )

                    // Location
                    if let location = event.location, !location.isEmpty {
                        DetailRow(
                            icon: "location",
                            title: location,
                            subtitle: nil
                        )
                    }

                    // Description
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Description")
                                .font(Theme.fontCaption)
                                .foregroundColor(Theme.textSecondary)

                            Text(event.description)
                                .font(Theme.fontBody)
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Reminder
                    if let reminder = event.reminder {
                        DetailRow(
                            icon: "bell",
                            title: reminder.rawValue,
                            subtitle: nil
                        )
                    }

                    // Recurrence
                    if let recurrence = event.recurrence, recurrence != .none {
                        DetailRow(
                            icon: "repeat",
                            title: recurrence.rawValue,
                            subtitle: nil
                        )
                    }

                    Spacer(minLength: Theme.spacingXL)

                    // Delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Event")
                        }
                        .font(Theme.fontSubheadline)
                        .foregroundColor(Theme.errorColor)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingM)
                        .background(Theme.errorColor.opacity(0.1))
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingEditSheet = true }) {
                        Text("Edit")
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditEventView(event: event)
            }
            .alert("Delete Event", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    dataManager.deleteEvent(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()

        if event.startDate.isSameDay(as: event.endDate) {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: event.startDate)
        } else {
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: event.startDate)
            formatter.dateFormat = "MMM d, yyyy"
            let end = formatter.string(from: event.endDate)
            return "\(start) - \(end)"
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.primaryColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.backgroundSecondary)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Edit Event View

struct EditEventView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent

    @State private var title: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var selectedColor: String
    @State private var isAllDay: Bool
    @State private var reminder: ReminderType
    @State private var recurrence: RecurrenceType

    init(event: CalendarEvent) {
        self.event = event
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _location = State(initialValue: event.location ?? "")
        _selectedColor = State(initialValue: event.color)
        _isAllDay = State(initialValue: event.isAllDay)
        _reminder = State(initialValue: event.reminder ?? .none)
        _recurrence = State(initialValue: event.recurrence ?? .none)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Title
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Event Title")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextField("Enter event title", text: $title)
                            .font(Theme.fontBody)
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // All Day Toggle
                    Toggle(isOn: $isAllDay) {
                        HStack {
                            Image(systemName: "sun.max")
                                .foregroundColor(Theme.primaryColor)
                            Text("All Day")
                        }
                    }
                    .tint(Theme.primaryColor)
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)

                    // Date & Time
                    VStack(spacing: Theme.spacingM) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Theme.primaryColor)
                            Text("Start")
                            Spacer()
                            DatePicker("", selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                                .labelsHidden()
                        }

                        Divider()

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Theme.primaryColor)
                            Text("End")
                            Spacer()
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)

                    // Location
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Location")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Theme.textSecondary)
                            TextField("Add location", text: $location)
                        }
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Description")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(Theme.spacingS)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Color
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Color")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        ColorPickerGrid(selectedColor: $selectedColor)
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Reminder & Recurrence
                    HStack {
                        Picker("Reminder", selection: $reminder) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }

                        Picker("Repeat", selection: $recurrence) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(title.isEmpty ? Theme.textTertiary : Theme.primaryColor)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let updatedEvent = CalendarEvent(
            id: event.id,
            title: title.trimmed,
            description: description.trimmed,
            startDate: isAllDay ? startDate.startOfDay : startDate,
            endDate: isAllDay ? endDate.endOfDay : endDate,
            location: location.isEmpty ? nil : location.trimmed,
            color: selectedColor,
            isAllDay: isAllDay,
            reminder: reminder == .none ? nil : reminder,
            recurrence: recurrence == .none ? nil : recurrence,
            isFromAISchedule: event.isFromAISchedule,
            goalId: event.goalId
        )

        dataManager.updateEvent(updatedEvent)
        dismiss()
    }
}

#Preview {
    EventDetailView(event: CalendarEvent(
        title: "Team Meeting",
        description: "Weekly sync with the product team",
        startDate: Date(),
        endDate: Date().adding(days: 0),
        location: "Conference Room A"
    ))
    .environmentObject(DataManager())
}
