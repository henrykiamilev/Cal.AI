import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date().adding(.month, value: 3)
    @State private var category: GoalCategory = .personal

    let existingGoal: Goal?
    var onSave: ((Goal) -> Void)?

    var isEditing: Bool { existingGoal != nil }

    var isValid: Bool {
        !title.trimmed.isEmpty
    }

    init(
        goal: Goal? = nil,
        onSave: ((Goal) -> Void)? = nil
    ) {
        self.existingGoal = goal
        self.onSave = onSave

        if let goal = goal {
            _title = State(initialValue: goal.title)
            _description = State(initialValue: goal.description ?? "")
            _hasTargetDate = State(initialValue: goal.targetDate != nil)
            _targetDate = State(initialValue: goal.targetDate ?? Date().adding(.month, value: 3))
            _category = State(initialValue: goal.category)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Goal info
                Section {
                    TextField("What do you want to achieve?", text: $title)
                        .font(.headline)

                    TextField("Describe your goal (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Category
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(GoalCategory.allCases, id: \.self) { cat in
                            GoalCategoryButton(
                                category: cat,
                                isSelected: category == cat
                            ) {
                                category = cat
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Target date
                Section {
                    Toggle("Set Target Date", isOn: $hasTargetDate.animation())

                    if hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }

                // Examples
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goal Examples")
                            .font(.caption)
                            .foregroundColor(.textGray)

                        ForEach(goalExamples, id: \.0) { example in
                            Button {
                                title = example.0
                                description = example.1
                                category = example.2
                            } label: {
                                HStack {
                                    Image(systemName: example.2.icon)
                                        .foregroundColor(example.2.color)

                                    Text(example.0)
                                        .font(.subheadline)
                                        .foregroundColor(.textDark)

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.textGray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
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
        }
    }

    private var goalExamples: [(String, String, GoalCategory)] {
        [
            ("Become an Investment Banker", "Land a position at a top investment bank", .career),
            ("Lose 20 Pounds", "Achieve my target weight through diet and exercise", .health),
            ("Learn Spanish", "Become conversational in Spanish", .education),
            ("Save $10,000", "Build an emergency fund", .finance),
            ("Run a Marathon", "Complete a full 26.2 mile marathon", .fitness)
        ]
    }

    private func save() {
        let goal = Goal(
            id: existingGoal?.id ?? UUID(),
            title: title.trimmed,
            description: description.trimmed.isEmpty ? nil : description.trimmed,
            targetDate: hasTargetDate ? targetDate : nil,
            category: category,
            isActive: existingGoal?.isActive ?? true,
            progressPercentage: existingGoal?.progressPercentage ?? 0,
            aiSchedule: existingGoal?.aiSchedule,
            milestones: existingGoal?.milestones ?? [],
            createdAt: existingGoal?.createdAt ?? Date(),
            updatedAt: Date(),
            lastAIUpdateAt: existingGoal?.lastAIUpdateAt
        )

        onSave?(goal)
        dismiss()
    }
}

struct GoalCategoryButton: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : category.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? category.color : category.color.opacity(0.1))
                    .clipShape(Circle())

                Text(category.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? category.color : .textGray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    GoalFormView { _ in }
}
