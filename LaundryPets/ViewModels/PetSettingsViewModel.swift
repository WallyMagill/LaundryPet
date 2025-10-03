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
    
    /// Controls whether save confirmation dialog is shown
    @Published var showSaveConfirmation: Bool = false
    
    /// Controls whether reset statistics confirmation dialog is shown
    @Published var showResetConfirmation: Bool = false
    
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
        
        // Setup change detection
        setupChangeDetection()
        
        print("✅ PetSettingsViewModel initialized for: \(pet.name)")
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
        
        if hasUnsavedChanges {
            print("📝 Unsaved changes detected for \(pet.name)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Saves all current settings to the database
    /// - Returns: true if save succeeded, false if failed
    @discardableResult
    func saveSettings() -> Bool {
        // Validate inputs first
        guard validateInputs() else {
            return false
        }
        
        var saveSuccess = true
        
        // Update pet name if changed
        if petName != originalName {
            let nameSuccess = petService.updatePetName(pet, newName: petName)
            if !nameSuccess {
                saveSuccess = false
            }
        }
        
        // Update timer settings if changed
        let settingsChanged = cycleFrequencyDays != originalCycleFrequency ||
                            washDurationMinutes != originalWashDuration ||
                            dryDurationMinutes != originalDryDuration
        
        if settingsChanged {
            let settingsSuccess = petService.updatePetSettings(
                pet,
                cycleFrequencyDays: cycleFrequencyDays,
                washDurationMinutes: washDurationMinutes,
                dryDurationMinutes: dryDurationMinutes
            )
            if !settingsSuccess {
                saveSuccess = false
            }
        }
        
        if saveSuccess {
            // Clear unsaved changes state
            hasUnsavedChanges = false
            print("✅ Settings saved successfully for \(pet.name)")
        } else {
            errorMessage = "Unable to save some settings. Please try again."
            showError = true
        }
        
        return saveSuccess
    }
    
    /// Resets all settings to their original values
    /// Cancels any unsaved changes
    func resetToOriginal() {
        petName = originalName
        cycleFrequencyDays = originalCycleFrequency
        washDurationMinutes = originalWashDuration
        dryDurationMinutes = originalDryDuration
        hasUnsavedChanges = false
        
        print("🔄 Settings reset to original values for \(pet.name)")
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
        let success = petService.resetPetStatistics(pet)
        
        if success {
            print("✅ Statistics reset for \(pet.name)")
        } else {
            errorMessage = "Unable to reset statistics. Please try again."
            showError = true
        }
        
        showResetConfirmation = false
        return success
    }
    
    /// Cancels statistics reset
    func cancelResetStatistics() {
        showResetConfirmation = false
    }
    
    /// Shows save confirmation dialog
    func requestSaveConfirmation() {
        showSaveConfirmation = true
    }
    
    /// Confirms and executes save
    func confirmSave() {
        let success = saveSettings()
        showSaveConfirmation = false
        
        if success {
            // Could trigger a success notification here
            print("✅ Settings saved and confirmed for \(pet.name)")
        }
    }
    
    /// Cancels save operation
    func cancelSave() {
        showSaveConfirmation = false
    }
    
    // MARK: - Validation Methods
    
    /// Validates all input values
    /// - Returns: true if all inputs are valid, false otherwise
    private func validateInputs() -> Bool {
        // Validate pet name
        let trimmedName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count >= 1, trimmedName.count <= 50 else {
            errorMessage = "Pet name must be between 1 and 50 characters."
            showError = true
            return false
        }
        
        // Validate cycle frequency
        guard cycleFrequencyDays >= 1, cycleFrequencyDays <= 365 else {
            errorMessage = "Cycle frequency must be between 1 and 365 days."
            showError = true
            return false
        }
        
        // Validate wash duration
        guard washDurationMinutes >= 1, washDurationMinutes <= 180 else {
            errorMessage = "Wash duration must be between 1 and 180 minutes."
            showError = true
            return false
        }
        
        // Validate dry duration
        guard dryDurationMinutes >= 1, dryDurationMinutes <= 180 else {
            errorMessage = "Dry duration must be between 1 and 180 minutes."
            showError = true
            return false
        }
        
        return true
    }
    
    // MARK: - Computed Properties
    
    /// Pet's current health percentage
    var currentHealth: Int {
        return pet.currentHealth
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
    
    /// Whether the pet has an active laundry task
    var hasActiveTask: Bool {
        // This would need to be checked via PetViewModel or service
        // For now, return false as a placeholder
        return false
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error state
    /// Called when user dismisses error alert
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
}
