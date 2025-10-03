//
//  LaundryStage.swift
//  LaundryPets
//
//  Laundry workflow stage enumeration
//  Defines the progression through a complete laundry cycle
//

import Foundation

/// Represents stages in the laundry workflow
/// Progression: cycle → washing → washComplete → drying → dryComplete → completed → (new cycle)
enum LaundryStage: String, Codable, CaseIterable {
    /// Background cycle timer (time between laundries)
    /// This is the "waiting" state before laundry is needed
    /// User can start a new wash from this stage
    case cycle = "cycle"
    
    /// Wash timer active
    /// User has started washing, timer counting down
    /// User must wait for timer to complete
    case washing = "washing"
    
    /// Wash timer completed, ready to start dryer
    /// User can now start the drying phase
    case washComplete = "washComplete"
    
    /// Dry timer active
    /// User has started drying, timer counting down
    /// User must wait for timer to complete
    case drying = "drying"
    
    /// Dry timer completed, ready to fold or dry more
    /// User can choose to fold or add more drying time
    case dryComplete = "dryComplete"
    
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
        case .washComplete:
            return "Wash complete! Ready to dry"
        case .drying:
            return "Drying in progress..."
        case .dryComplete:
            return "Dry complete! Choose next step"
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
        case .washComplete:
            return "Start Dryer"
        case .drying:
            return "Drying..."
        case .dryComplete:
            return "Fold" // Primary action
        case .completed:
            return "Mark Folded"
        }
    }
    
    /// Whether action button should be enabled
    /// User can take action during cycle, washComplete, dryComplete, and completed stages
    var isActionable: Bool {
        switch self {
        case .cycle:
            return true        // Can start wash
        case .washing:
            return false       // Must wait for timer
        case .washComplete:
            return true        // Can start dryer
        case .drying:
            return false       // Must wait for timer
        case .dryComplete:
            return true        // Can fold or dry more
        case .completed:
            return true        // Can mark folded
        }
    }
    
    /// Whether this stage should show two action buttons (Dry More + Fold)
    /// Only true for dryComplete stage
    var showsTwoButtons: Bool {
        return self == .dryComplete
    }
}

