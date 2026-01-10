import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: GoalCategory = .personal
    @State private var hasTargetDate = false
    @State private var targetDate = Date().adding(months: 3)
    @State private var milestones: [String] = []
    @State private var newMilestone = ""
    @State private var showingAISetup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Goal Title
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("What's your goal?")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextField("e.g., Become an investment banker", text: $title)
                            .font(Theme.fontBody)
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Category
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Category")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Theme.spacingS) {
                            ForEach(GoalCategory.allCases, id: \.self) { cat in
                                Button(action: { category = cat }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 24))
                                        Text(cat.rawValue)
                                            .font(Theme.fontSmall)
                                    }
                                    .foregroundColor(category == cat ? .white : cat.color)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                    .cornerRadius(Theme.cornerRadiusMedium)
                                }
                            }
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Tell us more about your goal")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(Theme.spacingS)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)

                        Text("The more details you provide, the better our AI can create a personalized schedule for you")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textTertiary)
                    }

                    // Target Date
                    Toggle(isOn: $hasTargetDate) {
                        HStack {
                            Image(systemName: "flag")
                                .foregroundColor(Theme.primaryColor)
                            Text("Target Date")
                        }
                    }
                    .tint(Theme.primaryColor)
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)

                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(Theme.spacingM)
                            .background(Theme.backgroundSecondary)
                            .cornerRadius(Theme.cornerRadiusMedium)
                    }

                    // Milestones
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Key Milestones (Optional)")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        Text("Add major checkpoints on your journey")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textTertiary)

                        VStack(spacing: Theme.spacingS) {
                            ForEach(milestones.indices, id: \.self) { index in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(Theme.fontSmall)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Theme.primaryColor)
                                        .clipShape(Circle())

                                    Text(milestones[index])
                                        .font(Theme.fontBody)

                                    Spacer()

                                    Button(action: { milestones.remove(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                                .padding(Theme.spacingS)
                                .background(Theme.backgroundSecondary)
                                .cornerRadius(Theme.cornerRadiusSmall)
                            }

                            HStack {
                                TextField("Add a milestone", text: $newMilestone)
                                    .font(Theme.fontBody)

                                Button(action: addMilestone) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Theme.primaryColor)
                                }
                                .disabled(newMilestone.isEmpty)
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
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        if subscriptionManager.isPremium {
                            showingAISetup = true
                        } else {
                            saveGoalWithoutAI()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(title.isEmpty ? Theme.textTertiary : Theme.primaryColor)
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingAISetup) {
                AIGoalView(goalTitle: title, goalDescription: description, category: category, targetDate: hasTargetDate ? targetDate : nil, milestones: milestones.enumerated().map { Milestone(title: $0.element, order: $0.offset) })
            }
        }
    }

    private func addMilestone() {
        guard !newMilestone.isEmpty else { return }
        milestones.append(newMilestone.trimmed)
        newMilestone = ""
    }

    private func saveGoalWithoutAI() {
        let goal = Goal(
            title: title.trimmed,
            description: description.trimmed,
            category: category,
            targetDate: hasTargetDate ? targetDate : nil,
            milestones: milestones.enumerated().map { Milestone(title: $0.element, order: $0.offset) }
        )

        dataManager.addGoal(goal)
        dismiss()
    }
}

#Preview {
    AddGoalView()
        .environmentObject(DataManager())
        .environmentObject(SubscriptionManager())
}
