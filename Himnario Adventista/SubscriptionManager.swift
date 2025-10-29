//
//  SubscriptionManager.swift
//  Himnario Adventista SwiftUI
//
//  Subscription manager with StoreKit 2 integration for gating Playlist tab.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var isSubscribed = false
    @Published private(set) var expiryDate: Date? = nil
    @Published private(set) var subscriptionProduct: Product? = nil
    @Published private(set) var subscriptionProducts: [String: Product] = [:] // Map of productID to Product
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil
    
    // Auto-renewal specific properties
    @Published private(set) var autoRenewalEnabled = true
    @Published private(set) var nextRenewalDate: Date? = nil
    @Published private(set) var renewalStatus: RenewalStatus = .unknown
    @Published private(set) var daysUntilRenewal: Int? = nil
    
    // Product IDs
    let productIDs = [
        "com.JosePimentel.HimnarioViejoYNuevo.Basico",
        "com.JosePimentel.HimnarioViejoYNuevo.Seguidor",
        "com.JosePimentel.HimnarioViejoYNuevo.Patrocinador",
        "com.JosePimentel.HimnarioViejoYNuevo.Benefactor"
    ]
    
    private var updateListenerTask: Task<Void, Never>? = nil
    private var expirationCheckTimer: Timer?

    private init() {
        updateListenerTask = listenForTransactions()
        startExpirationTimer()
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
        expirationCheckTimer?.invalidate()
    }
    
    // MARK: - Expiration Timer
    
    private func startExpirationTimer() {
        // Check expiration every 30 seconds for sandbox testing
        expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.checkSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            isLoading = true
            errorMessage = nil
            
            let products = try await Product.products(for: productIDs)
            
            // Map products by their ID for easy access
            for product in products {
                subscriptionProducts[product.id] = product
                //print("✅ Loaded subscription product: \(product.displayName) - \(product.displayPrice)")
            }
            
            // Set the first product as the default (for backward compatibility)
            subscriptionProduct = products.first
            
            if products.isEmpty {
                errorMessage = "No subscription products found"
                //print("❌ Failed to load any products")
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            //print("❌ Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    // Get a specific product by ID
    func getProduct(for productID: String) -> Product? {
        return subscriptionProducts[productID]
    }

    // MARK: - Purchase Flow
    
    func purchase(productID: String) async throws {
        guard let product = subscriptionProducts[productID] else {
            throw SubscriptionError.productNotLoaded
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use defer to ensure isLoading is always reset
        defer {
            isLoading = false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update subscription status
                await updateSubscriptionStatus(from: transaction)
                
                // Finish the transaction
                await transaction.finish()
                
                //print("✅ Purchase successful!")
                
            case .userCancelled:
                //print("🚫 User cancelled purchase")
                throw SubscriptionError.userCancelled
                
            case .pending:
                //print("⏳ Purchase pending")
                throw SubscriptionError.purchasePending
                
            @unknown default:
                //print("❌ Unknown purchase result")
                throw SubscriptionError.unknown
            }
        } catch {
            errorMessage = error.localizedDescription
            //print("❌ Purchase failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restore() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            
            if isSubscribed {
                print("✅ Subscription restored successfully")
            } else {
                errorMessage = "No active subscription found"
                print("⚠️ No active subscription found")
            }
        } catch {
            errorMessage = "Failed to restore: \(error.localizedDescription)"
            print("❌ Restore failed: \(error)")
        }
        
        isLoading = false
    }

    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        //print("🔍 Checking subscription status at \(Date())")
        var foundActiveSubscription = false
        var latestTransaction: StoreKit.Transaction?
        
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID) {
                
//                print("📋 Found transaction: ID=\(transaction.id), ProductID=\(transaction.productID)")
//                print("📅 Purchase Date: \(transaction.purchaseDate)")
//                print("🚫 Revocation Date: \(transaction.revocationDate?.description ?? "None")")
//                print("⏰ Expiration Date: \(transaction.expirationDate?.description ?? "None")")
                
                // Skip revoked transactions
                if let revocationDate = transaction.revocationDate {
                    print("❌ Transaction revoked at: \(revocationDate)")
                    continue
                }
                
                // Check if subscription is still valid
                if let expirationDate = transaction.expirationDate {
                    let now = Date()
                    print("🔍 Expiration check: \(expirationDate) > \(now) = \(expirationDate > now)")
                    
                    if expirationDate > now {
                        print("✅ Subscription is active until: \(expirationDate)")
                        latestTransaction = transaction
                        foundActiveSubscription = true
                    } else {
                        print("❌ Subscription expired at: \(expirationDate)")
                        // Continue checking for newer transactions
                    }
                } else {
                    // Non-expiring product (shouldn't happen with subscriptions)
                    print("⚠️ Non-expiring subscription found")
                    latestTransaction = transaction
                    foundActiveSubscription = true
                }
            }
        }
        
        if foundActiveSubscription, let transaction = latestTransaction {
            await updateSubscriptionStatus(from: transaction)
        } else {
            // No active subscription found or all expired
            await setSubscriptionExpired()
        }
    }
    
    private func updateSubscriptionStatus(from transaction: StoreKit.Transaction) async {
        let wasSubscribed = isSubscribed
        isSubscribed = true
        expiryDate = transaction.expirationDate
        
        // Update auto-renewal information
        await updateAutoRenewalInfo(from: transaction)
        
        if let expiry = expiryDate {
            print("✅ Active subscription until: \(expiry)")
        } else {
            print("✅ Active subscription (no expiry)")
        }
        
        if !wasSubscribed {
            print("🎉 Subscription activated!")
        }
    }
    
    private func setSubscriptionExpired() async {
        let wasSubscribed = isSubscribed
        isSubscribed = false
        expiryDate = nil
        
        // Reset auto-renewal info when no subscription found
        autoRenewalEnabled = false
        nextRenewalDate = nil
        renewalStatus = .noSubscription
        daysUntilRenewal = nil
        
        if wasSubscribed {
            print("🚨 Subscription expired or not found")
        } else {
            print("📱 No active subscription found")
        }
    }
    
    private func updateAutoRenewalInfo(from transaction: StoreKit.Transaction) async {
        // For subscription products, we can assume they are auto-renewable
        autoRenewalEnabled = true
        
        // Set next renewal date (same as expiration date for auto-renewable)
        nextRenewalDate = transaction.expirationDate
        
        // Calculate days until renewal
        if let nextRenewal = nextRenewalDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: nextRenewal).day ?? 0
            daysUntilRenewal = max(0, days)
            
            // Determine renewal status
            if days <= 0 {
                renewalStatus = .expired
            } else if days <= 7 {
                renewalStatus = .renewingSoon
            } else if days <= 30 {
                renewalStatus = .active
            } else {
                renewalStatus = .active
            }
        } else {
            renewalStatus = .unknown
            daysUntilRenewal = nil
        }
        
        print("🔄 Auto-renewal info updated: \(renewalStatus.rawValue), \(daysUntilRenewal ?? 0) days until renewal")
    }

    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            
            for await result in StoreKit.Transaction.updates {
                print("🔄 Transaction update received")
                do {
                    // Verify transaction inline
                    let transaction: StoreKit.Transaction
                    switch result {
                    case .unverified:
                        print("❌ Unverified transaction received")
                        throw SubscriptionError.failedVerification
                    case .verified(let verifiedTransaction):
                        transaction = verifiedTransaction
                        print("✅ Verified transaction: \(transaction.id) for product: \(transaction.productID)")
                    }
                    
                    let currentProductIDs = await self.productIDs
                    if currentProductIDs.contains(transaction.productID) {
                        print("🎯 Processing transaction for our product")
                        await MainActor.run {
                            Task {
                                await self.checkSubscriptionStatus()
                            }
                        }
                    }
                    
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Properties
    
    var subscriptionPrice: String {
        subscriptionProduct?.displayPrice ?? "$1.99"
    }
    
    var isYearlySubscription: Bool {
        guard let product = subscriptionProduct,
              case .autoRenewable = product.type else {
            return false
        }
        return true
    }
    
    var subscriptionPeriod: String {
        guard let product = subscriptionProduct,
              let subscription = product.subscription else {
            return "month"
        }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value > 1 ? "\(period.value) days" : "day"
        case .week:
            return period.value > 1 ? "\(period.value) weeks" : "week"
        case .month:
            return period.value > 1 ? "\(period.value) months" : "month"
        case .year:
            return period.value > 1 ? "\(period.value) years" : "year"
        @unknown default:
            return "month"
        }
    }
    
    // MARK: - Auto-Renewal Management
    
    func manageAutoRenewal() {
        // Open App Store subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    func checkRenewalStatus() async {
        await checkSubscriptionStatus()
        
        // Log renewal information
        if let days = daysUntilRenewal {
            print("🔄 Renewal status: \(renewalStatus.rawValue)")
            print("📅 Days until renewal: \(days)")
            
            if days <= 7 {
                print("⚠️ Subscription renewing soon!")
            }
        }
    }
    
    var renewalStatusDescription: String {
        switch renewalStatus {
        case .active:
            return "Active"
        case .renewingSoon:
            return "Renewing Soon"
        case .expired:
            return "Expired"
        case .noSubscription:
            return "No Subscription"
        case .notAutoRenewable:
            return "Not Auto-Renewable"
        case .unknown:
            return "Unknown"
        }
    }
    
    var renewalStatusColor: Color {
        switch renewalStatus {
        case .active:
            return .green
        case .renewingSoon:
            return .orange
        case .expired:
            return .red
        case .noSubscription:
            return .gray
        case .notAutoRenewable:
            return .blue
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotLoaded
    case failedVerification
    case userCancelled
    case purchasePending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotLoaded:
            return "Subscription product not available"
        case .failedVerification:
            return "Failed to verify purchase"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Renewal Status

enum RenewalStatus: String, CaseIterable {
    case active = "Active"
    case renewingSoon = "Renewing Soon"
    case expired = "Expired"
    case noSubscription = "No Subscription"
    case notAutoRenewable = "Not Auto-Renewable"
    case unknown = "Unknown"
}


