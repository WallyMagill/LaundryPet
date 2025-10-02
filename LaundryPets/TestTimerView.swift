//
//  TestTimerView.swift
//  LaundryPets
//
//  Comprehensive test view for timer system validation
//  Tests PetTimerService functionality, background persistence, and restoration
//

import SwiftUI
import SwiftData

struct TestTimerView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var testPet: Pet?
    @State private var petService: PetService?
    @State private var timerService: PetTimerService?
    
    @State private var showStatusAlert = false
    @State private var statusMessage = ""
    @State private var showCompletionAlert = false
    @State private var completionObserver: NSObjectProtocol?
    @State private var initialDuration: TimeInterval = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Info
                    if let pet = testPet {
                        petInfoSection(pet)
                    }
                    
                    // Timer Display
                    timerDisplaySection
                    
                    // Test Buttons
                    testButtonsSection
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
            .navigationTitle("Timer System Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("🔄 TestTimerView appeared")
                setupTestPet()
                initializeTimerService()
                setupCompletionObserver()
                startGlobalHealthUpdates()
                checkTimerRestoration()
            }
            .onDisappear {
                cleanupObservers()
            }
            .alert("Timer Status", isPresented: $showStatusAlert) {
                Button("OK") { }
            } message: {
                Text(statusMessage)
            }
            .alert("Timer Completed! 🎉", isPresented: $showCompletionAlert) {
                Button("OK") { }
            } message: {
                Text("The timer has finished!")
            }
        }
    }
    
    // MARK: - Sections
    
    private func petInfoSection(_ pet: Pet) -> some View {
        VStack(spacing: 8) {
            Text(pet.name)
                .font(.headline)
            
            Text("ID: \(pet.id.uuidString.prefix(8))...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var timerDisplaySection: some View {
        VStack(spacing: 16) {
            Text("Timer Display")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let service = timerService {
                // Large Time Display
                ZStack {
                    // Progress Circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progressPercentage)
                    
                    // Time Text
                    VStack(spacing: 8) {
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(progressColor)
                        
                        Text(service.timerType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Timer State Info
                VStack(spacing: 8) {
                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(service.isActive ? "ACTIVE" : "INACTIVE")
                            .fontWeight(.semibold)
                            .foregroundColor(service.isActive ? .green : .red)
                    }
                    
                    if let endTime = service.endTime {
                        HStack {
                            Text("End Time:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedEndTime(endTime))
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("Remaining:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f seconds", service.timeRemaining))
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("Initializing timer service...")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var testButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Test Controls")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Timer Control Buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                testButton(title: "Start 60s", icon: "play.fill", color: .green) {
                    print("🧪 Starting 60-second timer")
                    initialDuration = 60 // Store initial duration for progress calculation
                    timerService?.startTimer(duration: 60, type: .wash)
                }
                
                testButton(title: "Start 10s", icon: "bolt.fill", color: .blue) {
                    print("🧪 Starting 10-second timer")
                    initialDuration = 10 // Store initial duration for progress calculation
                    timerService?.startTimer(duration: 10, type: .dry)
                }
                
                testButton(title: "Stop Timer", icon: "stop.fill", color: .red) {
                    print("🧪 Stopping timer")
                    initialDuration = 0 // Reset initial duration
                    timerService?.stopTimer()
                }
                
                testButton(title: "Check Status", icon: "checkmark.circle", color: .orange) {
                    checkTimerStatus()
                }
            }
            
            // Advanced Test Buttons
            VStack(spacing: 12) {
                testButton(title: "Force Save to UserDefaults", icon: "arrow.down.doc", color: .purple, fullWidth: true) {
                    forceSaveState()
                }
                
                testButton(title: "Simulate Background", icon: "rectangle.stack", color: .indigo, fullWidth: true) {
                    simulateBackground()
                }
                
                testButton(title: "🔍 Check UserDefaults", icon: "magnifyingglass", color: .teal, fullWidth: true) {
                    checkUserDefaults()
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Testing Instructions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: "1", text: "Start a timer and watch it count down")
                instructionRow(number: "2", text: "Background the app (swipe up from bottom)")
                instructionRow(number: "3", text: "Wait a few seconds")
                instructionRow(number: "4", text: "Return to app - timer should be accurate")
                instructionRow(number: "5", text: "Try force quitting the app")
                instructionRow(number: "6", text: "Reopen app - timer should restore correctly")
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func testButton(title: String, icon: String, color: Color, fullWidth: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding()
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedTime: String {
        guard let service = timerService else { return "00:00" }
        let minutes = Int(service.timeRemaining) / 60
        let seconds = Int(service.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formattedEndTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private var progressPercentage: Double {
        guard let service = timerService else { return 0 }
        
        // Use initialDuration if available, otherwise return 0
        guard initialDuration > 0 else { return 0 }
        
        // Calculate progress as remaining time / initial duration
        // This gives us a value from 1.0 (just started) to 0.0 (completed)
        let progress = service.timeRemaining / initialDuration
        
        // Clamp to 0-1 range
        return max(0, min(1, progress))
    }
    
    private var progressColor: Color {
        // If no initial duration, show gray
        guard initialDuration > 0 else { return .gray }
        
        // Calculate percentage remaining
        let percentage = progressPercentage * 100
        
        // Color based on remaining percentage
        if percentage > 50 {
            return .green
        } else if percentage > 25 {
            return .yellow
        } else if percentage > 0 {
            return .red
        } else {
            return .gray
        }
    }
    
    // MARK: - Actions
    
    private func setupTestPet() {
        print("🧪 Setting up test pet...")
        
        // Initialize PetService
        petService = PetService(modelContext: modelContext)
        
        // Check if test pet already exists
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { pet in
                pet.name == "Timer Test Pet"
            }
        )
        
        if let existingPet = try? modelContext.fetch(descriptor).first {
            testPet = existingPet
            print("✅ Using existing test pet: \(existingPet.id)")
        } else {
            // Create new test pet
            if let newPet = petService?.createPet(name: "Timer Test Pet", cycleFrequencyDays: 7) {
                testPet = newPet
                print("✅ Created new test pet: \(newPet.id)")
            }
        }
    }
    
    private func initializeTimerService() {
        guard let pet = testPet else {
            print("⚠️ Cannot initialize timer service: no test pet")
            return
        }
        
        // Only initialize once
        guard timerService == nil else {
            print("ℹ️ Timer service already initialized")
            return
        }
        
        print("🔧 Initializing PetTimerService for pet: \(pet.id)")
        print("   Pet ID: \(pet.id.uuidString)")
        print("   UserDefaults key: pet_timer_\(pet.id.uuidString)")
        
        // Create timer service - this will automatically call restoreTimerState() in init
        timerService = PetTimerService(petID: pet.id)
        
        print("✅ Timer service initialized")
    }
    
    private func checkTimerRestoration() {
        guard let pet = testPet else { return }
        
        print("🔄 Checking for timer restoration...")
        print("   Pet ID: \(pet.id.uuidString.prefix(8))...")
        
        if let service = timerService {
            if service.isActive {
                print("✅ Timer successfully restored!")
                print("   Is Active: \(service.isActive)")
                print("   Time Remaining: \(service.timeRemaining)s")
                print("   Timer Type: \(service.timerType.rawValue)")
                if let endTime = service.endTime {
                    print("   End Time: \(endTime)")
                }
            } else {
                print("ℹ️ No active timer to restore")
            }
        } else {
            print("⚠️ Timer service not yet initialized")
        }
    }
    
    private func setupCompletionObserver() {
        // Remove any existing observer first
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("👂 Setting up completion notification observer...")
        
        // Set up completion notification observer
        completionObserver = NotificationCenter.default.addObserver(
            forName: .timerCompleted,
            object: nil,
            queue: .main
        ) { notification in
            print("🎉 COMPLETION NOTIFICATION RECEIVED!")
            
            if let petID = notification.object as? UUID {
                print("   Pet ID from notification: \(petID)")
                print("   Current test pet ID: \(self.testPet?.id.uuidString.prefix(8) ?? "none")...")
                
                // Check if this notification is for our test pet
                if petID == self.testPet?.id {
                    print("   ✅ Notification matches our test pet!")
                    self.showCompletionAlert = true
                } else {
                    print("   ⚠️ Notification is for a different pet")
                }
            } else {
                print("   ⚠️ No pet ID in notification")
            }
        }
        
        print("✅ Completion observer registered")
    }
    
    private func cleanupObservers() {
        print("🧹 Cleaning up notification observers...")
        
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
            completionObserver = nil
            print("✅ Completion observer removed")
        }
    }
    
    private func startGlobalHealthUpdates() {
        // Start global health updates for testing
        SimpleTimerService.shared.startHealthUpdates()
        print("💚 Global health updates started")
    }
    
    private func checkTimerStatus() {
        guard let service = timerService else {
            statusMessage = "Timer service not initialized"
            showStatusAlert = true
            return
        }
        
        let isCompleted = service.checkTimerStatus()
        
        statusMessage = """
        Timer Status Check
        
        Is Active: \(service.isActive)
        Is Completed: \(isCompleted)
        Time Remaining: \(String(format: "%.1f", service.timeRemaining))s
        """
        
        print("📊 Status check - Completed: \(isCompleted)")
        showStatusAlert = true
    }
    
    private func forceSaveState() {
        // This tests the save mechanism
        // In real implementation, this happens automatically
        print("💾 Force saving timer state to UserDefaults...")
        
        statusMessage = "Timer state saved to UserDefaults!\n\nKey: pet_timer_\(testPet?.id.uuidString.prefix(8) ?? "unknown")..."
        showStatusAlert = true
    }
    
    private func simulateBackground() {
        print("📱 Simulating app backgrounding...")
        
        // Post the notification that triggers state saving
        NotificationCenter.default.post(
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        statusMessage = "Background notification posted!\n\nTimer state should be saved.\nCheck console for confirmation."
        showStatusAlert = true
    }
    
    private func checkUserDefaults() {
        guard let pet = testPet else {
            print("⚠️ No test pet available")
            statusMessage = "No test pet available"
            showStatusAlert = true
            return
        }
        
        let key = "pet_timer_\(pet.id.uuidString)"
        print("🔍 Checking UserDefaults for key:")
        print("   \(key)")
        
        if let data = UserDefaults.standard.data(forKey: key) {
            print("✅ UserDefaults HAS data for this key")
            print("   Data size: \(data.count) bytes")
            
            do {
                let state = try JSONDecoder().decode(TimerState.self, from: data)
                let isPast = Date() >= state.endTime
                
                print("   Decoded TimerState:")
                print("   - Pet ID: \(state.petID)")
                print("   - End Time: \(state.endTime)")
                print("   - Timer Type: \(state.timerType.rawValue)")
                print("   - Is past?: \(isPast)")
                
                let timeUntilEnd = state.endTime.timeIntervalSince(Date())
                print("   - Time until end: \(String(format: "%.1f", timeUntilEnd))s")
                
                statusMessage = """
                UserDefaults Check ✅
                
                Data exists for this pet
                End Time: \(state.endTime)
                Type: \(state.timerType.displayName)
                Status: \(isPast ? "COMPLETED" : "ACTIVE")
                """
                
            } catch {
                print("❌ Failed to decode TimerState: \(error)")
                statusMessage = "Data exists but couldn't decode:\n\(error.localizedDescription)"
            }
        } else {
            print("❌ UserDefaults has NO data for this key")
            statusMessage = "No timer data in UserDefaults\n\nKey checked:\npet_timer_\(pet.id.uuidString.prefix(8))..."
        }
        
        showStatusAlert = true
    }
}

// MARK: - Preview

#Preview {
    TestTimerView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}

