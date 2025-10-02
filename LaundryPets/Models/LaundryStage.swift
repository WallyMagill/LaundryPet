//
//  LaundryStage.swift
//  LaundryPets
//
//  Laundry workflow stage enumeration
//  Defines the progression through a complete laundry cycle
//

import Foundation

/// Represents stages in the laundry workflow
/// Progression: cycle → washing → drying → completed → (new cycle)
enum LaundryStage: String, Codable, CaseIterable {
    /// Background cycle timer (time between laundries)
    /// This is the "waiting" state before laundry is needed
    /// User can start a new wash from this stage
    case cycle = "cycle"
    
    /// Wash timer active
    /// User has started washing, timer counting down
    /// User must wait for timer to complete
    case washing = "washing"
    
    /// Dry timer active
    /// User has moved clothes to dryer, timer counting down
    /// User must wait for timer to complete
    case drying = "drying"
    
    /// Cycle complete, ready to fold
    /// Timer finished, waiting for user to mark as folded
    /// User can complete the cycle
    case completed = "completed"
    
    // MARK: - Display Properties
    
    /// User-facing status text for current stage
    var displayText: String {
        switch self {
        case .cycle:
            return "Ready to start laundry"
        case .washing:
            return "Washing in progress..."
        case .drying:
            return "Drying in progress..."
        case .completed:
            return "Time to fold!"
        }
    }
    
    /// Action button text for current stage
    /// Shows what the user should do next
    var actionButtonText: String {
        switch self {
        case .cycle:
            return "Start Wash"
        case .washing:
            return "Washing..."
        case .drying:
            return "Move to Dryer"
        case .completed:
            return "Mark Folded"
        }
    }
    
    /// Whether action button should be enabled
    /// User can only take action during cycle and completed stages
    var isActionable: Bool {
        switch self {
        case .cycle:
            return true  // Can start wash
        case .washing:
            return false // Must wait for timer
        case .drying:
            return false // Must wait for timer
        case .completed:
            return true  // Can mark folded
        }
    }
}

