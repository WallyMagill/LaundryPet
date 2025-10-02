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
    
    /// Loads all active pets from the database
    /// Fetches pets sorted by creation date and updates the @Published pets array
    /// Wraps database operations in do-catch for error handling
    func loadPets() {
        do {
            // Fetch active pets sorted by creation date (oldest first)
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate { pet in
                    pet.isActive == true
                },
                sortBy: [SortDescriptor(\.createdDate, order: .forward)]
            )
            
            let fetchedPets = try modelContext.fetch(descriptor)
            
            // Update published property on main thread
            self.pets = fetchedPets
            
            print("✅ Loaded \(fetchedPets.count) active pets")
            
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
    func createPet(name: String, cycleFrequencyDays: Int = 7) {
        // Use pet service to create the pet
        guard petService.createPet(name: name, cycleFrequencyDays: cycleFrequencyDays) != nil else {
            // Pet creation failed - service already logged the error
            print("❌ Operation failed: Pet creation returned nil")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to create pet. Please try again."
            
            // Trigger error alert
            self.showError = true
            
            return
        }
        
        // Pet created successfully, reload the pets list
        loadPets()
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
    
    // MARK: - Error Handling
    
    /// Clears the current error state
    /// Called when user dismisses error alert
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
}
