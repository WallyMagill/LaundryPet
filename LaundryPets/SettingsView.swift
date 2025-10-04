//
//  SettingsView.swift
//  LaundryPets
//
//  App settings and configuration view
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self._settingsViewModel = StateObject(wrappedValue: SettingsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { settingsViewModel.settings?.notificationsEnabled ?? true },
                        set: { newValue in
                            settingsViewModel.settings?.notificationsEnabled = newValue
                            settingsViewModel.saveSettings()
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if settingsViewModel.settings?.notificationsEnabled == true {
                        Toggle("Sound", isOn: Binding(
                            get: { settingsViewModel.settings?.soundEnabled ?? true },
                            set: { newValue in
                                settingsViewModel.settings?.soundEnabled = newValue
                                settingsViewModel.saveSettings()
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                
                // MARK: - Appearance Section
                Section(header: Text("Appearance")) {
                    Picker("Appearance", selection: Binding(
                        get: { settingsViewModel.settings?.appearanceMode ?? .system },
                        set: { newValue in
                            settingsViewModel.updateAppearanceMode(newValue)
                        }
                    )) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Interaction Section
                Section(header: Text("Interaction")) {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settingsViewModel.settings?.hapticsEnabled ?? true },
                        set: { newValue in
                            settingsViewModel.settings?.hapticsEnabled = newValue
                            settingsViewModel.saveSettings()
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // MARK: - App Information Section
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Made with ❤️")
                        Spacer()
                    }
                }
                
                // MARK: - Data Management Section
                Section(header: Text("Data"), footer: Text("This will permanently delete all pets and their data. This action cannot be undone.")) {
                    Button("Reset All Data") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            settingsViewModel.loadSettings()
        }
        .alert("Error", isPresented: $settingsViewModel.showError) {
            Button("OK") {
                settingsViewModel.clearError()
            }
        } message: {
            Text(settingsViewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Reset All Data", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all pets, laundry tasks, and app settings. This action cannot be undone.")
        }
    }
    
    // MARK: - State
    
    @State private var showingResetConfirmation = false
    
    // MARK: - Actions
    
    private func resetAllData() {
        // Delete all pets and their associated tasks
        do {
            let petDescriptor = FetchDescriptor<Pet>()
            let taskDescriptor = FetchDescriptor<LaundryTask>()
            let settingsDescriptor = FetchDescriptor<AppSettings>()
            
            let pets = try modelContext.fetch(petDescriptor)
            let tasks = try modelContext.fetch(taskDescriptor)
            let settings = try modelContext.fetch(settingsDescriptor)
            
            for pet in pets {
                modelContext.delete(pet)
            }
            
            for task in tasks {
                modelContext.delete(task)
            }
            
            for setting in settings {
                modelContext.delete(setting)
            }
            
            try modelContext.save()
            
            print("✅ All data reset successfully")
            dismiss()
            
        } catch {
            print("❌ Failed to reset data: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    
    return SettingsView(modelContext: modelContext)
}
