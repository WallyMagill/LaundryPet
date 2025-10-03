//
//  PetSettingsViewModel.swift
//  LaundryPets
//
//  ViewModel for managing individual pet settings and configuration
//  Handles pet name updates, timer settings, statistics management, and UI updates
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel responsible for managing individual pet settings and configuration
/// Provides reactive UI updates and handles pet-specific operations
@MainActor
final class PetSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current pet being configured
    /// Immutable reference set at initialization
    let pet: Pet
    
    /// Current pet name for editing
    /// Bound to text fields in UI
    @Published var petName: String = ""
    
    /// Current cycle frequency for editing
    /// How often this pet needs laundry (in days)
    @Published var cycleFrequencyDays: Int = 7
    
    /// Current wash duration for editing
    /// How long the wash cycle takes (in minutes)
    @Published var washDurationMinutes: Int = 45
    
    /// Current dry duration for editing
    /// How long the dry cycle takes (in minutes)
    @Published var dryDurationMinutes: Int = 60
    
    /// Whether the pet settings have been modified
    /// Used to enable/disable save button
    @Published var hasUnsavedChanges: Bool = false
    
    /// User-friendly error message for display in alerts
    /// nil when no error, contains descriptive message when error occurs
    @Published var errorMessage: String? = nil
    
    /// Controls whether error alert is shown
    /// Set to true when errorMessage is set, triggers alert presentation
    @Published var showError: Bool = false
    
    /// Controls whether reset statistics confirmation dialog is shown
    @Published var showResetConfirmation: Bool = false
    
    /// Controls whether delete pet confirmation dialog is shown
    @Published var showDeleteConfirmation: Bool = false
    
    /// Controls whether edit name dialog is shown
    @Published var showEditName: Bool = false
    
    /// New pet name for editing
    @Published var newPetName: String = ""
    
    // MARK: - Private Properties
    
    /// SwiftData model context for database operations
    /// Injected via initializer for testability and dependency injection
    private let modelContext: ModelContext
    
    /// Service for pet business logic and CRUD operations
    private let petService: PetService
    
    /// Original values for comparison (detecting changes)
    private let originalName: String
    private let originalCycleFrequency: Int
    private let originalWashDuration: Int
    private let originalDryDuration: Int
    
    // MARK: - Initialization
    
    /// Creates a new PetSettingsViewModel for a specific pet
    /// - Parameters:
    ///   - pet: The pet whose settings will be managed
    ///   - modelContext: SwiftData context for database operations
    init(pet: Pet, modelContext: ModelContext) {
        self.pet = pet
        self.modelContext = modelContext
        
        // Create pet service with the provided context
        self.petService = PetService(modelContext: modelContext)
        
        // Store original values for change detection
        self.originalName = pet.name
        self.originalCycleFrequency = pet.cycleFrequencyDays
        self.originalWashDuration = pet.washDurationMinutes
        self.originalDryDuration = pet.dryDurationMinutes
        
        // Initialize published properties with current pet values
        self.petName = pet.name
        self.cycleFrequencyDays = pet.cycleFrequencyDays
        self.washDurationMinutes = pet.washDurationMinutes
        self.dryDurationMinutes = pet.dryDurationMinutes
        self.newPetName = pet.name
        
        // Setup change detection
        setupChangeDetection()
    }
    
    // MARK: - Setup Methods
    
    /// Sets up change detection to monitor for unsaved changes
    /// Updates hasUnsavedChanges when any property is modified
    private func setupChangeDetection() {
        // Monitor changes to detect if settings have been modified
        // This will be called whenever any published property changes
        DispatchQueue.main.async { [weak self] in
            self?.updateUnsavedChangesState()
        }
    }
    
    /// Updates the unsaved changes state by comparing current vs original values
    private func updateUnsavedChangesState() {
        let nameChanged = petName != originalName
        let frequencyChanged = cycleFrequencyDays != originalCycleFrequency
        let washDurationChanged = washDurationMinutes != originalWashDuration
        let dryDurationChanged = dryDurationMinutes != originalDryDuration
        
        hasUnsavedChanges = nameChanged || frequencyChanged || washDurationChanged || dryDurationChanged
    }
    
    // MARK: - Public Methods
    
    /// Updates the cycle frequency setting
    /// - Parameter newValue: The new cycle frequency in days
    func updateCycleFrequency(_ newValue: Int) {
        do {
            pet.cycleFrequencyDays = newValue
            try modelContext.save()
            self.cycleFrequencyDays = newValue
        } catch {
            #if DEBUG
            print("❌ Failed to update cycle frequency: \(error)")
            #endif
            errorMessage = "Failed to update cycle frequency. Please try again."
            showError = true
            // Revert the picker selection
            self.cycleFrequencyDays = pet.cycleFrequencyDays
        }
    }
    
    /// Updates the wash duration setting
    /// - Parameter newValue: The new wash duration in minutes
    func updateWashDuration(_ newValue: Int) {
        do {
            pet.washDurationMinutes = newValue
            try modelContext.save()
            self.washDurationMinutes = newValue
        } catch {
            #if DEBUG
            print("❌ Failed to update wash duration: \(error)")
            #endif
            errorMessage = "Failed to update wash duration. Please try again."
            showError = true
            // Revert the picker selection
            self.washDurationMinutes = pet.washDurationMinutes
        }
    }
    
    /// Updates the dry duration setting
    /// - Parameter newValue: The new dry duration in minutes
    func updateDryDuration(_ newValue: Int) {
        do {
            pet.dryDurationMinutes = newValue
            try modelContext.save()
            self.dryDurationMinutes = newValue
        } catch {
            #if DEBUG
            print("❌ Failed to update dry duration: \(error)")
            #endif
            errorMessage = "Failed to update dry duration. Please try again."
            showError = true
            // Revert the picker selection
            self.dryDurationMinutes = pet.dryDurationMinutes
        }
    }
    
    /// Updates the pet's name
    /// - Parameter newName: The new name for the pet
    /// - Returns: true if update succeeded, false if failed
    @discardableResult
    func updatePetName(_ newName: String) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count >= 1, trimmedName.count <= 50 else {
            errorMessage = "Pet name must be between 1 and 50 characters."
            showError = true
            return false
        }
        
        let success = petService.updatePetName(pet, newName: trimmedName)
        
        if success {
            self.petName = trimmedName
            self.newPetName = trimmedName
            showEditName = false
        } else {
            errorMessage = "Unable to update pet name. Please try again."
            showError = true
        }
        
        return success
    }
    
    /// Resets the pet's statistics to zero
    /// Shows confirmation dialog before proceeding
    func resetStatistics() {
        showResetConfirmation = true
    }
    
    /// Confirms and executes statistics reset
    /// - Returns: true if reset succeeded, false if failed
    @discardableResult
    func confirmResetStatistics() -> Bool {
        do {
            pet.totalCyclesCompleted = 0
            pet.currentStreak = 0
            pet.longestStreak = 0
            pet.lastLaundryDate = nil
            
            // Reset health to default
            pet.health = 100
            pet.currentState = .happy
            
            try modelContext.save()
            
            showResetConfirmation = false
            return true
            
        } catch {
            #if DEBUG
            print("❌ Failed to reset statistics: \(error)")
            #endif
            errorMessage = "Failed to reset statistics. Please try again."
            showError = true
            showResetConfirmation = false
            return false
        }
    }
    
    /// Cancels statistics reset
    func cancelResetStatistics() {
        showResetConfirmation = false
    }
    
    /// Shows delete confirmation dialog
    func requestDeleteConfirmation() {
        showDeleteConfirmation = true
    }
    
    /// Confirms and executes pet deletion
    /// - Parameter petsViewModel: The PetsViewModel to use for deletion
    /// - Returns: true if deletion succeeded, false if failed
    @discardableResult
    func confirmDeletePet(using petsViewModel: PetsViewModel) -> Bool {
        petsViewModel.deletePet(pet)
        showDeleteConfirmation = false
        return true
    }
    
    /// Cancels pet deletion
    func cancelDeletePet() {
        showDeleteConfirmation = false
    }
    
    /// Shows edit name dialog
    func showEditNameDialog() {
        newPetName = pet.name
        showEditName = true
    }
    
    /// Cancels edit name
    func cancelEditName() {
        newPetName = pet.name
        showEditName = false
    }
    
    // MARK: - Computed Properties
    
    /// Pet's current health percentage
    var currentHealth: Int {
        return pet.health ?? 100
    }
    
    /// Pet's current state
    var currentState: PetState {
        return pet.currentState
    }
    
    /// Pet's total cycles completed
    var totalCyclesCompleted: Int {
        return pet.totalCyclesCompleted
    }
    
    /// Pet's current streak
    var currentStreak: Int {
        return pet.currentStreak
    }
    
    /// Pet's longest streak
    var longestStreak: Int {
        return pet.longestStreak
    }
    
    /// Health color based on pet state
    var healthColor: Color {
        switch pet.currentState {
        case .happy:
            return .green
        case .neutral:
            return .blue
        case .sad:
            return .orange
        case .verySad:
            return .red
        case .dead:
            return .red
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error state
    /// Called when user dismisses error alert
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
}
