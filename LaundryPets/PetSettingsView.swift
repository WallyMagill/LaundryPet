//
//  PetSettingsView.swift
//  LaundryPets
//
//  View for managing individual pet settings and configuration
//

import SwiftUI
import SwiftData

struct PetSettingsView: View {
    let pet: Pet
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var petViewModel: PetViewModel
    let petsViewModel: PetsViewModel
    
    @StateObject private var settingsViewModel: PetSettingsViewModel
    
    init(pet: Pet, modelContext: ModelContext, petViewModel: PetViewModel, petsViewModel: PetsViewModel) {
        self.pet = pet
        self.modelContext = modelContext
        self.petViewModel = petViewModel
        self.petsViewModel = petsViewModel
        self._settingsViewModel = StateObject(wrappedValue: PetSettingsViewModel(pet: pet, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Pet Information Section
                Section(header: Text("Pet Information")) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.blue)
                        Text("Name")
                        Spacer()
                        Button(action: {
                            settingsViewModel.showEditNameDialog()
                        }) {
                            HStack(spacing: 4) {
                                Text(pet.name)
                                    .foregroundColor(.primary)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Created")
                        Spacer()
                        Text(pet.createdDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Laundry Schedule Section
                Section(
                    header: Text("Laundry Schedule"),
                    footer: Text("How often this pet needs laundry. Shorter cycles mean more frequent care.")
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundColor(.orange)
                            Text("Cycle Frequency")
                            Spacer()
                        }
                        
                        Picker("", selection: $settingsViewModel.cycleFrequencyDays) {
                            ForEach(1...99, id: \.self) { days in
                                Text("\(days) day\(days == 1 ? "" : "s")").tag(days)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: settingsViewModel.cycleFrequencyDays) { _, newValue in
                            settingsViewModel.updateCycleFrequency(newValue)
                        }
                    }
                }
                
                // MARK: - Timer Settings Section
                Section(
                    header: Text("Timer Settings"),
                    footer: Text("Customize how long each stage takes. These settings affect new laundry cycles.")
                ) {
                    // Wash Duration
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "washer")
                                .foregroundColor(.blue)
                            Text("Wash Duration")
                            Spacer()
                        }
                        
                        Picker("", selection: $settingsViewModel.washDurationMinutes) {
                            ForEach(1...120, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: settingsViewModel.washDurationMinutes) { _, newValue in
                            settingsViewModel.updateWashDuration(newValue)
                        }
                    }
                    
                    // Dry Duration
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "fan")
                                .foregroundColor(.orange)
                            Text("Dry Duration")
                            Spacer()
                        }
                        
                        Picker("", selection: $settingsViewModel.dryDurationMinutes) {
                            ForEach(1...120, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: settingsViewModel.dryDurationMinutes) { _, newValue in
                            settingsViewModel.updateDryDuration(newValue)
                        }
                    }
                }
                
                // MARK: - Statistics Section
                Section(header: Text("Statistics")) {
                    HStack {
                        Image(systemName: "repeat.circle")
                            .foregroundColor(.blue)
                        Text("Total Cycles")
                        Spacer()
                        Text("\(settingsViewModel.totalCyclesCompleted)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        Text("Current Streak")
                        Spacer()
                        Text("\(settingsViewModel.currentStreak)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "trophy")
                            .foregroundColor(.yellow)
                        Text("Best Streak")
                        Spacer()
                        Text("\(settingsViewModel.longestStreak)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                        Text("Current Health")
                        Spacer()
                        Text("\(petViewModel.healthPercentage)%")
                            .foregroundColor(settingsViewModel.healthColor)
                    }
                }
                
                // MARK: - Current Task Section
                if let task = petViewModel.currentTask, !task.isCompleted {
                    Section(header: Text("Current Task")) {
                        HStack {
                            Image(systemName: "washer.fill")
                                .foregroundColor(.blue)
                            Text("Status")
                            Spacer()
                            Text(task.currentStage.displayText)
                                .foregroundColor(.secondary)
                        }
                        
                        if petViewModel.timerActive {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.blue)
                                Text("Time Remaining")
                                Spacer()
                                Text(petViewModel.getFormattedTimeRemaining())
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Started")
                            Spacer()
                            Text(task.startDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Danger Zone Section
                Section(
                    header: Text("Danger Zone"),
                    footer: Text("These actions cannot be undone. Proceed with caution.")
                ) {
                    Button("Reset All Statistics") {
                        settingsViewModel.resetStatistics()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Delete Pet") {
                        settingsViewModel.requestDeleteConfirmation()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Pet Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Statistics", isPresented: $settingsViewModel.showResetConfirmation) {
            Button("Reset", role: .destructive) {
                let success = settingsViewModel.confirmResetStatistics()
                if success {
                    petViewModel.refreshPetData()
                }
            }
            Button("Cancel", role: .cancel) {
                settingsViewModel.cancelResetStatistics()
            }
        } message: {
            Text("This will reset all statistics for \(pet.name) including total cycles, streaks, and health. This action cannot be undone.")
        }
        .alert("Delete Pet", isPresented: $settingsViewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let success = settingsViewModel.confirmDeletePet(using: petsViewModel)
                if success {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                settingsViewModel.cancelDeletePet()
            }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action cannot be undone and will also delete all associated laundry tasks.")
        }
        .alert("Edit Pet Name", isPresented: $settingsViewModel.showEditName) {
            TextField("Pet Name", text: $settingsViewModel.newPetName)
            Button("Save") {
                let success = settingsViewModel.updatePetName(settingsViewModel.newPetName)
                if success {
                    // Name updated successfully, notification will be posted automatically
                }
            }
            Button("Cancel", role: .cancel) {
                settingsViewModel.cancelEditName()
            }
        } message: {
            Text("Enter a new name for \(pet.name)")
        }
        .alert("Error", isPresented: $settingsViewModel.showError) {
            Button("OK") {
                settingsViewModel.clearError()
            }
        } message: {
            Text(settingsViewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    let samplePet = Pet(name: "Fluffy", cycleFrequencyDays: 7)
    let petsViewModel = PetsViewModel(modelContext: modelContext)
    let petViewModel = PetViewModel(pet: samplePet, modelContext: modelContext)
    
    PetSettingsView(pet: samplePet, modelContext: modelContext, petViewModel: petViewModel, petsViewModel: petsViewModel)
}
