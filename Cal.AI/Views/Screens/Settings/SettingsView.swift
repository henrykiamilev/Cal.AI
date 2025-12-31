import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingProfileEditor = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    if let profile = viewModel.userProfile {
                        ProfileRow(profile: profile) {
                            showingProfileEditor = true
                        }
                    }
                }

                // AI Settings
                Section("AI Planning") {
                    HStack {
                        Label("Planning Engine", systemImage: "sparkles")

                        Spacer()

                        Text("On-Device")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.successGreen)
                    }

                    Text("Goal plans are generated locally on your device using smart templates. No internet connection or API key required.")
                        .font(.caption)
                        .foregroundColor(.textGray)
                }

                // Preferences
                Section("Preferences") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink {
                        AvailabilitySettingsView(profile: viewModel.userProfile)
                    } label: {
                        Label("Availability", systemImage: "clock")
                    }
                }

                // Privacy
                Section("Privacy & Data") {
                    Button {
                        if let url = viewModel.exportData() {
                            exportURL = url
                            showingExportSheet = true
                        }
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        viewModel.showingDeleteConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.textGray)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfileEditor) {
                if let profile = viewModel.userProfile {
                    ProfileEditorView(profile: profile) { updatedProfile in
                        viewModel.updateProfile(updatedProfile)
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Delete All Data", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your events, tasks, goals, and personal data. This action cannot be undone.")
            }
        }
    }
}

struct ProfileRow: View {
    let profile: UserProfile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 60, height: 60)

                    Text(profile.initials)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.textDark)

                    if let occupation = profile.occupation {
                        Text(occupation)
                            .font(.subheadline)
                            .foregroundColor(.textGray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var occupation: String
    @State private var interests: [String]

    let profile: UserProfile
    let onSave: (UserProfile) -> Void

    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _name = State(initialValue: profile.name)
        _occupation = State(initialValue: profile.occupation ?? "")
        _interests = State(initialValue: profile.interests)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Name", text: $name)
                    TextField("Occupation", text: $occupation)
                }

                Section("Interests") {
                    ForEach(interests, id: \.self) { interest in
                        Text(interest)
                    }
                    .onDelete { indexSet in
                        interests.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = profile
                        updated.name = name.trimmed
                        updated.occupation = occupation.trimmed.isEmpty ? nil : occupation.trimmed
                        updated.interests = interests
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmed.isEmpty)
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var eventReminders = true
    @State private var taskReminders = true
    @State private var aiTaskReminders = true
    @State private var dailySummary = false

    var body: some View {
        Form {
            Section("Reminders") {
                Toggle("Event Reminders", isOn: $eventReminders)
                Toggle("Task Reminders", isOn: $taskReminders)
                Toggle("AI Task Reminders", isOn: $aiTaskReminders)
            }

            Section("Summary") {
                Toggle("Daily Summary", isOn: $dailySummary)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct AvailabilitySettingsView: View {
    let profile: UserProfile?
    @State private var weeklyHours: Double

    init(profile: UserProfile?) {
        self.profile = profile
        _weeklyHours = State(initialValue: profile?.weeklyAvailableHours ?? 10)
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Text("\(Int(weeklyHours)) hours/week")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)

                    Slider(value: $weeklyHours, in: 1...40, step: 1)
                        .tint(.primaryBlue)
                }
                .padding(.vertical)
            } footer: {
                Text("This is used to plan realistic schedules for your goals.")
            }
        }
        .navigationTitle("Availability")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    SettingsView()
}
