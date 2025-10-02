//
//  Pet.swift
//  LaundryPets
//
//  SwiftData model representing a virtual pet with independent state and health
//

import Foundation
import SwiftData

@Model
final class Pet {
    // MARK: - Identity
    
    /// Unique identifier (primary key)
    var id: UUID
    
    /// User-defined pet name
    /// Constraints: Cannot be empty, typically 1-30 characters
    var name: String
    
    /// Timestamp when pet was created
    /// Used for sorting and analytics
    var createdDate: Date
    
    // MARK: - State
    
    /// Current emotional state of the pet
    /// Determines UI presentation (animation, color, text)
    var currentState: PetState
    
    /// Last time a laundry cycle was completed
    /// nil = never completed laundry
    /// Used for health decay calculation
    var lastLaundryDate: Date?
    
    /// Whether pet is active in the system
    /// Soft delete: isActive = false instead of hard delete
    var isActive: Bool
    
    // MARK: - Health System
    
    /// Current health level (0-100)
    /// 100 = perfectly healthy (recent laundry)
    /// 0 = dead (too long without laundry)
    /// nil = not yet initialized
    /// Decreases over time based on cycleFrequencyDays
    var health: Int?
    
    /// Last time health was recalculated
    /// Used to prevent redundant calculations
    var lastHealthUpdate: Date?
    
    // MARK: - Customization
    
    /// Custom icon identifier for the pet
    /// Optional string identifier for pet avatar/icon selection
    var customIcon: String?
    
    // MARK: - Laundry Cycle Settings
    
    /// How often this pet needs laundry (in days)
    /// Minimum: 1 day
    /// Maximum: 30 days
    /// Default: 7 days (weekly laundry)
    /// Affects health decay rate
    var cycleFrequencyDays: Int
    
    /// When the current laundry cycle started
    /// nil = no active cycle
    /// Used to track time elapsed in current cycle
    var currentCycleStartDate: Date?
    
    // MARK: - Initialization
    
    /// Creates a new pet with required and optional parameters
    /// - Parameters:
    ///   - name: Pet's name (must not be empty)
    ///   - cycleFrequencyDays: How often pet needs laundry in days (1-30, default 7)
    init(name: String, cycleFrequencyDays: Int = 7) {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmedName.isEmpty, "Pet name cannot be empty")
        
        // Validate cycle frequency
        precondition((1...30).contains(cycleFrequencyDays), 
                    "Cycle frequency must be between 1-30 days")
        
        // Automatic properties
        self.id = UUID()
        self.createdDate = Date()
        self.isActive = true
        self.currentState = .happy
        
        // Required properties
        self.name = trimmedName
        self.cycleFrequencyDays = cycleFrequencyDays
        
        // Optional properties (initialized as nil)
        self.lastLaundryDate = nil
        self.health = nil
        self.lastHealthUpdate = nil
        self.customIcon = nil
        self.currentCycleStartDate = nil
    }
    
    // MARK: - Validation
    
    /// Validates the pet's current state
    /// - Returns: true if all properties are valid
    func validate() -> Bool {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Validate cycle frequency
        guard (1...30).contains(cycleFrequencyDays) else {
            return false
        }
        
        // Validate health if present
        if let health = health {
            guard (0...100).contains(health) else {
                return false
            }
        }
        
        return true
    }
    
    /// Updates health value with validation
    /// - Parameter newHealth: New health value (will be clamped to 0-100)
    func updateHealth(_ newHealth: Int) {
        self.health = max(0, min(100, newHealth))
        self.lastHealthUpdate = Date()
    }
}

