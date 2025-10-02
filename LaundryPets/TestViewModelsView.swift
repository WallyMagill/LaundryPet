//
//  TestViewModelsView.swift
//  LaundryPets
//
//  Phase 2 Guided Testing Interface for ViewModels
//  Walks through systematic testing of PetsViewModel, SettingsViewModel, and PetViewModel
//  ⚠️ TEMPORARY - Will be replaced with real UI in Phase 3
//

import SwiftUI
import SwiftData

struct TestViewModelsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var petsViewModel: PetsViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var selectedPet: Pet? = nil
    @State private var petViewModel: PetViewModel? = nil
    @State private var testCounter: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Test PetsViewModel
                if let petsViewModel = petsViewModel {
                    Section {
                        petsViewModelSection(petsViewModel)
                    } header: {
                        Text("Test PetsViewModel")
                            .font(.headline)
                    }
                }
                
                // Section 2: Test SettingsViewModel
                if let settingsViewModel = settingsViewModel, settingsViewModel.settings != nil {
                    Section {
                        settingsViewModelSection(settingsViewModel)
                    } header: {
                        Text("Test SettingsViewModel")
                            .font(.headline)
                    }
                }
                
                // Section 3: Test PetViewModel
                if let petViewModel = petViewModel {
                    Section {
                        petViewModelSection(petViewModel)
                    } header: {
                        Text("Test PetViewModel")
                            .font(.headline)
                    }
                }
                
                // Multi-Pet Timer Overview Section
                Section {
                    multiPetTimerOverview
                } header: {
                    Text("⚠️ Multi-Pet Timer Overview")
                        .font(.headline)
                }
                
                // Instructions Section
                Section {
                    instructionsSection
                } header: {
                    Text("Testing Instructions")
                        .font(.headline)
                }
                
                // Reset Section
                Section {
                    resetSection
                } header: {
                    Text("Reset Data")
                        .font(.headline)
                }
            }
            .navigationTitle("Test ViewModels")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize ViewModels
                if petsViewModel == nil {
                    petsViewModel = PetsViewModel(modelContext: modelContext)
                    print("✅ PetsViewModel initialized")
                }
                
                if settingsViewModel == nil {
                    settingsViewModel = SettingsViewModel(modelContext: modelContext)
                    print("✅ SettingsViewModel initialized")
                }
            }
        }
    }
    
    // MARK: - PetsViewModel Section
    
    @ViewBuilder
    private func petsViewModelSection(_ petsViewModel: PetsViewModel) -> some View {
        // Step 1: Pets Loaded
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Step 1: Pets Loaded")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Count: \(petsViewModel.pets.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if !petsViewModel.pets.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        
        // Step 2: Create Test Pet
        Button(action: {
            testCounter += 1
            // Create pet with SHORT durations for testing (5 min cycle, 1 min wash/dry)
            petsViewModel.createPet(name: "Test Pet \(testCounter)", cycleFrequencyDays: 7)
            
            // After creation, find the newly created pet and update its durations
            // The pet should be the last one in the pets array after creation
            if let newPet = petsViewModel.pets.last {
                // Update to testing durations immediately after creation
                newPet.washDurationMinutes = 1  // 1 minute for testing
                newPet.dryDurationMinutes = 1   // 1 minute for testing
                try? modelContext.save()
                print("✅ Created test pet with 1 min wash/dry durations")
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Step 2: Create Test Pet (1 min timers)")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        
        // Step 3: Pet List
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 3: Tap a pet below to test PetViewModel")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if petsViewModel.pets.isEmpty {
                Text("No pets created yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(petsViewModel.pets, id: \.id) { pet in
                    Button(action: {
                        selectedPet = pet
                        petViewModel = PetViewModel(pet: pet, modelContext: modelContext)
                        print("✅ PetViewModel created for: \(pet.name)")
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pet.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
                                    Text("Health: \(pet.health ?? 0)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("State: \(pet.currentState.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedPet?.id == pet.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            petsViewModel.deletePet(pet)
                        }
                    }
                }
            }
        }
        
        // Step 4: Refresh
        Button(action: {
            petsViewModel.refreshPets()
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Step 4: Refresh Pets")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(8)
        }
        
        // Error Display
        if petsViewModel.showError {
            Text(petsViewModel.errorMessage ?? "Unknown error")
                .font(.caption)
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // MARK: - SettingsViewModel Section
    
    @ViewBuilder
    private func settingsViewModelSection(_ settingsViewModel: SettingsViewModel) -> some View {
        // Step 1: Current Settings
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 1: Current Settings")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let settings = settingsViewModel.settings {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications: \(settings.notificationsEnabled ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Appearance: \(settings.appearanceMode.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Sounds: \(settings.soundEnabled ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Haptics: \(settings.hapticsEnabled ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
        }
        
        // Step 2: Toggle Settings
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 2: Toggle Settings")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let settings = settingsViewModel.settings {
                VStack(spacing: 12) {
                    // Notifications Toggle
                    HStack {
                        Text("Notifications")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { settingsViewModel.updateNotificationsEnabled($0) }
                        ))
                    }
                    
                    // Appearance Mode Picker
                    HStack {
                        Text("Appearance Mode")
                            .font(.subheadline)
                        Spacer()
                        Picker("Appearance", selection: Binding(
                            get: { settings.appearanceMode },
                            set: { settingsViewModel.updateAppearanceMode($0) }
                        )) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Sounds Toggle
                    HStack {
                        Text("Sounds")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.soundEnabled },
                            set: { settingsViewModel.updateSoundsEnabled($0) }
                        ))
                    }
                    
                    // Haptics Toggle
                    HStack {
                        Text("Haptics")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settingsViewModel.updateHapticsEnabled($0) }
                        ))
                    }
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
        }
        
        // Error Display
        if settingsViewModel.showError {
            Text(settingsViewModel.errorMessage ?? "Unknown error")
                .font(.caption)
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // MARK: - PetViewModel Section
    
    @ViewBuilder
    private func petViewModelSection(_ viewModel: PetViewModel) -> some View {
        // Header
        Text("Testing Pet: \(viewModel.pet.name)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.blue)
        
        // Step 1: Pet State
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 1: Pet State")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health: \(viewModel.healthPercentage)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("State: \(viewModel.petState.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Health indicator
                Circle()
                    .fill(healthColor(viewModel.healthPercentage))
                    .frame(width: 20, height: 20)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        
        // Step 1b: Statistics
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 1b: Statistics")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Cycles: \(viewModel.pet.totalCyclesCompleted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Current Streak: \(viewModel.pet.currentStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Longest Streak: \(viewModel.pet.longestStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let lastLaundry = viewModel.pet.lastLaundryDate {
                        Text("Last: \(lastLaundry, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Last: Never")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(6)
        }
        
        // Step 2: Timer State
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 2: Timer State")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active: \(viewModel.timerActive ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Type: \(viewModel.timerType.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Remaining: \(formatTime(viewModel.timeRemaining))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(6)
        }
        
        // Step 3: Current Task
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 3: Current Task")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let task = viewModel.currentTask {
                Text("Stage: \(task.currentStage.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            } else {
                Text("No active task")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        
        // Step 3b: Timer Settings
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 3b: Timer Settings")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Wash Duration: \(viewModel.pet.washDurationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Dry Duration: \(viewModel.pet.dryDurationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Cycle Frequency: \(viewModel.pet.cycleFrequencyDays) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.cyan.opacity(0.1))
            .cornerRadius(6)
        }
        
        // Step 4: Laundry Workflow
        VStack(alignment: .leading, spacing: 8) {
            Text("Step 4: Laundry Workflow")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.startCycle()
                    }) {
                        Text("Start Cycle")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(viewModel.timerActive ? 0.3 : 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .disabled(viewModel.timerActive)
                    
                    Button(action: {
                        viewModel.startWash()
                    }) {
                        Text("Start Wash")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(viewModel.timerActive ? 0.3 : 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .disabled(viewModel.timerActive)
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.startDry()
                    }) {
                        Text("Start Dry")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(viewModel.timerActive ? 0.3 : 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .disabled(viewModel.timerActive)
                    
                    Button(action: {
                        viewModel.completeCycle()
                    }) {
                        Text("Complete Cycle")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.cancelTimer()
                    }) {
                        Text("Cancel Timer")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(viewModel.timerActive ? 0.8 : 0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .disabled(!viewModel.timerActive)
                    
                    Button(action: {
                        selectedPet = nil
                        petViewModel = nil
                    }) {
                        Text("Deselect Pet")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        
        // Error Display
        if viewModel.showError {
            Text(viewModel.errorMessage ?? "Unknown error")
                .font(.caption)
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    // MARK: - Multi-Pet Timer Overview
    
    @ViewBuilder
    private var multiPetTimerOverview: some View {
        if let petsVM = petsViewModel {
            VStack(alignment: .leading, spacing: 8) {
                Text("CRITICAL TEST: Verify timer independence")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("All pets with active timers should count down independently:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if petsVM.pets.isEmpty {
                    Text("No pets created yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(petsVM.pets, id: \.id) { pet in
                        // Create a temporary PetViewModel to check timer status
                        let tempVM = PetViewModel(pet: pet, modelContext: modelContext)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pet.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if tempVM.timerActive {
                                    Text("\(tempVM.timerType.rawValue): \(formatTime(tempVM.timeRemaining))")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("No active timer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if tempVM.timerActive {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(tempVM.timerActive ? Color.green.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(8)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Testing Instructions:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Add testing note about short durations
            Text("Note: Test pets created with 1 min wash/dry timers for fast testing")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionText("1. Create 2-3 test pets in Section 1", emoji: "1️⃣")
                instructionText("2. Select first pet and start its cycle timer", emoji: "2️⃣")
                instructionText("3. Select second pet and start its cycle timer", emoji: "3️⃣")
                instructionText("4. Check 'Multi-Pet Timer Overview' - both should run", emoji: "⚠️")
                instructionText("5. Switch between pets - timers stay independent", emoji: "✅")
                instructionText("6. Test complete cycle workflow on one pet", emoji: "6️⃣")
                instructionText("7. Verify statistics update after completion", emoji: "7️⃣")
                instructionText("8. Toggle settings and verify they persist", emoji: "8️⃣")
            }
            .padding(8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(6)
        }
    }
    
    @ViewBuilder
    private func instructionText(_ text: String, emoji: String = "") -> some View {
        HStack(spacing: 4) {
            if !emoji.isEmpty {
                Text(emoji)
                    .font(.caption)
            }
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clear all test data and start fresh")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: resetAllData) {
                HStack {
                    Image(systemName: "trash.circle.fill")
                    Text("Reset All Data")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            
            Text("⚠️ This will delete all pets, tasks, and settings")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    private func resetAllData() {
        // Clear pets
        if let petsVM = petsViewModel {
            for pet in petsVM.pets {
                petsVM.deletePet(pet)
            }
        }
        
        // Reset ViewModels
        selectedPet = nil
        petViewModel = nil
        testCounter = 0
        
        // Clear any errors
        petsViewModel?.clearError()
        settingsViewModel?.clearError()
        
        print("✅ All test data cleared")
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func healthColor(_ health: Int) -> Color {
        switch health {
        case 75...100: return .green
        case 50..<75: return .blue
        case 25..<50: return .orange
        case 1..<25: return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    TestViewModelsView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
