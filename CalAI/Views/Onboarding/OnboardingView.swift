import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    @State private var showingLogin = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Smart Calendar",
            description: "Keep track of all your events, classes, and appointments in one beautiful, easy-to-use calendar"
        ),
        OnboardingPage(
            icon: "checklist",
            title: "Task Management",
            description: "Organize your tasks, set priorities, and never forget important to-dos like homework or groceries"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "AI-Powered Goals",
            description: "Set ambitious goals and let our AI create a personalized schedule to help you achieve them"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "Monitor your journey with adaptive schedules that adjust based on your performance"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    showingLogin = true
                }
                .font(Theme.fontCaption)
                .foregroundColor(Theme.textSecondary)
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Theme.primaryColor : Theme.backgroundTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.vertical, Theme.spacingL)

            // Action button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    showingLogin = true
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacingL)
            .padding(.bottom, Theme.spacingXL)
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showingLogin) {
            LoginView()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.primaryColor.opacity(0.1))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(Theme.primaryColor.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.primaryGradient)
            }

            VStack(spacing: Theme.spacingM) {
                Text(page.title)
                    .font(Theme.fontTitle)
                    .foregroundColor(Theme.textPrimary)

                Text(page.description)
                    .font(Theme.fontBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingL)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}
