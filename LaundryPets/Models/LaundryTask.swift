//
//  LaundryTask.swift
//  LaundryPets
//
//  SwiftData model representing a single laundry cycle for a specific pet
//  Tracks the complete workflow: cycle → washing → drying → completed
//

import Foundation
import SwiftData

@Model
final class LaundryTask {
    // MARK: - Identity & Relationship
    
    /// Unique identifier (primary key)
    var id: UUID
    
    /// Foreign key to Pet
    /// Links this task to a specific pet
    /// CASCADE DELETE: If pet deleted, all tasks deleted
    /// Note: Using UUID instead of @Relationship for explicit control
    var petID: UUID
    
    /// When this task was created
    /// Used for sorting and statistics
    var startDate: Date
    
    // MARK: - State
    
    /// Current stage in the laundry workflow
    /// Determines which action button to show and UI state
    /// Progression: .cycle → .washing → .drying → .completed
    var currentStage: LaundryStage
    
    /// Whether the entire cycle is complete
    /// true = all stages done (folded), pet is happy
    /// false = still in progress or abandoned
    var isCompleted: Bool
    
    // MARK: - Timing (Audit Trail)
    
    /// When wash stage started
    /// nil = not started yet
    /// Set when user taps "Start Wash"
    var washStartTime: Date?
    
    /// When wash stage ended
    /// nil = not finished yet or skipped
    /// Set when wash timer completes
    var washEndTime: Date?
    
    /// When dry stage started
    /// nil = not started yet
    /// Set when user taps "Move to Dryer"
    var dryStartTime: Date?
    
    /// When dry stage ended
    /// nil = not finished yet or skipped
    /// Set when dry timer completes
    var dryEndTime: Date?
    
    /// When folding was marked complete
    /// nil = not folded yet
    /// When set, isCompleted = true
    /// Set when user taps "Mark Folded"
    var foldCompletedTime: Date?
    
    // MARK: - Duration Settings
    
    /// Wash duration (in minutes)
    /// Copied from Pet.washDurationMinutes at task creation
    /// Stored here so changing pet settings doesn't affect active tasks
    var washDurationMinutes: Int
    
    /// Dry duration (in minutes)
    /// Copied from Pet.dryDurationMinutes at task creation
    /// Stored here so changing pet settings doesn't affect active tasks
    var dryDurationMinutes: Int
    
    /// Additional dry time if user needs more (optional feature)
    /// nil = no additional time requested
    /// Used for "Dry 10 More Minutes" button
    var additionalDryMinutes: Int?
    
    // MARK: - Initialization
    
    /// Creates a new laundry task for a specific pet
    /// - Parameters:
    ///   - petID: UUID of the pet this task belongs to
    ///   - washDuration: Wash timer duration in minutes (default: 45)
    ///   - dryDuration: Dry timer duration in minutes (default: 60)
    init(petID: UUID, washDuration: Int = 45, dryDuration: Int = 60) {
        self.id = UUID()
        self.petID = petID
        self.startDate = Date()
        self.currentStage = .cycle
        self.isCompleted = false
        self.washDurationMinutes = washDuration
        self.dryDurationMinutes = dryDuration
        
        // All timing fields start as nil
        self.washStartTime = nil
        self.washEndTime = nil
        self.dryStartTime = nil
        self.dryEndTime = nil
        self.foldCompletedTime = nil
        self.additionalDryMinutes = nil
    }
    
    // MARK: - Stage Management
    
    /// Advances the task to the next stage in the workflow
    /// Updates currentStage and sets appropriate timestamps
    func advanceToNextStage() {
        let now = Date()
        
        switch currentStage {
        case .cycle:
            // Start washing
            currentStage = .washing
            washStartTime = now
            
        case .washing:
            // Move to washComplete (user will manually start dryer)
            washEndTime = now
            currentStage = .washComplete
            
        case .washComplete:
            // Start drying (user initiated)
            currentStage = .drying
            dryStartTime = now
            
        case .drying:
            // Complete drying
            dryEndTime = now
            currentStage = .dryComplete
            
        case .dryComplete:
            // Move to completed (user chose to fold)
            currentStage = .completed
            
        case .completed:
            // Already completed, no further advancement
            break
        }
    }
    
    /// Marks the task as fully completed (folded)
    /// Sets isCompleted = true and foldCompletedTime
    func markFolded() {
        self.isCompleted = true
        self.foldCompletedTime = Date()
    }
    
    // MARK: - Validation
    
    /// Validates the task's current state
    /// - Returns: true if all properties are valid
    func validate() -> Bool {
        // Validate duration
        guard washDurationMinutes > 0, dryDurationMinutes > 0 else {
            return false
        }
        
        // Validate timestamp sequence if set
        if let washStart = washStartTime, let washEnd = washEndTime {
            guard washEnd >= washStart else { return false }
        }
        
        if let dryStart = dryStartTime, let dryEnd = dryEndTime {
            guard dryEnd >= dryStart else { return false }
        }
        
        // If completed, must have fold time
        if isCompleted {
            guard foldCompletedTime != nil else { return false }
        }
        
        return true
    }
    
    /// Total time spent on this task (from start to fold)
    /// - Returns: Time interval in seconds, or nil if not completed
    func totalDuration() -> TimeInterval? {
        guard isCompleted, let foldTime = foldCompletedTime else {
            return nil
        }
        
        return foldTime.timeIntervalSince(startDate)
    }
}
