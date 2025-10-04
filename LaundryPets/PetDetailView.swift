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
    
    @ObservedObject var petViewModel: PetViewModel
    let petsViewModel: PetsViewModel
    @State private var showingSettings = false
    @State private var selectedExtraDryTime: Int = 10
    
    // Cached computed values to prevent recalculation during scrolling
    @State private var cachedDaysSinceCreated: Int = 0
    @State private var cachedPetStateIcon: String = "face.smiling"
    @State private var cachedPetStateColor: Color = .green
    @State private var cachedPetStateText: String = ""
    
    init(pet: Pet, modelContext: ModelContext, petViewModel: PetViewModel, petsViewModel: PetsViewModel) {
        self.pet = pet
        self.modelContext = modelContext
        self.petViewModel = petViewModel
        self.petsViewModel = petsViewModel
    }
    
    // Cache expensive computed values on appear
    private func updateCachedValues() {
        cachedDaysSinceCreated = calculateDaysSinceCreated()
        cachedPetStateIcon = calculatePetStateIcon()
        cachedPetStateColor = calculatePetStateColor()
        cachedPetStateText = calculatePetStateText()
    }
    
    var body: some View {
        ScrollView {
            // CRITICAL FIX: Replace LazyVStack with VStack to eliminate layout overhead
            VStack(spacing: 24) {
                // MARK: - Pet Status Section
                petStatusSection
                
                // MARK: - Health Section
                healthSection
                
                // MARK: - Laundry Workflow Section
                laundryWorkflowSection
                
                // MARK: - Statistics Section
                statisticsSection
                
                
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
            PetSettingsView(pet: pet, modelContext: modelContext, petViewModel: petViewModel, petsViewModel: petsViewModel)
        }
        .alert("Error", isPresented: $petViewModel.showError) {
            Button("OK") {
                petViewModel.clearError()
            }
        } message: {
            Text(petViewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            updateCachedValues()
        }
        .onChange(of: petViewModel.currentTask) { oldValue, newValue in
            // Only update if the task actually changed
            guard oldValue?.id != newValue?.id else { return }
            updateCachedValues()
        }
        .onChange(of: petViewModel.petState) { oldValue, newValue in
            // Only update if the state actually changed
            guard oldValue != newValue else { return }
            updateCachedValues()
        }
    }
    
    // MARK: - Pet Status Section
    
    private var petStatusSection: some View {
        VStack(spacing: 16) {
            // Large Pet State Icon - Optimized for performance
            Image(systemName: cachedPetStateIcon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(cachedPetStateColor)
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(cachedPetStateColor.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(cachedPetStateColor.opacity(0.3), lineWidth: 3)
                        )
                )
                .shadow(color: cachedPetStateColor.opacity(0.2), radius: 10, x: 0, y: 5)
                // REMOVED: .drawingGroup() - causes excessive memory allocation
            
            // Pet State Text
            Text(cachedPetStateText)
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
                    .foregroundColor(healthBarColor)
            }
            
            // Health Bar - Redesigned for accuracy and efficiency
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar (always full width)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Health bar (width based on percentage)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(healthBarColor)
                        .frame(width: geometry.size.width * CGFloat(petViewModel.healthPercentage) / 100, height: 12)
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
                
                // Timer Display - Simplified for performance
                if petViewModel.timerActive {
                    Text(formatTime(petViewModel.timeRemaining))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                        // REMOVED: .equatable() and .id() - causes excessive view recreation
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
                
                // Extra Dry Time Picker (for dryComplete stage)
                if task.currentStage == .dryComplete {
                    VStack(spacing: 8) {
                        Button(action: {
                            _ = petViewModel.addMoreDryTime(additionalMinutes: selectedExtraDryTime)
                        }) {
                            Text("Dry More")
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Extra Dry Time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Picker("", selection: $selectedExtraDryTime) {
                                ForEach(1...120, id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                        }
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
            
            // CRITICAL FIX: Replace LazyVGrid with VStack for better performance
            VStack(spacing: 16) {
                HStack(spacing: 16) {
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
                }
                
                HStack(spacing: 16) {
                    StatCard(
                        title: "Best Streak",
                        value: "\(pet.longestStreak)",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                    
                    StatCard(
                        title: "Days Since Created",
                        value: "\(cachedDaysSinceCreated)",
                        icon: "calendar.circle.fill",
                        color: .green
                    )
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
    
    
    // MARK: - Helper Methods
    
    /// Health bar color based on health percentage (more accurate than pet state)
    private var healthBarColor: Color {
        let health = petViewModel.healthPercentage
        switch health {
        case 80...100:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        case 20..<40:
            return .red
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Computed Properties
    
    private func calculatePetStateIcon() -> String {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return "washer.fill"
            case .drying:
                return "fan.fill"
            case .dryComplete:
                return "hand.raised.fill"
            default:
                return calculateHealthBasedIcon()
            }
        } else {
            return calculateHealthBasedIcon()
        }
    }
    
    private func calculateHealthBasedIcon() -> String {
        switch petViewModel.petState {
        case .happy, .neutral:
            return "face.smiling"
        case .sad, .verySad:
            return "face.dashed"
        case .dead:
            return "xmark.circle.fill"
        }
    }
    
    private func calculatePetStateColor() -> Color {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return .blue
            case .drying:
                return .orange
            case .dryComplete:
                return .purple
            default:
                return calculateHealthColor()
            }
        } else {
            return calculateHealthColor()
        }
    }
    
    private func calculateHealthColor() -> Color {
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
    
    private func calculatePetStateText() -> String {
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
    
    private func calculateDaysSinceCreated() -> Int {
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



// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    let samplePet = Pet(name: "Fluffy", cycleFrequencyDays: 7)
    let petsViewModel = PetsViewModel(modelContext: modelContext)
    
    NavigationView {
        PetDetailView(pet: samplePet, modelContext: modelContext, petViewModel: PetViewModel(pet: samplePet, modelContext: modelContext), petsViewModel: petsViewModel)
    }
}
