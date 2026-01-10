import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingXL) {
                    // Header
                    VStack(spacing: Theme.spacingM) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(Theme.premiumGradient)
                        }

                        Text("Calendar AI Premium")
                            .font(Theme.fontTitle)
                            .foregroundColor(Theme.textPrimary)

                        if subscriptionManager.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Active Subscription")
                            }
                            .font(Theme.fontSubheadline)
                            .foregroundColor(Theme.successColor)
                        }
                    }
                    .padding(.top, Theme.spacingL)

                    // Features
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("Premium Features")
                            .font(Theme.fontHeadline)
                            .foregroundColor(Theme.textPrimary)

                        FeatureListItem(
                            icon: "brain",
                            title: "AI Goal Scheduling",
                            description: "Get personalized schedules to achieve any goal"
                        )

                        FeatureListItem(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Adaptive Plans",
                            description: "Schedules that adjust based on your progress"
                        )

                        FeatureListItem(
                            icon: "lightbulb.fill",
                            title: "Smart Recommendations",
                            description: "AI-powered tips to stay on track"
                        )

                        FeatureListItem(
                            icon: "infinity",
                            title: "Unlimited Goals",
                            description: "Create as many AI-powered goals as you want"
                        )

                        FeatureListItem(
                            icon: "icloud.fill",
                            title: "Priority Sync",
                            description: "Faster cloud sync across all devices"
                        )
                    }
                    .padding(.horizontal, Theme.spacingM)

                    Spacer(minLength: Theme.spacingL)

                    // Pricing
                    if !subscriptionManager.isPremium {
                        VStack(spacing: Theme.spacingM) {
                            if let product = subscriptionManager.monthlyProduct {
                                VStack(spacing: Theme.spacingS) {
                                    Text(product.displayPrice)
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)

                                    Text("per month")
                                        .font(Theme.fontBody)
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Button(action: subscribe) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Subscribe Now")
                                        }
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isLoading)
                            } else {
                                ProgressView()
                                    .padding()
                            }

                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary)

                            Text("Cancel anytime. Subscription automatically renews.")
                                .font(Theme.fontSmall)
                                .foregroundColor(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, Theme.spacingL)
                    } else {
                        // Subscription info
                        subscriptionInfo
                    }

                    // Legal links
                    HStack(spacing: Theme.spacingL) {
                        Button("Terms of Use") {
                            // Open terms
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.textSecondary)

                        Button("Privacy Policy") {
                            // Open privacy
                        }
                        .font(Theme.fontSmall)
                        .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, Theme.spacingL)
                }
            }
            .background(Theme.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var subscriptionInfo: some View {
        VStack(spacing: Theme.spacingM) {
            Text("Subscription Details")
                .font(Theme.fontSubheadline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: Theme.spacingS) {
                HStack {
                    Text("Status")
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Active")
                        .foregroundColor(Theme.successColor)
                }

                Divider()

                HStack {
                    Text("Plan")
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Monthly ($9.99)")
                        .foregroundColor(Theme.textPrimary)
                }

                Divider()

                HStack {
                    Text("Renews")
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Auto-renewal enabled")
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.backgroundSecondary)
            .cornerRadius(Theme.cornerRadiusMedium)

            Text("Manage your subscription in Settings > Apple ID > Subscriptions")
                .font(Theme.fontSmall)
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacingL)
    }

    private func subscribe() {
        guard let product = subscriptionManager.monthlyProduct else { return }

        isLoading = true

        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

struct FeatureListItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.premiumGradient)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.fontSubheadline)
                    .foregroundColor(Theme.textPrimary)

                Text(description)
                    .font(Theme.fontCaption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.backgroundSecondary)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionManager())
}
