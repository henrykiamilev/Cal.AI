import SwiftUI

struct MonthView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedDate: Date
    var onEventTap: ((CalendarEvent) -> Void)?

    @State private var displayedMonth: Date = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    private var monthDates: [Date] {
        Calendar.current.generateDates(for: displayedMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeader(selectedDate: $displayedMonth, viewMode: .month)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, Theme.spacingS)
            .background(Color.white)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(monthDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: date.isSameDay(as: selectedDate),
                        isCurrentMonth: date.month == displayedMonth.month,
                        events: dataManager.events(for: date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .background(Color.white)

            Divider()

            // Selected day events
            selectedDayEvents
        }
        .background(Theme.backgroundPrimary)
        .onChange(of: selectedDate) { _, newDate in
            if !newDate.isInCurrentMonth || newDate.month != displayedMonth.month {
                withAnimation {
                    displayedMonth = newDate
                }
            }
        }
    }

    private var selectedDayEvents: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text(selectedDate.dateFormatted)
                    .font(Theme.fontSubheadline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                if selectedDate.isToday {
                    Text("Today")
                        .font(Theme.fontSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor)
                        .cornerRadius(Theme.cornerRadiusSmall)
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.top, Theme.spacingM)

            let events = dataManager.events(for: selectedDate)
            let tasks = dataManager.tasks(for: selectedDate)

            if events.isEmpty && tasks.isEmpty {
                VStack(spacing: Theme.spacingS) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textTertiary)
                    Text("No events for this day")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingXL)
            } else {
                ScrollView {
                    VStack(spacing: Theme.spacingS) {
                        ForEach(events) { event in
                            EventCard(event: event) {
                                onEventTap?(event)
                            }
                        }

                        ForEach(tasks) { task in
                            TaskRow(task: task, onToggle: {
                                dataManager.toggleTaskCompletion(task)
                            })
                        }
                    }
                    .padding(.horizontal, Theme.spacingM)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEvent]

    private let maxDots = 3

    var body: some View {
        VStack(spacing: 4) {
            Text("\(date.dayOfMonth)")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundColor)
                .clipShape(Circle())

            // Event dots
            HStack(spacing: 2) {
                ForEach(0..<min(events.count, maxDots), id: \.self) { index in
                    Circle()
                        .fill(events[index].eventColor)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Theme.primaryColor.opacity(0.1) : Color.clear)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if date.isToday {
            return Theme.primaryColor
        } else if !isCurrentMonth {
            return Theme.textTertiary
        } else if date.isWeekend {
            return Theme.textSecondary
        }
        return Theme.textPrimary
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.primaryColor
        } else if date.isToday {
            return Theme.primaryColor.opacity(0.1)
        }
        return Color.clear
    }
}

#Preview {
    MonthView(selectedDate: .constant(Date()))
        .environmentObject(DataManager())
}
