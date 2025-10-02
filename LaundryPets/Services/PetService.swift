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
    
    /// Updates an existing pet in the database
    /// - Parameter pet: The pet to update (must already exist in context)
    /// - Returns: true if save succeeded, false if it failed
    func updatePet(_ pet: Pet) -> Bool {
        do {
            // Validate pet data before saving
            guard pet.validate() else {
                print("❌ Pet validation failed before update")
                // User-friendly error: "Invalid pet data"
                return false
            }
            
            // Save changes to database
            try modelContext.save()
            
            print("✅ Pet updated successfully: \(pet.name)")
            return true
            
        } catch {
            // Log error with details
            print("❌ Failed to update pet: \(error.localizedDescription)")
            
            // User-friendly error: "Unable to save changes. Please try again."
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
    
    /// Fetches only active pets from the database
    /// - Returns: Array of active pets, sorted by creation date (oldest first)
    func fetchActivePets() -> [Pet] {
        do {
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate { pet in
                    pet.isActive == true
                },
                sortBy: [SortDescriptor(\.createdDate, order: .forward)]
            )
            
            let pets = try modelContext.fetch(descriptor)
            
            print("✅ Fetched \(pets.count) active pet(s) from database")
            return pets
            
        } catch {
            // Log error with details
            print("❌ Failed to fetch active pets: \(error.localizedDescription)")
            
            // User-friendly error: "Unable to load pets. Please restart the app."
            // Return empty array as fallback (graceful degradation)
            return []
        }
    }
    
    // MARK: - Business Logic Methods
    
    /// Updates a pet's health with validation and saves to database
    /// - Parameters:
    ///   - pet: The pet whose health to update
    ///   - newHealth: The new health value (will be clamped to 0-100)
    func updatePetHealth(_ pet: Pet, newHealth: Int) {
        // Clamp health to valid range (0-100)
        let clampedHealth = max(0, min(100, newHealth))
        
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
        do {
            try modelContext.save()
            print("✅ Pet health updated: \(pet.name) -> \(clampedHealth)%")
        } catch {
            print("❌ Failed to save pet health: \(error.localizedDescription)")
            // User-friendly error: "Unable to save health update"
        }
    }
    
    /// Updates a pet's current state and saves to database
    /// - Parameters:
    ///   - pet: The pet whose state to update
    ///   - newState: The new state for the pet
    func updatePetState(_ pet: Pet, to newState: PetState) {
        // Update pet's state
        pet.currentState = newState
        
        // Save to database
        do {
            try modelContext.save()
            print("✅ Pet state updated: \(pet.name) -> \(newState.rawValue)")
        } catch {
            print("❌ Failed to save pet state: \(error.localizedDescription)")
            // User-friendly error: "Unable to save state change"
        }
    }
    
    /// Completes a laundry cycle for the pet, restoring health and updating state
    /// - Parameter pet: The pet who completed a laundry cycle
    func completeCycle(for pet: Pet) {
        // Update last laundry date
        pet.lastLaundryDate = Date()
        
        // Reset health to 100%
        pet.health = 100
        pet.lastHealthUpdate = Date()
        
        // Set state to happy
        pet.currentState = .happy
        
        // Save to database
        do {
            try modelContext.save()
            print("✅ Cycle completed for pet: \(pet.name)")
        } catch {
            print("❌ Failed to save cycle completion: \(error.localizedDescription)")
            // User-friendly error: "Unable to save cycle completion"
        }
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

