//
//  PetService.swift
//  LaundryPets
//
//  Service layer for Pet CRUD operations and business logic
//  Handles all database interactions for Pet entities with comprehensive error handling
//

import Foundation
import SwiftData

/// Service responsible for Pet entity management and business logic
/// All operations are performed on the main actor for UI thread safety
@MainActor
final class PetService {
    // MARK: - Properties
    
    /// SwiftData model context for database operations
    /// Injected via initializer for testability and flexibility
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    /// Creates a new PetService with the provided model context
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Creates a new pet and saves it to the database
    /// - Parameters:
    ///   - name: The name for the new pet (will be trimmed)
    ///   - cycleFrequencyDays: How often the pet needs laundry (default: 7 days)
    /// - Returns: The created Pet instance, or nil if creation failed
    func createPet(name: String, cycleFrequencyDays: Int = 7) -> Pet? {
        do {
            // Create new pet (validation happens in Pet.init)
            let pet = Pet(name: name, cycleFrequencyDays: cycleFrequencyDays)
            
            // Insert into context
            modelContext.insert(pet)
            
            // Save to database
            try modelContext.save()
            
            print("✅ Pet created successfully: \(pet.name) (ID: \(pet.id))")
            return pet
            
        } catch {
            // Log error with details
            print("❌ Failed to create pet: \(error.localizedDescription)")
            
            // User-friendly error: "Unable to create pet. Please try again."
            return nil
        }
    }
    
