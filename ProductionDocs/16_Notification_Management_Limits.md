# LaundryTime - Notification Management & Limits

## Overview

This document addresses iOS notification limits, intelligent scheduling strategies, and graceful handling when limits are reached. iOS imposes a 64 pending notification limit, requiring smart management in multi-pet scenarios.

---

## 🚨 iOS Notification Constraints

### System Limits

**Hard Limits**:
- **Maximum pending notifications**: 64 per app
- **Delivery timing**: Within 1 second of scheduled time
- **Notification content size**: ~4KB per notification
- **Sound duration**: Maximum 30 seconds

**Behavioral Limits**:
- Notifications older than scheduled time are dropped
- Duplicate identifiers replace previous notifications
- Background delivery not guaranteed if app force-quit
- System may delay delivery under heavy load

### Impact on LaundryTime

**Worst Case Scenario**:
- User has 20 pets
- Each pet can have 3 concurrent timers (wash, dry, fold reminder)
- Total potential notifications: 60
- **Risk**: Approaching limit with just 20 pets

**Realistic Scenario**:
- Typical user: 2-5 pets
- Average active timers: 1-2 per pet
- Total notifications: 2-10
- **Status**: Well within limits

---

## 📊 Notification Budget Tracking

### Budget Manager

```swift
@MainActor
final class NotificationBudgetManager: ObservableObject {
    static let shared = NotificationBudgetManager()
    
    @Published var pendingCount: Int = 0
    @Published var budgetStatus: BudgetStatus = .healthy
    
    private let maxNotifications = 64
    private let warningThreshold = 50  // 78% capacity
    private let criticalThreshold = 60  // 94% capacity
    
    enum BudgetStatus {
        case healthy       // < 50 notifications
        case warning       // 50-59 notifications
        case critical      // 60-63 notifications
        case atLimit       // 64 notifications
        
        var color: Color {
            switch self {
            case .healthy: return .happyGreen
            case .warning: return .neutralOrange
            case .critical: return .sadRed
            case .atLimit: return .error
            }
        }
        
        var message: String {
            switch self {
            case .healthy:
                return "Notification system healthy"
            case .warning:
                return "Approaching notification limit. Consider completing some cycles."
            case .critical:
                return "Very close to notification limit. Some notifications may not be scheduled."
            case .atLimit:
                return "Notification limit reached. Complete cycles to free up space."
            }
        }
    }
    
    func updateBudget() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        
        await MainActor.run {
            self.pendingCount = pending.count
            self.budgetStatus = calculateStatus(count: pending.count)
        }
    }
    
    private func calculateStatus(count: Int) -> BudgetStatus {
        switch count {
        case 0..<warningThreshold:
            return .healthy
        case warningThreshold..<criticalThreshold:
            return .warning
        case criticalThreshold..<maxNotifications:
            return .critical
        default:
            return .atLimit
        }
    }
    
    func availableSlots() async -> Int {
        await updateBudget()
        return max(0, maxNotifications - pendingCount)
    }
    
    func canSchedule(count: Int) async -> Bool {
        let available = await availableSlots()
        return available >= count
    }
}
```

---

## 🎯 Smart Notification Scheduling

### Priority System

```swift
enum NotificationPriority: Int, Comparable {
    case critical = 3      // Immediate cycle completion (wash done, dry done)
    case high = 2          // Upcoming completion (5 min warning)
    case medium = 1        // Health warnings
    case low = 0           // Informational
    
    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct PendingNotification {
    let identifier: String
    let priority: NotificationPriority
    let scheduledDate: Date
    let content: UNNotificationContent
    let petID: UUID
}
```

### Intelligent Scheduler

