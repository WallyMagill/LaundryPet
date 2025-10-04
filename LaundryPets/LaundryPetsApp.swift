//
//  LaundryPetsApp.swift
//  LaundryPets
//
//  Created by Walter Magill on 10/1/25.
//

import SwiftUI
import SwiftData

@main
struct LaundryPetsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pet.self,
            LaundryTask.self,
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var appSettings: AppSettings?
    @State private var colorScheme: ColorScheme?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, sharedModelContainer.mainContext)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    loadAppSettings()
                }
                .onReceive(NotificationCenter.default.publisher(for: .appearanceModeChanged)) { _ in
                    loadAppSettings()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Loads app settings and applies the selected theme
    private func loadAppSettings() {
        do {
            let descriptor = FetchDescriptor<AppSettings>()
            let settings = try sharedModelContainer.mainContext.fetch(descriptor)
            
            if let appSettings = settings.first {
                self.appSettings = appSettings
                self.colorScheme = appSettings.appearanceMode.colorScheme
                print("✅ Loaded theme: \(appSettings.appearanceMode.displayName)")
            } else {
                // Create default settings if none exist
                let newSettings = AppSettings()
                sharedModelContainer.mainContext.insert(newSettings)
                try sharedModelContainer.mainContext.save()
                
                self.appSettings = newSettings
                self.colorScheme = newSettings.appearanceMode.colorScheme
                print("✅ Created default theme: \(newSettings.appearanceMode.displayName)")
            }
        } catch {
            print("❌ Failed to load app settings: \(error)")
            // Fallback to system theme
            self.colorScheme = nil
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when appearance mode is changed in settings
    static let appearanceModeChanged = Notification.Name("appearanceModeChanged")
}
