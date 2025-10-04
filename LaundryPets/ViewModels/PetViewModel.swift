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
    
    /// Service for managing notifications
    private let notificationService: NotificationService
    
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
        self.notificationService = NotificationService.shared
        
        // ⚠️ CRITICAL: Create OWN timer service instance for this pet!
        self.timerService = PetTimerService(petID: pet.id)
        
        // Setup all observations and load initial state
        setupTimerObservation()
        setupHealthUpdateObservation()
        setupTimerCompletionObservation()
        loadCurrentTask()
        updateHealthDisplay()
        
        // Schedule proactive health notifications
        scheduleProactiveHealthNotifications()
    }
    
    deinit {
        // Clean up all subscriptions to prevent memory leaks
        timerObservationCancellables.removeAll()
        healthUpdateCancellable?.cancel()
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
        
        // Timer observation setup complete
    }
    
    /// Sets up observation of global health update broadcasts
    /// Subscribes to SimpleTimerService.shared health update notifications
    private func setupHealthUpdateObservation() {
        healthUpdateCancellable = NotificationCenter.default
            .publisher(for: .healthUpdateTick)
            .sink { [weak self] _ in
                self?.updateHealthDisplay()
            }
        
        // Health update observation setup complete
    }
    
    /// Notifies other components that this pet's state has been updated
    /// Posts a notification with the pet's ID for dashboard refresh
    private func notifyPetStateUpdated() {
        NotificationCenter.default.post(
            name: .petStateUpdated,
            object: pet.id
        )
        // Debug logging removed to reduce console spam
    }
    
    /// Sets up observation of timer completion notifications
    /// Handles automatic stage transitions when timers complete
    private func setupTimerCompletionObservation() {
        NotificationCenter.default
            .publisher(for: .timerCompleted)
            .sink { [weak self] notification in
                guard let petID = notification.object as? UUID,
                      petID == self?.pet.id else { return }
                
                self?.handleTimerCompletion()
            }
            .store(in: &timerObservationCancellables)
        
        // Timer completion observation setup complete
    }
    
    /// Restores timer state if there's an active task that needs timing
    /// Called after loading current task to ensure timer is running
    private func restoreTimerIfNeeded() {
        guard let task = currentTask else { return }
        
        // Only restore timer for washing or drying stages
        guard task.currentStage == .washing || task.currentStage == .drying else { return }
        
        // Don't start timer if one is already active (prevents duplicates)
        guard !timerService.isActive else { return }
        
        // Check if timer should still be active based on task timing
        if let washEndTime = task.washEndTime, task.currentStage == .drying {
            // Drying stage - check if dry timer should still be running
            let dryDuration = TimeInterval(pet.dryDurationMinutes * 60)
            let expectedDryEndTime = washEndTime.addingTimeInterval(dryDuration)
            
            if Date() < expectedDryEndTime {
                // Dry timer should still be running
                let remainingTime = expectedDryEndTime.timeIntervalSinceNow
                timerService.startTimer(duration: remainingTime, type: .dry)
            }
        } else if let washStartTime = task.washStartTime, task.currentStage == .washing {
            // Washing stage - check if wash timer should still be running
            let washDuration = TimeInterval(pet.washDurationMinutes * 60)
            let expectedWashEndTime = washStartTime.addingTimeInterval(washDuration)
            
            if Date() < expectedWashEndTime {
                // Wash timer should still be running
                let remainingTime = expectedWashEndTime.timeIntervalSinceNow
                timerService.startTimer(duration: remainingTime, type: .wash)
            }
        }
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
            
            // Restore timer if there's an active task
            restoreTimerIfNeeded()
            
            // Current task loaded
            
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
        let oldHealth = healthPercentage
        let (newHealth, newState) = healthUpdateService.updateHealthAndState(for: pet)
        
        // Only update if values have actually changed to prevent unnecessary UI updates
        guard newHealth != healthPercentage || newState != petState else {
            return
        }
        
        // Update ViewModel published properties
        self.healthPercentage = newHealth
        self.petState = newState
        
        // 🆕 Handle health-based notifications
        handleHealthNotifications(oldHealth: oldHealth, newHealth: newHealth)
        
        // CRITICAL FIX: Save health and state back to the pet model
        // This ensures the pet.health property stays in sync
        _ = petService.updatePetHealth(pet, newHealth: newHealth)
        if pet.currentState != newState {
            _ = petService.updatePetState(pet, to: newState)
        }
        
        #if DEBUG
        print("💓 Health updated for \(pet.name): \(newHealth)% (\(newState.rawValue))")
        #endif
    }
    
    /// Handles health-based notifications when health crosses thresholds
    /// - Parameters:
    ///   - oldHealth: Previous health level
    ///   - newHealth: New health level
    private func handleHealthNotifications(oldHealth: Int, newHealth: Int) {
        let thresholds = [25, 10, 5, 0]
        
        for threshold in thresholds {
            // Health crossed threshold downward
            if oldHealth > threshold && newHealth <= threshold {
                // Only schedule if we haven't already sent this notification
                if !pet.hasHealthNotificationBeenSent(for: threshold) {
                    scheduleHealthNotification(for: threshold)
                    pet.markHealthNotificationAsSent(for: threshold)
                }
            }
            // Health improved past threshold
            else if oldHealth <= threshold && newHealth > threshold {
                // Cancel the notification and reset tracking
                notificationService.cancelSpecificHealthNotification(for: pet.id, healthLevel: threshold)
                pet.clearHealthNotificationTracking(for: threshold)
            }
        }
    }
    
    /// Schedules a health notification for a specific threshold
    /// - Parameter threshold: Health threshold level (25, 10, 5, 0)
    private func scheduleHealthNotification(for threshold: Int) {
        // Calculate when this notification should trigger
        // For now, we'll schedule it immediately since health has already crossed the threshold
        let triggerDate = Date().addingTimeInterval(1) // 1 second delay
        
        notificationService.scheduleHealthWarning(
            for: pet.id,
            petName: pet.name,
            healthLevel: threshold,
            triggerDate: triggerDate
        )
    }
    
    /// Schedules proactive health notifications based on current health and cycle frequency
    /// Called when pet is created or when app returns from background
    private func scheduleProactiveHealthNotifications() {
        let referenceDate = pet.lastLaundryDate ?? pet.createdDate
        let currentHealth = healthUpdateService.calculateCurrentHealth(for: pet)
        
        notificationService.scheduleProactiveHealthNotifications(
            for: pet.id,
            petName: pet.name,
            currentHealth: currentHealth,
            cycleFrequencyDays: pet.cycleFrequencyDays,
            referenceDate: referenceDate
        )
    }
    
    /// Requests notification permission if not already determined
    /// Called before starting timers to ensure notifications work
    private func requestNotificationPermissionIfNeeded() async {
        guard notificationService.permissionStatus == .notDetermined else {
            return // Permission already handled
        }
        
        let granted = await notificationService.requestPermission()
        
        if !granted {
            #if DEBUG
            print("⚠️ Notification permission denied - timers will work but no notifications")
            #endif
        }
    }
    
    /// Handles timer completion events and transitions between stages
    /// Called automatically when a timer finishes
    private func handleTimerCompletion() {
        guard let task = currentTask else {
            #if DEBUG
            print("❌ Timer completed but no current task")
            #endif
            return
        }
        
        do {
            switch task.currentStage {
            case .washing:
                // Wash timer completed - transition to washComplete
                task.currentStage = .washComplete
                task.washEndTime = Date()
                try modelContext.save()
                #if DEBUG
                print("✅ Wash completed for \(pet.name) - ready to start dryer")
                #endif
                
            case .drying:
                // Dry timer completed - transition to dryComplete
                task.currentStage = .dryComplete
                task.dryEndTime = Date()
                try modelContext.save()
                #if DEBUG
                print("✅ Dry completed for \(pet.name) - ready to fold or dry more")
                #endif
                
            default:
                #if DEBUG
                print("⚠️ Timer completed but stage \(task.currentStage.rawValue) doesn't need transition")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ Failed to update task after timer completion: \(error)")
            #endif
            self.errorMessage = "Unable to update laundry progress. Please restart the app."
            self.showError = true
        }
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
            
            #if DEBUG
            print("✅ Started new cycle for \(pet.name)")
            #endif
            
            // Start the wash phase
            startWash()
            
            // Note: startWash() will handle the notification
            
        } catch {
            #if DEBUG
            print("❌ Failed to start cycle: \(error)")
            #endif
            self.errorMessage = "Unable to start laundry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Starts the wash phase of the current task
    /// Updates task state and starts wash timer
    func startWash() {
        guard let task = currentTask else {
            #if DEBUG
            print("❌ Cannot start wash: no current task")
            #endif
            self.errorMessage = "No active laundry task. Please start a new cycle."
            self.showError = true
            return
        }
        
        // Request notification permission if needed
        Task {
            await requestNotificationPermissionIfNeeded()
            
            await MainActor.run {
                self.startWashTimer(task: task)
            }
        }
    }
    
    /// Internal method to start wash timer after permission check
    private func startWashTimer(task: LaundryTask) {
        do {
            // Update task to washing stage
            task.currentStage = .washing
            task.washStartTime = Date()
            
            // Save changes
            try modelContext.save()
            
            // Start wash timer
            let washDuration = TimeInterval(pet.washDurationMinutes * 60)
            timerService.startTimer(duration: washDuration, type: .wash)
            
            // Schedule wash completion notification
            notificationService.scheduleTimerNotification(
                petID: pet.id,
                petName: pet.name,
                timerType: .wash,
                timeInterval: washDuration
            )
            
            #if DEBUG
            print("✅ Started wash for \(pet.name): \(pet.washDurationMinutes) minutes")
            #endif
            
            // Notify dashboard of state change
            notifyPetStateUpdated()
            
        } catch {
            #if DEBUG
            print("❌ Failed to start wash: \(error)")
            #endif
            self.errorMessage = "Unable to start wash cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Starts the dry phase of the current task
    /// Updates task state and starts dry timer
    func startDry() {
        guard let task = currentTask else {
            #if DEBUG
            print("❌ Cannot start dry: no current task")
            #endif
            self.errorMessage = "No active laundry task. Please start a new cycle."
            self.showError = true
            return
        }
        
        // Request notification permission if needed
        Task {
            await requestNotificationPermissionIfNeeded()
            
            await MainActor.run {
                self.startDryTimer(task: task)
            }
        }
    }
    
    /// Internal method to start dry timer after permission check
    private func startDryTimer(task: LaundryTask) {
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
            
            // Schedule dry completion notification
            notificationService.scheduleTimerNotification(
                petID: pet.id,
                petName: pet.name,
                timerType: .dry,
                timeInterval: dryDuration
            )
            
            #if DEBUG
            print("✅ Started dry for \(pet.name): \(pet.dryDurationMinutes) minutes")
            #endif
            
            // Notify dashboard of state change
            notifyPetStateUpdated()
            
        } catch {
            #if DEBUG
            print("❌ Failed to start dry: \(error)")
            #endif
            self.errorMessage = "Unable to start dry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Completes the laundry cycle
    /// Updates task as completed, restores pet health, and updates statistics
    func completeCycle() {
        guard let task = currentTask else {
            #if DEBUG
            print("❌ Cannot complete cycle: no current task")
            #endif
            self.errorMessage = "No active laundry task to complete."
            self.showError = true
            return
        }
        
        do {
            // Update task as completed
            task.currentStage = .completed
            task.dryEndTime = Date()
            task.markFolded()
            
            // Update pet with completion (includes statistics)
            let success = petService.completeCycle(for: pet)
            guard success else {
                self.errorMessage = "Unable to complete laundry cycle. Please try again."
                self.showError = true
                return
            }
            
            // Save changes
            try modelContext.save()
            
            // Clear current task (cycle complete)
            self.currentTask = nil
            
            // Reset health notification tracking since health improved
            pet.resetHealthNotificationTracking()
            notificationService.resetHealthNotifications(for: pet.id, petName: pet.name, currentHealth: 100)
            
            // Update health display
            updateHealthDisplay()
            
            #if DEBUG
            print("✅ Completed cycle for \(pet.name) - Stats: \(pet.totalCyclesCompleted) cycles, \(pet.currentStreak) streak")
            #endif
            
            // Notify dashboard of state change
            notifyPetStateUpdated()
            
        } catch {
            #if DEBUG
            print("❌ Failed to complete cycle: \(error)")
            #endif
            self.errorMessage = "Unable to complete laundry cycle. Please try again."
            self.showError = true
        }
    }
    
    /// Cancels the current timer and resets task state
    func cancelTimer() {
        // Stop the timer
        timerService.stopTimer()
        
        // Cancel any pending timer notifications
        notificationService.cancelAllTimerNotifications(for: pet.id)
        
        // Reset task state if exists
        if let task = currentTask {
            do {
                task.currentStage = .cycle
                try modelContext.save()
                #if DEBUG
                print("✅ Cancelled timer and reset task for \(pet.name)")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to reset task after cancellation: \(error)")
                #endif
                self.errorMessage = "Unable to reset laundry task. Please restart the app."
                self.showError = true
            }
        }
    }
    
    /// Adds additional drying time to the current task
    /// - Parameter additionalMinutes: Extra minutes to add to drying (default: 10)
    /// - Returns: true if successful, false if failed
    @discardableResult
    func addMoreDryTime(additionalMinutes: Int = 10) -> Bool {
        // Validate input
        guard additionalMinutes > 0, additionalMinutes <= 120 else {
            #if DEBUG
            print("❌ Invalid dry time: \(additionalMinutes) minutes (must be 1-120)")
            #endif
            self.errorMessage = "Please enter a valid dry time (1-120 minutes)."
            self.showError = true
            return false
        }
        
        guard let task = currentTask, task.currentStage == .dryComplete else {
            #if DEBUG
            print("❌ Cannot add dry time: no current task or wrong stage")
            #endif
            self.errorMessage = "Cannot add dry time at this stage."
            self.showError = true
            return false
        }
        
        do {
            // Add additional dry time to the task
            let currentAdditional = task.additionalDryMinutes ?? 0
            task.additionalDryMinutes = currentAdditional + additionalMinutes
            
            // Transition back to drying stage
            task.currentStage = .drying
            task.dryStartTime = Date() // Reset dry start time
            
            // Save changes
            try modelContext.save()
            
            // Start additional dry timer
            let additionalDuration = TimeInterval(additionalMinutes * 60)
            timerService.startTimer(duration: additionalDuration, type: .extraDry)
            
            // Schedule extra dry completion notification
            notificationService.scheduleTimerNotification(
                petID: pet.id,
                petName: pet.name,
                timerType: .extraDry,
                timeInterval: additionalDuration
            )
            
            #if DEBUG
            print("✅ Added \(additionalMinutes) more dry minutes for \(pet.name)")
            #endif
            return true
            
        } catch {
            #if DEBUG
            print("❌ Failed to add dry time: \(error)")
            #endif
            self.errorMessage = "Unable to add more drying time. Please try again."
            self.showError = true
            return false
        }
    }
    
    // MARK: - Pet Management
    
    /// Refreshes the pet data from the database
    /// Useful when pet properties might have been updated elsewhere
    /// - Returns: true if refresh succeeded, false if failed
    @discardableResult
    func refreshPetData() -> Bool {
        guard petService.fetchPet(by: pet.id) != nil else {
            #if DEBUG
            print("❌ Failed to refresh pet data for \(pet.name)")
            #endif
            self.errorMessage = "Unable to refresh pet data. Please restart the app."
            self.showError = true
            return false
        }
        
        // Note: We can't replace the pet reference since it's immutable
        // But we can update our health display with fresh data
        updateHealthDisplay()
        
        #if DEBUG
        print("✅ Refreshed pet data for \(pet.name)")
        #endif
        return true
    }
    
    /// Refreshes the ViewModel with updated pet data from the database
    /// Called when the pet data changes to keep the ViewModel in sync
    /// - Parameter updatedPet: The updated pet data to sync with
    func updatePet(_ updatedPet: Pet) {
        // Refresh current task and health display with updated pet data
        loadCurrentTask()
        updateHealthDisplay()
        
        // Note: Removed notifyPetStateUpdated() to prevent infinite loops
        // Pet state updates should be handled by the timer service and health updates
    }
    
    /// Updates the pet's name
    /// - Parameter newName: The new name for the pet
    /// - Returns: true if update succeeded, false if failed
    @discardableResult
    func updatePetName(_ newName: String) -> Bool {
        let success = petService.updatePetName(pet, newName: newName)
        
        if success {
            #if DEBUG
            print("✅ Updated pet name to: \(newName)")
            #endif
            // Notify dashboard of state change
            notifyPetStateUpdated()
        } else {
            self.errorMessage = "Unable to update pet name. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    /// Updates the pet's timer settings
    /// - Parameters:
    ///   - washDurationMinutes: New wash duration (nil to keep current)
    ///   - dryDurationMinutes: New dry duration (nil to keep current)
    /// - Returns: true if update succeeded, false if failed
    @discardableResult
    func updatePetTimerSettings(washDurationMinutes: Int? = nil, dryDurationMinutes: Int? = nil) -> Bool {
        let success = petService.updatePetSettings(
            pet,
            washDurationMinutes: washDurationMinutes,
            dryDurationMinutes: dryDurationMinutes
        )
        
        if success {
            #if DEBUG
            print("✅ Updated timer settings for \(pet.name)")
            #endif
        } else {
            self.errorMessage = "Unable to update timer settings. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    /// Resets the pet's statistics to zero
    /// - Returns: true if reset succeeded, false if failed
    @discardableResult
    func resetPetStatistics() -> Bool {
        let success = petService.resetPetStatistics(pet)
        
        if success {
            // Update health display after reset
            updateHealthDisplay()
            #if DEBUG
            print("✅ Reset statistics for \(pet.name)")
            #endif
        } else {
            self.errorMessage = "Unable to reset pet statistics. Please try again."
            self.showError = true
        }
        
        return success
    }
    
    /// Gets formatted time remaining for UI display
    /// - Returns: Formatted string (e.g., "2:30" or "0:45")
    func getFormattedTimeRemaining() -> String {
        return timerService.getFormattedTime()
    }
    
    /// Gets the remaining time in seconds
    /// - Returns: Time remaining in seconds, or 0 if no active timer
    func getTimeRemaining() -> TimeInterval {
        return timerService.getRemainingTime()
    }
    
    /// Checks if the pet has an active laundry task
    /// - Returns: true if there's an active task, false otherwise
    func hasActiveTask() -> Bool {
        return currentTask != nil
    }
    
    /// Gets the current stage of the laundry workflow
    /// - Returns: The current stage, or .cycle if no active task
    func getCurrentStage() -> LaundryStage {
        return currentTask?.currentStage ?? .cycle
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error state
    /// Called when user dismisses error alert
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
}
