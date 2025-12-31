import SwiftUI

struct EventCard: View {
    let event: Event
    var showDate: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(event.swiftUIColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textDark)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Time
                        Label(event.timeRangeFormatted, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.textGray)

                        if showDate {
                            Text(event.startDate.relativeDateString)
                                .font(.caption)
                                .foregroundColor(.textGray)
                        }

                        // Location if available
                        if let location = event.location, !location.isEmpty {
                            Label(location, systemImage: "mappin")
                                .font(.caption)
                                .foregroundColor(.textGray)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Category icon
                Image(systemName: event.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(event.swiftUIColor)
                    .frame(width: 32, height: 32)
                    .background(event.swiftUIColor.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(12)
            .background(Color.cardWhite)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactEventCard: View {
    let event: Event
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap?()
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(event.swiftUIColor)
                    .frame(width: 8, height: 8)

                Text(event.title)
                    .font(.caption)
                    .foregroundColor(.textDark)
                    .lineLimit(1)

                Spacer()

                Text(event.startDate.timeString)
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(event.swiftUIColor.opacity(0.1))
            .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineEventCard: View {
    let event: Event
    var isFirst: Bool = false
    var isLast: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack {
                Text(event.startDate.timeString)
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .frame(width: 60, alignment: .trailing)

                if event.durationInMinutes > 30 {
                    Text(event.endDate.timeString)
                        .font(.caption2)
                        .foregroundColor(.textGray.opacity(0.7))
                        .frame(width: 60, alignment: .trailing)
                }
            }

            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2, height: 10)
                }

                Circle()
                    .fill(event.isHappeningNow ? event.swiftUIColor : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(event.swiftUIColor)
                            .frame(width: 6, height: 6)
                    )

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Event content
            Button(action: {
                HapticManager.shared.buttonTap()
                onTap?()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textDark)

                    HStack(spacing: 8) {
                        Text(event.durationFormatted)
                            .font(.caption)
                            .foregroundColor(.textGray)

                        if let location = event.location {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.textGray)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(event.swiftUIColor.opacity(0.1))
                .cornerRadius(Constants.UI.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                        .stroke(event.isHappeningNow ? event.swiftUIColor : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleEvent = Event(
        title: "Team Meeting",
        notes: "Weekly sync with the product team",
        startDate: Date(),
        endDate: Date().adding(.hour, value: 1),
        category: .meeting,
        color: "3498DB",
        location: "Conference Room A"
    )

    VStack(spacing: 20) {
        EventCard(event: sampleEvent, showDate: true)

        CompactEventCard(event: sampleEvent)

        TimelineEventCard(event: sampleEvent)
    }
    .padding()
}
