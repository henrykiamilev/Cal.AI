import SwiftUI

enum Theme {
    // MARK: - Colors

    static let primaryColor = Color(hex: "5B5FEF")
    static let secondaryColor = Color(hex: "7C3AED")
    static let accentColor = Color(hex: "06B6D4")

    static let successColor = Color(hex: "10B981")
    static let warningColor = Color(hex: "F59E0B")
    static let errorColor = Color(hex: "EF4444")

    static let backgroundPrimary = Color(hex: "FAFAFA")
    static let backgroundSecondary = Color(hex: "F4F4F5")
    static let backgroundTertiary = Color(hex: "E4E4E7")

    static let textPrimary = Color(hex: "18181B")
    static let textSecondary = Color(hex: "71717A")
    static let textTertiary = Color(hex: "A1A1AA")

    // MARK: - Dark Mode Colors

    static let darkBackgroundPrimary = Color(hex: "18181B")
    static let darkBackgroundSecondary = Color(hex: "27272A")
    static let darkBackgroundTertiary = Color(hex: "3F3F46")

    static let darkTextPrimary = Color(hex: "FAFAFA")
    static let darkTextSecondary = Color(hex: "A1A1AA")
    static let darkTextTertiary = Color(hex: "71717A")

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [primaryColor, secondaryColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accentColor, primaryColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows

    static let shadowSmall = Shadow(
        color: Color.black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )

    static let shadowMedium = Shadow(
        color: Color.black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 4
    )

    static let shadowLarge = Shadow(
        color: Color.black.opacity(0.15),
        radius: 16,
        x: 0,
        y: 8
    )

    // MARK: - Corner Radius

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Typography

    static let fontTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let fontHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let fontSubheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    static let fontBody = Font.system(size: 16, weight: .regular, design: .default)
    static let fontCaption = Font.system(size: 14, weight: .regular, design: .default)
    static let fontSmall = Font.system(size: 12, weight: .regular, design: .default)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(
                color: Theme.shadowSmall.color,
                radius: Theme.shadowSmall.radius,
                x: Theme.shadowSmall.x,
                y: Theme.shadowSmall.y
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.fontSubheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.primaryGradient)
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.fontSubheadline)
            .foregroundColor(Theme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.primaryColor.opacity(0.1))
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
