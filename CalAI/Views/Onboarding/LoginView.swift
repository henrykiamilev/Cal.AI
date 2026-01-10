import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingProfileSetup = false

    enum AuthMode {
        case signIn
        case signUp
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingXL) {
                    // Logo/Header
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.primaryGradient)

                        Text("Calendar AI")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        Text(authMode == .signIn ? "Welcome back!" : "Create your account")
                            .font(Theme.fontBody)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, Theme.spacingXL)

                    // Auth mode picker
                    Picker("Auth Mode", selection: $authMode) {
                        Text("Sign In").tag(AuthMode.signIn)
                        Text("Sign Up").tag(AuthMode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Theme.spacingL)

                    // Form fields
                    VStack(spacing: Theme.spacingM) {
                        if authMode == .signUp {
                            CustomTextField(
                                placeholder: "Display Name",
                                text: $displayName,
                                icon: "person"
                            )
                        }

                        CustomTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope"
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                        CustomTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )

                        if authMode == .signUp {
                            CustomTextField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                icon: "lock.fill",
                                isSecure: true
                            )
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.errorColor)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: handleEmailAuth) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(authMode == .signIn ? "Sign In" : "Create Account")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading || !isFormValid)
                    }
                    .padding(.horizontal, Theme.spacingL)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Theme.backgroundTertiary)
                            .frame(height: 1)
                        Text("or")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textSecondary)
                        Rectangle()
                            .fill(Theme.backgroundTertiary)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Theme.spacingL)

                    // Sign in with Apple
                    VStack(spacing: Theme.spacingM) {
                        SignInWithAppleButtonRepresentable(
                            type: authMode == .signIn ? .signIn : .signUp,
                            style: .black
                        ) {
                            authManager.signInWithApple()
                        }
                        .frame(height: 50)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .padding(.horizontal, Theme.spacingL)

                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(Theme.fontSmall)
                            .foregroundColor(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacingL)
                    }

                    Spacer(minLength: Theme.spacingXL)
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationBarHidden(true)
            .onChange(of: authManager.isAuthenticated) { _, isAuth in
                if isAuth {
                    if dataManager.userProfile == nil {
                        showingProfileSetup = true
                    } else {
                        dismiss()
                    }
                }
            }
            .onChange(of: authManager.error) { _, error in
                errorMessage = error
            }
            .fullScreenCover(isPresented: $showingProfileSetup) {
                ProfileSetupView()
            }
        }
    }

    private var isFormValid: Bool {
        if authMode == .signIn {
            return email.isValidEmail && password.count >= 6
        } else {
            return email.isValidEmail &&
                   password.count >= 6 &&
                   password == confirmPassword &&
                   !displayName.isEmpty
        }
    }

    private func handleEmailAuth() {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        // Simulate email auth (in production, connect to your backend)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false

            // For demo purposes, we'll create a local session
            // In production, this would authenticate with your backend
            if authMode == .signUp {
                // Save user info
                KeychainManager.shared.save(key: "user_email", value: email)
                KeychainManager.shared.save(key: "user_name", value: displayName)
                KeychainManager.shared.save(key: "email_auth_token", value: UUID().uuidString)

                // Create user profile
                let profile = UserProfile(
                    email: email,
                    displayName: displayName
                )
                dataManager.updateUserProfile(profile)
            } else {
                // Verify credentials (demo: just check if email was previously registered)
                if let storedEmail = KeychainManager.shared.retrieve(key: "user_email"),
                   storedEmail == email {
                    // Valid credentials
                } else {
                    errorMessage = "Invalid email or password"
                    return
                }
            }

            // Mark as authenticated
            authManager.isAuthenticated = true

            if dataManager.userProfile == nil {
                showingProfileSetup = true
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Profile Setup View

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var age: String = ""
    @State private var occupation: String = ""
    @State private var workDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    @State private var workStartTime = Date()
    @State private var workEndTime = Date()
    @State private var wakeTime = Date()
    @State private var bedTime = Date()
    @State private var fitnessLevel: FitnessLevel = .moderatelyActive
    @State private var availableHours: Double = 10
    @State private var currentStep = 0

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 3)
                    .tint(Theme.primaryColor)
                    .padding(.horizontal, Theme.spacingM)

                TabView(selection: $currentStep) {
                    basicInfoStep.tag(0)
                    scheduleStep.tag(1)
                    preferencesStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Set Up Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep < 2 {
                        Button("Skip") {
                            saveProfile()
                        }
                        .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var basicInfoStep: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                VStack(spacing: Theme.spacingS) {
                    Text("Tell us about yourself")
                        .font(Theme.fontHeadline)
                    Text("This helps us personalize your experience")
                        .font(Theme.fontBody)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, Theme.spacingL)

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Display Name")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                    TextField("Your name", text: $displayName)
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                }

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Age (Optional)")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                    TextField("Your age", text: $age)
                        .keyboardType(.numberPad)
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                }

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Occupation (Optional)")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)
                    TextField("What do you do?", text: $occupation)
                        .padding(Theme.spacingM)
                        .background(Theme.backgroundSecondary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                }

                Spacer()

                Button(action: { withAnimation { currentStep = 1 } }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(displayName.isEmpty)
            }
            .padding(Theme.spacingM)
        }
    }

    private var scheduleStep: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                VStack(spacing: Theme.spacingS) {
                    Text("Your Schedule")
                        .font(Theme.fontHeadline)
                    Text("Help us understand your typical week")
                        .font(Theme.fontBody)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, Theme.spacingL)

                // Work days
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Work/School Days")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: Theme.spacingS) {
                        ForEach(1...7, id: \.self) { day in
                            Button(action: { toggleWorkDay(day) }) {
                                Text(weekdays[day - 1])
                                    .font(Theme.fontSmall)
                                    .fontWeight(.semibold)
                                    .foregroundColor(workDays.contains(day) ? .white : Theme.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(workDays.contains(day) ? Theme.primaryColor : Theme.backgroundSecondary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }

                // Work hours
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Work/School Hours")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    HStack {
                        DatePicker("Start", selection: $workStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: $workEndTime, displayedComponents: .hourAndMinute)
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)
                }

                // Sleep schedule
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Sleep Schedule")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Wake up")
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.textSecondary)
                            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Bedtime")
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.textSecondary)
                            DatePicker("", selection: $bedTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)
                }

                Spacer()

                HStack {
                    Button(action: { withAnimation { currentStep = 0 } }) {
                        Text("Back")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(action: { withAnimation { currentStep = 2 } }) {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.spacingM)
        }
    }

    private var preferencesStep: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                VStack(spacing: Theme.spacingS) {
                    Text("Almost Done!")
                        .font(Theme.fontHeadline)
                    Text("A few more details for better recommendations")
                        .font(Theme.fontBody)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, Theme.spacingL)

                // Fitness level
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Fitness Level")
                        .font(Theme.fontCaption)
                        .foregroundColor(Theme.textSecondary)

                    Picker("Fitness Level", selection: $fitnessLevel) {
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .background(Theme.backgroundSecondary)
                    .cornerRadius(Theme.cornerRadiusMedium)
                }

                // Available hours
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    HStack {
                        Text("Available Hours Per Week for Goals")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("\(Int(availableHours)) hrs")
                            .font(Theme.fontSubheadline)
                            .foregroundColor(Theme.primaryColor)
                    }

                    Slider(value: $availableHours, in: 1...40, step: 1)
                        .tint(Theme.primaryColor)
                }
                .padding(Theme.spacingM)
                .background(Theme.backgroundSecondary)
                .cornerRadius(Theme.cornerRadiusMedium)

                Spacer()

                HStack {
                    Button(action: { withAnimation { currentStep = 1 } }) {
                        Text("Back")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(action: saveProfile) {
                        Text("Complete Setup")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.spacingM)
        }
    }

    private func toggleWorkDay(_ day: Int) {
        if workDays.contains(day) {
            workDays.remove(day)
        } else {
            workDays.insert(day)
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
            availableHoursPerWeek: Int(availableHours)
        )

        let profile = UserProfile(
            appleUserId: authManager.currentUserId,
            email: KeychainManager.shared.retrieve(key: "user_email"),
            displayName: displayName,
            profileInfo: profileInfo
        )

        dataManager.updateUserProfile(profile)
        dismiss()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
}
