# LaundryTime - Error Handling & Recovery

## Overview

This document defines comprehensive error handling strategies, recovery mechanisms, and user-facing error states for LaundryTime. Every error scenario is accounted for with graceful degradation and clear user communication.

---

## 🎯 Error Handling Philosophy

### Core Principles

1. **Never Crash**: Always catch and handle errors gracefully
2. **User Context**: Show errors in terms users understand, not technical jargon
3. **Recovery Paths**: Always provide a way forward
4. **Silent Success**: Don't burden users with technical details when things work
5. **Log Everything**: Comprehensive logging for debugging (dev builds only)

---

## 🗄️ Database Errors (SwiftData)

### Error Types

```swift
enum DatabaseError: LocalizedError {
    case saveFailed(underlyingError: Error)
    case fetchFailed(underlyingError: Error)
    case deleteFailed(underlyingError: Error)
    case corruptedData
    case migrationFailed
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Unable to save your changes"
        case .fetchFailed:
            return "Unable to load your pets"
        case .deleteFailed:
            return "Unable to delete this item"
        case .corruptedData:
            return "Your data appears corrupted"
        case .migrationFailed:
            return "Unable to update app data"
        case .insufficientStorage:
            return "Not enough storage space"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Please try again. If the problem persists, restart the app."
        case .fetchFailed:
            return "Please restart the app. Contact support if this continues."
        case .deleteFailed:
            return "Please try again or restart the app."
        case .corruptedData:
            return "You may need to reset your data in Settings. This cannot be undone."
        case .migrationFailed:
            return "Please reinstall the app. Your data will be lost."
        case .insufficientStorage:
            return "Free up space on your device and try again."
        }
    }
}
```

### Save Failures

**Scenario**: `modelContext.save()` throws error

**Causes**:
- Disk full
- Database locked
- Invalid data
- Concurrent modification

**Handling**:

```swift
func savePet(_ pet: Pet) -> Result<Void, DatabaseError> {
    do {
        try modelContext.save()
        return .success(())
    } catch {
        // Log for debugging
        print("❌ Save failed: \(error.localizedDescription)")
        
        // Check specific failure reasons
        if isDiskFull(error) {
            return .failure(.insufficientStorage)
        }
        
        // Generic save failure
        return .failure(.saveFailed(underlyingError: error))
    }
}

private func isDiskFull(_ error: Error) -> Bool {
    let nsError = error as NSError
    return nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError
}
```

**User Experience**:

```swift
// In ViewModel
func createPet(name: String) {
    let pet = Pet(name: name)
    modelContext.insert(pet)
    
    let result = savePet(pet)
    
    switch result {
    case .success:
        // Silent success
        loadPets()
    case .failure(let error):
        // Show alert
        self.errorMessage = error.errorDescription
        self.showError = true
    }
}

// In View
.alert("Error", isPresented: $viewModel.showError) {
    Button("OK") { }
    Button("Retry") {
        viewModel.retryLastOperation()
    }
} message: {
    Text(viewModel.errorMessage ?? "An unknown error occurred")
    if let suggestion = viewModel.recoverySuggestion {
        Text(suggestion)
            .font(.caption)
    }
}
```

### Fetch Failures

**Scenario**: `modelContext.fetch()` throws error

**Handling**:

```swift
func loadPets() {
    let descriptor = FetchDescriptor<Pet>(
        predicate: #Predicate { $0.isActive == true },
        sortBy: [SortDescriptor(\.createdDate)]
    )
    
    do {
        pets = try modelContext.fetch(descriptor)
    } catch {
        print("❌ Fetch failed: \(error)")
        
        // Show error state
        self.errorMessage = "Unable to load your pets. Please restart the app."
        self.showError = true
        
        // Fallback to empty state
        pets = []
    }
}
```

**User Experience**:
- Show error banner at top of dashboard
- Display empty state with "Retry" button
- Log error for debugging

### Data Corruption

**Detection**:

```swift
func validatePetData(_ pet: Pet) -> Bool {
    // Check required fields
    guard !pet.name.isEmpty else { return false }
    
    // Check value ranges
    if let health = pet.health {
        guard health >= 0 && health <= 100 else { return false }
    }
    
    // Check date consistency
    if let lastLaundry = pet.lastLaundryDate {
        guard lastLaundry <= Date() else { return false }
    }
    
    return true
}
```

**Recovery**:

```swift
func handleCorruptedPet(_ pet: Pet) {
    // Attempt auto-repair
    if pet.name.isEmpty {
        pet.name = "Unnamed Pet"
    }
    
    if let health = pet.health, health < 0 || health > 100 {
        pet.health = 50 // Reset to neutral
    }
    
    // Save repaired data
    try? modelContext.save()
    
    // Log for monitoring
    print("⚠️ Auto-repaired corrupted pet: \(pet.id)")
}
```

---

## 💾 UserDefaults Errors

### Corruption/Missing Data

**Scenario**: Timer state in UserDefaults is corrupted or missing

**Detection**:

