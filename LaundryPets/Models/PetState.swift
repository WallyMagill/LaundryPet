//
//  PetState.swift
//  LaundryPets
//
//  Pet emotional and activity state enumeration
//

import Foundation

/// Defines all possible emotional and activity states for a pet
/// Determines UI presentation (animation, color, text)
enum PetState: String, Codable, CaseIterable {
    /// Pet is very happy (recent laundry completed)
    /// Health: 75-100%
    /// Color: Green
    case happy = "happy"
    
    /// Pet is content (laundry somewhat recent)
    /// Health: 50-74%
    /// Color: Blue
    case neutral = "neutral"
    
    /// Pet needs attention (laundry overdue)
    /// Health: 25-49%
    /// Color: Orange
    case sad = "sad"
    
    /// Pet is very neglected (critically needs laundry)
    /// Health: 1-24%
    /// Color: Red
    case verySad = "verySad"
    
    /// Pet has died from neglect
    /// Health: 0%
    /// Color: Gray
    /// Can be revived by completing laundry
    case dead = "dead"
    
    // MARK: - Display Properties
    
    /// User-facing text shown with pet
    var displayText: String {
        switch self {
        case .happy:
            return "is so happy!"
        case .neutral:
            return "is doing okay"
        case .sad:
            return "needs some laundry love"
        case .verySad:
            return "is very sad and neglected"
        case .dead:
            return "has died from neglect"
        }
    }
}

