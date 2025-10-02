//
//  AppSettings.swift
//  LaundryPets
//
//  SwiftData model for global app-level configuration
//
//  ⚠️ SINGLETON PATTERN ⚠️
//  Only ONE AppSettings instance should exist in the database.
//  Query for existing instance before creating a new one.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    // MARK: - Notification Settings
    
    /// Master toggle for all notifications
    /// When false, no notifications will be scheduled
    var notificationsEnabled: Bool
    
    /// Play sound with notifications
    /// Only applies when notificationsEnabled = true
    var soundsEnabled: Bool
    
    /// Enable haptic feedback for interactions
    /// Affects button taps, timer completions, and other UI interactions
    var hapticsEnabled: Bool
    
    // MARK: - Appearance Settings
    
    /// App appearance mode (light, dark, or system)
    /// Controls the color scheme throughout the app
    var appearanceMode: AppearanceMode
    
    // MARK: - Initialization
    
    /// Creates AppSettings with sensible defaults
    /// All properties initialized to user-friendly defaults
    ///
    /// ⚠️ SINGLETON: Check if AppSettings already exists before calling init()
    init() {
        self.notificationsEnabled = true
        self.soundsEnabled = true
        self.hapticsEnabled = true
        self.appearanceMode = .system
    }
}