```swift
func restoreTimerState() {
    guard let data = UserDefaults.standard.data(forKey: timerKey) else {
        print("⚠️ No timer state found for pet \(petID)")
        // Not an error - timer was never started
        return
    }
    
    do {
        let state = try JSONDecoder().decode(TimerState.self, from: data)
        
        // Validate decoded state
        guard isValidTimerState(state) else {
            print("❌ Invalid timer state detected")
            handleCorruptedTimerState()
            return
        }
        
        applyTimerState(state)
    } catch {
        print("❌ Failed to decode timer state: \(error)")
        handleCorruptedTimerState()
    }
}

private func isValidTimerState(_ state: TimerState) -> Bool {
    // End time must be in future or recent past
    guard abs(state.endTime.timeIntervalSinceNow) < 24 * 3600 else { return false }
    
    // Type must be valid
    guard [.wash, .dry, .cycle].contains(state.type) else { return false }
    
    return true
}
```

**Recovery**:

```swift
func handleCorruptedTimerState() {
    // Clear corrupted data
    UserDefaults.standard.removeObject(forKey: timerKey)
    
    // Reset timer state
    self.isActive = false
    self.timeRemaining = 0
    self.endTime = nil
    
    // Notify user
    NotificationCenter.default.post(
        name: .timerStateCorrupted,
        object: nil,
        userInfo: ["petID": petID]
    )
}
```

### Write Failures

**Scenario**: Unable to write to UserDefaults

**Handling**:

```swift
func saveTimerState() {
    let state = TimerState(endTime: endTime, type: timerType)
    
    do {
        let data = try JSONEncoder().encode(state)
        UserDefaults.standard.set(data, forKey: timerKey)
        
        // Verify write succeeded
        guard UserDefaults.standard.data(forKey: timerKey) != nil else {
            throw TimerError.persistenceFailed
        }
    } catch {
        print("❌ Failed to save timer state: \(error)")
        
        // Timer continues in-memory, but won't survive app termination
        // Show warning to user
        showPersistenceWarning()
    }
}

private func showPersistenceWarning() {
    // Post notification for ViewModel to display alert
    NotificationCenter.default.post(
        name: .timerPersistenceWarning,
        object: nil,
        userInfo: ["message": "Timer will reset if app closes"]
    )
}
```

---

## 🔔 Notification Errors

### Permission Denied

**Detection**:

```swift
func requestPermission() async -> Bool {
    do {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        
        self.permissionStatus = granted ? .authorized : .denied
        return granted
    } catch {
        print("❌ Notification permission request failed: \(error)")
        self.permissionStatus = .denied
        return false
    }
}
```

**User Experience**:

```swift
// In ViewModel
func startWash() {
    Task {
        let hasPermission = await notificationService.requestPermission()
        
        if !hasPermission {
            // Show alert explaining impact
            self.showNotificationPermissionAlert = true
            
            // Timer still works, just no notifications
            startTimerWithoutNotifications()
        } else {
            startTimerWithNotifications()
        }
    }
}

// In View
.alert("Notifications Disabled", isPresented: $viewModel.showNotificationPermissionAlert) {
    Button("Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    Button("Continue Anyway") { }
} message: {
    Text("LaundryTime works better with notifications enabled. You can change this in Settings.")
}
```

### Scheduling Failures

**Scenario**: `UNUserNotificationCenter.add()` fails

**Handling**:

```swift
func scheduleNotification(title: String, body: String, date: Date, identifier: String) async throws {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date),
        repeats: false
    )
    
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    do {
        try await UNUserNotificationCenter.current().add(request)
    } catch {
        print("❌ Failed to schedule notification: \(error)")
        
        // Check if we hit the 64 notification limit
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if pending.count >= 64 {
            throw NotificationError.limitExceeded
        }
        
        throw NotificationError.schedulingFailed(underlyingError: error)
    }
}
```

### Notification Limit Exceeded

**Handling**: See separate document `16_Notification_Management_Limits.md`

---

## ⏱️ Timer Errors

### Timer Creation Failure

**Scenario**: Timer.publish() fails to create timer

**Handling**:

```swift
func startTimer(duration: TimeInterval) {
    guard duration > 0 else {
        print("❌ Invalid timer duration: \(duration)")
        return
    }
    
    // Calculate absolute end time
    let endTime = Date().addingTimeInterval(duration)
    self.endTime = endTime
    self.isActive = true
    
    // Create timer
    timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.checkTimerStatus()
        }
    
    // Verify timer is running
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        guard let self = self else { return }
        
        if self.isActive && self.timerCancellable == nil {
            print("❌ Timer failed to start")
            self.handleTimerFailure()
        }
    }
}

private func handleTimerFailure() {
    // Attempt restart
    self.isActive = false
    
    // Notify user
    self.errorMessage = "Timer failed to start. Please try again."
    self.showError = true
}
```

### Time Calculation Errors

**Scenario**: Invalid date math results

**Handling**:

