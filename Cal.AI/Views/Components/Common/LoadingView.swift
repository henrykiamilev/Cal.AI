import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primaryBlue)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textDark)
            }
            .padding(32)
            .background(Color.cardWhite)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 20)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textGray.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textDark)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle = buttonTitle, let action = buttonAction {
                PrimaryButton(buttonTitle, icon: "plus", action: action)
                    .frame(width: 200)
            }
        }
        .padding(40)
    }
}

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.warningYellow)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.headline)
                    .foregroundColor(.textDark)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                    .multilineTextAlignment(.center)
            }

            if let retry = retryAction {
                SecondaryButton("Try Again", icon: "arrow.clockwise", action: retry)
                    .frame(width: 160)
            }
        }
        .padding(40)
    }
}

struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(height: 16, cornerRadius: 4)
                .frame(width: 120)

            SkeletonView(height: 12, cornerRadius: 4)

            SkeletonView(height: 12, cornerRadius: 4)
                .frame(width: 200)
        }
        .padding()
        .background(Color.cardWhite)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Generating plan...")

        EmptyStateView(
            icon: "calendar.badge.plus",
            title: "No Events",
            message: "You don't have any events yet. Tap the button below to create one.",
            buttonTitle: "Add Event"
        ) {}

        ErrorView(
            error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])
        ) {}

        VStack(spacing: 12) {
            SkeletonCard()
            SkeletonCard()
        }
    }
    .padding()
}
