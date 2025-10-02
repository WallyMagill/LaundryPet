//
//  PetViewModel.swift
//  LaundryPets
//
//  ViewModel for managing individual pet state and laundry workflow
//  Handles per-pet timer operations, health updates, and UI reactivity
//
//  ⚠️ CRITICAL ARCHITECTURE: PER-INSTANCE TIMER PATTERN
//
//  This ViewModel creates its OWN PetTimerService instance.
//  This ensures complete timer independence between pets.
//
//  Each pet gets its own timer that operates independently:
//  - Pet A washing: 30 minutes remaining
//  - Pet B drying: 15 minutes remaining  
//  - Pet C idle: no active timer
//  All operate simultaneously without interference.

import Foundation
import SwiftData
import SwiftUI
import Combine

/// ViewModel responsible for managing individual pet state and laundry workflow
/// Provides reactive UI updates and handles per-pet timer operations
@MainActor
final class PetViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// Immutable reference to the pet this ViewModel manages
    /// Set at initialization and never changed
    let pet: Pet
    
    /// Per-instance timer service for this specific pet
    /// ⚠️ CRITICAL: Each pet gets its own timer instance!
    private let timerService: PetTimerService
    
    /// Service for pet business logic and CRUD operations
    private let petService: PetService
    
    /// Service for health calculations and state evaluation
    private let healthUpdateService: HealthUpdateService
    
    /// SwiftData model context for database operations
    private let modelContext: ModelContext
    
    /// Combine cancellable for health update subscription
    private var healthUpdateCancellable: AnyCancellable?
    
    /// Combine cancellables for timer service observation
    private var timerObservationCancellables: Set<AnyCancellable> = []
    
    // MARK: - Published Properties for UI
    
    /// Current laundry task for this pet
    /// nil if no active task
    @Published var currentTask: LaundryTask?
    
    /// Whether a timer is currently active
    /// Mirrors timerService.isActive for UI updates
    @Published var timerActive: Bool = false
    
    /// Remaining time in seconds
    /// Mirrors timerService.timeRemaining for UI updates
    @Published var timeRemaining: TimeInterval = 0
    
    /// Current timer type (wash, dry, or cycle)
    /// Mirrors timerService.timerType for UI updates
    @Published var timerType: SimpleTimerType = .cycle
    
    /// Current health percentage (0-100)
    /// Updated when health recalculations occur
    @Published var healthPercentage: Int = 100
    
    /// Current pet state based on health
    /// Updated when health recalculations occur
    @Published var petState: PetState = .happy
    
    /// User-friendly error message for display in alerts
    /// nil when no error, contains descriptive message when error occurs
    @Published var errorMessage: String? = nil
    
    /// Controls whether error alert is shown
    /// Set to true when errorMessage is set, triggers alert presentation
    @Published var showError: Bool = false
    
    // MARK: - Initialization
    
    /// Creates a new PetViewModel for a specific pet
    /// - Parameters:
    ///   - pet: The pet this ViewModel will manage
    ///   - modelContext: SwiftData context for database operations
    init(pet: Pet, modelContext: ModelContext) {
        self.pet = pet
        self.modelContext = modelContext
        
        // Create services with the provided context
        self.petService = PetService(modelContext: modelContext)
        self.healthUpdateService = HealthUpdateService.shared
        
        // ⚠️ CRITICAL: Create OWN timer service instance for this pet!
        self.timerService = PetTimerService(petID: pet.id)
        
        // Setup all observations and load initial state
        setupTimerObservation()
        setupHealthUpdateObservation()
        loadCurrentTask()
        updateHealthDisplay()
    }
    
    // MARK: - Setup Methods
    
    /// Sets up observation of timer service properties
    /// Uses Combine's sink() to observe timerService published properties
    private func setupTimerObservation() {
        // Observe timer active state
        timerService.$isActive
            .sink { [weak self] isActive in
                self?.timerActive = isActive
            }
            .store(in: &timerObservationCancellables)
        
        // Observe time remaining
        timerService.$timeRemaining
            .sink { [weak self] timeRemaining in
                self?.timeRemaining = timeRemaining
            }
            .store(in: &timerObservationCancellables)
        
        // Observe timer type
        timerService.$timerType
            .sink { [weak self] timerType in
                self?.timerType = timerType
            }
            .store(in: &timerObservationCancellables)
        
        print("✅ Timer observation setup for pet: \(pet.name)")
    }
    
    /// Sets up observation of global health update broadcasts
    /// Subscribes to SimpleTimerService.shared health update notifications
    private func setupHealthUpdateObservation() {
        healthUpdateCancellable = NotificationCenter.default
            .publisher(for: .healthUpdateTick)
            .sink { [weak self] _ in
                self?.updateHealthDisplay()
            }
        
        print("✅ Health update observation setup for pet: \(pet.name)")
    }
    
    /// Loads the current active laundry task for this pet
    /// Uses FetchDescriptor to find most recent incomplete task
    private func loadCurrentTask() {
        do {
            // Fetch all incomplete tasks for this pet
            let descriptor = FetchDescriptor<LaundryTask>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            
            let allTasks = try modelContext.fetch(descriptor)
            // Filter manually since SwiftData predicates can't capture external values
            let petTasks = allTasks.filter { task in
                task.petID == self.pet.id && !task.isCompleted
            }
            
            self.currentTask = petTasks.first
            
            if let task = currentTask {
                print("✅ Loaded current task for \(pet.name): \(task.currentStage.rawValue)")
            } else {
                print("ℹ️ No current task found for \(pet.name)")
            }
            
        } catch {
            print("❌ Failed to load current task: \(error)")
            self.errorMessage = "Unable to load laundry task. Please restart the app."
            self.showError = true
            self.currentTask = nil
        }
    }
    
    /// Updates health display by recalculating current health and state
    /// Called by health update broadcasts and manual updates
    private func updateHealthDisplay() {
        let (newHealth, newState) = healthUpdateService.updateHealthAndState(for: pet)
        
        self.healthPercentage = newHealth
        self.petState = newState
        
        print("✅ Health display updated for \(pet.name): \(newHealth)% -> \(newState.rawValue)")
    }
    
    // MARK: - Laundry Workflow Methods
    
    /// Starts a new laundry cycle for this pet
    /// Creates a new LaundryTask and begins the wash phase
    func startCycle() {
        do {
            // Create new laundry task
            let task = LaundryTask(
                petID: pet.id,
                washDuration: pet.washDurationMinutes,
                dryDuration: pet.dryDurationMinutes
            )
            
            // Insert into context
            modelContext.insert(task)
            
            // Save to database
            try modelContext.save()
            
            // Update current task reference
            self.currentTask = task
            
            print("✅ Started new cycle for \(pet.name)")
            
            // Start the wash phase
            startWash()
            
        } catch {
            print("❌ Failed to start cycle: \(error)")
            self.errorMessage = "Unable to start laundry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Starts the wash phase of the current task
    /// Updates task state and starts wash timer
    func startWash() {
        guard let task = currentTask else {
            print("❌ Cannot start wash: no current task")
            self.errorMessage = "No active laundry task. Please start a new cycle."
            self.showError = true
            return
        }
        
        do {
            // Update task to washing stage
            task.currentStage = .washing
            task.washStartTime = Date()
            
            // Save changes
            try modelContext.save()
            
            // Start wash timer
            let washDuration = TimeInterval(pet.washDurationMinutes * 60)
            timerService.startTimer(duration: washDuration, type: .wash)
            
            print("✅ Started wash for \(pet.name): \(pet.washDurationMinutes) minutes")
            
        } catch {
            print("❌ Failed to start wash: \(error)")
            self.errorMessage = "Unable to start wash cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Starts the dry phase of the current task
    /// Updates task state and starts dry timer
    func startDry() {
        guard let task = currentTask else {
            print("❌ Cannot start dry: no current task")
            self.errorMessage = "No active laundry task. Please start a new cycle."
            self.showError = true
            return
        }
        
        do {
            // Update task to drying stage
            task.currentStage = .drying
            task.washEndTime = Date()
            task.dryStartTime = Date()
            
            // Save changes
            try modelContext.save()
            
            // Start dry timer
            let dryDuration = TimeInterval(pet.dryDurationMinutes * 60)
            timerService.startTimer(duration: dryDuration, type: .dry)
            
            print("✅ Started dry for \(pet.name): \(pet.dryDurationMinutes) minutes")
            
        } catch {
            print("❌ Failed to start dry: \(error)")
            self.errorMessage = "Unable to start dry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Completes the laundry cycle
    /// Updates task as completed and restores pet health
    func completeCycle() {
        guard let task = currentTask else {
            print("❌ Cannot complete cycle: no current task")
            self.errorMessage = "No active laundry task to complete."
            self.showError = true
            return
        }
        
        do {
            // Update task as completed
            task.currentStage = .completed
            task.dryEndTime = Date()
            task.markFolded()
            
            // Update pet with completion
            pet.lastLaundryDate = Date()
            petService.updatePetHealth(pet, newHealth: 100)
            petService.updatePetState(pet, to: .happy)
            
            // Save changes
            try modelContext.save()
            
            // Clear current task (cycle complete)
            self.currentTask = nil
            
            // Update health display
            updateHealthDisplay()
            
            print("✅ Completed cycle for \(pet.name)")
            
        } catch {
            print("❌ Failed to complete cycle: \(error)")
            self.errorMessage = "Unable to complete laundry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Cancels the current timer and resets task state
    func cancelTimer() {
        // Stop the timer
        timerService.stopTimer()
        
        // Reset task state if exists
        if let task = currentTask {
            do {
                task.currentStage = .cycle
                try modelContext.save()
                print("✅ Cancelled timer and reset task for \(pet.name)")
            } catch {
                print("❌ Failed to reset task after cancellation: \(error)")
                self.errorMessage = "Unable to reset laundry task. Please restart the app."
                self.showError = true
            }
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
