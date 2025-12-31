import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isValid: Bool = true
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? .primaryBlue : .textGray)
                        .frame(width: 20)
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .padding()
            .background(Color.backgroundLight)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(
                        isFocused ? Color.primaryBlue :
                            (!isValid ? Color.errorRed : Color.clear),
                        lineWidth: 2
                    )
            )

            if let error = errorMessage, !isValid {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.errorRed)
                    .padding(.leading, 4)
            }
        }
    }
}

struct CustomTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.textGray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: minHeight)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.backgroundLight)
        }
        .cornerRadius(Constants.UI.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(isFocused ? Color.primaryBlue : Color.clear, lineWidth: 2)
        )
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textGray)

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    HapticManager.shared.buttonTap()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textGray)
                }
            }
        }
        .padding(12)
        .background(Color.backgroundLight)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            placeholder: "Enter your email",
            text: .constant(""),
            icon: "envelope"
        )

        CustomTextField(
            placeholder: "Password",
            text: .constant(""),
            icon: "lock",
            isSecure: true
        )

        CustomTextField(
            placeholder: "Invalid field",
            text: .constant("test"),
            icon: "exclamationmark.triangle",
            isValid: false,
            errorMessage: "This field is invalid"
        )

        CustomTextEditor(
            placeholder: "Write your notes here...",
            text: .constant("")
        )

        SearchBar(text: .constant(""))
    }
    .padding()
}
