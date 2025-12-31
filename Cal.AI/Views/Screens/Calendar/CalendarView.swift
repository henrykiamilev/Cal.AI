import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingDayDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Calendar grid
                    CalendarGridView(viewModel: viewModel) { date in
                        showingDayDetail = true
                    }
                    .padding()
                    .background(Color.cardWhite)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding()

                    // Selected day events
                    SelectedDayEventsView(
                        date: viewModel.selectedDate,
                        events: viewModel.selectedDateEvents,
                        onEventTap: { event in
                            viewModel.showEditEventForm(for: event)
                        }
                    )
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus") {
                            viewModel.showNewEventForm()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.goToToday) {
                        Text("Today")
                            .font(.subheadline)
                            .foregroundColor(.primaryBlue)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingEventForm) {
                EventFormView(
                    event: viewModel.selectedEvent,
                    initialDate: viewModel.selectedDate
                ) { event in
                    if viewModel.selectedEvent != nil {
                        viewModel.updateEvent(event)
                    } else {
                        viewModel.createEvent(event)
                    }
                } onDelete: { event in
                    viewModel.deleteEvent(event)
                }
            }
            .sheet(isPresented: $showingDayDetail) {
                DayDetailView(
                    date: viewModel.selectedDate,
                    onEventTap: { event in
                        showingDayDetail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.showEditEventForm(for: event)
                        }
                    }
                )
            }
        }
    }
}

struct SelectedDayEventsView: View {
    let date: Date
    let events: [Event]
    var onEventTap: ((Event) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted(as: .dayOfWeek))
                        .font(.caption)
                        .foregroundColor(.textGray)

                    Text(date.formatted(as: .dayMonth))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.textDark)
                }

                Spacer()

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
            .padding(.horizontal)
            .padding(.top)

            if events.isEmpty {
                EmptyDayView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(events) { event in
                            EventCard(event: event) {
                                onEventTap?(event)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius, corners: [.topLeft, .topRight])
    }
}

struct EmptyDayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.textGray.opacity(0.5))

            Text("No events")
                .font(.subheadline)
                .foregroundColor(.textGray)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    CalendarView()
}
