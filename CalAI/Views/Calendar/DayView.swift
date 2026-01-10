import SwiftUI

struct DayView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedDate: Date
    var onEventTap: ((CalendarEvent) -> Void)?

    private let hourHeight: CGFloat = 60
    private let hours = Array(0..<24)

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeader(selectedDate: $selectedDate, viewMode: .day)

            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Time grid
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                HStack(alignment: .top, spacing: Theme.spacingS) {
                                    Text(formatHour(hour))
                                        .font(Theme.fontSmall)
                                        .foregroundColor(Theme.textSecondary)
                                        .frame(width: 50, alignment: .trailing)

                                    Rectangle()
                                        .fill(Theme.backgroundTertiary)
                                        .frame(height: 1)
                                }
                                .frame(height: hourHeight)
                                .id(hour)
                            }
                        }
                        .padding(.leading, Theme.spacingS)

                        // Events overlay
                        GeometryReader { geometry in
                            ForEach(eventsForSelectedDate) { event in
                                eventView(event, in: geometry.size)
                            }
                        }
                        .padding(.leading, 60)
                        .padding(.trailing, Theme.spacingM)

                        // Current time indicator
                        if selectedDate.isToday {
                            currentTimeIndicator
                        }
                    }
                }
                .onAppear {
                    // Scroll to current hour or 8 AM
                    let scrollToHour = selectedDate.isToday ? Calendar.current.component(.hour, from: Date()) : 8
                    proxy.scrollTo(scrollToHour, anchor: .top)
                }
            }
        }
        .background(Color.white)
    }

    private var eventsForSelectedDate: [CalendarEvent] {
        dataManager.events(for: selectedDate)
    }

    private func eventView(_ event: CalendarEvent, in size: CGSize) -> some View {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: event.startDate)
        let startMinute = calendar.component(.minute, from: event.startDate)

        let topOffset = CGFloat(startHour) * hourHeight + CGFloat(startMinute) / 60 * hourHeight
        let duration = event.duration / 3600 // in hours
        let height = max(CGFloat(duration) * hourHeight, 30)

        return Button(action: { onEventTap?(event) }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(Theme.fontCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if height > 40 {
                    Text(event.formattedTimeRange)
                        .font(Theme.fontSmall)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, Theme.spacingS)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(event.eventColor)
            .cornerRadius(Theme.cornerRadiusSmall)
        }
        .buttonStyle(.plain)
        .offset(y: topOffset)
    }

    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let topOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(Theme.errorColor)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Theme.errorColor)
                .frame(height: 2)
        }
        .padding(.leading, 46)
        .offset(y: topOffset - 4)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

#Preview {
    DayView(selectedDate: .constant(Date()))
        .environmentObject(DataManager())
}
