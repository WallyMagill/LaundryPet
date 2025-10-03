//
//  PetsViewModel.swift
//  LaundryPets
//
//  ViewModel for managing collection of pets with SwiftData integration
//  Handles pet CRUD operations, error states, and UI updates
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel responsible for managing the collection of pets
/// Provides reactive UI updates and handles all pet-related database operations
@MainActor
final class PetsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of all pets for UI observation
    /// Automatically triggers SwiftUI view updates when modified
    @Published var pets: [Pet] = []
    
    /// User-friendly error message for display in alerts
    /// nil when no error, contains descriptive message when error occurs
    @Published var errorMessage: String? = nil
    
    /// Controls whether error alert is shown
    /// Set to true when errorMessage is set, triggers alert presentation
    @Published var showError: Bool = false
    
    // MARK: - Private Properties
    
    /// SwiftData model context for database operations
    /// Injected via initializer for testability and dependency injection
    private let modelContext: ModelContext
    
    /// Service layer for pet business logic and CRUD operations
    /// Handles all database interactions with proper error handling
    private let petService: PetService
    
    // MARK: - Initialization
    
    /// Creates a new PetsViewModel with the provided model context
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Create pet service with the provided context
        self.petService = PetService(modelContext: modelContext)
        
        // Load pets immediately on initialization
        loadPets()
    }
    
    // MARK: - Public Methods
    
    /// Loads all pets from the database
    /// Fetches pets sorted by creation date and updates the @Published pets array
    /// Wraps database operations in do-catch for error handling
    func loadPets() {
        do {
            // Fetch all pets sorted by creation date (oldest first)
            let descriptor = FetchDescriptor<Pet>(
                sortBy: [SortDescriptor(\.createdDate, order: .forward)]
            )
            
            let fetchedPets = try modelContext.fetch(descriptor)
            
            // Update published property on main thread
            self.pets = fetchedPets
            
            print("✅ Loaded \(fetchedPets.count) pets")
            
        } catch {
            // Log error for debugging
            print("❌ Operation failed: \(error)")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to load pets. Please restart the app."
            
            // Trigger error alert
            self.showError = true
            
            // Fallback to empty array (graceful degradation)
            self.pets = []
        }
    }
    
    /// Creates a new pet and adds it to the collection
    /// - Parameters:
    ///   - name: The name for the new pet
    ///   - cycleFrequencyDays: How often the pet needs laundry (default: 7 days)
    /// - Returns: The newly created pet, or nil if creation failed
    func createPet(name: String, cycleFrequencyDays: Int = 7) -> Pet? {
        // Use pet service to create the pet
        guard let newPet = petService.createPet(name: name, cycleFrequencyDays: cycleFrequencyDays) else {
            // Pet creation failed - service already logged the error
            print("❌ Operation failed: Pet creation returned nil")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to create pet. Please try again."
            
            // Trigger error alert
            self.showError = true
            
            return nil
        }
        
        // Pet created successfully, reload the pets list
        loadPets()
        
        // Return the created pet for immediate use
        return newPet
    }
    
    /// Deletes a pet and removes it from the collection
    /// - Parameter pet: The pet to delete
    func deletePet(_ pet: Pet) {
        // Use pet service to delete the pet
        guard petService.deletePet(pet) else {
            // Pet deletion failed - service already logged the error
            print("❌ Operation failed: Pet deletion returned false")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to delete pet. Please try again."
            
            // Trigger error alert
            self.showError = true
            
            return
        }
        
        // Pet deleted successfully, reload the pets list
        loadPets()
    }
    
    /// Public wrapper for loadPets() to support pull-to-refresh
    /// Provides a clean interface for UI refresh operations
    func refreshPets() {
        loadPets()
    }
    
    /// Fetches a single pet by its unique identifier
    /// - Parameter id: The UUID of the pet to fetch
    /// - Returns: The Pet instance if found, nil if not found or error occurred
    func fetchPet(by id: UUID) -> Pet? {
        return petService.fetchPet(by: id)
    }
    
    /// Updates a pet's name
    /// - Parameters:
    ///   - pet: The pet whose name to update
    ///   - newName: The new name for the pet
    /// - Returns: true if update succeeded, false if failed
    @discardableResult
    func updatePetName(_ pet: Pet, newName: String) -> Bool {
        let success = petService.updatePetName(pet, newName: newName)
        
        if success {
            // Refresh the pets list to show updated name
            loadPets()
        } else {
            // Set error message
            self.errorMessage = "Unable to update pet name. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    /// Updates a pet's settings (cycle frequency, wash duration, dry duration)
    /// - Parameters:
    ///   - pet: The pet whose settings to update
    ///   - cycleFrequencyDays: New cycle frequency (nil to keep current)
    ///   - washDurationMinutes: New wash duration (nil to keep current)
    ///   - dryDurationMinutes: New dry duration (nil to keep current)
    /// - Returns: true if update succeeded, false if failed
    @discardableResult
    func updatePetSettings(_ pet: Pet, 
                          cycleFrequencyDays: Int? = nil,
                          washDurationMinutes: Int? = nil,
                          dryDurationMinutes: Int? = nil) -> Bool {
        let success = petService.updatePetSettings(
            pet,
            cycleFrequencyDays: cycleFrequencyDays,
            washDurationMinutes: washDurationMinutes,
            dryDurationMinutes: dryDurationMinutes
        )
        
        if success {
            // Refresh the pets list to show updated settings
            loadPets()
        } else {
            // Set error message
            self.errorMessage = "Unable to update pet settings. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    /// Resets a pet's statistics to zero (keeps pet but clears progress)
    /// - Parameter pet: The pet whose statistics to reset
    /// - Returns: true if reset succeeded, false if failed
    @discardableResult
    func resetPetStatistics(_ pet: Pet) -> Bool {
        let success = petService.resetPetStatistics(pet)
        
        if success {
            // Refresh the pets list to show reset statistics
            loadPets()
        } else {
            // Set error message
            self.errorMessage = "Unable to reset pet statistics. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error state
    /// Called when user dismisses error alert
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
}
