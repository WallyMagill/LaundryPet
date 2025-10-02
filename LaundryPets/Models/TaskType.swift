//
//  TaskType.swift
//  LaundryPets
//
//  Laundry task type enumeration
//

import Foundation

/// Defines the type of laundry task
/// Each type represents a different phase of the laundry process
enum TaskType: String, Codable, CaseIterable {
    /// Washing phase
    case wash = "wash"
    
    /// Drying phase
    case dry = "dry"
    
    /// Full laundry cycle (wash + dry)
    case cycle = "cycle"
    
    // MARK: - Display Properties
    
    /// User-facing label for the task type
    var displayText: String {
        switch self {
        case .wash:
            return "Wash"
        case .dry:
            return "Dry"
        case .cycle:
            return "Full Cycle"
        }
    }
}

