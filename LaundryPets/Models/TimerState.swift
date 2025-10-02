//
//  TimerState.swift
//  LaundryPets
//
//  Codable struct for persisting timer state to UserDefaults
//
//  ⚠️ CRITICAL DESIGN PATTERN: ABSOLUTE TIME
//
//  This struct uses ABSOLUTE TIME (endTime: Date) rather than relative counting.
//  This is essential because:
//  - The app may be backgrounded, force quit, or device restarted
//  - When restored, we calculate remaining time as: endTime.timeIntervalSinceNow
//  - This ensures timers are always accurate regardless of app state
//  - iOS handles the notification scheduling independently using this same endTime
//
//  Example: User starts a 45-minute wash timer at 2:00 PM
//
//  ❌ BAD APPROACH (Relative Counting):
//     Store: remainingSeconds = 2700 (45 minutes)
//     Problem: If app closes at 2:20 PM and reopens at 2:50 PM:
//              - We still have 2700 stored
//              - We don't know how much time actually passed
//              - Timer is completely inaccurate
//
//  ✅ GOOD APPROACH (Absolute Time):
//     Store: endTime = Date(2:45 PM)
//     Benefit: If app closes at 2:20 PM and reopens at 2:50 PM:
//              - We calculate: endTime - now = 2:45 PM - 2:50 PM
//              - Result: Timer completed 5 minutes ago
//              - UI shows completion state correctly
//
//  This pattern ensures perfect accuracy across:
//  - App backgrounding
//  - Force quit
//  - Device restart
//  - System time changes
//  - Time zone changes
//

import Foundation

/// Represents the persisted state of a timer in UserDefaults
/// Stores the absolute end time rather than relative duration for accuracy
struct TimerState: Codable {
    // MARK: - Properties
    
    /// Unique identifier for the pet this timer belongs to
    /// Used to restore the correct timer when app relaunches
    let petID: UUID
    
    /// Absolute completion time of the timer
    /// CRITICAL: This is the foundation of reliable background timers
    /// Always compare this to Date() to get accurate remaining time
    let endTime: Date
    
    /// Type of timer (wash, dry, or cycle)
    /// Determines notification content and UI presentation
    let timerType: SimpleTimerType
    
    // MARK: - Initialization
    
    /// Creates a new timer state for persistence
    /// - Parameters:
    ///   - petID: UUID of the pet this timer belongs to
    ///   - endTime: Absolute time when timer should complete
    ///   - timerType: Type of timer being tracked
    init(petID: UUID, endTime: Date, timerType: SimpleTimerType) {
        self.petID = petID
        self.endTime = endTime
        self.timerType = timerType
    }
}

