import SwiftUI
import Combine

struct TimelineView: View {
    let schedule: DaySchedule
    var onEventTap: ((Event) -> Void)? = nil
    var onTaskTap: ((CalTask) -> Void)? = nil
    var onTaskToggle: ((CalTask) -> Void)? = nil

    private let hourHeight: CGFloat = 60
    private let startHour = Constants.Calendar.timelineStartHour
    private let endHour = Constants.Calendar.timelineEndHour

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Hour lines
                VStack(spacing: 0) {
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        HourRow(hour: hour, height: hourHeight)
                    }
                }

                // Events overlay
                ForEach(schedule.events) { event in
                    EventBlock(
                        event: event,
                        hourHeight: hourHeight,
                        startHour: startHour,
                        onTap: { onEventTap?(event) }
                    )
                }

                // Current time indicator
                if schedule.date.isToday {
                    CurrentTimeIndicator(hourHeight: hourHeight, startHour: startHour)
                }
            }
            .padding(.leading, 60)
            .padding(.trailing, 16)

            // Tasks section at bottom
            if !schedule.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tasks Due Today")
                        .font(.headline)
                        .foregroundColor(.textDark)
                        .padding(.horizontal)

                    ForEach(schedule.tasks) { task in
                        CompactTaskCard(task: task) {
                            onTaskToggle?(task)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            onTaskTap?(task)
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

struct HourRow: View {
    let hour: Int
    let height: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(formatHour(hour))
                .font(.caption)
                .foregroundColor(.textGray)
                .frame(width: 50, alignment: .trailing)
                .offset(x: -58, y: -6)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
        }
        .frame(height: height)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

struct EventBlock: View {
    let event: Event
    let hourHeight: CGFloat
    let startHour: Int
    let onTap: () -> Void

    private var topOffset: CGFloat {
        let eventHour = event.startDate.hour
        let eventMinute = event.startDate.minute
        let hoursFromStart = CGFloat(eventHour - startHour)
        let minuteFraction = CGFloat(eventMinute) / 60
        return (hoursFromStart + minuteFraction) * hourHeight
    }

    private var height: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = CGFloat(duration) / 3600
        return max(hours * hourHeight, 30) // Minimum height
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if height > 50 {
                    Text(event.timeRangeFormatted)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }

                if height > 70, let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(event.swiftUIColor)
            .cornerRadius(Constants.UI.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                    .stroke(event.isHappeningNow ? Color.white : Color.clear, lineWidth: 2)
            )
            .shadow(color: event.swiftUIColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(y: topOffset)
    }
}

struct CurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var topOffset: CGFloat {
        let hour = currentTime.hour
        let minute = currentTime.minute
        let hoursFromStart = CGFloat(hour - startHour)
        let minuteFraction = CGFloat(minute) / 60
        return (hoursFromStart + minuteFraction) * hourHeight
    }

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.errorRed)
                .frame(width: 10, height: 10)
                .offset(x: -5)

            Rectangle()
                .fill(Color.errorRed)
                .frame(height: 2)
        }
        .offset(y: topOffset)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct DayTimelineHeader: View {
    let date: Date
    let eventCount: Int
    let taskCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted(as: .dayOfWeek))
                        .font(.caption)
                        .foregroundColor(.textGray)

                    Text(date.formatted(as: .dayMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textDark)
                }

                Spacer()

                HStack(spacing: 16) {
                    Label("\(eventCount)", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.textGray)

                    Label("\(taskCount)", systemImage: "checklist")
                        .font(.subheadline)
                        .foregroundColor(.textGray)
                }
            }

            if date.isToday {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryBlue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.cardWhite)
    }
}
