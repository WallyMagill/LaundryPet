//
//  SimpleTimerType.swift
//  LaundryPets
//
//  Timer type enumeration for laundry cycle phases
//

import Foundation

/// Defines the type of laundry timer
/// Used to track which phase of the laundry process is active
enum SimpleTimerType: String, Codable, CaseIterable {
    /// Washing phase timer
    /// Tracks time in the washing machine
    case wash = "wash"
    
    /// Drying phase timer
    /// Tracks time in the dryer
    case dry = "dry"
    
    /// Full cycle timer
    /// Background timer between laundry sessions
    /// Tracks time until next laundry is needed based on cycleFrequencyDays
    case cycle = "cycle"
    
    // MARK: - Display Properties
    
    /// User-facing name for the timer type
    var displayName: String {
        switch self {
        case .wash:
            return "Wash"
        case .dry:
            return "Dry"
        case .cycle:
            return "Full Cycle"
        }
    }
    
    /// Default duration for this timer type in seconds
    /// These are typical durations for each phase
    var defaultDuration: TimeInterval {
        switch self {
        case .wash:
            return 45 * 60  // 45 minutes (typical washing machine cycle)
        case .dry:
            return 60 * 60  // 60 minutes (typical dryer cycle)
        case .cycle:
            return 105 * 60 // 105 minutes (wash + dry combined)
        }
    }
}

