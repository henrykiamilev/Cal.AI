import SwiftUI

struct AIScheduleView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())
    @State private var showingAdjustSheet = false
    @State private var feedback = ""

    private var schedule: AISchedule? {
        goal.aiGeneratedSchedule
    }

    var body: some View {
        NavigationStack {
            if let schedule = schedule {
                VStack(spacing: 0) {
                    // Day selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.spacingS) {
                            ForEach(1...7, id: \.self) { day in
                                let daySchedule = schedule.weeklySchedule.first { $0.dayOfWeek == day }
                                let activityCount = daySchedule?.activities.count ?? 0
                                let completedCount = daySchedule?.activities.filter { $0.isCompleted }.count ?? 0

                                Button(action: { selectedDay = day }) {
                                    VStack(spacing: 4) {
                                        Text(dayName(for: day))
                                            .font(Theme.fontSmall)

                                        if activityCount > 0 {
                                            Text("\(completedCount)/\(activityCount)")
                                                .font(.system(size: 10))
                                                .foregroundColor(selectedDay == day ? .white.opacity(0.8) : Theme.textSecondary)
                                        }
                                    }
                                    .foregroundColor(selectedDay == day ? .white : Theme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(selectedDay == day ? Theme.primaryColor : Theme.backgroundSecondary)
                                    .cornerRadius(Theme.cornerRadiusMedium)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.spacingM)
                    }
                    .padding(.vertical, Theme.spacingS)

                    Divider()

                    // Day's activities
                    if let daySchedule = schedule.weeklySchedule.first(where: { $0.dayOfWeek == selectedDay }) {
                        if daySchedule.activities.isEmpty {
                            restDayView
                        } else {
                            ScrollView {
                                VStack(spacing: Theme.spacingS) {
                                    ForEach(daySchedule.activities.sorted { $0.startTime < $1.startTime }) { activity in
                                        ActivityRow(activity: activity) {
                                            dataManager.markActivityComplete(
                                                goalId: goal.id,
                                                dayOfWeek: daySchedule.dayOfWeek,
                                                activityId: activity.id
                                            )
                                        }
                                    }
                                }
                                .padding(Theme.spacingM)
                            }
                        }
                    } else {
                        restDayView
                    }
                }
                .background(Theme.backgroundPrimary)
                .navigationTitle("\(goal.title) Schedule")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(Theme.primaryColor)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAdjustSheet = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Theme.primaryColor)
                        }
                    }
                }
                .sheet(isPresented: $showingAdjustSheet) {
                    adjustScheduleSheet
                }
            } else {
                noScheduleView
            }
        }
    }

    private var restDayView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primaryGradient)

            Text("Rest Day")
                .font(Theme.fontHeadline)

            Text("Take this day to recover and recharge. Rest is an important part of progress!")
                .font(Theme.fontBody)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    private var noScheduleView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Theme.textTertiary)

            Text("No Schedule Available")
                .font(Theme.fontHeadline)

            Text("This goal doesn't have an AI-generated schedule yet.")
                .font(Theme.fontBody)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("Schedule")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(Theme.primaryColor)
            }
        }
    }

    private var adjustScheduleSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingL) {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("How is your schedule working?")
                        .font(Theme.fontSubheadline)

                    Text("Let us know how you're doing and we'll adjust your schedule to better fit your needs.")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                }

                // Stats
                HStack(spacing: Theme.spacingM) {
                    VStack {
                        Text("\(dataManager.getCompletedActivities(for: goal.id).count)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Theme.successColor)
                        Text("Completed")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text("\(dataManager.getMissedActivities(for: goal.id).count)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Theme.errorColor)
                        Text("Missed")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Theme.spacingM)
                .background(Theme.backgroundSecondary)
                .cornerRadius(Theme.cornerRadiusMedium)

                // Feedback
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Your Feedback (Optional)")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    TextEditor(text: $feedback)
                        .frame(minHeight: 100)
                        .padding(Theme.spacingS)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)

                    Text("e.g., \"Morning workouts are too early\" or \"I have more time on weekends\"")
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()

                Button(action: adjustSchedule) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Adjust My Schedule")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.spacingM)
            .navigationTitle("Adjust Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingAdjustSheet = false
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func dayName(for day: Int) -> String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[day]
    }

    private func adjustSchedule() {
        guard let currentSchedule = schedule else { return }

        Task {
            do {
                let adjustedSchedule = try await AIService.shared.adjustSchedule(
                    currentSchedule: currentSchedule,
                    completedActivities: dataManager.getCompletedActivities(for: goal.id),
                    missedActivities: dataManager.getMissedActivities(for: goal.id),
                    userFeedback: feedback.isEmpty ? nil : feedback
                )

                var updatedGoal = goal
                updatedGoal.aiGeneratedSchedule = adjustedSchedule
                dataManager.updateGoal(updatedGoal)

                showingAdjustSheet = false
            } catch {
                print("Failed to adjust schedule: \(error)")
            }
        }
    }
}

#Preview {
    AIScheduleView(goal: Goal(
        title: "Become an Investment Banker",
        category: .career,
        aiGeneratedSchedule: AISchedule(
            weeklySchedule: [
                ScheduleDay(dayOfWeek: 1, activities: []),
                ScheduleDay(dayOfWeek: 2, activities: [
                    ScheduledActivity(title: "Study Financial Modeling", startTime: "06:00", duration: 60),
                    ScheduledActivity(title: "Read Wall Street Journal", startTime: "07:30", duration: 30)
                ]),
                ScheduleDay(dayOfWeek: 3, activities: [
                    ScheduledActivity(title: "Practice Excel Skills", startTime: "06:00", duration: 45)
                ])
            ],
            recommendations: ["Start with basics", "Network regularly"],
            estimatedTimeToGoal: "12-18 months",
            difficultyLevel: .challenging
        )
    ))
    .environmentObject(DataManager())
}
