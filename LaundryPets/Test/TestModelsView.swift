//
//  TestModelsView.swift
//  LaundryPets
//
//  Phase 1 Guided Testing Interface
//  Walks through systematic testing of SwiftData models, services, and business logic
//  ⚠️ TEMPORARY - Will be replaced with real UI in Phase 2
//

import SwiftUI
import SwiftData

struct TestModelsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Pet.createdDate) private var pets: [Pet]
    @Query(sort: \LaundryTask.startDate, order: .reverse) private var tasks: [LaundryTask]
    
    // MARK: - Services
    
    @State private var petService: PetService?
    
    // MARK: - State
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var step2Result = ""
    @State private var step3Result = ""
    @State private var step4Result = ""
    @State private var step6Result = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Step 1: Create Pet
                    stepSection(
                        number: 1,
                        title: "Create Pet",
                        isComplete: !pets.isEmpty,
                        canStart: true
                    ) {
                        createPetContent
                    }
                    
                    // Step 2: Test Task Creation
                    stepSection(
                        number: 2,
                        title: "Test Task Creation",
                        isComplete: !tasks.isEmpty,
                        canStart: !pets.isEmpty
                    ) {
                        taskCreationContent
                    }
                    
                    // Step 3: Test Statistics
                    stepSection(
                        number: 3,
                        title: "Test Statistics System",
                        isComplete: pets.first?.totalCyclesCompleted ?? 0 > 0,
                        canStart: !pets.isEmpty
                    ) {
                        statisticsContent
                    }
                    
                    // Step 4: Test Health Decay
                    stepSection(
                        number: 4,
                        title: "Test Health Decay",
                        isComplete: false,
                        canStart: !pets.isEmpty
                    ) {
                        healthDecayContent
                    }
                    
                    // Step 5: Timer System
                    stepSection(
                        number: 5,
                        title: "Test Timer System",
                        isComplete: false,
                        canStart: true
                    ) {
                        timerSystemContent
                    }
                    
                    // Step 6: Cycle Completion
                    stepSection(
                        number: 6,
                        title: "Test Cycle Completion",
                        isComplete: false,
                        canStart: !pets.isEmpty
                    ) {
                        cycleCompletionContent
                    }
                    
                    // Pet Display Card
                    if let pet = pets.first {
                        petDisplayCard(pet)
                    }
                    
                    // Task Display
                    if !tasks.isEmpty {
                        taskDisplaySection
                    }
                    
                    // Reset Button
                    resetButton
                }
                .padding()
            }
            .navigationTitle("Phase 1 Testing")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if petService == nil {
                    petService = PetService(modelContext: modelContext)
                    print("✅ PetService initialized")
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🧪 Phase 1 Model Testing")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Follow the steps below to verify all models and services")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Step Sections
    
    private func stepSection<Content: View>(
        number: Int,
        title: String,
        isComplete: Bool,
        canStart: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Header
            HStack {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.green : (canStart ? Color.blue : Color.gray))
                        .frame(width: 32, height: 32)
                    
                    if isComplete {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    } else {
                        Text("\(number)")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(canStart ? .primary : .secondary)
                
                Spacer()
            }
            
            // Content
            if canStart {
                content()
            } else {
                Text("Complete previous steps first")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(canStart ? Color.white : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isComplete ? Color.green : (canStart ? Color.blue : Color.gray), lineWidth: 2)
        )
        .opacity(canStart ? 1.0 : 0.6)
    }
    
    // MARK: - Step 1: Create Pet
    
    private var createPetContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create a test pet to begin testing all systems")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: createTestPet) {
                Label("Create Test Pet", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            if !pets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ Pet Created Successfully!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text("Proceed to Step 2 →")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Step 2: Task Creation
    
    private var taskCreationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create a task and watch it progress through stages")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let pet = pets.first {
                Button(action: createTestTask) {
                    Label("Create Task for \(pet.name)", systemImage: "doc.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }
            
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expected progression:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("cycle → washing → drying → completed → folded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    
                    HStack(spacing: 8) {
                        Button(action: advanceTaskStage) {
                            Label("Advance Stage", systemImage: "arrow.right.circle")
                                .font(.caption)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.indigo.opacity(0.2))
                                .foregroundColor(.indigo)
                                .cornerRadius(8)
                        }
                        .disabled(noIncompleteTasks)
                        
                        Button(action: markTaskFolded) {
                            Label("Mark Folded", systemImage: "checkmark.square")
                                .font(.caption)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                        .disabled(noCompletedStageTasks)
                    }
                    
                    if !step2Result.isEmpty {
                        resultBox(step2Result, success: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Statistics
    
    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Increment cycle counts and verify statistics update")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: incrementPetCycles) {
                Label("Complete Cycle +1", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(10)
            }
            
            Text("💡 Tap 3 times to see: Cycles: 3, Streak: 3/3")
                .font(.caption)
                .foregroundColor(.blue)
            
            if !step3Result.isEmpty {
                resultBox(step3Result, success: true)
            }
        }
    }
    
    // MARK: - Step 4: Health Decay
    
    private var healthDecayContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test health calculation over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Button(action: setPetToYesterday) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set to 1 Day Ago")
                            .fontWeight(.semibold)
                        Text("Expected: ~86% health (1/7 days)")
                            .font(.caption)
                            .foregroundColor(.orange.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
                
                Button(action: calculateHealth) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calculate Current Health")
                            .fontWeight(.semibold)
                        Text("Shows calculated health and state")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                Button(action: setToSevenDaysAgo) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set to 7 Days Ago")
                            .fontWeight(.semibold)
                        Text("Expected: 0% health (dead)")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(10)
                }
            }
            
            if !step4Result.isEmpty {
                resultBox(step4Result, success: true)
            }
        }
    }
    
    // MARK: - Step 5: Timer System
    
    private var timerSystemContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test the actual PetTimerService (NOT just buttons)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("⚠️ Note: Timer system has separate comprehensive tests")
                .font(.caption)
                .foregroundColor(.orange)
            
            NavigationLink(destination: TestTimerView()) {
                HStack {
                    Image(systemName: "timer")
                    Text("Open Timer Test View")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(Color.indigo)
                .cornerRadius(10)
            }
            
            Text("Tests: Absolute time, background persistence, restoration")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Step 6: Cycle Completion
    
    private var cycleCompletionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Complete a full cycle and verify reset")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let pet = pets.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Health: \(pet.health ?? 0)% → After: 100%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("State: \(pet.currentState.rawValue) → After: happy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: completeCycle) {
                Label("Complete Full Cycle", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            if !step6Result.isEmpty {
                resultBox(step6Result, success: true)
            }
        }
    }
    
    // MARK: - Display Cards
    
    private func petDisplayCard(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🐾 Pet Details")
                    .font(.headline)
                Spacer()
                Text("ID: \(pet.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Name and State
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stateColor(pet.currentState))
                            .frame(width: 8, height: 8)
                        Text(pet.currentState.displayText)
                            .font(.subheadline)
                            .foregroundColor(stateColor(pet.currentState))
                    }
                }
                
                Spacer()
                
                // Health Badge
                if let health = pet.health {
                    VStack(spacing: 4) {
                        Text("\(health)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(healthColor(health))
                        
                        Text("Health")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(healthColor(health).opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            Divider()
            
            // Statistics
            HStack(spacing: 16) {
                statItem(icon: "checkmark.circle", label: "Total", value: "\(pet.totalCyclesCompleted)")
                statItem(icon: "flame", label: "Streak", value: "\(pet.currentStreak)")
                statItem(icon: "trophy", label: "Best", value: "\(pet.longestStreak)")
            }
            
            Divider()
            
            // Timer Settings
            VStack(alignment: .leading, spacing: 4) {
                Text("Timer Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    timerSettingItem(icon: "drop.fill", label: "Wash", value: "\(pet.washDurationMinutes)m")
                    timerSettingItem(icon: "wind", label: "Dry", value: "\(pet.dryDurationMinutes)m")
                    timerSettingItem(icon: "repeat", label: "Cycle", value: "\(pet.cycleFrequencyDays)d")
                }
            }
            
            // Last Laundry
            if let lastLaundry = pet.lastLaundryDate {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Last laundry: \(relativeTime(from: lastLaundry))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Never done laundry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 2)
        )
    }
    
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func timerSettingItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(label): \(value)")
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Task Display
    
    private var taskDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 Tasks (\(tasks.count))")
                .font(.headline)
            
            ForEach(tasks) { task in
                VStack(alignment: .leading, spacing: 8) {
                    // Stage Header
                    HStack {
                        Text(task.currentStage.displayText)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if task.isCompleted {
                            Text("✅ Folded")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        } else {
                            Text("⏳ In Progress")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(6)
                        }
                    }
                    
                    // Action Button
                    HStack {
                        Image(systemName: task.currentStage.isActionable ? "hand.tap.fill" : "clock.fill")
                            .foregroundColor(task.currentStage.isActionable ? .blue : .gray)
                        Text("Action: \(task.currentStage.actionButtonText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Durations
                    HStack {
                        Text("Wash: \(task.washDurationMinutes)m")
                        Text("•")
                        Text("Dry: \(task.dryDurationMinutes)m")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Timestamps (Audit Trail)
                    if let washStart = task.washStartTime {
                        timestampRow(icon: "drop.fill", label: "Wash started", date: washStart, color: .blue)
                    }
                    if let washEnd = task.washEndTime {
                        timestampRow(icon: "checkmark.circle", label: "Wash ended", date: washEnd, color: .blue)
                    }
                    if let dryStart = task.dryStartTime {
                        timestampRow(icon: "wind", label: "Dry started", date: dryStart, color: .orange)
                    }
                    if let dryEnd = task.dryEndTime {
                        timestampRow(icon: "checkmark.circle", label: "Dry ended", date: dryEnd, color: .orange)
                    }
                    if let foldTime = task.foldCompletedTime {
                        timestampRow(icon: "checkmark.circle.fill", label: "Folded", date: foldTime, color: .green)
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(task.isCompleted ? Color.green : Color.purple, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func timestampRow(icon: String, label: String, date: Date, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(label):")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(relativeTime(from: date))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func resultBox(_ text: String, success: Bool) -> some View {
        HStack {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(success ? .green : .red)
            Text(text)
                .font(.caption)
                .foregroundColor(success ? .green : .red)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((success ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button(action: resetAllData) {
            Label("Reset All & Start Over", systemImage: "arrow.counterclockwise.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var noIncompleteTasks: Bool {
        tasks.first(where: { !$0.isCompleted }) == nil
    }
    
    private var noCompletedStageTasks: Bool {
        tasks.first(where: { $0.currentStage == .completed && !$0.isCompleted }) == nil
    }
    
    // MARK: - Actions
    
    private func createTestPet() {
        guard let petService = petService else { return }
        
        let count = pets.count + 1
        print("🐾 Creating test pet #\(count)...")
        
        if let pet = petService.createPet(name: "Test Pet \(count)", cycleFrequencyDays: 7) {
            _ = petService.updatePetHealth(pet, newHealth: 100)
            print("✅ Test pet created successfully")
        }
    }
    
    private func createTestTask() {
        guard let pet = pets.first else { return }
        
        print("📝 Creating test LaundryTask for \(pet.name)...")
        
        let task = LaundryTask(
            petID: pet.id,
            washDuration: pet.washDurationMinutes,
            dryDuration: pet.dryDurationMinutes
        )
        
        modelContext.insert(task)
        
        do {
            try modelContext.save()
            print("✅ Task created: \(task.currentStage.displayText)")
            step2Result = "Task created at stage: \(task.currentStage.rawValue)"
        } catch {
            print("❌ Failed to create task: \(error)")
        }
    }
    
    private func advanceTaskStage() {
        guard let task = tasks.first(where: { !$0.isCompleted }) else { return }
        
        let oldStage = task.currentStage
        task.advanceToNextStage()
        
        do {
            try modelContext.save()
            print("✅ Advanced: \(oldStage.rawValue) → \(task.currentStage.rawValue)")
            step2Result = "Advanced to: \(task.currentStage.displayText)"
        } catch {
            print("❌ Failed to advance: \(error)")
        }
    }
    
    private func markTaskFolded() {
        guard let task = tasks.first(where: { $0.currentStage == .completed && !$0.isCompleted }) else {
            return
        }
        
        task.markFolded()
        
        do {
            try modelContext.save()
            print("✅ Task marked as folded!")
            step2Result = "Task completed and folded! ✅"
        } catch {
            print("❌ Failed to mark folded: \(error)")
        }
    }
    
    private func incrementPetCycles() {
        guard let pet = pets.first else { return }
        
        pet.totalCyclesCompleted += 1
        pet.currentStreak += 1
        
        if pet.currentStreak > pet.longestStreak {
            pet.longestStreak = pet.currentStreak
        }
        
        do {
            try modelContext.save()
            print("✅ Cycles: \(pet.totalCyclesCompleted), Streak: \(pet.currentStreak)/\(pet.longestStreak)")
            step3Result = "Total: \(pet.totalCyclesCompleted), Streak: \(pet.currentStreak)/\(pet.longestStreak)"
        } catch {
            print("❌ Failed to update: \(error)")
        }
    }
    
    private func setPetToYesterday() {
        guard let petService = petService, let pet = pets.first else { return }
        
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            pet.lastLaundryDate = yesterday
            
            if petService.savePet(pet) {
                let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
                _ = petService.updatePetHealth(pet, newHealth: health)
                step4Result = "Set to 1 day ago → Health: \(health)%"
                print("✅ Set to yesterday, health: \(health)%")
            }
        }
    }
    
    private func calculateHealth() {
        guard let pet = pets.first else { return }
        
        let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
        let state = HealthUpdateService.shared.evaluateState(fromHealth: health)
        
        alertTitle = "Health Calculation"
        alertMessage = """
        Pet: \(pet.name)
        Calculated Health: \(health)%
        Evaluated State: \(state.rawValue)
        Display: \(state.displayText)
        """
        showAlert = true
        
        step4Result = "Calculated: \(health)% → \(state.rawValue)"
    }
    
    private func setToSevenDaysAgo() {
        guard let petService = petService, let pet = pets.first else { return }
        
        if let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) {
            pet.lastLaundryDate = sevenDaysAgo
            
            if petService.savePet(pet) {
                let health = HealthUpdateService.shared.calculateCurrentHealth(for: pet)
                _ = petService.updatePetHealth(pet, newHealth: health)
                step4Result = "Set to 7 days ago → Health: \(health)% (should be 0)"
                print("✅ Set to 7 days ago, health: \(health)%")
            }
        }
    }
    
    private func completeCycle() {
        guard let petService = petService, let pet = pets.first else { return }
        
        let oldHealth = pet.health ?? 0
        let oldState = pet.currentState
        
        _ = petService.completeCycle(for: pet)
        
        step6Result = "Health: \(oldHealth)% → 100%, State: \(oldState.rawValue) → happy"
        print("✅ Cycle completed")
    }
    
    private func resetAllData() {
        for task in tasks {
            modelContext.delete(task)
        }
        for pet in pets {
            modelContext.delete(pet)
        }
        
        do {
            try modelContext.save()
            step2Result = ""
            step3Result = ""
            step4Result = ""
            step6Result = ""
            print("✅ All data reset")
        } catch {
            print("❌ Failed to reset: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func healthColor(_ health: Int) -> Color {
        switch health {
        case 75...100: return .green
        case 50..<75: return .blue
        case 25..<50: return .orange
        case 1..<25: return .red
        default: return .gray
        }
    }
    
    private func stateColor(_ state: PetState) -> Color {
        switch state {
        case .happy: return .green
        case .neutral: return .blue
        case .sad: return .yellow
        case .verySad: return .orange
        case .dead: return .red
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    TestModelsView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
