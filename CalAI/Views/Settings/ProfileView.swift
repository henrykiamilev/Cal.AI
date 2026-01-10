import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var age: String = ""
    @State private var occupation: String = ""
    @State private var fitnessLevel: FitnessLevel = .moderatelyActive
    @State private var learningStyle: LearningStyle = .visual
    @State private var availableHours: Double = 10
    @State private var workDays: Set<Int> = []
    @State private var workStartTime = Date()
    @State private var workEndTime = Date()
    @State private var wakeTime = Date()
    @State private var bedTime = Date()

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Occupation")
                        Spacer()
                        TextField("What do you do?", text: $occupation)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Work Schedule
                Section("Work/School Schedule") {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Work Days")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                        HStack(spacing: Theme.spacingS) {
                            ForEach(1...7, id: \.self) { day in
                                Button(action: { toggleWorkDay(day) }) {
                                    Text(weekdays[day - 1])
                                        .font(Theme.fontSmall)
                                        .fontWeight(.semibold)
                                        .foregroundColor(workDays.contains(day) ? .white : Theme.textSecondary)
                                        .frame(width: 32, height: 32)
                                        .background(workDays.contains(day) ? Theme.primaryColor : Theme.backgroundTertiary)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    DatePicker("Start Time", selection: $workStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $workEndTime, displayedComponents: .hourAndMinute)
                }

                // Sleep Schedule
                Section("Sleep Schedule") {
                    DatePicker("Wake Up", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Bedtime", selection: $bedTime, displayedComponents: .hourAndMinute)
                }

                // Preferences
                Section("Preferences") {
                    Picker("Fitness Level", selection: $fitnessLevel) {
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Picker("Learning Style", selection: $learningStyle) {
                        ForEach(LearningStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Available Hours/Week")
                            Spacer()
                            Text("\(Int(availableHours)) hrs")
                                .foregroundColor(Theme.primaryColor)
                        }
                        Slider(value: $availableHours, in: 1...40, step: 1)
                            .tint(Theme.primaryColor)
                    }
                }

                // Account Info
                Section("Account") {
                    if let email = dataManager.userProfile?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    if let appleId = dataManager.userProfile?.appleUserId {
                        HStack {
                            Text("Apple ID")
                            Spacer()
                            Text("Connected")
                                .foregroundColor(Theme.successColor)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
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
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.primaryColor)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func toggleWorkDay(_ day: Int) {
        if workDays.contains(day) {
            workDays.remove(day)
        } else {
            workDays.insert(day)
        }
    }

    private func loadProfile() {
        guard let profile = dataManager.userProfile else { return }

        displayName = profile.displayName
        age = profile.profileInfo.age.map { String($0) } ?? ""
        occupation = profile.profileInfo.occupation ?? ""
        fitnessLevel = profile.profileInfo.fitnessLevel ?? .moderatelyActive
        learningStyle = profile.profileInfo.learningStyle ?? .visual
        availableHours = Double(profile.profileInfo.availableHoursPerWeek ?? 10)

        if let workSchedule = profile.profileInfo.workSchedule {
            workDays = Set(workSchedule.workDays)
            workStartTime = timeFromString(workSchedule.startTime) ?? Date()
            workEndTime = timeFromString(workSchedule.endTime) ?? Date()
        }

        if let sleepSchedule = profile.profileInfo.sleepSchedule {
            wakeTime = timeFromString(sleepSchedule.wakeTime) ?? Date()
            bedTime = timeFromString(sleepSchedule.bedtime) ?? Date()
        }
    }

    private func saveProfile() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let profileInfo = ProfileInfo(
            age: Int(age),
            occupation: occupation.isEmpty ? nil : occupation,
            workSchedule: WorkSchedule(
                workDays: Array(workDays).sorted(),
                startTime: timeFormatter.string(from: workStartTime),
                endTime: timeFormatter.string(from: workEndTime)
            ),
            sleepSchedule: SleepSchedule(
                bedtime: timeFormatter.string(from: bedTime),
                wakeTime: timeFormatter.string(from: wakeTime)
            ),
            fitnessLevel: fitnessLevel,
            learningStyle: learningStyle,
            availableHoursPerWeek: Int(availableHours)
        )

        let currentProfile = dataManager.userProfile ?? UserProfile()
        let updatedProfile = UserProfile(
            id: currentProfile.id,
            appleUserId: currentProfile.appleUserId,
            email: currentProfile.email,
            displayName: displayName,
            profileInfo: profileInfo,
            preferences: currentProfile.preferences
        )

        dataManager.updateUserProfile(updatedProfile)
        dismiss()
    }

    private func timeFromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: string)
    }
}

#Preview {
    ProfileView()
        .environmentObject(DataManager())
}