```swift
@MainActor
final class IntelligentNotificationScheduler {
    static let shared = IntelligentNotificationScheduler()
    
    private let budgetManager = NotificationBudgetManager.shared
    private var scheduledNotifications: [PendingNotification] = []
    
    func scheduleNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String,
        priority: NotificationPriority,
        petID: UUID
    ) async throws {
        // Check budget
        let available = await budgetManager.availableSlots()
        
        if available == 0 {
            // At limit - need to make space
            try await makeSpace(for: priority)
        }
        
        // Create notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule
        try await UNUserNotificationCenter.current().add(request)
        
        // Track
        let notification = PendingNotification(
            identifier: identifier,
            priority: priority,
            scheduledDate: date,
            content: content,
            petID: petID
        )
        scheduledNotifications.append(notification)
        
        // Update budget
        await budgetManager.updateBudget()
    }
    
    private func makeSpace(for priority: NotificationPriority) async throws {
        // Get all pending notifications
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        
        // Find lowest priority notification that's lower than requested priority
        var lowestPriority: NotificationPriority = .critical
        var lowestIdentifier: String?
        
        for notification in scheduledNotifications {
            if notification.priority < priority && notification.priority <= lowestPriority {
                lowestPriority = notification.priority
                lowestIdentifier = notification.identifier
            }
        }
        
        guard let identifier = lowestIdentifier else {
            throw NotificationError.cannotMakeSpace
        }
        
        // Cancel lowest priority notification
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeAll { $0.identifier == identifier }
        
        print("📤 Removed low-priority notification to make space: \(identifier)")
    }
    
    func cancelNotification(identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeAll { $0.identifier == identifier }
        await budgetManager.updateBudget()
    }
    
    func cancelAllNotifications(for petID: UUID) async {
        let identifiers = scheduledNotifications
            .filter { $0.petID == petID }
            .map { $0.identifier }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        scheduledNotifications.removeAll { $0.petID == petID }
        await budgetManager.updateBudget()
    }
}

enum NotificationError: LocalizedError {
    case limitExceeded
    case cannotMakeSpace
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .limitExceeded:
            return "Notification limit reached"
        case .cannotMakeSpace:
            return "Cannot free up notification space"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}
```

---

## 🧹 Notification Cleanup

### Automatic Cleanup

```swift
struct NotificationCleaner {
    static func cleanupExpiredNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        
        let now = Date()
        var expiredIdentifiers: [String] = []
        
        for request in pending {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let triggerDate = trigger.nextTriggerDate(),
               triggerDate < now {
                expiredIdentifiers.append(request.identifier)
            }
        }
        
        if !expiredIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: expiredIdentifiers)
            print("🧹 Cleaned up \(expiredIdentifiers.count) expired notifications")
        }
    }
    
    static func cleanupCompletedCycles() async {
        // When a cycle completes, remove its notifications
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        
        let identifiers = delivered.map { $0.request.identifier }
        
        if !identifiers.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
            print("🧹 Cleaned up \(identifiers.count) delivered notifications")
        }
    }
    
    static func cleanupOnAppLaunch() async {
        // Clean expired
        await cleanupExpiredNotifications()
        
        // Clean delivered
        await cleanupCompletedCycles()
        
        // Update budget
        await NotificationBudgetManager.shared.updateBudget()
    }
}

// In App lifecycle
struct LaundryTimeApp: App {
    init() {
        Task {
            await NotificationCleaner.cleanupOnAppLaunch()
        }
    }
}
```

---

## ⚠️ User-Facing Limit Handling

### Warning UI

```swift
struct NotificationBudgetWarning: View {
    @ObservedObject var budgetManager = NotificationBudgetManager.shared
    
    var body: some View {
        if budgetManager.budgetStatus != .healthy {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: warningIcon)
                        .foregroundColor(budgetManager.budgetStatus.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notification Budget")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(budgetManager.budgetStatus.message)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(budgetManager.pendingCount)/64")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.textTertiary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surface)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(budgetManager.budgetStatus.color)
                            .frame(
                                width: geometry.size.width * CGFloat(budgetManager.pendingCount) / 64,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surface)
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
            .padding(.horizontal)
        }
    }
    
    private var warningIcon: String {
        switch budgetManager.budgetStatus {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .atLimit: return "xmark.circle.fill"
        }
    }
}

// Show in dashboard
struct PetDashboardView: View {
    var body: some View {
        VStack {
            NotificationBudgetWarning()
            
            // Rest of dashboard...
        }
    }
}
```

### Settings Info

```swift
struct NotificationDebugView: View {
    @ObservedObject var budgetManager = NotificationBudgetManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        List {
            Section("Budget Status") {
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(budgetManager.pendingCount)")
                        .foregroundColor(budgetManager.budgetStatus.color)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Available Slots")
                    Spacer()
                    Text("\(64 - budgetManager.pendingCount)")
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(statusText)
                        .foregroundColor(budgetManager.budgetStatus.color)
                }
            }
            
            Section("Pending Notifications") {
                if pendingNotifications.isEmpty {
                    Text("No pending notifications")
                        .foregroundColor(.textSecondary)
                } else {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                                .font(.headline)
                            
                            Text(notification.identifier)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                               let date = trigger.nextTriggerDate() {
                                Text(date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Refresh") {
                    Task {
                        await loadNotifications()
                    }
                }
                
                Button("Clean Up Expired", role: .destructive) {
                    Task {
                        await NotificationCleaner.cleanupExpiredNotifications()
                        await loadNotifications()
                    }
                }
            }
        }
        .navigationTitle("Notification Budget")
        .task {
            await loadNotifications()
        }
    }
    
    private var statusText: String {
        switch budgetManager.budgetStatus {
        case .healthy: return "Healthy"
        case .warning: return "Warning"
        case .critical: return "Critical"
        case .atLimit: return "At Limit"
        }
    }
    
    private func loadNotifications() async {
        await budgetManager.updateBudget()
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        self.pendingNotifications = pending.sorted { $0.identifier < $1.identifier }
    }
}
```

