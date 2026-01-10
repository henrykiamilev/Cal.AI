import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium
    @State private var category: TaskCategory = .general
    @State private var subtasks: [Subtask] = []
    @State private var newSubtask = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Title
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Task Title")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextField("What do you need to do?", text: $title)
                            .font(Theme.fontBody)
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Due Date
                    VStack(spacing: Theme.spacingM) {
                        Toggle(isOn: $hasDueDate) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Theme.primaryColor)
                                Text("Due Date")
                            }
                        }
                        .tint(Theme.primaryColor)

                        if hasDueDate {
                            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)

                    // Priority
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Priority")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        HStack(spacing: Theme.spacingS) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                Button(action: { priority = p }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: p.icon)
                                        Text(p.rawValue)
                                    }
                                    .font(Theme.fontSmall)
                                    .foregroundColor(priority == p ? .white : p.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(priority == p ? p.color : p.color.opacity(0.1))
                                    .cornerRadius(Theme.cornerRadiusSmall)
                                }
                            }
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Category")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Theme.spacingS) {
                            ForEach(TaskCategory.allCases, id: \.self) { cat in
                                Button(action: { category = cat }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                        Text(cat.rawValue)
                                    }
                                    .font(Theme.fontSmall)
                                    .foregroundColor(category == cat ? .white : cat.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                    .cornerRadius(Theme.cornerRadiusSmall)
                                }
                            }
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Notes (Optional)")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(Theme.spacingS)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Subtasks
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Subtasks")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        VStack(spacing: Theme.spacingS) {
                            ForEach(subtasks) { subtask in
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(Theme.textTertiary)
                                    Text(subtask.title)
                                        .font(Theme.fontBody)
                                    Spacer()
                                    Button(action: { removeSubtask(subtask) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                                .padding(Theme.spacingS)
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(Theme.cornerRadiusSmall)
                            }

                            HStack {
                                TextField("Add subtask", text: $newSubtask)
                                    .font(Theme.fontBody)

                                Button(action: addSubtask) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Theme.primaryColor)
                                }
                                .disabled(newSubtask.isEmpty)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                        }
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(title.isEmpty ? Theme.textTertiary : Theme.primaryColor)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addSubtask() {
        guard !newSubtask.isEmpty else { return }
        subtasks.append(Subtask(title: newSubtask.trimmed))
        newSubtask = ""
    }

    private func removeSubtask(_ subtask: Subtask) {
        subtasks.removeAll { $0.id == subtask.id }
    }

    private func saveTask() {
        let task = Task(
            title: title.trimmed,
            description: description.trimmed,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            category: category,
            subtasks: subtasks
        )

        dataManager.addTask(task)
        dismiss()
    }
}

#Preview {
    AddTaskView()
        .environmentObject(DataManager())
}
