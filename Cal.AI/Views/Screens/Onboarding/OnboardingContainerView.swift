import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isComplete: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.backgroundLight, .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                StepProgress(
                    currentStep: viewModel.currentStep.rawValue + 1,
                    totalSteps: OnboardingStep.allCases.count
                )
                .padding(.horizontal, 40)
                .padding(.top)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(OnboardingStep.welcome)

                    ProfileStepView(viewModel: viewModel)
                        .tag(OnboardingStep.profile)

                    InterestsStepView(viewModel: viewModel)
                        .tag(OnboardingStep.interests)

                    AvailabilityStepView(viewModel: viewModel)
                        .tag(OnboardingStep.availability)

                    NotificationsStepView(viewModel: viewModel) {
                        isComplete = true
                    }
                    .tag(OnboardingStep.notifications)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .onTapHideKeyboard()
    }
}

struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo/Icon
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient.primaryGradient)

                Text("Cal.AI")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textDark)
            }

            // Description
            VStack(spacing: 12) {
                Text("Your AI-Powered\nCalendar Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textDark)

                Text("Organize your schedule, track your goals, and let AI guide you to success.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textGray)
                    .padding(.horizontal, 40)
            }

            // Features
            VStack(spacing: 16) {
                FeatureRow(icon: "calendar", title: "Smart Calendar", description: "Manage events and tasks effortlessly")
                FeatureRow(icon: "sparkles", title: "AI Planning", description: "Get personalized schedules for your goals")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", description: "Track and adjust based on your progress")
            }
            .padding(.horizontal)

            Spacer()

            // Continue button
            PrimaryButton("Get Started", icon: "arrow.right") {
                viewModel.next()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primaryBlue)
                .frame(width: 44, height: 44)
                .background(Color.primaryBlue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textDark)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.textGray)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ProfileStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            // Header
            OnboardingHeader(
                title: "Let's get to know you",
                subtitle: "This helps us personalize your experience"
            )

            // Form
            VStack(spacing: 20) {
                CustomTextField(
                    placeholder: "Your name",
                    text: $viewModel.name,
                    icon: "person"
                )

                CustomTextField(
                    placeholder: "Your occupation (optional)",
                    text: $viewModel.occupation,
                    icon: "briefcase"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Navigation
            OnboardingNavigation(
                canProceed: viewModel.canProceed,
                isLastStep: false,
                onBack: viewModel.back,
                onNext: viewModel.next
            )
        }
        .padding(.top, 40)
    }
}

struct InterestsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        VStack(spacing: 24) {
            // Header
            OnboardingHeader(
                title: "What interests you?",
                subtitle: "Select at least one to help us tailor your experience"
            )

            // Interests grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(UserProfile.suggestedInterests, id: \.self) { interest in
                        InterestChip(
                            title: interest,
                            isSelected: viewModel.selectedInterests.contains(interest)
                        ) {
                            viewModel.toggleInterest(interest)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Navigation
            OnboardingNavigation(
                canProceed: viewModel.canProceed,
                isLastStep: false,
                onBack: viewModel.back,
                onNext: viewModel.next
            )
        }
        .padding(.top, 40)
    }
}

struct InterestChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .textDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.primaryBlue : Color.cardWhite)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct AvailabilityStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            // Header
            OnboardingHeader(
                title: "Your availability",
                subtitle: "How many hours per week can you dedicate to your goals?"
            )

            VStack(spacing: 24) {
                // Hours display
                VStack(spacing: 8) {
                    Text("\(Int(viewModel.weeklyHours))")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryBlue)

                    Text("hours per week")
                        .font(.subheadline)
                        .foregroundColor(.textGray)
                }

                // Slider
                Slider(value: $viewModel.weeklyHours, in: 1...40, step: 1)
                    .tint(.primaryBlue)
                    .padding(.horizontal, 24)

                // Presets
                HStack(spacing: 12) {
                    ForEach([5, 10, 15, 20], id: \.self) { hours in
                        Button {
                            withAnimation { viewModel.weeklyHours = Double(hours) }
                            HapticManager.shared.selection()
                        } label: {
                            Text("\(hours)h")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.weeklyHours == Double(hours) ? .white : .primaryBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.weeklyHours == Double(hours) ? Color.primaryBlue : Color.primaryBlue.opacity(0.1)
                                )
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Navigation
            OnboardingNavigation(
                canProceed: viewModel.canProceed,
                isLastStep: false,
                onBack: viewModel.back,
                onNext: viewModel.next
            )
        }
        .padding(.top, 40)
    }
}

struct NotificationsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primaryGradient)

            // Header
            VStack(spacing: 12) {
                Text("Stay on track")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textDark)

                Text("Enable notifications to get reminders for your events, tasks, and AI-scheduled activities.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textGray)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                PrimaryButton("Enable Notifications", icon: "bell") {
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                        viewModel.completeOnboarding()
                        onComplete()
                    }
                }

                Button("Maybe Later") {
                    viewModel.completeOnboarding()
                    onComplete()
                }
                .font(.subheadline)
                .foregroundColor(.textGray)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Common Components
struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textDark)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct OnboardingNavigation: View {
    let canProceed: Bool
    let isLastStep: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            SecondaryButton("Back", icon: "chevron.left", action: onBack)

            PrimaryButton(
                isLastStep ? "Complete" : "Continue",
                icon: isLastStep ? "checkmark" : "arrow.right",
                isDisabled: !canProceed,
                action: onNext
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView(isComplete: .constant(false))
}
