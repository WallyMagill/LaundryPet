//
//  SettingsViewModel.swift
//  LaundryPets
//
//  ViewModel for managing global app settings with SwiftData integration
//  Handles AppSettings singleton operations, error states, and UI updates
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel responsible for managing global app settings
/// Provides reactive UI updates and handles AppSettings singleton operations
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// AppSettings singleton instance for UI observation
    /// Automatically triggers SwiftUI view updates when modified
    @Published var settings: AppSettings? = nil
    
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
    
    // MARK: - Initialization
    
    /// Creates a new SettingsViewModel with the provided model context
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load settings immediately on initialization
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Loads AppSettings singleton from database or creates default instance
    /// Fetches existing settings or creates new ones with default values
    /// Wraps database operations in do-catch for error handling
    func loadSettings() {
        do {
            // Query for existing AppSettings (should be singleton)
            let descriptor = FetchDescriptor<AppSettings>()
            let existingSettings = try modelContext.fetch(descriptor)
            
            if let settings = existingSettings.first {
                // Settings exist, use them
                self.settings = settings
                print("✅ Loaded existing AppSettings")
            } else {
                // No settings found, create default instance
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                
                // Save the new settings
                try modelContext.save()
                
                // Update published property
                self.settings = newSettings
                print("✅ Created new AppSettings with defaults")
            }
            
        } catch {
            // Log error for debugging
            print("❌ Failed to load settings: \(error)")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to load settings. Please restart the app."
            
            // Trigger error alert
            self.showError = true
            
            // Fallback to nil (graceful degradation)
            self.settings = nil
        }
    }
    
    /// Updates the notifications enabled setting
    /// - Parameter enabled: Whether notifications should be enabled
    func updateNotificationsEnabled(_ enabled: Bool) {
        guard let settings = settings else {
            print("❌ Cannot update settings: settings is nil")
            return
        }
        
        settings.notificationsEnabled = enabled
        saveSettings()
    }
    
    /// Updates the app appearance mode setting
    /// - Parameter mode: The new appearance mode (light, dark, or system)
    func updateAppearanceMode(_ mode: AppearanceMode) {
        guard let settings = settings else {
            print("❌ Cannot update settings: settings is nil")
            return
        }
        
        settings.appearanceMode = mode
        saveSettings()
    }
    
    /// Updates the sounds enabled setting
    /// - Parameter enabled: Whether notification sounds should be enabled
    func updateSoundsEnabled(_ enabled: Bool) {
        guard let settings = settings else {
            print("❌ Cannot update settings: settings is nil")
            return
        }
        
        settings.soundEnabled = enabled
        saveSettings()
    }
    
    /// Updates the haptics enabled setting
    /// - Parameter enabled: Whether haptic feedback should be enabled
    func updateHapticsEnabled(_ enabled: Bool) {
        guard let settings = settings else {
            print("❌ Cannot update settings: settings is nil")
            return
        }
        
        settings.hapticsEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    /// Saves the current settings to the database
    /// Handles save errors with user-friendly error messages
    private func saveSettings() {
        do {
            try modelContext.save()
            print("✅ Settings saved successfully")
            
        } catch {
            // Log error for debugging
            print("❌ Failed to save settings: \(error)")
            
            // Set user-friendly error message
            self.errorMessage = "Unable to save settings. Please try again."
            
            // Trigger error alert
            self.showError = true
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
