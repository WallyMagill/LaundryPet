//
//  LaundryTask.swift
//  LaundryPets
//
//  SwiftData model representing a laundry task for a specific pet
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
    /// Note: Using UUID instead of @Relationship for explicit control
    var petID: UUID
    
    // MARK: - Timing
    
    /// When this task was created/started
    /// Used for tracking and sorting
    var startDate: Date
    
    /// When this task was completed
    /// nil = task not yet completed
    var endDate: Date?
    
    // MARK: - Task Details
    
    /// Type of laundry task (wash, dry, or full cycle)
    /// Determines the nature of the work
    var type: TaskType
    
    /// Duration of the task in minutes
    /// Must be greater than 0
    var durationMinutes: Int
    
    /// Whether the task has been completed
    /// true = finished, false = in progress or pending
    var completed: Bool
    
    // MARK: - Initialization
    
    /// Creates a new laundry task
    /// - Parameters:
    ///   - petID: UUID of the pet this task belongs to
    ///   - type: Type of laundry task (wash, dry, or cycle)
    ///   - durationMinutes: How long the task takes (must be > 0)
    init(petID: UUID, type: TaskType, durationMinutes: Int) {
        // Validate duration
        precondition(durationMinutes > 0, "Duration must be greater than 0")
        
        // Automatic properties
        self.id = UUID()
        self.startDate = Date()
        self.completed = false
        
        // Required properties
        self.petID = petID
        self.type = type
        self.durationMinutes = durationMinutes
        
        // Optional properties
        self.endDate = nil
    }
    
    // MARK: - Validation
    
    /// Validates the task's current state
    /// - Returns: true if all properties are valid
    func validate() -> Bool {
        // Validate duration
        guard durationMinutes > 0 else {
            return false
        }
        
        // Validate endDate if present
        if let endDate = endDate {
            guard endDate > startDate else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Task Management
    
    /// Marks the task as complete
    /// Sets completed to true and endDate to current time
    func markComplete() {
        self.completed = true
        self.endDate = Date()
    }
    
    /// Calculates the elapsed time since task started
    /// - Returns: Time interval in seconds, or nil if task is completed
    func elapsedTime() -> TimeInterval? {
        guard !completed else { return nil }
        return Date().timeIntervalSince(startDate)
    }
    
    /// Calculates remaining time for the task
    /// - Returns: Remaining time in seconds, or 0 if time has expired or task is complete
    func remainingTime() -> TimeInterval {
        guard !completed else { return 0 }
        let elapsed = Date().timeIntervalSince(startDate)
        let total = TimeInterval(durationMinutes * 60)
        return max(0, total - elapsed)
    }
    
    /// Checks if the task timer has expired
    /// - Returns: true if the duration has passed and task is not completed
    var isExpired: Bool {
        guard !completed else { return false }
        return remainingTime() <= 0
    }
}

