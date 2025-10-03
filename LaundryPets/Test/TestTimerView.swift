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
    @Environment(\.modelContext) private var modelContext
    
    // Pet state
    @State private var testPet: Pet?
    
    // CRITICAL FIX: Use @ObservedObject instead of @StateObject
    // We'll create the service manually and observe it
    @State private var timerService: PetTimerService?
    
    // UI State
    @State private var initialDuration: TimeInterval = 0
    @State private var showCompletionAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Timer System Test")
                    .font(.title)
                    .bold()
                
                // Timer Display
                if let service = timerService {
                    TimerDisplayView(
                        timerService: service,
                        initialDuration: $initialDuration
                    )
                } else {
                    Text("Initializing...")
                        .foregroundColor(.gray)
                }
                
                // Test Controls
                testControlsSection
                
                // Instructions
                instructionsSection
            }
            .padding()
        }
        .onAppear {
            setupTestPet()
            setupNotificationObserver()
        }
        .alert("Timer Completed! 🎉", isPresented: $showCompletionAlert) {
            Button("OK") { }
        }
    }
    
    private var testControlsSection: some View {
        VStack(spacing: 16) {
            Text("Test Controls")
                .font(.headline)
            
            // Timer buttons
            HStack(spacing: 16) {
                Button(action: start60Timer) {
                    Label("Start 60s", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button(action: start10Timer) {
                    Label("Start 10s", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            HStack(spacing: 16) {
                Button(action: stopTimer) {
                    Label("Stop Timer", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button(action: checkStatus) {
                    Label("Check Status", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            // Debug buttons
            Button(action: checkUserDefaults) {
                Label("🔍 Check UserDefaults", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(12)
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Testing Instructions")
                .font(.headline)
            
            Text("""
            1. Start timer and watch it count down
            2. Background the app (swipe up)
            3. Wait a few seconds
            4. Return - timer should be accurate
            5. Try force quitting and reopening
            """)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Setup
    
    private func setupTestPet() {
        print("🔄 TestTimerView appeared")
        print("🧪 Setting up test pet...")
        
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { $0.name == "Timer Test Pet" }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            print("✅ Using existing test pet: \(existing.id)")
            testPet = existing
            setupTimerService(for: existing)
        } else {
            let newPet = Pet(name: "Timer Test Pet", cycleFrequencyDays: 7)
            modelContext.insert(newPet)
            try? modelContext.save()
            print("✅ Created new test pet: \(newPet.id)")
            testPet = newPet
            setupTimerService(for: newPet)
        }
        
        SimpleTimerService.shared.startHealthUpdates()
    }
    
    private func setupTimerService(for pet: Pet) {
        print("🔧 Creating timer service for pet: \(pet.id)")
        timerService = PetTimerService(petID: pet.id)
        print("✅ Timer service created")
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .timerCompleted,
            object: nil,
            queue: .main
        ) { notification in
            print("🎉 COMPLETION NOTIFICATION RECEIVED!")
            showCompletionAlert = true
        }
    }
    
    // MARK: - Actions
    
    private func start60Timer() {
        print("🧪 Starting 60-second timer")
        initialDuration = 60
        timerService?.startTimer(duration: 60, type: .wash)
    }
    
    private func start10Timer() {
        print("🧪 Starting 10-second timer")
        initialDuration = 10
        timerService?.startTimer(duration: 10, type: .dry)
    }
    
    private func stopTimer() {
        print("🧪 Stopping timer")
        timerService?.stopTimer()
        initialDuration = 0
    }
    
    private func checkStatus() {
        let completed = timerService?.checkTimerStatus() ?? false
        print("📊 Status check - Completed: \(completed)")
    }
    
    private func checkUserDefaults() {
        guard let pet = testPet else { return }
        let key = "pet_timer_\(pet.id.uuidString)"
        
        print("🔍 Checking UserDefaults for key:")
        print("   \(key)")
        
        if let data = UserDefaults.standard.data(forKey: key) {
            print("✅ UserDefaults HAS data")
            if let state = try? JSONDecoder().decode(TimerState.self, from: data) {
                print("   EndTime: \(state.endTime)")
                print("   Type: \(state.timerType)")
                print("   Time until end: \(state.endTime.timeIntervalSinceNow)s")
            }
        } else {
            print("❌ UserDefaults has NO data")
        }
    }
}

// MARK: - Timer Display Component

struct TimerDisplayView: View {
    @ObservedObject var timerService: PetTimerService
    @Binding var initialDuration: TimeInterval
    
    var body: some View {
        VStack(spacing: 16) {
            // Time display
            Text(timeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(timerService.isActive ? .primary : .gray)
            
            Text(timerService.timerType.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
            }
            .frame(width: 200, height: 200)
            
            // Status
            HStack {
                Text("Status:")
                    .foregroundColor(.secondary)
                Text(timerService.isActive ? "ACTIVE" : "INACTIVE")
                    .foregroundColor(timerService.isActive ? .green : .red)
                    .bold()
            }
            
            HStack {
                Text("Remaining:")
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", timerService.timeRemaining)) seconds")
                    .bold()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var timeString: String {
        let minutes = Int(timerService.timeRemaining) / 60
        let seconds = Int(timerService.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: CGFloat {
        guard initialDuration > 0 else { return 0 }
        return CGFloat(timerService.timeRemaining / initialDuration)
    }
    
    private var progressColor: Color {
        guard initialDuration > 0 else { return .gray }
        let percentage = (timerService.timeRemaining / initialDuration) * 100
        if percentage > 50 { return .green }
        else if percentage > 25 { return .yellow }
        else { return .red }
    }
}

// MARK: - Preview

#Preview {
    TestTimerView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
