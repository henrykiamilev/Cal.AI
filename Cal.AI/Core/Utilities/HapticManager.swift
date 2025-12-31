import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func lightImpact() {
        impact(.light)
    }

    func mediumImpact() {
        impact(.medium)
    }

    func heavyImpact() {
        impact(.heavy)
    }

    func softImpact() {
        impact(.soft)
    }

    func rigidImpact() {
        impact(.rigid)
    }

    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func success() {
        notification(.success)
    }

    func warning() {
        notification(.warning)
    }

    func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Convenience Extensions
extension HapticManager {
    /// Use for button taps
    func buttonTap() {
        lightImpact()
    }

    /// Use for toggling switches
    func toggle() {
        selection()
    }

    /// Use for completing a task
    func taskComplete() {
        success()
    }

    /// Use for deleting something
    func delete() {
        warning()
    }

    /// Use for validation errors
    func validationError() {
        error()
    }

    /// Use for scrolling through picker values
    func scroll() {
        selection()
    }

    /// Use for long press actions
    func longPress() {
        heavyImpact()
    }
}