---

## 🎯 Optimization Strategies

### Strategy 1: Consolidate Notifications

Instead of individual notifications per stage, use one notification per cycle:

```swift
func scheduleConsolidatedNotification(for pet: Pet, task: LaundryTask) async {
    // Cancel individual stage notifications
    await cancelStageNotifications(for: pet.id)
    
    // Schedule single "Cycle Complete" notification at fold time
    let foldTime = calculateFoldTime(task: task)
    
    try? await IntelligentNotificationScheduler.shared.scheduleNotification(
        title: "\(pet.name)'s laundry is ready!",
        body: "Time to fold and complete the cycle",
        date: foldTime,
        identifier: "cycle_complete_\(pet.id.uuidString)",
        priority: .critical,
        petID: pet.id
    )
}
```

**Savings**: 3 notifications → 1 notification per cycle

### Strategy 2: Just-In-Time Scheduling

Don't schedule all notifications upfront - schedule as needed:

```swift
func scheduleNextStageNotification(for pet: Pet, stage: LaundryStage) async {
    // Cancel future stages
    await cancelFutureStageNotifications(for: pet.id, after: stage)
    
    // Schedule only the immediate next stage
    guard let nextStage = stage.next else { return }
    
    let nextTime = calculateStageTime(for: nextStage)
    
    try? await IntelligentNotificationScheduler.shared.scheduleNotification(
        title: "\(pet.name): \(nextStage.displayName)",
        body: nextStage.notificationBody,
        date: nextTime,
        identifier: "\(pet.id.uuidString)_\(nextStage.rawValue)",
        priority: .critical,
        petID: pet.id
    )
}
```

**Savings**: Only 1 notification scheduled at a time per pet

### Strategy 3: Batch Operations

When completing cycles, batch notification updates:

```swift
func batchCompleteCycles(pets: [Pet]) async {
    // Collect all notification changes
    var toCancel: [String] = []
    var toSchedule: [(title: String, body: String, date: Date, id: String, priority: NotificationPriority, petID: UUID)] = []
    
    for pet in pets {
        // Cancel completed cycle notifications
        toCancel.append("cycle_\(pet.id.uuidString)")
        
        // Schedule health warning if needed
        if let warningDate = calculateHealthWarningDate(for: pet) {
            toSchedule.append((
                title: "\(pet.name) needs laundry",
                body: "Health is declining",
                date: warningDate,
                id: "health_warning_\(pet.id.uuidString)",
                priority: .medium,
                petID: pet.id
            ))
        }
    }
    
    // Execute batch
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toCancel)
    
    for item in toSchedule {
        try? await IntelligentNotificationScheduler.shared.scheduleNotification(
            title: item.title,
            body: item.body,
            date: item.date,
            identifier: item.id,
            priority: item.priority,
            petID: item.petID
        )
    }
    
    await NotificationBudgetManager.shared.updateBudget()
}
```

---

## 📱 User Education

### Onboarding Message

```swift
struct NotificationLimitEducation: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .font(.largeTitle)
                .foregroundColor(.primaryBlue)
            
            Text("Notification Tip")
                .font(.headline)
            
            Text("iOS limits apps to 64 pending notifications. LaundryTime manages this automatically, but with many pets and timers, older notifications may be replaced.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Text("💡 Complete cycles regularly to free up notification space")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### In-App Tips

- Show tip when creating 10th pet
- Show tip when budget reaches warning level
- Include in Help/FAQ section

---

## 🧪 Testing Notification Limits

### Test Scenarios

```swift
final class NotificationLimitTests: XCTestCase {
    
