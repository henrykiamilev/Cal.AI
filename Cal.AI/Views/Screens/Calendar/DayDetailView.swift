import SwiftUI

struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskRepository = TaskRepository()

    let date: Date
    var onEventTap: ((Event) -> Void)? = nil

    @State private var events: [Event] = []
    @State private var tasks: [CalTask] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Day header
                    DayTimelineHeader(
                        date: date,
                        eventCount: events.count,
                        taskCount: tasks.count
                    )

                    Divider()

                    // Content
                    if events.isEmpty && tasks.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.plus",
                            title: "Nothing scheduled",
                            message: "You have no events or tasks for this day."
                        )
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            // Events section
                            if !events.isEmpty {
                                Section {
                                    ForEach(events) { event in
                                        TimelineEventCard(
                                            event: event,
                                            isFirst: event.id == events.first?.id,
                                            isLast: event.id == events.last?.id
                                        ) {
                                            onEventTap?(event)
                                            dismiss()
                                        }
                                    }
                                } header: {
                                    SectionHeader(title: "Events", count: events.count)
                                }
                            }

                            // Tasks section
                            if !tasks.isEmpty {
                                Section {
                                    ForEach(tasks) { task in
                                        TaskCard(task: task) {
                                            // Task tap
                                        } onToggleComplete: {
                                            taskRepository.toggleComplete(task)
                                            loadData()
                                        }
                                    }
                                } header: {
                                    SectionHeader(title: "Tasks", count: tasks.count)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.backgroundLight)
            .navigationTitle(date.relativeDateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        let eventRepo = EventRepository()
        events = eventRepo.fetch(for: date)

        tasks = taskRepository.fetchAll().filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate.isSameDay(as: date)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.textDark)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.primaryBlue)
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.backgroundLight)
    }
}

// MARK: - Preview
#Preview {
    DayDetailView(date: Date())
}
