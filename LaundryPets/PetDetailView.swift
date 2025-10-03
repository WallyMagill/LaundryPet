//
//  PetDetailView.swift
//  LaundryPets
//
//  Detailed view for individual pet management and laundry workflow
//

import SwiftUI
import SwiftData

struct PetDetailView: View {
    let pet: Pet
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var petViewModel: PetViewModel
    @State private var showingSettings = false
    @State private var showingEditName = false
    @State private var newPetName = ""
    
    init(pet: Pet, modelContext: ModelContext) {
        self.pet = pet
        self.modelContext = modelContext
        self._petViewModel = StateObject(wrappedValue: PetViewModel(pet: pet, modelContext: modelContext))
        self._newPetName = State(initialValue: pet.name)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // MARK: - Pet Status Section
                petStatusSection
                
                // MARK: - Health Section
                healthSection
                
                // MARK: - Laundry Workflow Section
                laundryWorkflowSection
                
                // MARK: - Statistics Section
                statisticsSection
                
                // MARK: - Quick Actions Section
                quickActionsSection
                
                // Bottom padding
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            PetSettingsView(pet: pet, modelContext: modelContext)
        }
        .alert("Edit Pet Name", isPresented: $showingEditName) {
            TextField("Pet Name", text: $newPetName)
            Button("Save") {
                if !newPetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    _ = petViewModel.updatePetName(newPetName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            Button("Cancel", role: .cancel) {
                newPetName = pet.name
            }
        } message: {
            Text("Enter a new name for \(pet.name)")
        }
        .alert("Error", isPresented: $petViewModel.showError) {
            Button("OK") {
                petViewModel.clearError()
            }
        } message: {
            Text(petViewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Pet Status Section
    
    private var petStatusSection: some View {
        VStack(spacing: 16) {
            // Large Pet State Icon
            Image(systemName: petStateIcon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(petStateColor)
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(petStateColor.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(petStateColor.opacity(0.3), lineWidth: 3)
                        )
                )
                .shadow(color: petStateColor.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Pet State Text
            Text(petStateText)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Health Section
    
    private var healthSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Health")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(petViewModel.healthPercentage)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(healthColor)
            }
            
            // Health Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(healthColor)
                        .frame(width: geometry.size.width * CGFloat(petViewModel.healthPercentage) / 100, height: 12)
                        .cornerRadius(6)
                        .animation(.easeInOut(duration: 0.5), value: petViewModel.healthPercentage)
                }
            }
            .frame(height: 12)
            
            // Health Info
            VStack(spacing: 8) {
                if let lastLaundry = pet.lastLaundryDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Last laundry: \(timeSinceLastLaundry(from: lastLaundry))")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Next laundry: \(timeUntilNextWash())")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Laundry Workflow Section
    
    private var laundryWorkflowSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Laundry Status")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                
                if let task = petViewModel.currentTask, !task.isCompleted {
                    Image(systemName: "washer.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            
            // Current Stage Display
            VStack(spacing: 12) {
                Text(currentStageText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Timer Display
                if petViewModel.timerActive {
                    Text(petViewModel.getFormattedTimeRemaining())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 12)
            
            // Action Buttons
            actionButtonsView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if let task = petViewModel.currentTask, !task.isCompleted {
                // Primary Action Button
                Button(action: primaryAction) {
                    Text(primaryActionText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(primaryActionColor)
                        .cornerRadius(12)
                }
                .disabled(!primaryActionEnabled)
                .opacity(primaryActionEnabled ? 1.0 : 0.6)
                
                // Secondary Action Button (for dryComplete stage)
                if task.currentStage == .dryComplete {
                    Button(action: {
                        _ = petViewModel.addMoreDryTime(additionalMinutes: 10)
                    }) {
                        Text("Dry 10 More Minutes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Cancel Button (if timer is active)
                if petViewModel.timerActive {
                    Button(action: {
                        petViewModel.cancelTimer()
                    }) {
                        Text("Cancel Timer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            } else {
                // No active task - Start new cycle
                Button(action: {
                    petViewModel.startCycle()
                }) {
                    Text("Start New Laundry Cycle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Cycles",
                    value: "\(pet.totalCyclesCompleted)",
                    icon: "repeat.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(pet.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Best Streak",
                    value: "\(pet.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Days Since Created",
                    value: "\(daysSinceCreated)",
                    icon: "calendar.circle.fill",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                QuickActionRow(
                    icon: "pencil",
                    title: "Edit Pet Name",
                    subtitle: "Change \(pet.name)'s name",
                    action: {
                        showingEditName = true
                    }
                )
                
                QuickActionRow(
                    icon: "gear",
                    title: "Pet Settings",
                    subtitle: "Manage cycle frequency and timers",
                    action: {
                        showingSettings = true
                    }
                )
                
                QuickActionRow(
                    icon: "chart.bar.fill",
                    title: "View History",
                    subtitle: "See detailed laundry history",
                    action: {
                        // TODO: Implement history view
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties
    
    private var petStateIcon: String {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return "washer.fill"
            case .drying:
                return "fan.fill"
            case .dryComplete:
                return "hand.raised.fill"
            default:
                return healthBasedIcon
            }
        } else {
            return healthBasedIcon
        }
    }
    
    private var healthBasedIcon: String {
        switch petViewModel.petState {
        case .happy, .neutral:
            return "face.smiling"
        case .sad, .verySad:
            return "face.dashed"
        case .dead:
            return "xmark.circle.fill"
        }
    }
    
    private var petStateColor: Color {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return .blue
            case .drying:
                return .orange
            case .dryComplete:
                return .purple
            default:
                return healthColor
            }
        } else {
            return healthColor
        }
    }
    
    private var healthColor: Color {
        switch petViewModel.petState {
        case .happy:
            return .green
        case .neutral:
            return .blue
        case .sad:
            return .orange
        case .verySad:
            return .red
        case .dead:
            return .red
        }
    }
    
    private var petStateText: String {
        if let task = petViewModel.currentTask, !task.isCompleted {
            return task.currentStage.displayText
        } else {
            return "\(pet.name) \(petViewModel.petState.displayText)"
        }
    }
    
    private var currentStageText: String {
        guard let task = petViewModel.currentTask, !task.isCompleted else {
            return "Ready to start a new laundry cycle"
        }
        return task.currentStage.displayText
    }
    
    private var primaryActionText: String {
        guard let task = petViewModel.currentTask, !task.isCompleted else {
            return "Start New Cycle"
        }
        return task.currentStage.actionButtonText
    }
    
    private var primaryActionColor: Color {
        guard let task = petViewModel.currentTask, !task.isCompleted else {
            return .blue
        }
        switch task.currentStage {
        case .cycle, .washComplete, .dryComplete, .completed:
            return .blue
        case .washing, .drying:
            return .gray
        }
    }
    
    private var primaryActionEnabled: Bool {
        guard let task = petViewModel.currentTask, !task.isCompleted else {
            return true
        }
        return task.currentStage.isActionable
    }
    
    private var daysSinceCreated: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: pet.createdDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    // MARK: - Actions
    
    private func primaryAction() {
        guard let task = petViewModel.currentTask, !task.isCompleted else {
            petViewModel.startCycle()
            return
        }
        
        switch task.currentStage {
        case .cycle:
            petViewModel.startWash()
        case .washComplete:
            petViewModel.startDry()
        case .dryComplete:
            petViewModel.completeCycle()
        case .completed:
            petViewModel.completeCycle()
        default:
            break
        }
    }
    
    private func timeSinceLastLaundry(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: date, to: Date())
        
        if let days = components.day, days > 0 {
            if days == 1 {
                return "1 day ago"
            } else {
                return "\(days) days ago"
            }
        } else if let hours = components.hour, hours > 0 {
            if hours == 1 {
                return "1 hour ago"
            } else {
                return "\(hours) hours ago"
            }
        } else {
            return "Just now"
        }
    }
    
    private func timeUntilNextWash() -> String {
        guard let lastLaundry = pet.lastLaundryDate else {
            return "Overdue"
        }
        
        let cycleDuration = TimeInterval(pet.cycleFrequencyDays * 24 * 60 * 60)
        let nextWashDate = lastLaundry.addingTimeInterval(cycleDuration)
        let timeRemaining = nextWashDate.timeIntervalSinceNow
        
        if timeRemaining <= 0 {
            return "Overdue"
        } else {
            let days = Int(timeRemaining / 86400)
            let hours = Int((timeRemaining.truncatingRemainder(dividingBy: 86400)) / 3600)
            
            if days > 0 {
                return "\(days)d \(hours)h"
            } else {
                return "\(hours)h"
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PetSettingsView

struct PetSettingsView: View {
    let pet: Pet
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var petViewModel: PetViewModel
    @State private var cycleFrequency: Int
    @State private var washDuration: Int
    @State private var dryDuration: Int
    @State private var showingResetConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(pet: Pet, modelContext: ModelContext) {
        self.pet = pet
        self.modelContext = modelContext
        self._petViewModel = StateObject(wrappedValue: PetViewModel(pet: pet, modelContext: modelContext))
        self._cycleFrequency = State(initialValue: pet.cycleFrequencyDays)
        self._washDuration = State(initialValue: pet.washDurationMinutes)
        self._dryDuration = State(initialValue: pet.dryDurationMinutes)
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
                        Text(pet.name)
                            .foregroundColor(.secondary)
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
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.orange)
                        Text("Cycle Frequency")
                        Spacer()
                        Picker("Cycle Frequency", selection: $cycleFrequency) {
                            ForEach(1...30, id: \.self) { days in
                                Text("\(days) day\(days == 1 ? "" : "s")").tag(days)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: cycleFrequency) { _, newValue in
                            saveCycleFrequency(newValue)
                        }
                    }
                }
                
                // MARK: - Timer Settings Section
                Section(
                    header: Text("Timer Settings"),
                    footer: Text("Customize how long each stage takes. These settings affect new laundry cycles.")
                ) {
                    // Wash Duration
                    HStack {
                        Image(systemName: "washer")
                            .foregroundColor(.blue)
                        Text("Wash Duration")
                        Spacer()
                        Picker("Wash Duration", selection: $washDuration) {
                            ForEach(Array(stride(from: 5, through: 120, by: 5)), id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: washDuration) { _, newValue in
                            saveWashDuration(newValue)
                        }
                    }
                    
                    // Dry Duration
                    HStack {
                        Image(systemName: "fan")
                            .foregroundColor(.orange)
                        Text("Dry Duration")
                        Spacer()
                        Picker("Dry Duration", selection: $dryDuration) {
                            ForEach(Array(stride(from: 10, through: 180, by: 10)), id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: dryDuration) { _, newValue in
                            saveDryDuration(newValue)
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
                        Text("\(pet.totalCyclesCompleted)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        Text("Current Streak")
                        Spacer()
                        Text("\(pet.currentStreak)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "trophy")
                            .foregroundColor(.yellow)
                        Text("Best Streak")
                        Spacer()
                        Text("\(pet.longestStreak)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                        Text("Current Health")
                        Spacer()
                        Text("\(petViewModel.healthPercentage)%")
                            .foregroundColor(healthColor)
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
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.orange)
                    
                    Button("Delete Pet") {
                        // TODO: Implement pet deletion
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
        .alert("Reset Statistics", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetStatistics()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all statistics for \(pet.name) including total cycles, streaks, and health. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthColor: Color {
        switch petViewModel.petState {
        case .happy:
            return .green
        case .neutral:
            return .blue
        case .sad:
            return .orange
        case .verySad:
            return .red
        case .dead:
            return .red
        }
    }
    
    // MARK: - Actions
    
    private func saveCycleFrequency(_ newValue: Int) {
        do {
            pet.cycleFrequencyDays = newValue
            try modelContext.save()
            print("✅ Updated cycle frequency to \(newValue) days")
        } catch {
            print("❌ Failed to update cycle frequency: \(error)")
            errorMessage = "Failed to update cycle frequency. Please try again."
            showingError = true
            // Revert the picker selection
            cycleFrequency = pet.cycleFrequencyDays
        }
    }
    
    private func saveWashDuration(_ newValue: Int) {
        do {
            pet.washDurationMinutes = newValue
            try modelContext.save()
            print("✅ Updated wash duration to \(newValue) minutes")
        } catch {
            print("❌ Failed to update wash duration: \(error)")
            errorMessage = "Failed to update wash duration. Please try again."
            showingError = true
            // Revert the picker selection
            washDuration = pet.washDurationMinutes
        }
    }
    
    private func saveDryDuration(_ newValue: Int) {
        do {
            pet.dryDurationMinutes = newValue
            try modelContext.save()
            print("✅ Updated dry duration to \(newValue) minutes")
        } catch {
            print("❌ Failed to update dry duration: \(error)")
            errorMessage = "Failed to update dry duration. Please try again."
            showingError = true
            // Revert the picker selection
            dryDuration = pet.dryDurationMinutes
        }
    }
    
    private func resetStatistics() {
        do {
            pet.totalCyclesCompleted = 0
            pet.currentStreak = 0
            pet.longestStreak = 0
            pet.lastLaundryDate = nil
            
            // Reset health to default
            pet.health = 100
            pet.currentState = .happy
            
            try modelContext.save()
            print("✅ Reset statistics for \(pet.name)")
            
            // Refresh the pet view model
            petViewModel.refreshPetData()
            
        } catch {
            print("❌ Failed to reset statistics: \(error)")
            errorMessage = "Failed to reset statistics. Please try again."
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    let samplePet = Pet(name: "Fluffy", cycleFrequencyDays: 7)
    
    return NavigationView {
        PetDetailView(pet: samplePet, modelContext: modelContext)
    }
}
