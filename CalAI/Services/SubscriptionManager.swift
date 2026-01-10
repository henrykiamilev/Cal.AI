import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    private let productIDs = ["com.calai.premium.monthly"]
    private var updateListenerTask: Task<Void, Error>?

    var isPremium: Bool {
        purchasedProductIDs.contains("com.calai.premium.monthly")
    }

    var subscriptionStatus: SubscriptionStatus {
        isPremium ? .premium : .free
    }

    var monthlyProduct: Product? {
        products.first { $0.id == "com.calai.premium.monthly" }
    }

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchasedIDs
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else { return }

        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }

        await transaction.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let item):
            return item
        }
    }

    func formatPrice(_ product: Product) -> String {
        product.displayPrice
    }

    func getSubscriptionInfo() async -> SubscriptionInfo? {
        guard let product = monthlyProduct else { return nil }

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == product.id else { continue }

            return SubscriptionInfo(
                productID: transaction.productID,
                purchaseDate: transaction.purchaseDate,
                expirationDate: transaction.expirationDate,
                isActive: transaction.revocationDate == nil
            )
        }

        return nil
    }
}

struct SubscriptionInfo {
    let productID: String
    let purchaseDate: Date
    let expirationDate: Date?
    let isActive: Bool

    var formattedExpirationDate: String? {
        guard let date = expirationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

enum SubscriptionError: Error, LocalizedError {
    case failedVerification
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        case .purchaseFailed:
            return "Purchase could not be completed."
        }
    }
}
