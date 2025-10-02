//
//  TestViewModelsView.swift
//  LaundryPets
//
//  Phase 2 Guided Testing Interface for ViewModels
//  Systematic testing of PetsViewModel, SettingsViewModel, and PetViewModel
//  ⚠️ TEMPORARY - Will be replaced with real UI in Phase 3
//

import SwiftUI
import SwiftData
import Combine

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
                        Text("1. Test PetsViewModel")
                            .font(.headline)
                    }
                }
                
                // Section 2: Test SettingsViewModel
                if let settingsViewModel = settingsViewModel, settingsViewModel.settings != nil {
                    Section {
                        settingsViewModelSection(settingsViewModel)
                    } header: {
                        Text("2. Test SettingsViewModel")
                            .font(.headline)
                    }
                }
                
                // Section 3: Test PetViewModel
                if let petViewModel = petViewModel {
                    Section {
                        petViewModelSection(petViewModel)
                    } header: {
                        Text("3. Test PetViewModel")
                            .font(.headline)
                    }
                }
                
                // Active Timers Overview
                if let petsVM = petsViewModel, !petsVM.pets.isEmpty {
                    Section {
                        activeTimersOverview
                    } header: {
                        Text("⚠️ Multi-Pet Timer Check")
                            .font(.headline)
                    }
                }
                
                // Instructions
                Section {
                    instructionsSection
                } header: {
                    Text("Testing Instructions")
                        .font(.headline)
                }
                
                // Reset
                Section {
                    resetSection
                } header: {
                    Text("Reset Testing Data")
                            .font(.headline)
                }
            }
            .navigationTitle("Test ViewModels")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
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
        VStack(alignment: .leading, spacing: 12) {
            // Step 1: Pets Count
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
            
            // Step 2: Create Pet
            Button(action: {
                testCounter += 1
                if let newPet = petsViewModel.createPet(name: "Test Pet \(testCounter)", cycleFrequencyDays: 7) {
                    // Set short test durations
                    newPet.washDurationMinutes = 1
                    newPet.dryDurationMinutes = 1
                    try? modelContext.save()
                    print("✅ Created pet with 1 min wash/dry")
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
                Text("Step 3: Select Pet for Testing")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if petsViewModel.pets.isEmpty {
                    Text("No pets yet - create one above")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(petsViewModel.pets, id: \.id) { pet in
                        Button(action: {
                            selectedPet = pet
                            petViewModel = PetViewModel(pet: pet, modelContext: modelContext)
                            print("✅ Selected: \(pet.name)")
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pet.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 12) {
                                        Text("HP: \(pet.health ?? 0)%")
                                            .font(.caption)
                                        Text(pet.currentState.rawValue)
                                            .font(.caption)
                                        Text("\(pet.washDurationMinutes)m/\(pet.dryDurationMinutes)m")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .foregroundColor(.secondary)
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
                                if selectedPet?.id == pet.id {
                                    selectedPet = nil
                                    petViewModel = nil
                                }
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
                    Text("Step 4: Refresh Pet List")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
            }
            
            // Errors
            if petsViewModel.showError {
                Text(petsViewModel.errorMessage ?? "Unknown error")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - SettingsViewModel Section
    
    @ViewBuilder
    private func settingsViewModelSection(_ settingsViewModel: SettingsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current Settings
            if let settings = settingsViewModel.settings {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications: \(settings.notificationsEnabled ? "On" : "Off")")
                            .font(.caption)
                        Text("Appearance: \(settings.appearanceMode.rawValue)")
                            .font(.caption)
                        Text("Sounds: \(settings.soundsEnabled ? "On" : "Off")")
                            .font(.caption)
                        Text("Haptics: \(settings.hapticsEnabled ? "On" : "Off")")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Toggle Settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Toggle Settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Notifications", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { settingsViewModel.updateNotificationsEnabled($0) }
                        ))
                        
                        HStack {
                            Text("Appearance")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settings.appearanceMode },
                                set: { settingsViewModel.updateAppearanceMode($0) }
                            )) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Toggle("Sounds", isOn: Binding(
                            get: { settings.soundsEnabled },
                            set: { settingsViewModel.updateSoundsEnabled($0) }
                        ))
                        
                        Toggle("Haptics", isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settingsViewModel.updateHapticsEnabled($0) }
                        ))
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            // Errors
            if settingsViewModel.showError {
                Text(settingsViewModel.errorMessage ?? "Unknown error")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - PetViewModel Section
    
    @ViewBuilder
    private func petViewModelSection(_ viewModel: PetViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Testing: \(viewModel.pet.name)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Button("Deselect") {
                    selectedPet = nil
                    petViewModel = nil
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            // Pet State
            VStack(alignment: .leading, spacing: 8) {
                Text("Pet State")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health: \(viewModel.healthPercentage)%")
                            .font(.caption)
                        Text("State: \(viewModel.petState.rawValue)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(healthColor(viewModel.healthPercentage))
                        .frame(width: 20, height: 20)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Timer State
            VStack(alignment: .leading, spacing: 8) {
                Text("Timer State")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Active:")
                            .font(.caption)
                        Text(viewModel.timerActive ? "YES" : "NO")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.timerActive ? .green : .secondary)
                    }
                    
                    if viewModel.timerActive {
                        HStack {
                            Text("Type:")
                                .font(.caption)
                            Text(viewModel.timerType.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Remaining:")
                                .font(.caption)
                            Text(formatTime(viewModel.timeRemaining))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Task State
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Task")
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
            
            // Workflow Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Laundry Workflow")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("Start Cycle") {
                            viewModel.startCycle()
                        }
                        .buttonStyle(WorkflowButtonStyle(color: .blue, disabled: viewModel.timerActive))
                        .disabled(viewModel.timerActive)
                        
                        Button("Start Wash") {
                            viewModel.startWash()
                        }
                        .buttonStyle(WorkflowButtonStyle(color: .green, disabled: viewModel.timerActive))
                        .disabled(viewModel.timerActive)
                    }
                    
                    HStack(spacing: 8) {
                        Button("Start Dry") {
                            viewModel.startDry()
                        }
                        .buttonStyle(WorkflowButtonStyle(color: .orange, disabled: viewModel.timerActive))
                        .disabled(viewModel.timerActive)
                        
                        Button("Complete Cycle") {
                            viewModel.completeCycle()
                        }
                        .buttonStyle(WorkflowButtonStyle(color: .green, disabled: false))
                    }
                    
                    Button("Cancel Timer") {
                        viewModel.cancelTimer()
                    }
                    .buttonStyle(WorkflowButtonStyle(color: .red, disabled: !viewModel.timerActive))
                    .disabled(!viewModel.timerActive)
                }
            }
            
            // Errors
            if viewModel.showError {
                Text(viewModel.errorMessage ?? "Unknown error")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Active Timers Overview
    
    private var activeTimersOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CRITICAL: Verify timer independence")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Each pet's timer should count down independently")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let petsVM = petsViewModel {
                ForEach(petsVM.pets, id: \.id) { pet in
                    TimerStatusRow(pet: pet, modelContext: modelContext)
                }
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(8)
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Testing Flow:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("⚠️ Test pets use 1 min wash/dry for fast testing")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 6) {
                instructionRow("1", "Create 2-3 test pets")
                instructionRow("2", "Select first pet, start cycle")
                instructionRow("3", "Select second pet, start cycle")
                instructionRow("4", "Check timer overview - both running?")
                instructionRow("5", "Switch between pets - timers independent?")
                instructionRow("6", "Complete a full cycle on one pet")
                instructionRow("7", "Verify statistics updated")
                instructionRow("8", "Toggle settings, verify persistence")
            }
        }
    }
    
    @ViewBuilder
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clear all test data")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: resetAllData) {
                HStack {
                    Image(systemName: "trash.circle.fill")
                    Text("Reset All Data")
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            
            Text("⚠️ Deletes all pets, tasks, settings")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    private func resetAllData() {
        if let petsVM = petsViewModel {
            for pet in petsVM.pets {
                petsVM.deletePet(pet)
            }
        }
        
        selectedPet = nil
        petViewModel = nil
        testCounter = 0
        
        petsViewModel?.clearError()
        settingsViewModel?.clearError()
        
        print("✅ All data cleared")
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
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

// MARK: - Timer Status Row Component

struct TimerStatusRow: View {
    let pet: Pet
    let modelContext: ModelContext
    @StateObject private var timerChecker: TimerStatusChecker
    
    init(pet: Pet, modelContext: ModelContext) {
        self.pet = pet
        self.modelContext = modelContext
        _timerChecker = StateObject(wrappedValue: TimerStatusChecker(pet: pet, modelContext: modelContext))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if timerChecker.isActive {
                    Text("\(timerChecker.timerType.rawValue): \(formatTime(timerChecker.timeRemaining))")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("No active timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if timerChecker.isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(timerChecker.isActive ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Timer Status Checker

@MainActor
class TimerStatusChecker: ObservableObject {
    @Published var isActive: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerType: SimpleTimerType = .cycle
    
    private let petTimerService: PetTimerService
    private var cancellables: Set<AnyCancellable> = []
    
    init(pet: Pet, modelContext: ModelContext) {
        self.petTimerService = PetTimerService(petID: pet.id)
        
        petTimerService.$isActive
            .assign(to: &$isActive)
        
        petTimerService.$timeRemaining
            .assign(to: &$timeRemaining)
        
        petTimerService.$timerType
            .assign(to: &$timerType)
    }
}

// MARK: - Workflow Button Style

struct WorkflowButtonStyle: ButtonStyle {
    let color: Color
    let disabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(color.opacity(disabled ? 0.3 : 0.8))
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    TestViewModelsView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