    func testApproachingLimit() async throws {
        // Create 20 pets with active timers
        for i in 1...20 {
            let pet = Pet(name: "Pet \(i)")
            // Start wash, dry, and schedule fold reminder
            // = 3 notifications per pet = 60 total
        }
        
        let budgetManager = NotificationBudgetManager.shared
        await budgetManager.updateBudget()
        
        XCTAssertEqual(budgetManager.budgetStatus, .critical)
    }
    
    func testSmartEviction() async throws {
        // Fill to capacity with low-priority notifications
        for i in 1...64 {
            try await scheduleNotification(priority: .low, id: "low_\(i)")
        }
        
        // Try to schedule high-priority notification
        try await scheduleNotification(priority: .critical, id: "critical_1")
        
        // Verify high-priority was scheduled by evicting low-priority
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let hasCritical = pending.contains { $0.identifier == "critical_1" }
        
        XCTAssertTrue(hasCritical)
    }
    
    func testCleanupRemovesExpired() async throws {
        // Schedule notifications in the past
        let pastDate = Date().addingTimeInterval(-3600)
        try await scheduleNotification(date: pastDate, id: "expired")
        
        // Run cleanup
        await NotificationCleaner.cleanupExpiredNotifications()
        
        // Verify removed
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let hasExpired = pending.contains { $0.identifier == "expired" }
        
        XCTAssertFalse(hasExpired)
    }
}
```

---

## 📊 Monitoring & Analytics

### Track Notification Health

```swift
struct NotificationAnalytics {
    static func recordNotificationScheduled(priority: NotificationPriority) {
        var counts = UserDefaults.standard.dictionary(forKey: "notificationScheduleCounts") as? [String: Int] ?? [:]
        let key = "priority_\(priority.rawValue)"
        counts[key, default: 0] += 1
        UserDefaults.standard.set(counts, forKey: "notificationScheduleCounts")
    }
    
    static func recordNotificationEvicted(priority: NotificationPriority) {
        var counts = UserDefaults.standard.dictionary(forKey: "notificationEvictionCounts") as? [String: Int] ?? [:]
        let key = "priority_\(priority.rawValue)"
        counts[key, default: 0] += 1
        UserDefaults.standard.set(counts, forKey: "notificationEvictionCounts")
    }
    
    static func recordBudgetStatus(_ status: NotificationBudgetManager.BudgetStatus) {
        let key = "lastBudgetStatus"
        UserDefaults.standard.set(status.rawValue, forKey: key)
    }
    
    static func getNotificationHealth() -> [String: Any] {
        return [
            "scheduleCounts": UserDefaults.standard.dictionary(forKey: "notificationScheduleCounts") ?? [:],
            "evictionCounts": UserDefaults.standard.dictionary(forKey: "notificationEvictionCounts") ?? [:],
            "lastBudgetStatus": UserDefaults.standard.string(forKey: "lastBudgetStatus") ?? "unknown"
        ]
    }
}
```

---

## ✅ Implementation Checklist

### Core Features
- [ ] NotificationBudgetManager implemented
- [ ] IntelligentNotificationScheduler implemented
- [ ] Priority system defined
- [ ] Smart eviction logic working
- [ ] Cleanup routines automated

### UI Components
- [ ] Budget warning banner created
- [ ] Debug view for settings
- [ ] User education displayed
- [ ] Limit reached handling graceful

### Testing
- [ ] Limit tests passing
- [ ] Eviction tests passing
- [ ] Cleanup tests passing
- [ ] Real-device testing with 20+ pets

### Monitoring
- [ ] Budget tracking implemented
- [ ] Analytics recorded locally
- [ ] Debug logging comprehensive

---

## 🎯 Recommended Strategy for V1.0

### Conservative Approach

**For V1.0, keep it simple:**

1. **Limit pets to 10 maximum** (60 potential notifications max)
2. **Use just-in-time scheduling** (only schedule next immediate stage)
3. **Aggressive cleanup** (clean on every app launch and cycle completion)
4. **No warnings unless critical** (don't alarm users unnecessarily)

**Implementation**:

```swift
// In PetsViewModel
let maxPets = 10

func canCreatePet() -> Bool {
    return pets.count < maxPets
}

func createPet(name: String) {
    guard canCreatePet() else {
        showError = true
        errorMessage = "Maximum 10 pets reached. Complete or delete pets to create more."
        return
    }
    
    // Create pet...
}
```

### Future Enhancement (V1.1+)

- Remove pet limit
- Implement full intelligent scheduler
- Add priority-based eviction
- Show budget monitoring UI

---

**Smart notification management ensures reliability even as users scale their laundry management.** 🔔✨