//
//  TestModelsView.swift
//  LaundryPets
//
//  Simple test view to verify SwiftData models work correctly
//  ⚠️ TEMPORARY - Phase 1 testing only, will be replaced with real views
//

import SwiftUI
import SwiftData

struct TestModelsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Pet.createdDate) private var pets: [Pet]
    
    // MARK: - Services
    
    @State private var petService: PetService?
    
    // MARK: - State
    
    @State private var showHealthAlert = false
    @State private var healthAlertMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Create Test Pet Button
                Button(action: createTestPet) {
                    Label("Create Test Pet", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Test Buttons Section
                if !pets.isEmpty {
                    VStack(spacing: 12) {
                        Text("Testing Tools")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Button(action: setPetToYesterday) {
                                VStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.minus")
                                    Text("Yesterday")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            }
                            
                            Button(action: calculateHealth) {
                                VStack(spacing: 4) {
                                    Image(systemName: "heart.text.square")
                                    Text("Calculate")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: completeCycle) {
                                VStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                    Text("Complete")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                            
                            Button(action: setToSevenDaysAgo) {
                                VStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                    Text("7 Days (Death)")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Pet List
                if pets.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No pets yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'Create Test Pet' to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                } else {
                    List {
                        ForEach(pets) { pet in
                            VStack(alignment: .leading, spacing: 8) {
                                // Name and Health
                                HStack {
                                    Text(pet.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if let health = pet.health {
                                        Text("\(health)%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(healthColor(health))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(healthColor(health).opacity(0.2))
                                            .cornerRadius(8)
                                    } else {
                                        Text("No health")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // State Display
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(stateColor(pet.currentState))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(pet.currentState.displayText)
                                        .font(.subheadline)
                                        .foregroundColor(stateColor(pet.currentState))
                                }
                                
                                // Last Laundry Date
                                if let lastLaundry = pet.lastLaundryDate {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                        Text("Last laundry: \(relativeTime(from: lastLaundry))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                        Text("Never done laundry")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Cycle Frequency
                                HStack {
                                    Image(systemName: "repeat")
                                        .font(.caption2)
                                    Text("Cycle: \(pet.cycleFrequencyDays) day\(pet.cycleFrequencyDays == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deletePets)
                    }
                }
                
                // Delete All Button
                if !pets.isEmpty {
                    Button(action: deleteAllPets) {
                        Label("Delete All Pets", systemImage: "trash.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("SwiftData Model Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(pets.count) pet\(pets.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                // Initialize PetService with model context
                if petService == nil {
                    petService = PetService(modelContext: modelContext)
                    print("✅ PetService initialized")
                }
            }
            .alert("Health Calculation", isPresented: $showHealthAlert) {
                Button("OK") { }
            } message: {
                Text(healthAlertMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Creates a new test pet with incremented name using PetService
    private func createTestPet() {
        guard let petService = petService else {
            print("❌ PetService not initialized")
            return
        }
        
        let count = pets.count + 1
        
        print("🐾 Creating test pet #\(count)...")
        
        if let pet = petService.createPet(name: "Test Pet \(count)", cycleFrequencyDays: 7) {
            // Set random health for variety
            let randomHealth = Int.random(in: 0...100)
            petService.updatePetHealth(pet, newHealth: randomHealth)
            print("✅ Test pet created with \(randomHealth)% health")
        } else {
            print("❌ Failed to create test pet")
        }
    }
    
    /// Sets the first pet's lastLaundryDate to 1 day ago
    private func setPetToYesterday() {
        guard let petService = petService else { return }
        guard let pet = pets.first else {
            print("⚠️ No pets available")
            return
        }
        
        print("📅 Setting \(pet.name) to 1 day ago...")
        
        // Calculate yesterday
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            pet.lastLaundryDate = yesterday
            
            if petService.updatePet(pet) {
                print("✅ Pet set to 1 day ago")
                
                // Calculate new health
                let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
                let state = HealthUpdateService.shared.evaluateState(fromHealth: health)
                print("   New health: \(health)%, State: \(state.rawValue)")
                
                // Update the pet
                petService.updatePetHealth(pet, newHealth: health)
            }
        }
    }
    
    /// Calculates health for the first pet and shows in alert
    private func calculateHealth() {
        guard let pet = pets.first else {
            print("⚠️ No pets available")
            return
        }
        
        print("💚 Calculating health for \(pet.name)...")
        
        let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
        let state = HealthUpdateService.shared.evaluateState(fromHealth: health)
        
        healthAlertMessage = """
        Pet: \(pet.name)
        Calculated Health: \(health)%
        Evaluated State: \(state.rawValue)
        State Display: \(state.displayText)
        """
        
        print("✅ Health: \(health)%, State: \(state.rawValue)")
        showHealthAlert = true
    }
    
    /// Completes a laundry cycle for the first pet
    private func completeCycle() {
        guard let petService = petService else { return }
        guard let pet = pets.first else {
            print("⚠️ No pets available")
            return
        }
        
        print("🎉 Completing cycle for \(pet.name)...")
        
        petService.completeCycle(for: pet)
        print("✅ Cycle completed - health: 100%, state: happy")
    }
    
    /// Sets the first pet to 7 days ago (death scenario)
    private func setToSevenDaysAgo() {
        guard let petService = petService else { return }
        guard let pet = pets.first else {
            print("⚠️ No pets available")
            return
        }
        
        print("💀 Setting \(pet.name) to 7 days ago (death test)...")
        
        // Calculate 7 days ago
        if let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) {
            pet.lastLaundryDate = sevenDaysAgo
            
            if petService.updatePet(pet) {
                print("✅ Pet set to 7 days ago")
                
                // Calculate new health (should be 0 for 7-day cycle)
                let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
                let state = HealthUpdateService.shared.evaluateState(fromHealth: health)
                print("   New health: \(health)%, State: \(state.rawValue)")
                
                // Update the pet
                petService.updatePetHealth(pet, newHealth: health)
            }
        }
    }
    
    /// Deletes selected pets (swipe to delete)
    private func deletePets(at offsets: IndexSet) {
        for index in offsets {
            let pet = pets[index]
            modelContext.delete(pet)
        }
        
        do {
            try modelContext.save()
            print("✅ Deleted \(offsets.count) pet(s)")
        } catch {
            print("❌ Error deleting pets: \(error)")
        }
    }
    
    /// Deletes all pets from the database
    private func deleteAllPets() {
        for pet in pets {
            modelContext.delete(pet)
        }
        
        do {
            try modelContext.save()
            print("✅ Deleted all \(pets.count) pets")
        } catch {
            print("❌ Error deleting all pets: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    /// Returns appropriate color based on health value
    private func healthColor(_ health: Int) -> Color {
        switch health {
        case 75...100:
            return .green
        case 50..<75:
            return .blue
        case 25..<50:
            return .orange
        case 1..<25:
            return .red
        default:
            return .gray
        }
    }
    
    /// Returns color for pet state
    private func stateColor(_ state: PetState) -> Color {
        switch state {
        case .happy:
            return .green
        case .neutral:
            return .blue
        case .sad:
            return .yellow
        case .verySad:
            return .orange
        case .dead:
            return .red
        }
    }
    
    /// Formats a date as relative time (e.g., "2 hours ago", "1 day ago")
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    TestModelsView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}

