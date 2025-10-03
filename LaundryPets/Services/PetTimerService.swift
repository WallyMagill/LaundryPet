//
//  PetTimerService.swift
//  LaundryPets
//
//  Per-pet timer service for managing individual laundry timers
//
//  ⚠️ CRITICAL ARCHITECTURE: PER-INSTANCE DESIGN
//
//  This is NOT a singleton! Each PetViewModel creates its own PetTimerService instance.
//  This ensures complete timer independence between pets.
//
//  Why Per-Instance?
//  - ✅ Complete isolation: No shared state between pets
//  - ✅ Easy testing: Can test individual timers independently
//  - ✅ Natural lifecycle: Timer owned by ViewModel, cleaned up automatically
//  - ✅ Scalability: Support unlimited pets without complexity
//
//  Example: 3 pets washing simultaneously
//  - Pet A has PetTimerService A (endTime: 2:45 PM)
//  - Pet B has PetTimerService B (endTime: 2:50 PM)
//  - Pet C has PetTimerService C (endTime: 2:47 PM)
//  Each operates independently with no interference.
//
//  ⚠️ CRITICAL CONCEPT: ABSOLUTE TIME
//
//  This service uses ABSOLUTE TIME (Date-based endTime) instead of relative counting.
//  - Survives app backgrounding, force quit, device restart
//  - Always accurate: remaining = endTime - Date()
//  - No drift or accumulation errors
//  - Simple restoration logic
//

import Foundation
import Combine
import UIKit

/// Service for managing a single pet's timer with background persistence
/// Each pet gets its own instance for complete independence
@MainActor
final class PetTimerService: ObservableObject {
    // MARK: - Published State (Observable by UI)
    
    /// Whether a timer is currently active
    @Published var isActive: Bool = false
    
    /// Remaining time in seconds
    /// Updated every second when timer is active
    @Published var timeRemaining: TimeInterval = 0
    
    /// Current timer type (wash, dry, extraDry, or cycle)
    @Published var timerType: SimpleTimerType = .cycle
    
    // MARK: - Configuration
    
    /// Unique identifier for the pet
    /// Immutable - set at initialization
    let petID: UUID
    
    /// Absolute end time of current timer
    /// CRITICAL: This is the source of truth for timer accuracy
    private(set) var endTime: Date?
    
    // MARK: - Private Dependencies
    
    /// Combine cancellable for UI update timer
    /// Fires every second to update timeRemaining
    private var timerCancellable: AnyCancellable?
    
    /// Combine cancellable for app lifecycle observation
    /// Ensures state is saved when backgrounding
    private var lifecycleObserver: AnyCancellable?
    
    // MARK: - Computed Properties
    
    /// Unique UserDefaults key for this pet's timer
    /// Format: "pet_timer_{UUID}"
    /// Ensures no collision between pets
    private var userDefaultsKey: String {
        "pet_timer_\(petID.uuidString)"
    }
    
    // MARK: - Initialization
    
    /// Creates a new timer service for a specific pet
    /// - Parameter petID: UUID of the pet this timer belongs to
    init(petID: UUID) {
        self.petID = petID
        
        // Restore any previously saved timer state
        restoreTimerState()
        
        // Start observing app lifecycle for persistence
        observeAppLifecycle()
    }
    
    // MARK: - Public API
    
    /// Starts a new timer with the specified duration
    /// - Parameters:
    ///   - duration: Timer duration in seconds (must be positive)
    ///   - type: Type of timer (wash, dry, extraDry, or cycle)
    func startTimer(duration: TimeInterval, type: SimpleTimerType) {
        // Validate duration
        guard duration > 0 else {
            #if DEBUG
            print("❌ Invalid timer duration: \(duration)s for pet \(petID)")
            #endif
            return
        }
        
        // Prevent starting if already active
        guard !isActive else {
            #if DEBUG
            print("⚠️ Timer already active for pet \(petID)")
            #endif
            return
        }
        
        // Stop any existing timer first
        clearTimerState()
        
        // Calculate absolute end time (CRITICAL: absolute time, not relative)
        let now = Date()
        let end = now.addingTimeInterval(duration)
        
        // Update state
        self.endTime = end
        self.timerType = type
        self.isActive = true
        self.timeRemaining = duration
        
        // Persist state to UserDefaults
        saveTimerState()
        
        // Start UI update loop
        startUIUpdates()
    }
    
    /// Stops the current timer (user cancellation)
    /// Clears all timer state and persists the cancellation
    func stopTimer() {
        // Only stop if active
        guard isActive else {
            #if DEBUG
            print("⚠️ No active timer to stop for pet \(petID)")
            #endif
            return
        }
        
        // Clear all timer state
        clearTimerState()
    }
    