    /// Saves changes to an existing pet in the database
    /// Use this after manually modifying pet properties
    /// - Parameter pet: The pet to save (must already exist in context)
    /// - Returns: true if save succeeded, false if validation failed or save error
    func savePet(_ pet: Pet) -> Bool {
        do {
            // Validate pet data before saving
            guard pet.validate() else {
                print("❌ Pet validation failed before save")
                return false
            }
            
            // Save changes to database
            try modelContext.save()
            
            print("✅ Pet saved successfully: \(pet.name)")
            return true
            
        } catch {
            print("❌ Failed to save pet: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Deletes a pet and all associated laundry tasks (cascade delete)
    /// - Parameter pet: The pet to delete
    /// - Returns: true if deletion succeeded, false if it failed
    func deletePet(_ pet: Pet) -> Bool {
        do {
            // Step 1: Find and delete all associated LaundryTasks
            // Capture the pet ID before using in predicate
            let petID = pet.id
            
            let taskDescriptor = FetchDescriptor<LaundryTask>(
                predicate: #Predicate { task in
                    task.petID == petID
                }
            )
            
            let tasks = try modelContext.fetch(taskDescriptor)
            
            // Delete each task
            for task in tasks {
                modelContext.delete(task)
            }
            
            print("✅ Deleted \(tasks.count) task(s) for pet: \(pet.name)")
            
            // Step 2: Delete the pet
            modelContext.delete(pet)
            
            // Step 3: Save changes
            try modelContext.save()
            
            print("✅ Pet deleted successfully: \(pet.name)")
            return true
            
        } catch {
            // Log error with details
            print("❌ Failed to delete pet: \(error.localizedDescription)")
            
            // User-friendly error: "Unable to delete pet. Please try again."
            return false
        }
    }
    
    /// Fetches all pets from the database
    /// - Returns: Array of all pets, sorted by creation date (oldest first)
    func fetchAllPets() -> [Pet] {
        do {
            let descriptor = FetchDescriptor<Pet>(
                sortBy: [SortDescriptor(\.createdDate, order: .forward)]
            )
            
            let pets = try modelContext.fetch(descriptor)
            
            print("✅ Fetched \(pets.count) pet(s) from database")
            return pets
            
        } catch {
            // Log error with details
            print("❌ Failed to fetch all pets: \(error.localizedDescription)")
            
            // User-friendly error: "Unable to load pets. Please restart the app."
            // Return empty array as fallback (graceful degradation)
            return []
        }
    }
    
    /// Fetches a single pet by its unique identifier
    /// - Parameter id: The UUID of the pet to fetch
    /// - Returns: The Pet instance if found, nil if not found or error occurred
    func fetchPet(by id: UUID) -> Pet? {
        do {
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate { pet in
                    pet.id == id
                }
            )
            
            let pets = try modelContext.fetch(descriptor)
            
            if let pet = pets.first {
                print("✅ Fetched pet: \(pet.name) (ID: \(pet.id))")
                return pet
            } else {
                print("⚠️ No pet found with ID: \(id)")
                return nil
            }
            
        } catch {
            print("❌ Failed to fetch pet by ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Pet Settings Update Methods
    
    /// Updates a pet's name with validation
    /// - Parameters:
    ///   - pet: The pet whose name to update
    ///   - newName: The new name (will be trimmed and validated)
    /// - Returns: true if update succeeded, false if validation failed or save error
    func updatePetName(_ pet: Pet, newName: String) -> Bool {
        // Validate and trim the new name
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            print("❌ Pet name cannot be empty")
            return false
        }
        
        do {
            // Update the pet's name
            pet.name = trimmedName
            
            // Validate the entire pet before saving
            guard pet.validate() else {
                print("❌ Pet validation failed after name update")
                return false
            }
            
            // Save to database
            try modelContext.save()
            
            print("✅ Pet name updated: \(trimmedName)")
            return true
            
        } catch {
            print("❌ Failed to update pet name: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates a pet's settings (cycle frequency, wash duration, dry duration)
    /// - Parameters:
    ///   - pet: The pet whose settings to update
    ///   - cycleFrequencyDays: New cycle frequency (nil to keep current)
    ///   - washDurationMinutes: New wash duration (nil to keep current)
    ///   - dryDurationMinutes: New dry duration (nil to keep current)
    /// - Returns: true if update succeeded, false if validation failed or save error
    func updatePetSettings(_ pet: Pet, 
                          cycleFrequencyDays: Int? = nil,
                          washDurationMinutes: Int? = nil,
                          dryDurationMinutes: Int? = nil) -> Bool {
        do {
            // Update cycle frequency if provided
            if let newFrequency = cycleFrequencyDays {
                guard (1...30).contains(newFrequency) else {
                    print("❌ Cycle frequency must be between 1-30 days")
                    return false
                }
                pet.cycleFrequencyDays = newFrequency
                print("✅ Updated cycle frequency: \(newFrequency) days")
            }
            
            // Update wash duration if provided
            if let newWashDuration = washDurationMinutes {
                guard (1...120).contains(newWashDuration) else {
                    print("❌ Wash duration must be between 1-120 minutes")
                    return false
                }
                pet.washDurationMinutes = newWashDuration
                print("✅ Updated wash duration: \(newWashDuration) minutes")
            }
            
            // Update dry duration if provided
            if let newDryDuration = dryDurationMinutes {
                guard (1...180).contains(newDryDuration) else {
                    print("❌ Dry duration must be between 1-180 minutes")
                    return false
                }
                pet.dryDurationMinutes = newDryDuration
                print("✅ Updated dry duration: \(newDryDuration) minutes")
            }
            
            // Validate the entire pet before saving
            guard pet.validate() else {
                print("❌ Pet validation failed after settings update")
                return false
            }
            
            // Save to database
            try modelContext.save()
            
            print("✅ Pet settings updated for: \(pet.name)")
            return true
            
        } catch {
            print("❌ Failed to update pet settings: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Resets a pet's statistics to zero (keeps pet but clears progress)
    /// - Parameter pet: The pet whose statistics to reset
    /// - Returns: true if reset succeeded, false if save error
    func resetPetStatistics(_ pet: Pet) -> Bool {
        do {
            // Reset all statistics to zero
            pet.totalCyclesCompleted = 0
            pet.currentStreak = 0
            pet.longestStreak = 0
            
            // Reset health and state to initial values
            pet.health = nil
            pet.lastHealthUpdate = nil
            pet.lastLaundryDate = nil
            pet.currentState = .happy
            
            // Save to database
            try modelContext.save()
            
            print("✅ Statistics reset for pet: \(pet.name)")
            return true
            
        } catch {
            print("❌ Failed to reset pet statistics: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Business Logic Methods
    
    /// Updates a pet's health with validation and saves to database
    /// - Parameters:
    ///   - pet: The pet whose health to update
    ///   - newHealth: The new health value (will be clamped to 0-100)
    /// - Returns: true if update succeeded, false if save error
    func updatePetHealth(_ pet: Pet, newHealth: Int) -> Bool {
        // Clamp health to valid range (0-100)
        let clampedHealth = max(0, min(100, newHealth))
        
        do {
            // Update pet's health
            pet.health = clampedHealth
            pet.lastHealthUpdate = Date()
            
            // Update pet state based on health if needed
            let newState = evaluatePetState(health: clampedHealth)
            if pet.currentState != newState {
                pet.currentState = newState
                print("✅ Pet state changed to \(newState.rawValue) based on health")
            }
            
            // Save to database
            try modelContext.save()
            print("✅ Pet health updated: \(pet.name) -> \(clampedHealth)%")
            return true
            
        } catch {
            print("❌ Failed to save pet health: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates a pet's current state and saves to database
    /// - Parameters:
    ///   - pet: The pet whose state to update
    ///   - newState: The new state for the pet
    /// - Returns: true if update succeeded, false if save error
    func updatePetState(_ pet: Pet, to newState: PetState) -> Bool {
        do {
            // Update pet's state
            pet.currentState = newState
            
            // Save to database
            try modelContext.save()
            print("✅ Pet state updated: \(pet.name) -> \(newState.rawValue)")
            return true
            
        } catch {
            print("❌ Failed to save pet state: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Completes a laundry cycle for the pet, restoring health and updating state
    /// - Parameter pet: The pet who completed a laundry cycle
    /// - Returns: true if completion succeeded, false if save error
    func completeCycle(for pet: Pet) -> Bool {
        do {
            // Update last laundry date
            pet.lastLaundryDate = Date()
            
            // Reset health to 100%
            pet.health = 100
            pet.lastHealthUpdate = Date()
            
            // Set state to happy
            pet.currentState = .happy
            
            // Update statistics
            updateCycleStatistics(for: pet)
            
            // Save to database
            try modelContext.save()
            print("✅ Cycle completed for pet: \(pet.name)")
            return true
            
        } catch {
            print("❌ Failed to save cycle completion: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates cycle completion statistics for a pet
    /// Increments total cycles, manages streaks
    /// - Parameter pet: The pet whose statistics to update
    func updateCycleStatistics(for pet: Pet) {
        // Increment total cycles completed
        pet.totalCyclesCompleted += 1
        
        // Increment current streak
        pet.currentStreak += 1
        
        // Update longest streak if current streak is longer
        if pet.currentStreak > pet.longestStreak {
            pet.longestStreak = pet.currentStreak
        }
        
        print("✅ Statistics updated for \(pet.name): Total: \(pet.totalCyclesCompleted), Streak: \(pet.currentStreak)/\(pet.longestStreak)")
    }
    
    // MARK: - Helper Methods
    
    /// Evaluates what state a pet should be in based on health
    /// - Parameter health: The pet's current health (0-100)
    /// - Returns: The appropriate PetState for that health level
    private func evaluatePetState(health: Int) -> PetState {
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
            // Should never happen due to clamping, but safe fallback
            return .neutral
        }
    }
}

