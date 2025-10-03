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
    
    // Testing progress tracking
    @State private var petsCreated: Bool = false
    @State private var petSelected: Bool = false
    @State private var cycleStarted: Bool = false
    @State private var settingsTested: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Quick Start Guide
                Section {
                    quickStartGuide
                } header: {
                    Text("🚀 Quick Start")
                        .font(.headline)
                }
                
                // Section 1: Test PetsViewModel
                if let petsViewModel = petsViewModel {
                    Section {
                        petsViewModelSection(petsViewModel)
                    } header: {
                        HStack {
                            Text("1️⃣ Test Multi-Pet Management")
                                .font(.headline)
                            Spacer()
                            if petsCreated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Section 2: Test SettingsViewModel
                if let settingsViewModel = settingsViewModel, settingsViewModel.settings != nil {
                    Section {
                        settingsViewModelSection(settingsViewModel)
                    } header: {
                        HStack {
                            Text("2️⃣ Test Settings Persistence")
                                .font(.headline)
                            Spacer()
                            if settingsTested {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Section 3: Test PetViewModel
                if let petViewModel = petViewModel {
                    Section {
                        petViewModelSection(petViewModel)
                    } header: {
                        HStack {
                            Text("3️⃣ Test Pet Workflow")
                                .font(.headline)
                            Spacer()
                            if cycleStarted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Active Timers Overview - CRITICAL TEST
                if let petsVM = petsViewModel, !petsVM.pets.isEmpty {
                    Section {
                        activeTimersOverview
                    } header: {
                        Text("⚠️ CRITICAL: Multi-Pet Timer Independence")
                            .font(.headline)
                            .foregroundColor(.orange)
                    } footer: {
                        Text("This is the MOST IMPORTANT test. Each pet must have its own independent timer.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Testing Progress Summary
                Section {
                    testingProgressSummary
                } header: {
                    Text("📊 Testing Progress")
                        .font(.headline)
                }
                
                // Reset
                Section {
                    resetSection
                } header: {
                    Text("🗑️ Reset & Start Over")
                        .font(.headline)
                }
            }
            .navigationTitle("Phase 2 Testing")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Quick Start Guide
    
    private var quickStartGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow these steps in order:")
                .font(.subheadline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                guideStep("1", "Create 2-3 test pets below", completed: petsCreated)
                guideStep("2", "Toggle settings to test persistence", completed: settingsTested)
                guideStep("3", "Select a pet and start a cycle", completed: petSelected)
                guideStep("4", "Start cycles on multiple pets", completed: cycleStarted)
                guideStep("5", "Verify timers run independently", completed: false)
            }
            
            Text("⏱️ Timers are set to 1 minute for quick testing")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func guideStep(_ number: String, _ text: String, completed: Bool) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(completed ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                if completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(completed ? .secondary : .primary)
                .strikethrough(completed)
        }
    }
    
    // MARK: - Testing Progress Summary
    
    private var testingProgressSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                progressIndicator(
                    title: "Pets Created",
                    completed: petsCreated,
                    icon: "person.3.fill"
                )
                progressIndicator(
                    title: "Settings Tested",
                    completed: settingsTested,
                    icon: "gearshape.fill"
                )
            }
            
            HStack(spacing: 20) {
                progressIndicator(
                    title: "Pet Selected",
                    completed: petSelected,
                    icon: "hand.point.up.left.fill"
                )
                progressIndicator(
                    title: "Cycle Started",
                    completed: cycleStarted,
                    icon: "timer"
                )
            }
            
            let totalProgress = [petsCreated, settingsTested, petSelected, cycleStarted].filter { $0 }.count
            ProgressView(value: Double(totalProgress), total: 4.0)
                .tint(.green)
            
            Text("\(totalProgress) of 4 core tests completed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func progressIndicator(title: String, completed: Bool, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(completed ? .green : .gray)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(completed ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - PetsViewModel Section
    
    @ViewBuilder
    private func petsViewModelSection(_ petsViewModel: PetsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current Status
            statusBox(
                title: "Pets in Database",
                value: "\(petsViewModel.pets.count)",
                color: .blue,
                icon: "person.3.fill"
            )
            
            // Step 1: Create Pet Button
            actionButton(
                title: "Create Test Pet",
                subtitle: "1 min wash/dry timers",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                testCounter += 1
                if let newPet = petsViewModel.createPet(name: "Test Pet \(testCounter)", cycleFrequencyDays: 7) {
                    newPet.washDurationMinutes = 1
                    newPet.dryDurationMinutes = 1
                    try? modelContext.save()
                    petsCreated = true
                    print("✅ Created pet with 1 min wash/dry")
                }
            }
            
            // Pet List
            if petsViewModel.pets.isEmpty {
                infoBox(
                    text: "No pets yet. Create your first test pet above!",
                    color: .orange
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a pet to test:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(petsViewModel.pets, id: \.id) { pet in
                        petCard(pet: pet, petsViewModel: petsViewModel)
                    }
                }
            }
            
            // Refresh Button
            actionButton(
                title: "Refresh Pet List",
                subtitle: "Reload from database",
                icon: "arrow.clockwise",
                color: .green
            ) {
                petsViewModel.refreshPets()
            }
            
            // Error Display
            if petsViewModel.showError {
                errorBox(message: petsViewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    @ViewBuilder
    private func petCard(pet: Pet, petsViewModel: PetsViewModel) -> some View {
        Button(action: {
            selectedPet = pet
            petViewModel = PetViewModel(pet: pet, modelContext: modelContext)
            petSelected = true
            print("✅ Selected: \(pet.name)")
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pet.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label("\(pet.health ?? 0)%", systemImage: "heart.fill")
                            .font(.caption)
                        Label(pet.currentState.rawValue, systemImage: "face.smiling")
                            .font(.caption)
                        Label("\(pet.washDurationMinutes)m/\(pet.dryDurationMinutes)m", systemImage: "timer")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedPet?.id == pet.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(selectedPet?.id == pet.id ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                petsViewModel.deletePet(pet)
                if selectedPet?.id == pet.id {
                    selectedPet = nil
                    petViewModel = nil
                    petSelected = false
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - SettingsViewModel Section
    
    @ViewBuilder
    private func settingsViewModelSection(_ settingsViewModel: SettingsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            infoBox(
                text: "Toggle these settings. Force quit the app and reopen to verify they persist.",
                color: .blue
            )
            
            if let settings = settingsViewModel.settings {
                VStack(spacing: 16) {
                    // Notifications
                    settingToggle(
                        title: "Notifications",
                        icon: "bell.fill",
                        isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: {
                                settingsViewModel.updateNotificationsEnabled($0)
                                settingsTested = true
                            }
                        )
                    )
                    
                    // Appearance
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Appearance")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.appearanceMode },
                            set: {
                                settingsViewModel.updateAppearanceMode($0)
                                settingsTested = true
                            }
                        )) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Sounds
                    settingToggle(
                        title: "Sounds",
                        icon: "speaker.wave.2.fill",
                        isOn: Binding(
                            get: { settings.soundEnabled },
                            set: {
                                settingsViewModel.updateSoundsEnabled($0)
                                settingsTested = true
                            }
                        )
                    )
                    
                    // Haptics
                    settingToggle(
                        title: "Haptics",
                        icon: "hand.tap.fill",
                        isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: {
                                settingsViewModel.updateHapticsEnabled($0)
                                settingsTested = true
                            }
                        )
                    )
                }
            }
            
            // Error Display
            if settingsViewModel.showError {
                errorBox(message: settingsViewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    @ViewBuilder
    private func settingToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(title)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: isOn)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - PetViewModel Section
    
    @ViewBuilder
    private func petViewModelSection(_ viewModel: PetViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with deselect
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Testing: \(viewModel.pet.name)")
                        .font(.headline)
                    Text("Follow the workflow below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    selectedPet = nil
                    petViewModel = nil
                    petSelected = false
                }) {
                    Label("Deselect", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Pet Stats
            HStack(spacing: 12) {
                statBox(
                    title: "Health",
                    value: "\(viewModel.healthPercentage)%",
                    color: healthColor(viewModel.healthPercentage),
                    icon: "heart.fill"
                )
                statBox(
                    title: "State",
                    value: viewModel.petState.rawValue,
                    color: .blue,
                    icon: "face.smiling"
                )
                statBox(
                    title: "Cycles",
                    value: "\(viewModel.pet.totalCyclesCompleted)",
                    color: .purple,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            
            // Timer Status
            if viewModel.timerActive {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                        Text("TIMER ACTIVE")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Spacer()
                        Text(formatTime(viewModel.timeRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .monospacedDigit()
                    }
                    
                    Text("Type: \(viewModel.timerType.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                infoBox(text: "No active timer", color: .gray)
            }
            
            // Task Info
            if let task = viewModel.currentTask {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(.purple)
                    Text("Current Stage: \(task.currentStage.rawValue)")
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            Divider()
            
            // Workflow Buttons
            Text("Laundry Workflow:")
                .font(.subheadline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                workflowButton(
                    title: "Start Cycle",
                    subtitle: "Creates task & starts wash",
                    icon: "play.circle.fill",
                    color: .blue,
                    disabled: viewModel.timerActive
                ) {
                    viewModel.startCycle()
                    cycleStarted = true
                }
                
                workflowButton(
                    title: "Start Wash",
                    subtitle: "Begin wash phase",
                    icon: "drop.fill",
                    color: .cyan,
                    disabled: viewModel.timerActive
                ) {
                    viewModel.startWash()
                }
                
                workflowButton(
                    title: "Start Dry",
                    subtitle: "Begin dry phase",
                    icon: "flame.fill",
                    color: .orange,
                    disabled: viewModel.timerActive
                ) {
                    viewModel.startDry()
                }
                
                workflowButton(
                    title: "Complete Cycle",
                    subtitle: "Mark laundry done",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    disabled: false
                ) {
                    viewModel.completeCycle()
                }
                
                workflowButton(
                    title: "Cancel Timer",
                    subtitle: "Stop current timer",
                    icon: "xmark.circle.fill",
                    color: .red,
                    disabled: !viewModel.timerActive
                ) {
                    viewModel.cancelTimer()
                }
            }
            
            // Error Display
            if viewModel.showError {
                errorBox(message: viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Active Timers Overview
    
    private var activeTimersOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Test Objective: Verify Timer Independence")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text("Start cycles on 2+ pets. Each timer should count down independently without affecting the others.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            if let petsVM = petsViewModel {
                if petsVM.pets.isEmpty {
                    infoBox(text: "Create pets first to test timers", color: .orange)
                } else {
                    ForEach(petsVM.pets, id: \.id) { pet in
                        TimerStatusRow(pet: pet, modelContext: modelContext)
                    }
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
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
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Deletes all pets, tasks & resets settings")
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
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
        petsCreated = false
        petSelected = false
        cycleStarted = false
        settingsTested = false
        
        petsViewModel?.clearError()
        settingsViewModel?.clearError()
        
        print("✅ All data cleared")
    }
    
    // MARK: - Reusable Components
    
    @ViewBuilder
    private func statusBox(title: String, value: String, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func statBox(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func actionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func workflowButton(title: String, subtitle: String, icon: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                }
                Spacer()
                if disabled {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(disabled ? Color.gray.opacity(0.1) : color.opacity(0.15))
            .foregroundColor(disabled ? .gray : color)
            .cornerRadius(12)
        }
        .disabled(disabled)
    }
    
    @ViewBuilder
    private func infoBox(text: String, color: Color) -> some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func errorBox(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                if timerChecker.isActive {
                    HStack(spacing: 8) {
                        Text(timerChecker.timerType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("•")
                            .foregroundColor(.gray)
                        Text(formatTime(timerChecker.timeRemaining))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("No active timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if timerChecker.isActive {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }
        .padding()
        .background(timerChecker.isActive ? Color.green.opacity(0.05) : Color.gray.opacity(0.02))
        .cornerRadius(12)
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

// MARK: - Preview

#Preview {
    TestViewModelsView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}