    /// Checks if the timer has completed
    /// - Returns: true if current time >= endTime
    func checkTimerStatus() -> Bool {
        guard let end = endTime else { return false }
        return Date() >= end
    }
    
    /// Gets the current remaining time for UI display
    /// - Returns: Remaining time in seconds, or 0 if timer is not active
    func getRemainingTime() -> TimeInterval {
        guard let end = endTime else { return 0 }
        return max(0, end.timeIntervalSinceNow)
    }
    
    /// Gets formatted time string for UI display (MM:SS format)
    /// - Returns: Formatted time string or "00:00" if not active
    func getFormattedTime() -> String {
        let remaining = getRemainingTime()
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Methods: State Management
    
    /// Saves current timer state to UserDefaults for background persistence
    private func saveTimerState() {
        guard let end = endTime else {
            #if DEBUG
            print("⚠️ Cannot save timer state: no endTime for pet \(petID)")
            #endif
            return
        }
        
        // Create codable state object
        let state = TimerState(
            petID: petID,
            endTime: end,
            timerType: timerType
        )
        
        do {
            // Encode to JSON
            let encoded = try JSONEncoder().encode(state)
            
            // Save to UserDefaults with unique key
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            print("❌ Failed to save timer state for pet \(petID): \(error.localizedDescription)")
            #endif
            // Remove corrupted data
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    /// Restores timer state from UserDefaults on app launch
    /// Handles completed timers and calculates remaining time
    private func restoreTimerState() {
        // Load data from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            // Decode timer state
            let state = try JSONDecoder().decode(TimerState.self, from: data)
            
            // Validate petID matches
            guard state.petID == self.petID else {
                #if DEBUG
                print("❌ Timer state petID mismatch: expected \(petID), got \(state.petID)")
                #endif
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                return
            }
            
            let now = Date()
            
            // Check if timer completed while app was closed
            if now >= state.endTime {
                #if DEBUG
                print("✅ Timer completed while app was closed: \(state.timerType.displayName)")
                #endif
                handleTimerCompletion()
                return
            }
            
            // Timer still running - restore state
            self.endTime = state.endTime
            self.timerType = state.timerType
            self.isActive = true
            self.timeRemaining = state.endTime.timeIntervalSince(now)
            
            // Resume UI updates
            startUIUpdates()
            
        } catch {
            #if DEBUG
            print("❌ Corrupted timer data for pet \(petID): \(error.localizedDescription)")
            #endif
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    /// Clears all timer state and cancels updates
    private func clearTimerState() {
        // Cancel timer updates
        timerCancellable?.cancel()
        timerCancellable = nil
        
        // Reset state
        self.isActive = false
        self.timeRemaining = 0
        self.endTime = nil
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Methods: UI Updates
    
    /// Starts the UI update loop that fires every second
    /// Uses Combine Timer.publish for reactive updates
    private func startUIUpdates() {
        // Cancel any existing timer
        timerCancellable?.cancel()
        
        // Timer updates every second for smooth countdown when active
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                guard let endTime = self.endTime else {
                    #if DEBUG
                    print("❌ No endTime available for pet \(self.petID)")
                    #endif
                    self.clearTimerState()
                    return
                }
                
                // Calculate time remaining
                let remaining = endTime.timeIntervalSinceNow
                
                // Update published properties on main thread
                self.timeRemaining = max(0, remaining)
                
                // Debug logging disabled for performance
                
                // Check for completion
                if remaining <= 0 {
                    self.handleTimerCompletion()
                }
            }
    }
    
    /// Handles timer completion - posts notification and clears state
    private func handleTimerCompletion() {
        // Clear timer state first
        clearTimerState()
        
        // Post notification for ViewModel to handle
        // Include petID so ViewModel can identify which timer completed
        NotificationCenter.default.post(
            name: .timerCompleted,
            object: petID,
            userInfo: ["timerType": timerType.rawValue]
        )
    }
    
    // MARK: - Private Methods: App Lifecycle
    
    /// Observes app lifecycle events for background persistence
    /// Ensures timer state is saved when app backgrounds
    private func observeAppLifecycle() {
        // Observe when app is about to background
        lifecycleObserver = NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Save state when backgrounding
                if self.isActive {
                    self.saveTimerState()
                }
            }
    }
}

// MARK: - Notification Names

/// Extension to define custom notification names
extension Notification.Name {
    /// Posted when a timer completes
    /// Object contains the petID (UUID) of the completed timer
    static let timerCompleted = Notification.Name("timerCompleted")
    
    /// Posted when a pet's state is updated (cycle started, completed, etc.)
    /// Object contains the petID (UUID) of the updated pet
    static let petStateUpdated = Notification.Name("petStateUpdated")
}

