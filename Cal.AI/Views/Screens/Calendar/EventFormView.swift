import SwiftUI

struct EventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventFormViewModel

    var onSave: ((Event) -> Void)?
    var onDelete: ((Event) -> Void)?

    init(
        event: Event? = nil,
        initialDate: Date = Date(),
        onSave: ((Event) -> Void)? = nil,
        onDelete: ((Event) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: EventFormViewModel(
            event: event,
            initialDate: initialDate
        ))
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    TextField("Event title", text: $viewModel.title)
                        .font(.headline)
                }

                // Date & Time section
                Section {
                    Toggle("All-day", isOn: $viewModel.isAllDay)

                    DatePicker(
                        "Starts",
                        selection: $viewModel.startDate,
                        displayedComponents: viewModel.isAllDay ? .date : [.date, .hourAndMinute]
                    )

                    DatePicker(
                        "Ends",
                        selection: $viewModel.endDate,
                        in: viewModel.startDate...,
                        displayedComponents: viewModel.isAllDay ? .date : [.date, .hourAndMinute]
                    )
                }

                // Category section
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: viewModel.category == category
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Location section
                Section {
                    HStack {
                        Image(systemName: "mappin")
                            .foregroundColor(.textGray)
                        TextField("Location", text: $viewModel.location)
                    }
                }

                // Reminder section
                Section("Reminder") {
                    Picker("Alert", selection: $viewModel.reminderMinutes) {
                        ForEach(viewModel.reminderOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }

                // Notes section
                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                }

                // Delete button (for editing)
                if viewModel.isEditing {
                    Section {
                        Button(role: .destructive) {
                            viewModel.confirmDelete()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Event")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.onSave = onSave
                        viewModel.onDismiss = { dismiss() }
                        viewModel.save()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Event", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.onDelete = onDelete
                    viewModel.onDismiss = { dismiss() }
                    viewModel.delete()
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
    }
}

struct CategoryButton: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Color(hex: category.defaultColor))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? Color(hex: category.defaultColor) : Color(hex: category.defaultColor).opacity(0.1)
                    )
                    .clipShape(Circle())

                Text(category.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color(hex: category.defaultColor) : .textGray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    EventFormView()
}
