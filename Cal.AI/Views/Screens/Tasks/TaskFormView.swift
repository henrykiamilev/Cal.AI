import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var priority: Priority = .medium
    @State private var category: TaskCategory = .personal

    @State private var showingDeleteConfirmation = false

    let existingTask: CalTask?
    var onSave: ((CalTask) -> Void)?
    var onDelete: ((CalTask) -> Void)?

    var isEditing: Bool { existingTask != nil }

    init(
        task: CalTask? = nil,
        onSave: ((CalTask) -> Void)? = nil,
        onDelete: ((CalTask) -> Void)? = nil
    ) {
        self.existingTask = task
        self.onSave = onSave
        self.onDelete = onDelete

        if let task = task {
            _title = State(initialValue: task.title)
            _notes = State(initialValue: task.notes ?? "")
            _hasDueDate = State(initialValue: task.dueDate != nil)
            _dueDate = State(initialValue: task.dueDate ?? Date())
            _priority = State(initialValue: task.priority)
            _category = State(initialValue: task.category)
        }
    }

    var isValid: Bool {
        !title.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title
                Section {
                    TextField("Task title", text: $title)
                        .font(.headline)
                }

                // Due date
                Section {
                    Toggle("Has Due Date", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Priority
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(priority.color)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Category
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            TaskCategoryButton(
                                category: cat,
                                isSelected: category == cat
                            ) {
                                category = cat
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                // Delete
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Task")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let task = existingTask {
                        onDelete?(task)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }

    private func save() {
        let task = CalTask(
            id: existingTask?.id ?? UUID(),
            title: title.trimmed,
            notes: notes.trimmed.isEmpty ? nil : notes.trimmed,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            category: category,
            isCompleted: existingTask?.isCompleted ?? false,
            completedAt: existingTask?.completedAt,
            color: category.defaultColor,
            parentGoalId: existingTask?.parentGoalId,
            createdAt: existingTask?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave?(task)
        dismiss()
    }
}

struct TaskCategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : Color(hex: category.defaultColor))
                    .frame(width: 40, height: 40)
                    .background(
                        isSelected ? Color(hex: category.defaultColor) : Color(hex: category.defaultColor).opacity(0.1)
                    )
                    .clipShape(Circle())

                Text(category.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color(hex: category.defaultColor) : .textGray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    TaskFormView()
}
