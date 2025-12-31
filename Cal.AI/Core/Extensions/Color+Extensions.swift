import SwiftUI

extension Color {
    // MARK: - Hex Initialization
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

    // MARK: - Hex String Output
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else {
            return "000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "%02X%02X%02X", r, g, b)
    }

    // MARK: - Color Manipulation
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.2) -> Color {
        adjust(by: -abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: min(max(red + percentage, 0), 1),
            green: min(max(green + percentage, 0), 1),
            blue: min(max(blue + percentage, 0), 1),
            opacity: alpha
        )
    }

    // MARK: - Opacity Variants
    var soft: Color {
        self.opacity(0.1)
    }

    var medium: Color {
        self.opacity(0.5)
    }

    // MARK: - Semantic Colors
    static func forCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "work", "meeting":
            return .categoryWork
        case "personal":
            return .categoryPersonal
        case "health", "fitness", "exercise":
            return .categoryHealth
        case "education", "class", "study", "homework":
            return .categoryEducation
        case "finance", "money":
            return .categoryFinance
        case "career":
            return .categoryCareer
        default:
            return .primaryBlue
        }
    }

    static func forPriority(_ priority: Int) -> Color {
        switch priority {
        case 2: return .errorRed
        case 1: return .warningYellow
        default: return .textGray
        }
    }
}

// MARK: - Gradient Helpers
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.primaryBlue, .secondaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [.successGreen, Color(hex: "2ECC71")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [.accentOrange, Color(hex: "E74C3C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coolGradient = LinearGradient(
        colors: [Color(hex: "3498DB"), Color(hex: "9B59B6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
