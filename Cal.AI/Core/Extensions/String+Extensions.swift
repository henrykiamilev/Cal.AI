import Foundation

extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    var isNotEmpty: Bool {
        !isEmpty && !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Formatting
    var capitalizingFirstLetter: String {
        prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter
    }

    // MARK: - Truncation
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }

    // MARK: - Localization
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }

    // MARK: - JSON
    var jsonData: Data? {
        data(using: .utf8)
    }

    func toJSON<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = jsonData else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Initials
    var initials: String {
        let words = components(separatedBy: .whitespaces)
        let initials = words.compactMap { $0.first?.uppercased() }
        return initials.prefix(2).joined()
    }

    // MARK: - Safe Subscript
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0 && range.upperBound <= count else { return nil }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}

// MARK: - Optional String
extension Optional where Wrapped == String {
    var orEmpty: String {
        self ?? ""
    }

    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }

    var isNotNilOrEmpty: Bool {
        !isNilOrEmpty
    }
}
