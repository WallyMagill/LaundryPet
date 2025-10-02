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
    
    /// Current timer type (wash, dry, or cycle)
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
    ///   - duration: Timer duration in seconds
    ///   - type: Type of timer (wash, dry, or cycle)
    func startTimer(duration: TimeInterval, type: SimpleTimerType) {
        // Prevent starting if already active
        guard !isActive else {
            print("⚠️ Timer already active for pet \(petID)")
            return
        }
        
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
        
        print("⏰ Timer started: \(duration)s for pet \(petID)")
    }
    
    /// Stops the current timer (user cancellation)
    func stopTimer() {
        // Only stop if active
        guard isActive else { return }
        
        // Clear all timer state
        clearTimerState()
        
        print("⏹️ Timer stopped for pet \(petID)")
    }
    
    /// Checks if the timer has completed
    /// - Returns: true if current time >= endTime
    func checkTimerStatus() -> Bool {
        guard let end = endTime else { return false }
        return Date() >= end
    }
    
    // MARK: - Private Methods: State Management
    
    /// Saves current timer state to UserDefaults for background persistence
    private func saveTimerState() {
        guard let end = endTime else {
            print("⚠️ Cannot save timer state: no endTime")
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
            
            print("💾 Timer state saved for pet \(petID)")
        } catch {
            print("❌ Failed to save timer state: \(error.localizedDescription)")
        }
    }
    
    /// Restores timer state from UserDefaults on app launch
    /// Handles completed timers and calculates remaining time
    private func restoreTimerState() {
        // Load data from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("⚠️ No saved timer state for pet \(petID)")
            return
        }
        
        do {
            // Decode timer state
            let state = try JSONDecoder().decode(TimerState.self, from: data)
            
            let now = Date()
            
            // Check if timer completed while app was closed
            if now >= state.endTime {
                print("✅ Timer completed while app was closed")
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
            
            print("✅ Timer restored for pet \(petID): \(timeRemaining)s remaining")
            
        } catch {
            print("❌ Corrupted timer data for pet \(petID): \(error.localizedDescription)")
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
        
        print("🗑️ Timer state cleared for pet \(petID)")
    }
    
    // MARK: - Private Methods: UI Updates
    
    /// Starts the UI update loop that fires every second
    /// Uses Combine Timer.publish for reactive updates
    private func startUIUpdates() {
        // Cancel any existing timer
        timerCancellable?.cancel()
        
        // Create timer that fires every 1 second
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                guard let endTime = self.endTime else {
                    print("❌ No endTime available")
                    self.clearTimerState()
                    return
                }
                
                // Calculate time remaining
                let remaining = endTime.timeIntervalSinceNow
                
                // CRITICAL FIX: Update on main thread with explicit objectWillChange
                Task { @MainActor in
                    self.objectWillChange.send() // Force SwiftUI to notice
                    self.timeRemaining = max(0, remaining)
                }
                
                print("⏱️ Timer tick - Remaining: \(Int(max(0, remaining)))s")
                
                // Check for completion
                if remaining <= 0 {
                    print("✅ Timer reached zero!")
                    Task { @MainActor in
                        self.handleTimerCompletion()
                    }
                }
            }
        
        print("🔄 UI updates started for pet \(petID)")
    }
    
    /// Handles timer completion - posts notification and clears state
    private func handleTimerCompletion() {
        print("✅ Timer completed for pet \(petID)!")
        
        // Clear timer state
        clearTimerState()
        
        // Post notification for ViewModel to handle
        // Include petID so ViewModel can identify which timer completed
        NotificationCenter.default.post(
            name: .timerCompleted,
            object: petID
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
                    print("📱 App backgrounding - timer state saved for pet \(self.petID)")
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
}

