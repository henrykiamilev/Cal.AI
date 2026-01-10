import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let selectedDate: Date

    @State private var title = ""
    @State private var description = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location = ""
    @State private var selectedColor = "blue"
    @State private var isAllDay = false
    @State private var reminder: ReminderType = .fifteenMinutes
    @State private var recurrence: RecurrenceType = .none

    init(selectedDate: Date) {
        self.selectedDate = selectedDate

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let startHour = max(hour + 1, 9)

        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? start

        _startDate = State(initialValue: start)
        _endDate = State(initialValue: end)
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
                                .font(Theme.fontBody)
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
                                .font(Theme.fontBody)
                            Spacer()
                            DatePicker("", selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                                .labelsHidden()
                        }

                        Divider()

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Theme.primaryColor)
                            Text("End")
                                .font(Theme.fontBody)
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
                        Text("Location (Optional)")
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
                        Text("Description (Optional)")
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

                    // Reminder
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Reminder")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        Picker("Reminder", selection: $reminder) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Recurrence
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Repeat")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        Picker("Repeat", selection: $recurrence) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("New Event")
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
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(title.isEmpty ? Theme.textTertiary : Theme.primaryColor)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveEvent() {
        let event = CalendarEvent(
            title: title.trimmed,
            description: description.trimmed,
            startDate: isAllDay ? startDate.startOfDay : startDate,
            endDate: isAllDay ? endDate.endOfDay : endDate,
            location: location.isEmpty ? nil : location.trimmed,
            color: selectedColor,
            isAllDay: isAllDay,
            reminder: reminder == .none ? nil : reminder,
            recurrence: recurrence == .none ? nil : recurrence
        )

        dataManager.addEvent(event)
        dismiss()
    }
}

#Preview {
    AddEventView(selectedDate: Date())
        .environmentObject(DataManager())
}
