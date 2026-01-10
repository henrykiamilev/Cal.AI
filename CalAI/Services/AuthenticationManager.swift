import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var isLoading = false
    @Published var error: String?

    private let keychainManager = KeychainManager.shared

    override init() {
        super.init()
        checkExistingAuthentication()
    }

    private func checkExistingAuthentication() {
        if let userId = keychainManager.retrieve(key: "apple_user_id") {
            currentUserId = userId
            verifyAppleIDCredential(userId: userId)
        }
    }

    private func verifyAppleIDCredential(userId: String) {
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userId) { [weak self] state, error in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.isAuthenticated = true
                case .revoked, .notFound:
                    self?.signOut()
                case .transferred:
                    // Handle account transfer if needed
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()

        isLoading = true
    }

    func signOut() {
        keychainManager.delete(key: "apple_user_id")
        keychainManager.delete(key: "user_email")
        keychainManager.delete(key: "user_name")

        currentUserId = nil
        isAuthenticated = false
    }

    func deleteAccount() async {
        // In a production app, you would also:
        // 1. Call your backend to delete user data
        // 2. Revoke Apple Sign In token
        // 3. Delete CloudKit data

        signOut()
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isLoading = false

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            error = "Invalid credential type"
            return
        }

        let userId = credential.user

        // Store user ID securely
        keychainManager.save(key: "apple_user_id", value: userId)

        // Store email if provided (only on first sign in)
        if let email = credential.email {
            keychainManager.save(key: "user_email", value: email)
        }

        // Store name if provided
        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                keychainManager.save(key: "user_name", value: name)
            }
        }

        currentUserId = userId
        isAuthenticated = true
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false

        let authError = error as? ASAuthorizationError

        switch authError?.code {
        case .canceled:
            // User cancelled, no error message needed
            break
        case .failed:
            self.error = "Authorization failed. Please try again."
        case .invalidResponse:
            self.error = "Invalid response from Apple. Please try again."
        case .notHandled:
            self.error = "Authorization not handled. Please try again."
        case .notInteractive:
            self.error = "Authorization requires interaction."
        case .unknown:
            self.error = "An unknown error occurred."
        default:
            self.error = error.localizedDescription
        }
    }
}

// SwiftUI wrapper for Sign in with Apple button
struct SignInWithAppleButton: View {
    @EnvironmentObject var authManager: AuthenticationManager
    let onCompletion: () -> Void

    var body: some View {
        SignInWithAppleButtonRepresentable(
            type: .signIn,
            style: .black
        ) {
            authManager.signInWithApple()
        }
        .frame(height: 50)
        .cornerRadius(12)
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            if isAuth {
                onCompletion()
            }
        }
    }
}

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let action: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func buttonTapped() {
            action()
        }
    }
}