```swift
func checkTimerStatus() {
    guard let endTime = endTime else {
        stopTimer()
        return
    }
    
    let remaining = endTime.timeIntervalSinceNow
    
    // Sanity check: remaining time should never be absurdly large
    guard remaining < 24 * 3600 else {
        print("❌ Invalid remaining time: \(remaining)")
        handleInvalidTimerState()
        return
    }
    
    if remaining <= 0 {
        completeTimer()
    } else {
        timeRemaining = remaining
    }
}

private func handleInvalidTimerState() {
    stopTimer()
    clearTimerState()
    
    // Notify user
    self.errorMessage = "Timer error detected. Please start a new cycle."
    self.showError = true
}
```

---

## 🌐 System-Level Errors

### Low Memory

**Detection**:

```swift
// In AppDelegate or App struct
func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    // Post notification
    NotificationCenter.default.post(name: .memoryWarning, object: nil)
}

// In ViewModels
init() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleMemoryWarning),
        name: .memoryWarning,
        object: nil
    )
}

@objc private func handleMemoryWarning() {
    // Clear caches
    clearNonEssentialData()
    
    // Log
    print("⚠️ Low memory warning received")
}
```

### Storage Full

**Detection**:

```swift
func checkStorageAvailability() -> Bool {
    do {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: documentsPath.path)
        
        if let freeSize = attributes[.systemFreeSize] as? NSNumber {
            let freeSizeMB = freeSize.int64Value / 1024 / 1024
            
            // Warn if less than 50MB free
            if freeSizeMB < 50 {
                return false
            }
        }
    } catch {
        print("❌ Failed to check storage: \(error)")
    }
    
    return true
}
```

**Handling**:

```swift
// Before saving
if !checkStorageAvailability() {
    self.errorMessage = "Storage is almost full. Please free up space."
    self.showError = true
    return
}
```

---

## 🔄 Network Errors (Future)

**Note**: V1.0 has no network functionality, but planning ahead:

```swift
enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(code: Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again."
        case .timeout:
            return "Please try again in a moment."
        case .serverError:
            return "Please try again later. Contact support if this persists."
        }
    }
}
```

---

## 🎨 Error UI Components

### Error Banner

```swift
struct ErrorBannerView: View {
    let message: String
    let action: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            if let action = action {
                Button("Retry") {
                    action()
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.error)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding()
    }
}
```

### Empty State with Error

```swift
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .frame(height: 44)
                        .background(Color.primaryBlue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 32)
    }
}
```

---

## 📊 Error Logging

### Development Logging

```swift
enum LogLevel {
    case debug, info, warning, error
}

func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let filename = (file as NSString).lastPathComponent
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    
    let emoji: String
    switch level {
    case .debug: emoji = "🔍"
    case .info: emoji = "ℹ️"
    case .warning: emoji = "⚠️"
    case .error: emoji = "❌"
    }
    
    print("\(emoji) [\(timestamp)] \(filename):\(line) \(function) - \(message)")
    #endif
}
```

### Production Error Tracking

```swift
// Use App Store Connect's built-in crash reporting
// No third-party analytics to preserve privacy

func trackError(_ error: Error, context: String) {
    #if DEBUG
    log("Error in \(context): \(error.localizedDescription)", level: .error)
    #else
    // In production, rely on automatic crash reports
    // No custom tracking to maintain privacy promise
    #endif
}
```

---

## ✅ Error Handling Checklist

### Database Operations
- [ ] All `modelContext.save()` wrapped in do-catch
- [ ] All `modelContext.fetch()` wrapped in do-catch
- [ ] Validation before saving data
- [ ] Corruption detection and auto-repair
- [ ] User-friendly error messages

### Timer Operations
- [ ] Invalid duration checks
- [ ] Timer creation failure handling
- [ ] State corruption detection
- [ ] Recovery from invalid states
- [ ] UserDefaults write verification

### Notifications
- [ ] Permission status checked before scheduling
- [ ] Scheduling failures handled
- [ ] 64 notification limit managed
- [ ] Graceful degradation without notifications

### User Experience
- [ ] Never show technical error messages
- [ ] Always provide recovery suggestions
- [ ] Retry mechanisms where appropriate
- [ ] Loading states during error recovery
- [ ] Haptic feedback for errors

---

## 🎯 Error Recovery Strategies

### Automatic Recovery
1. **Auto-repair**: Fix corrupted data automatically when possible
2. **Retry logic**: Automatic retry for transient failures (up to 3 attempts)
3. **Graceful degradation**: Continue with limited functionality

### User-Initiated Recovery
1. **Retry buttons**: Let users retry failed operations
2. **Reset options**: Settings → Reset All Data (nuclear option)
3. **Settings deep link**: Direct users to iOS Settings for permissions

### Support Escalation
1. **Clear error messages**: Help users self-diagnose
2. **Support email**: Easy way to contact support
3. **Version/device info**: Include in support requests

---

## 🔮 Future Enhancements

### V1.1 Considerations
- [ ] Error analytics (privacy-preserving)
- [ ] Smart retry with exponential backoff
- [ ] Offline queue for future network operations
- [ ] Advanced diagnostics in Settings

### V1.2 Considerations
- [ ] iCloud sync error handling
- [ ] Conflict resolution for shared data
- [ ] Network reachability monitoring

---

**Every error is an opportunity to maintain user trust through graceful handling and clear communication.** 🛡️✨