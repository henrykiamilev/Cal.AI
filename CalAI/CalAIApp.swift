import SwiftUI

@main
struct CalAIApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var dataManager = DataManager()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.light)
        }
    }
}
