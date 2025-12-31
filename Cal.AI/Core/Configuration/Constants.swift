import SwiftUI

enum Constants {
    // MARK: - App Info
    enum App {
        static let name = "Cal.AI"
        static let version = "1.0.0"
        static let bundleId = "com.calai.app"
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userProfileId = "userProfileId"
        static let encryptionKey = "encryptionKey"
        static let apiKey = "openai_api_key"
    }

    // MARK: - UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let iconSize: CGFloat = 24
        static let avatarSize: CGFloat = 48
        static let buttonHeight: CGFloat = 50
        static let cardShadowRadius: CGFloat = 8
        static let animationDuration: Double = 0.3
    }

    // MARK: - Calendar
    enum Calendar {
        static let weekStartsOnMonday = false
        static let hoursInDay = 24
        static let defaultEventDurationMinutes = 60
        static let timelineStartHour = 6
        static let timelineEndHour = 23
    }

    // MARK: - AI
    enum AI {
        static let maxPhasesPerGoal = 5
        static let maxTasksPerPhase = 10
        static let defaultWeeklyHours = 10.0
        static let minimumAdjustmentDays = 7
    }

    // MARK: - Notifications
    enum Notifications {
        static let defaultReminderMinutes = 15
        static let aiTaskReminderHour = 9
    }
}

// MARK: - Color Palette
extension Color {
    static let appPrimary = Color("Primary")
    static let appSecondary = Color("Secondary")
    static let appAccent = Color("Accent")
    static let appBackground = Color("Background")
    static let appCardBackground = Color("CardBackground")
    static let appText = Color("TextPrimary")
    static let appTextSecondary = Color("TextSecondary")
    static let appSuccess = Color("Success")
    static let appWarning = Color("Warning")
    static let appError = Color("Error")

    // Fallback colors when assets aren't configured
    static let primaryBlue = Color(hex: "4A90E2")
    static let secondaryPurple = Color(hex: "9B59B6")
    static let accentOrange = Color(hex: "F39C12")
    static let backgroundLight = Color(hex: "F8F9FA")
    static let cardWhite = Color(hex: "FFFFFF")
    static let textDark = Color(hex: "2C3E50")
    static let textGray = Color(hex: "7F8C8D")
    static let successGreen = Color(hex: "27AE60")
    static let warningYellow = Color(hex: "F1C40F")
    static let errorRed = Color(hex: "E74C3C")
}

// MARK: - Category Colors
extension Color {
    static let categoryWork = Color(hex: "3498DB")
    static let categoryPersonal = Color(hex: "9B59B6")
    static let categoryHealth = Color(hex: "27AE60")
    static let categoryEducation = Color(hex: "F39C12")
    static let categoryFinance = Color(hex: "1ABC9C")
    static let categoryCareer = Color(hex: "E74C3C")
}
