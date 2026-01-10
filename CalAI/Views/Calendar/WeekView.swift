import SwiftUI

struct WeekView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedDate: Date
    var onEventTap: ((CalendarEvent) -> Void)?

    private let hourHeight: CGFloat = 50
    private let hours = Array(0..<24)

    private var weekDates: [Date] {
        let startOfWeek = selectedDate.startOfWeek
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeader(selectedDate: $selectedDate, viewMode: .week)

            // Week day headers
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 45)

                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(date.shortWeekdayName.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)

                        Text("\(date.dayOfMonth)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(date.isToday ? .white : Theme.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(date.isToday ? Theme.primaryColor : Color.clear)
                            .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.vertical, Theme.spacingS)
            .background(Color.white)

            Divider()

            // Time grid with events
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                HStack(spacing: 0) {
                                    Text(formatHour(hour))
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textSecondary)
                                        .frame(width: 40, alignment: .trailing)
                                        .padding(.trailing, 5)

                                    Rectangle()
                                        .fill(Theme.backgroundTertiary)
                                        .frame(height: 1)
                                }
                                .frame(height: hourHeight)
                                .id(hour)
                            }
                        }

                        // Vertical day separators
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 45)

                            ForEach(0..<7, id: \.self) { _ in
                                Rectangle()
                                    .fill(Theme.backgroundTertiary)
                                    .frame(width: 1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: hourHeight * 24)

                        // Events
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 45)

                            ForEach(weekDates, id: \.self) { date in
                                ZStack(alignment: .topLeading) {
                                    ForEach(dataManager.events(for: date)) { event in
                                        weekEventView(event)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        // Current time indicator
                        if weekDates.contains(where: { $0.isToday }) {
                            currentTimeIndicator
                        }
                    }
                }
                .onAppear {
                    let scrollToHour = Date().isToday ? Calendar.current.component(.hour, from: Date()) : 8
                    proxy.scrollTo(scrollToHour, anchor: .top)
                }
            }
        }
        .background(Color.white)
    }

    private func weekEventView(_ event: CalendarEvent) -> some View {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: event.startDate)
        let startMinute = calendar.component(.minute, from: event.startDate)

        let topOffset = CGFloat(startHour) * hourHeight + CGFloat(startMinute) / 60 * hourHeight
        let duration = event.duration / 3600
        let height = max(CGFloat(duration) * hourHeight, 25)

        return Button(action: { onEventTap?(event) }) {
            Text(event.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: height)
                .background(event.eventColor)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .offset(y: topOffset)
    }

    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let topOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        let todayIndex = weekDates.firstIndex(where: { $0.isToday }) ?? 0
        let dayWidth = (UIScreen.main.bounds.width - 45) / 7
        let leftOffset = 45 + CGFloat(todayIndex) * dayWidth

        return HStack(spacing: 0) {
            Circle()
                .fill(Theme.errorColor)
                .frame(width: 6, height: 6)

            Rectangle()
                .fill(Theme.errorColor)
                .frame(width: dayWidth - 6, height: 2)
        }
        .offset(x: leftOffset, y: topOffset - 3)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

#Preview {
    WeekView(selectedDate: .constant(Date()))
        .environmentObject(DataManager())
}
