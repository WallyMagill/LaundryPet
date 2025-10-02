//
//  AppearanceMode.swift
//  LaundryPets
//
//  App appearance mode enumeration
//

import Foundation
import SwiftUI

/// Defines the app's appearance mode (light, dark, or system)
enum AppearanceMode: String, Codable, CaseIterable {
    /// Always use light mode
    case light = "light"
    
    /// Always use dark mode
    case dark = "dark"
    
    /// Follow system appearance setting (recommended)
    case system = "system"
    
    // MARK: - Display Properties
    
    /// User-friendly label for the appearance mode
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    /// SwiftUI ColorScheme for this appearance mode
    /// Returns nil for .system to allow SwiftUI auto-detection
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // SwiftUI auto-detects system preference
        }
    }
}

