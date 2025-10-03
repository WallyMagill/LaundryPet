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
    
    // MARK: - Statistics
    
    /// Total laundry cycles completed (lifetime)
    /// Incremented when user taps "Mark Folded"
    /// Never decreases (even if streak broken)
    var totalCyclesCompleted: Int
    
    /// Current consecutive streak
    /// Incremented on completion if cycle finished on time
    /// Reset to 0 if pet dies or cycle abandoned
    var currentStreak: Int
    
    /// Longest streak ever achieved
    /// High score for user motivation
    /// Only increases, never decreases
    var longestStreak: Int
    
    // MARK: - Per-Pet Settings (INDEPENDENT!)
    
    /// How often this pet needs laundry (in days)
    /// Minimum: 1 day
    /// Maximum: 30 days
    /// Default: 7 days (weekly laundry)
    /// Affects health decay rate
    var cycleFrequencyDays: Int
    
    /// Wash timer duration (in minutes)
    /// Default: 45 minutes (typical washing machine)
    /// Range: 1-120 minutes
    /// INDEPENDENT per pet (not global setting!)
    var washDurationMinutes: Int
    
    /// Dry timer duration (in minutes)
    /// Default: 60 minutes (typical dryer)
    /// Range: 1-180 minutes
    /// INDEPENDENT per pet (not global setting!)
    var dryDurationMinutes: Int
    
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
        self.currentState = .happy
        
        // Required properties
        self.name = trimmedName
        self.cycleFrequencyDays = cycleFrequencyDays
        
        // Statistics (start at zero)
        self.totalCyclesCompleted = 0
        self.currentStreak = 0
        self.longestStreak = 0
        
        // Per-Pet Timer Settings (defaults per spec)
        self.washDurationMinutes = 45  // 45 minutes (typical wash cycle)
        self.dryDurationMinutes = 60   // 60 minutes (typical dry cycle)
        
        // Optional properties (initialized as nil)
        self.lastLaundryDate = nil
        self.health = nil
        self.lastHealthUpdate = nil
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
        
        // Validate timer durations
        guard (1...120).contains(washDurationMinutes) else {
            return false
        }
        
        guard (1...180).contains(dryDurationMinutes) else {
            return false
        }
        
        // Validate statistics (should never be negative)
        guard totalCyclesCompleted >= 0,
              currentStreak >= 0,
              longestStreak >= 0 else {
            return false
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

