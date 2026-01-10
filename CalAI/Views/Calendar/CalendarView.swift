import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var showingAddEvent = false
    @State private var selectedEvent: CalendarEvent?

    enum CalendarViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)

                // Calendar content
                switch viewMode {
                case .day:
                    DayView(selectedDate: $selectedDate, onEventTap: { event in
                        selectedEvent = event
                    })
                case .week:
                    WeekView(selectedDate: $selectedDate, onEventTap: { event in
                        selectedEvent = event
                    })
                case .month:
                    MonthView(selectedDate: $selectedDate, onEventTap: { event in
                        selectedEvent = event
                    })
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { selectedDate = Date() }) {
                        Text("Today")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.primaryColor)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(selectedDate: selectedDate)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }
}

// MARK: - Calendar Header

struct CalendarHeader: View {
    @Binding var selectedDate: Date
    let viewMode: CalendarView.CalendarViewMode

    var body: some View {
        HStack {
            Button(action: { navigatePrevious() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryColor)
            }

            Spacer()

            Text(headerTitle)
                .font(Theme.fontHeadline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button(action: { navigateNext() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryColor)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
    }

    private var headerTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMM d, yyyy"
        case .week:
            let startOfWeek = selectedDate.startOfWeek
            let endOfWeek = selectedDate.endOfWeek
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "MMM d"
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "MMM d, yyyy"
            return "\(startFormatter.string(from: startOfWeek)) - \(endFormatter.string(from: endOfWeek))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private func navigatePrevious() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch viewMode {
            case .day:
                selectedDate = selectedDate.adding(days: -1)
            case .week:
                selectedDate = selectedDate.adding(weeks: -1)
            case .month:
                selectedDate = selectedDate.adding(months: -1)
            }
        }
    }

    private func navigateNext() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch viewMode {
            case .day:
                selectedDate = selectedDate.adding(days: 1)
            case .week:
                selectedDate = selectedDate.adding(weeks: 1)
            case .month:
                selectedDate = selectedDate.adding(months: 1)
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(DataManager())
}
