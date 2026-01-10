import SwiftUI

struct AIGoalView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    let goalTitle: String
    let goalDescription: String
    let category: GoalCategory
    let targetDate: Date?
    let milestones: [Milestone]

    @State private var isGenerating = false
    @State private var generatedSchedule: AISchedule?
    @State private var error: String?
    @State private var showingSubscription = false

    var body: some View {
        NavigationStack {
            Group {
                if !subscriptionManager.isPremium {
                    premiumRequired
                } else if isGenerating {
                    generatingView
                } else if let schedule = generatedSchedule {
                    schedulePreview(schedule)
                } else if let error = error {
                    errorView(error)
                } else {
                    setupView
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("AI Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }

    private var premiumRequired: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(Theme.premiumGradient)

            VStack(spacing: Theme.spacingM) {
                Text("AI Schedule Maker")
                    .font(Theme.fontTitle)
                    .foregroundColor(Theme.textPrimary)

                Text("Unlock the power of AI to create personalized schedules that help you achieve your goals faster")
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: Theme.spacingM) {
                FeatureRow(icon: "calendar.badge.clock", text: "Smart weekly schedules tailored to you")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Adaptive plans that adjust to your progress")
                FeatureRow(icon: "brain", text: "AI-powered recommendations")
                FeatureRow(icon: "clock.arrow.circlepath", text: "Respects your existing commitments")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: { showingSubscription = true }) {
                HStack {
                    Text("Unlock for $9.99/month")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacingL)

            Button("Save goal without AI") {
                saveGoalWithoutAI()
            }
            .font(Theme.fontCaption)
            .foregroundColor(Theme.textSecondary)

            Spacer()
        }
        .padding()
    }

    private var generatingView: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.backgroundTertiary, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Theme.primaryGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isGenerating)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.primaryGradient)
            }

            VStack(spacing: Theme.spacingS) {
                Text("Creating Your Schedule")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)

                Text("Our AI is analyzing your goal and creating a personalized plan...")
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    private var setupView: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primaryGradient)

            VStack(spacing: Theme.spacingM) {
                Text("Ready to Create Your Plan")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)

                Text("Our AI will analyze your goal and create a personalized weekly schedule")
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Goal summary
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(goalTitle)
                        .font(Theme.fontSubheadline)
                }

                if let targetDate = targetDate {
                    HStack {
                        Image(systemName: "flag")
                            .foregroundColor(Theme.textSecondary)
                        Text("Target: \(targetDate.dateFormatted)")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                if !milestones.isEmpty {
                    HStack {
                        Image(systemName: "list.number")
                            .foregroundColor(Theme.textSecondary)
                        Text("\(milestones.count) milestones")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.backgroundSecondary)
            .cornerRadius(Theme.cornerRadiusMedium)
            .padding(.horizontal)

            Spacer()

            Button(action: generateSchedule) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate AI Schedule")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacingL)

            Spacer()
        }
        .padding()
    }

    private func schedulePreview(_ schedule: AISchedule) -> some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Header
                VStack(spacing: Theme.spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.successColor)

                    Text("Your Schedule is Ready!")
                        .font(Theme.fontHeadline)

                    Text("Estimated time to goal: \(schedule.estimatedTimeToGoal)")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, Theme.spacingL)

                // Difficulty
                HStack {
                    Text("Intensity:")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                    Text(schedule.difficultyLevel.rawValue)
                        .font(Theme.fontCaption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.primaryColor)
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(Theme.primaryColor.opacity(0.1))
                .cornerRadius(Theme.cornerRadiusSmall)

                // Weekly Schedule Preview
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    Text("Weekly Schedule")
                        .font(Theme.fontSubheadline)
                        .foregroundColor(Theme.textPrimary)

                    ForEach(schedule.weeklySchedule.sorted { $0.dayOfWeek < $1.dayOfWeek }) { day in
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text(day.dayName)
                                .font(Theme.fontCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primaryColor)

                            ForEach(day.activities) { activity in
                                HStack {
                                    Text(activity.startTime)
                                        .font(Theme.fontSmall)
                                        .foregroundColor(Theme.textSecondary)
                                        .frame(width: 50, alignment: .leading)

                                    Text(activity.title)
                                        .font(Theme.fontCaption)
                                        .foregroundColor(Theme.textPrimary)

                                    Spacer()

                                    Text("\(activity.duration)m")
                                        .font(Theme.fontSmall)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }
                }
                .padding(.horizontal)

                // Recommendations
                if !schedule.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("AI Recommendations")
                            .font(Theme.fontSubheadline)
                            .foregroundColor(Theme.textPrimary)

                        ForEach(schedule.recommendations, id: \.self) { rec in
                            HStack(alignment: .top, spacing: Theme.spacingS) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Theme.warningColor)
                                    .font(.system(size: 14))
                                Text(rec)
                                    .font(Theme.fontCaption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.warningColor.opacity(0.1))
                    .cornerRadius(Theme.cornerRadiusMedium)
                    .padding(.horizontal)
                }

                // Save button
                Button(action: { saveGoalWithSchedule(schedule) }) {
                    Text("Save Goal & Schedule")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacingL)
                .padding(.bottom, Theme.spacingL)
            }
        }
    }

    private func errorView(_ errorMessage: String) -> some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(Theme.errorColor)

            VStack(spacing: Theme.spacingS) {
                Text("Something Went Wrong")
                    .font(Theme.fontHeadline)

                Text(errorMessage)
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Theme.spacingM) {
                Button("Try Again") {
                    error = nil
                    generateSchedule()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Save without AI Schedule") {
                    saveGoalWithoutAI()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.spacingL)

            Spacer()
        }
        .padding()
    }

    private func generateSchedule() {
        isGenerating = true
        error = nil

        let goal = Goal(
            title: goalTitle,
            description: goalDescription,
            category: category,
            targetDate: targetDate,
            milestones: milestones
        )

        Task {
            do {
                let schedule = try await AIService.shared.generateGoalSchedule(
                    goal: goal,
                    userProfile: dataManager.userProfile ?? UserProfile(),
                    existingEvents: dataManager.events
                )
                generatedSchedule = schedule
            } catch {
                self.error = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func saveGoalWithSchedule(_ schedule: AISchedule) {
        let goal = Goal(
            title: goalTitle,
            description: goalDescription,
            category: category,
            targetDate: targetDate,
            aiGeneratedSchedule: schedule,
            milestones: milestones
        )

        dataManager.addGoal(goal)
        dismiss()
    }

    private func saveGoalWithoutAI() {
        let goal = Goal(
            title: goalTitle,
            description: goalDescription,
            category: category,
            targetDate: targetDate,
            milestones: milestones
        )

        dataManager.addGoal(goal)
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.primaryColor)
                .frame(width: 30)

            Text(text)
                .font(Theme.fontBody)
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
    }
}

#Preview {
    AIGoalView(
        goalTitle: "Become an investment banker",
        goalDescription: "I want to break into investment banking within the next year",
        category: .career,
        targetDate: Date().adding(months: 12),
        milestones: []
    )
    .environmentObject(DataManager())
    .environmentObject(SubscriptionManager())
}
