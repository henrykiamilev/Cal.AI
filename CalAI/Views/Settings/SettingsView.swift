import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var showingProfile = false
    @State private var showingSubscription = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingDeleteAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    Button(action: { showingProfile = true }) {
                        HStack(spacing: Theme.spacingM) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryGradient)
                                    .frame(width: 50, height: 50)

                                Text(initials)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(dataManager.userProfile?.displayName ?? "User")
                                    .font(Theme.fontSubheadline)
                                    .foregroundColor(Theme.textPrimary)

                                Text(dataManager.userProfile?.email ?? "Set up your profile")
                                    .font(Theme.fontSmall)
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                // Subscription Section
                Section {
                    Button(action: { showingSubscription = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Theme.premiumGradient)
                                .frame(width: 24)

                            Text("Calendar AI Premium")
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            if subscriptionManager.isPremium {
                                Text("Active")
                                    .font(Theme.fontSmall)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.successColor)
                                    .cornerRadius(Theme.cornerRadiusSmall)
                            } else {
                                Text("$9.99/mo")
                                    .font(Theme.fontSmall)
                                    .foregroundColor(Theme.primaryColor)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }

                // Calendar Settings
                Section("Calendar") {
                    SettingsRow(
                        icon: "calendar",
                        title: "Default Event Duration",
                        value: "\(dataManager.userProfile?.preferences.defaultEventDuration ?? 60) min"
                    )

                    SettingsRow(
                        icon: "bell",
                        title: "Default Reminder",
                        value: dataManager.userProfile?.preferences.defaultReminderType.rawValue ?? "15 min before"
                    )

                    SettingsRow(
                        icon: "calendar.badge.plus",
                        title: "Week Starts On",
                        value: dataManager.userProfile?.preferences.calendarStartDay == 2 ? "Monday" : "Sunday"
                    )
                }

                // Notifications
                Section("Notifications") {
                    Toggle(isOn: .constant(dataManager.userProfile?.preferences.notificationsEnabled ?? true)) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 24)
                            Text("Push Notifications")
                        }
                    }
                    .tint(Theme.primaryColor)
                }

                // Data & Privacy
                Section("Data & Privacy") {
                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 24)
                            Text("Export My Data")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                        }
                    }

                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 24)
                            Text("Privacy Policy")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }

                    Button(action: { showingTerms = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 24)
                            Text("Terms of Service")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "mailto:support@calendarai.app")!) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 24)
                            Text("Contact Support")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 24)
                        Text("Version")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // Account Actions
                Section {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Theme.warningColor)
                                .frame(width: 24)
                            Text("Sign Out")
                                .foregroundColor(Theme.warningColor)
                        }
                    }

                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(Theme.errorColor)
                                .frame(width: 24)
                            Text("Delete Account")
                                .foregroundColor(Theme.errorColor)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }

    private var initials: String {
        let name = dataManager.userProfile?.displayName ?? "U"
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func exportData() {
        guard let data = dataManager.exportUserData() else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("calendar_ai_export.json")
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func deleteAccount() {
        dataManager.deleteAllUserData()
        Task {
            await authManager.deleteAccount()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
        .environmentObject(SubscriptionManager())
}
