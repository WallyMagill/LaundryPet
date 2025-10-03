//
//  PetCardView.swift
//  LaundryPets
//
//  Individual pet card component displaying pet state, health, and timer information
//  Features real-time updates, beautiful styling, and accessibility support
//

import SwiftUI
import SwiftData

struct PetCardView: View {
    // MARK: - Properties
    
    let pet: Pet
    let modelContext: ModelContext
    @ObservedObject var petViewModel: PetViewModel
    let petsViewModel: PetsViewModel
    
    // MARK: - Initialization
    
    init(pet: Pet, modelContext: ModelContext, petViewModel: PetViewModel, petsViewModel: PetsViewModel) {
        self.pet = pet
        self.modelContext = modelContext
        self.petViewModel = petViewModel
        self.petsViewModel = petsViewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink(destination: PetDetailView(pet: pet, modelContext: modelContext, petViewModel: petViewModel, petsViewModel: petsViewModel)) {
            cardContent
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBackground)
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pet.name), health \(petViewModel.healthPercentage) percent")
        .accessibilityHint("Double tap to view pet details")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            petStateIconView
            petInformationView
            Spacer()
            statusIndicatorView
        }
        .padding(20)
    }
    
    // MARK: - Card Components
    
    private var petStateIconView: some View {
        VStack {
            Image(systemName: petStateIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(petStateColor)
                .frame(width: 50, height: 50)
                .background(iconBackground)
        }
    }
    
    private var iconBackground: some View {
        Circle()
            .fill(petStateColor.opacity(0.15))
            .overlay(
                Circle()
                    .stroke(petStateColor.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var petInformationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pet Name
            Text(pet.name)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Health/Status with better styling
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(healthOrStatusText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            // Timer Information - Removed "Time left" text
        }
    }
    
    private var statusIndicatorView: some View {
        VStack(spacing: 4) {
            // Health percentage or timer progress
            if petViewModel.timerActive {
                Text(formatTime(petViewModel.timeRemaining))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(petStateColor)
                    .monospacedDigit()
            } else {
                Text("\(petViewModel.healthPercentage)%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(petStateColor)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(petStateColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    /// Pet state icon based on current state
    private var petStateIcon: String {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return "washer.fill"
            case .washComplete:
                return "arrow.right.circle.fill"
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
    
    /// Icon based on health level
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
    
    /// Pet state color based on current state
    private var petStateColor: Color {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return .blue
            case .washComplete:
                return .green
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
    
    /// Color based on health level
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
    
    /// Health or status text based on current state
    private var healthOrStatusText: String {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return "Washing"
            case .washComplete:
                return "Move to Dryer"
            case .drying:
                return "Drying"
            case .dryComplete:
                return "Fold Me"
            default:
                return "Health \(petViewModel.healthPercentage)%"
            }
        } else {
            return "Health \(petViewModel.healthPercentage)%"
        }
    }
    
    /// Status color based on current state
    private var statusColor: Color {
        if let task = petViewModel.currentTask, !task.isCompleted {
            switch task.currentStage {
            case .washing:
                return .blue
            case .washComplete:
                return .green
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
    
    // Timer information text removed - timer now only displays on the right side
    
    /// Formats time remaining for display
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Calculates time until next wash is needed
    private func calculateTimeUntilNextWash() -> String {
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

// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    let samplePet = Pet(name: "Fluffy", cycleFrequencyDays: 7)
    let petViewModel = PetViewModel(pet: samplePet, modelContext: modelContext)
    let petsViewModel = PetsViewModel(modelContext: modelContext)
    
    PetCardView(pet: samplePet, modelContext: modelContext, petViewModel: petViewModel, petsViewModel: petsViewModel)
        .padding()
}
