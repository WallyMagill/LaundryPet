//
//  HealthUpdateService.swift
//  LaundryPets
//
//  Service for calculating pet health decay based on time since last laundry
//  Determines appropriate state changes based on health levels
//

import Foundation

/// Service responsible for health decay calculations and state evaluation
/// Singleton pattern for shared health calculation logic
final class HealthUpdateService {
    // MARK: - Singleton
    
    /// Shared instance for health calculations
    static let shared = HealthUpdateService()
    
    private init() {}
    
    // MARK: - Health Calculation
    
    /// Calculates current health based on time since last laundry
    /// - Parameter pet: The pet whose health to calculate
    /// - Returns: Calculated health value (0-100)
    func calculateCurrentHealth(for pet: Pet) -> Int {
        // If no lastLaundryDate, use createdDate as baseline
        let referenceDate = pet.lastLaundryDate ?? pet.createdDate
        
        // Calculate time elapsed since last laundry
        let timeElapsed = Date().timeIntervalSince(referenceDate)
        let hoursElapsed = timeElapsed / 3600
        let daysElapsed = hoursElapsed / 24
        
        print("🔍 Health calculation for \(pet.name):")
        print("   Reference date: \(referenceDate)")
        print("   Days elapsed: \(String(format: "%.2f", daysElapsed))")
        print("   Cycle frequency: \(pet.cycleFrequencyDays) days")
        
        // If cycleFrequencyDays is 0, use testing mode (5 minutes = full decay)
        if pet.cycleFrequencyDays == 0 {
            let testingMinutes = timeElapsed / 60
            let decayPercentage = (testingMinutes / 5.0) * 100
            let health = max(0, 100 - Int(decayPercentage))
            print("   Testing mode: \(String(format: "%.2f", testingMinutes)) min elapsed -> \(health)% health")
            return health
        }
        
        // Calculate health decay
        // Health decreases proportionally to time elapsed vs cycle frequency
        let decayPercentage = (daysElapsed / Double(pet.cycleFrequencyDays)) * 100
        let calculatedHealth = max(0, 100 - Int(decayPercentage))
        
        print("   Decay percentage: \(String(format: "%.2f", decayPercentage))%")
        print("   Calculated health: \(calculatedHealth)%")
        
        return calculatedHealth
    }
    
    /// Evaluates what state a pet should be in based on health
    /// - Parameter health: The pet's current health (0-100)
    /// - Returns: The appropriate PetState for that health level
    func evaluateState(fromHealth health: Int) -> PetState {
        switch health {
        case 75...100:
            return .happy
        case 50..<75:
            return .neutral
        case 25..<50:
            return .sad
        case 1..<25:
            return .verySad
        case 0:
            return .dead
        default:
            // Should never happen, but safe fallback
            return .neutral
        }
    }
    
    /// Updates a pet's health based on time elapsed and returns the new state
    /// - Parameter pet: The pet to update
    /// - Returns: Tuple of (newHealth, newState)
    func updateHealthAndState(for pet: Pet) -> (health: Int, state: PetState) {
        let newHealth = calculateCurrentHealth(for: pet)
        let newState = evaluateState(fromHealth: newHealth)
        
        print("✅ Health updated for \(pet.name): \(newHealth)% -> \(newState.rawValue)")
        
        return (newHealth, newState)
    }
}

