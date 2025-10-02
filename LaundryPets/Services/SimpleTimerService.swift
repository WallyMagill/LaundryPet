//
//  SimpleTimerService.swift
//  LaundryPets
//
//  Global singleton service for broadcasting health update notifications
//
//  ⚠️ CRITICAL DISTINCTION FROM PetTimerService:
//
//  SimpleTimerService (THIS FILE):
//  - GLOBAL singleton service
//  - Broadcasts health updates every 30 seconds
//  - Does NOT manage pet-specific laundry timers
//  - All pets listen and update their own health independently
//
//  PetTimerService (DIFFERENT FILE):
//  - PER-INSTANCE service (one per pet)
//  - Manages individual wash/dry timers
//  - Handles background persistence
//  - Completely independent from this service
//
//  Why This Design?
//  - Efficient: One global timer instead of health timer per pet
//  - Battery-friendly: Batched updates every 30 seconds
//  - Scalable: Works with unlimited pets without overhead
//  - Independent: Health updates separate from laundry timers
//
//  Usage Pattern:
//
//  // In app startup (LaundryPetsApp.swift):
//  SimpleTimerService.shared.startHealthUpdates()
//
//  // In PetViewModel:
//  NotificationCenter.default.addObserver(forName: .healthUpdateTick, ...) { _ in
//      // Recalculate this pet's health
//      let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
//      petService.updatePetHealth(pet, newHealth: health)
//  }
//

import Foundation
import Combine

/// Global singleton service for broadcasting periodic health update notifications
/// All active pets listen for these broadcasts and recalculate their own health
@MainActor
final class SimpleTimerService {
    // MARK: - Singleton
    
    /// Shared instance (singleton pattern)
    static let shared = SimpleTimerService()
    
    // MARK: - Properties
    
    /// Combine cancellable for the health update timer
    /// nil when timer is not running
    private var timerCancellable: AnyCancellable?
    
    /// Health update broadcast interval (30 seconds)
    /// Balance between responsiveness and battery efficiency:
    /// - Too frequent (e.g., 1s): Unnecessary battery drain
    /// - Too infrequent (e.g., 5min): Health feels unresponsive
    /// - 30s: Sweet spot for smooth UX with minimal battery impact
    private let updateInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    /// Timer does not start automatically - must call startHealthUpdates()
    private init() {
        // Empty - timer starts manually
    }
    
    // MARK: - Public API
    
    /// Starts the global health update broadcast timer
    /// Posts .healthUpdateTick notification every 30 seconds
    /// Safe to call multiple times - will not create duplicate timers
    func startHealthUpdates() {
        // Prevent duplicate timers
        guard timerCancellable == nil else {
            print("⚠️ Health update timer already running")
            return
        }
        
        // Create timer that publishes every 30 seconds
        timerCancellable = Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.broadcastHealthUpdate()
            }
        
        print("💚 Health update timer started (every \(updateInterval)s)")
    }
    
    /// Stops the global health update broadcast timer
    /// Useful for testing or app lifecycle management
    func stopHealthUpdates() {
        // Cancel timer
        timerCancellable?.cancel()
        timerCancellable = nil
        
        print("🛑 Health update timer stopped")
    }
    
    // MARK: - Private Methods
    
    /// Broadcasts a health update notification
    /// All listening pets will recalculate their health when this fires
    private func broadcastHealthUpdate() {
        // Post global notification
        NotificationCenter.default.post(
            name: .healthUpdateTick,
            object: nil
        )
        
        // Debug logging (can be disabled in production for performance)
        #if DEBUG
        print("💓 Health update broadcast")
        #endif
    }
}

// MARK: - Notification Names

/// Extension to define custom notification names
extension Notification.Name {
    /// Posted every 30 seconds to trigger health recalculation
    /// All active PetViewModels should observe this notification
    static let healthUpdateTick = Notification.Name("healthUpdateTick")
}

