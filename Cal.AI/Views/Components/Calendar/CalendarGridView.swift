import SwiftUI

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let onDaySelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            MonthHeader(
                monthYear: viewModel.monthYearString,
                onPrevious: viewModel.previousMonth,
                onNext: viewModel.nextMonth,
                onToday: viewModel.goToToday
            )

            // Weekday headers
            WeekdayHeader(symbols: viewModel.weekdaySymbols)

            // Days grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isToday: viewModel.isToday(date),
                            isSelected: viewModel.isSelected(date),
                            isCurrentMonth: viewModel.isCurrentMonth(date),
                            events: viewModel.events(for: date),
                            onTap: {
                                HapticManager.shared.selection()
                                viewModel.selectDate(date)
                                onDaySelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
}

struct MonthHeader: View {
    let monthYear: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                HapticManager.shared.buttonTap()
                onPrevious()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryBlue)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: {
                HapticManager.shared.buttonTap()
                onToday()
            }) {
                Text(monthYear)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textDark)
            }

            Spacer()

            Button(action: {
                HapticManager.shared.buttonTap()
                onNext()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryBlue)
                    .frame(width: 44, height: 44)
            }
        }
    }
}

struct WeekdayHeader: View {
    let symbols: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textGray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let events: [Event]
    let onTap: () -> Void

    private var hasEvents: Bool {
        !events.isEmpty
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection/Today background
                    if isSelected {
                        Circle()
                            .fill(Color.primaryBlue)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Color.primaryBlue, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(date.day)")
                        .font(.system(size: 16, weight: isToday || isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected ? .white :
                                isToday ? .primaryBlue :
                                isCurrentMonth ? .textDark : .textGray.opacity(0.5)
                        )
                }

                // Event indicators
                if hasEvents {
                    HStack(spacing: 2) {
                        ForEach(events.prefix(3), id: \.id) { event in
                            Circle()
                                .fill(event.swiftUIColor)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 5)
                } else {
                    Spacer()
                        .frame(height: 5)
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Week View
struct WeekRowView: View {
    let dates: [Date]
    let selectedDate: Date
    let events: [Date: [Event]]
    let onDaySelected: (Date) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(dates, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isToday: date.isToday,
                    isSelected: date.isSameDay(as: selectedDate),
                    events: events[date.startOfDay] ?? [],
                    onTap: { onDaySelected(date) }
                )
            }
        }
    }
}

struct WeekDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let events: [Event]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(date.formatted(as: .shortDayOfWeek))
                    .font(.caption2)
                    .foregroundColor(.textGray)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.primaryBlue)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Color.primaryBlue, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(date.day)")
                        .font(.system(size: 16, weight: isToday || isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : isToday ? .primaryBlue : .textDark)
                }

                // Event count
                if !events.isEmpty {
                    Text("\(events.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.primaryBlue)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryBlue.opacity(0.1) : Color.clear)
            .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
