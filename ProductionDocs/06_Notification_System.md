# LaundryTime - Notification System

## Overview

The notification system is critical to LaundryTime's user experience, ensuring users never miss a laundry cycle completion. This document specifies the complete notification architecture, permission handling, scheduling logic, and user preference management.

---

## 🎯 Notification Requirements

### Functional Requirements

**FR-1: Timer Completion Notifications**

- Deliver notification when wash cycle completes
- Deliver notification when dry cycle completes
- Notifications include clear, actionable text
- Deep link back to specific pet on tap

**FR-2: Permission Management**

- Request permission at appropriate time (not immediately on launch)
- Handle permission denied gracefully
- Allow users to enable/disable notifications in settings
- Respect iOS system notification preferences

**FR-3: Reliable Delivery**

- Notifications scheduled at exact timer end time
- Survive app termination and device restart
- Cancel notifications if timer manually stopped
- Update notifications if timer duration changes

**FR-4: User Preferences**

- Allow sound on/off
- Allow badge count on/off
- Test notification feature in settings
- Clear notification language and value

### Non-Functional Requirements

**NFR-1: User Experience**

- Permission request feels natural, not intrusive
- Clear value proposition for notifications
- No spam (only meaningful notifications)
- Notification content is friendly and helpful

**NFR-2: Privacy**

- Local notifications only (no remote/server)
- No notification tracking or analytics
- User has complete control

**NFR-3: Performance**

- Scheduling has negligible performance impact
- Notification delivery is accurate (± 2 seconds)
- Badge updates are instant

---

## 🏗️ Architecture

### NotificationService

**Design Pattern**: Singleton service managing all notification operations

**Responsibilities**:

- Request notification permissions
- Check permission status
- Schedule timer completion notifications
- Cancel notifications
- Send test notifications
- Manage badge count

**Location**: `LaundryTime/Services/NotificationService.swift`

### Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                    Notification Flow                         │
└─────────────────────────────────────────────────────────────┘

PetViewModel
    ↓
    User taps "Start Wash"
    ↓
PetTimerService.startTimer()
    ↓
    Calculates endTime
    ↓
    Calls scheduleCompletionNotification()
    ↓
NotificationService.scheduleNotification()
    ↓
    Creates UNNotificationContent
    ↓
    Sets UNTimeIntervalNotificationTrigger
    ↓
    Submits UNNotificationRequest to iOS
    ↓
iOS UserNotificationCenter
    ↓
    [App closes, time passes...]
    ↓
    Timer reaches endTime
    ↓
iOS delivers notification
    ↓
    User taps notification
    ↓
App launches / foregrounds
    ↓
    Optional: Deep link to specific pet
```

---

## 📋 Complete Implementation

### NotificationService Class

```swift
import Foundation
import UserNotifications
import SwiftUI

@MainActor
final class NotificationService: ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Published State

    /// Current authorization status
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are enabled in app settings
    @Published var notificationsEnabled: Bool = true

    /// Whether sounds are enabled for notifications
    @Published var soundEnabled: Bool = true

    // MARK: - Private Properties

    private let center = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {
        updatePermissionStatus()
        observeAppLifecycle()
    }

    // MARK: - Permission Management

    /// Request notification permission from user
    /// Should be called at appropriate time (e.g., before first timer start)
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                updatePermissionStatus()
            }

            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }

            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    /// Check current permission status
    func updatePermissionStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionStatus = settings.authorizationStatus
                print("📱 Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }

    /// Open iOS Settings to enable notifications (if user denied)
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Timer Completion Notifications

    /// Schedule notification for timer completion
    func scheduleTimerNotification(
        petID: UUID,
        petName: String,
        timerType: TimerType,
        timeInterval: TimeInterval
    ) {
        guard permissionStatus == .authorized else {
            print("⚠️ Cannot schedule notification: Permission not granted")
            return
        }

        guard notificationsEnabled else {
            print("⚠️ Cannot schedule notification: Notifications disabled in app settings")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()

        switch timerType {
        case .wash:
            content.title = "Wash Complete!"
            content.body = "\(petName) is ready for the dryer!"
        case .dry:
            content.title = "Dry Complete!"
            content.body = "Time to fold \(petName)'s laundry!"
        case .cycle:
            content.title = "Laundry Time!"
            content.body = "\(petName) needs attention!"
        }

        // Configure notification
        content.sound = soundEnabled ? .default : nil
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "TIMER_COMPLETE"
        content.userInfo = [
            "petID": petID.uuidString,
            "timerType": timerType.rawValue
        ]

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, timeInterval),
            repeats: false
        )

        // Create request
        let identifier = notificationIdentifier(for: petID, type: timerType)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Notification scheduled: \(identifier) in \(Int(timeInterval))s")
            }
        }
    }

    /// Cancel specific notification
    func cancelNotification(for petID: UUID, type: TimerType) {
        let identifier = notificationIdentifier(for: petID, type: type)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🚫 Cancelled notification: \(identifier)")
    }

    /// Cancel all notifications for a pet
    func cancelAllNotifications(for petID: UUID) {
        let identifiers = TimerType.allCases.map { notificationIdentifier(for: petID, type: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 Cancelled all notifications for pet: \(petID)")
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🚫 Cancelled all pending notifications")
    }

    // MARK: - Badge Management

    /// Update app icon badge count
    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    /// Clear app icon badge
    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - Test Notification

    /// Send test notification (for settings testing)
    func sendTestNotification() {
        guard permissionStatus == .authorized else {
            print("⚠️ Cannot send test notification: Permission not granted")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notifications are working perfectly! 🎉"
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send test notification: \(error)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }

    // MARK: - Notification Listing (Debug)

    /// Get list of all pending notifications
    func listPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    /// Print all pending notifications (debug)
    func debugPrintPendingNotifications() {
        Task {
            let requests = await listPendingNotifications()
            print("📬 Pending notifications: \(requests.count)")
            for request in requests {
                let trigger = request.trigger as? UNTimeIntervalNotificationTrigger
                let timeRemaining = trigger?.nextTriggerDate()?.timeIntervalSinceNow ?? 0
                print("  - \(request.identifier): \(Int(timeRemaining))s remaining")
            }
        }
    }

    // MARK: - Helper Methods

    private func notificationIdentifier(for petID: UUID, type: TimerType) -> String {
        "timer_\(petID.uuidString)_\(type.rawValue)"
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // Update permission status when app becomes active
        // (user may have changed settings in iOS Settings app)
        updatePermissionStatus()

        // Clear badge when app opens
        clearBadge()
    }
}

// MARK: - Supporting Types

enum TimerType: String, Codable, CaseIterable {
    case cycle = "cycle"
    case wash = "wash"
    case dry = "dry"
}

extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}
```

---

## 🎭 Permission Request Flow

### When to Request Permission

**❌ Don't Request Immediately on Launch**

- Users don't understand the value yet
- Feels intrusive and spammy
- High rejection rate

**✅ Request at Natural Moment**

- When user taps "Start Wash" for the first time
- User understands why notifications are needed
- Context makes permission valuable

### Permission Request Implementation

```swift
// In PetViewModel.swift

func startWash() {
    Task {
        // Check if we need to request permission
        let notificationService = NotificationService.shared

        if notificationService.permissionStatus == .notDetermined {
            // First time - request permission
            let granted = await notificationService.requestPermission()

            if granted {
                // Permission granted - proceed with timer
                await MainActor.run {
                    startWashTimer()
                }
            } else {
                // Permission denied - still start timer, but warn user
                await MainActor.run {
                    startWashTimer()
                    showNotificationWarning = true
                }
            }
        } else {
            // Permission already handled - proceed
            startWashTimer()
        }
    }
}

private func startWashTimer() {
    guard let pet = pet else { return }

    // Start timer via PetTimerService
    let duration = TimeInterval(pet.washDurationMinutes * 60)
    petTimerService.startTimer(duration: duration, type: .wash)

    // Schedule notification (if authorized)
    NotificationService.shared.scheduleTimerNotification(
        petID: pet.id,
        petName: pet.name,
        timerType: .wash,
        timeInterval: duration
    )
}
```

### Permission States & Handling

**Not Determined** (Never asked):

```swift
Status: .notDetermined
Behavior:
  - Request permission at natural moment
  - Show clear value proposition
  - Handle both granted and denied
```

**Authorized** (User granted):

```swift
Status: .authorized
Behavior:
  - Schedule notifications normally
  - No prompts needed
  - Deliver notifications on time
```

**Denied** (User denied):

```swift
Status: .denied
Behavior:
  - App continues to work normally
  - Timer still functions (in-app progress)
  - Show gentle reminder in settings:
    "Enable notifications in iOS Settings to get reminders when laundry is done."
  - Provide "Open Settings" button
```

**Provisional** (iOS 12+ quiet notifications):

```swift
Status: .provisional
Behavior:
  - Notifications delivered quietly
  - No interruption to user
  - Can be promoted to .authorized later
```

---

## 📝 Notification Content Strategy

### Timer Completion Notifications

**Wash Complete**:

```
Title: "Wash Complete!"
Body: "{PetName} is ready for the dryer!"
Sound: Default (if enabled)
Badge: 1
Category: TIMER_COMPLETE
UserInfo: { petID: UUID, timerType: "wash" }

Why this content:
  - Clear what happened ("Wash Complete")
  - Next action implied ("ready for the dryer")
  - Personal (uses pet name)
  - Friendly, not nagging
```

**Dry Complete**:

```
Title: "Dry Complete!"
Body: "Time to fold {PetName}'s laundry!"
Sound: Default (if enabled)
Badge: 1
Category: TIMER_COMPLETE
UserInfo: { petID: UUID, timerType: "dry" }

Why this content:
  - Clear completion ("Dry Complete")
  - Actionable ("time to fold")
  - Personal (pet name)
  - Encouraging tone
```

### Notification Categories (Future Enhancement)

**Category: TIMER_COMPLETE**

```swift
// Notification actions (iOS 10+)
let completeAction = UNNotificationAction(
    identifier: "COMPLETE_ACTION",
    title: "Mark Folded",
    options: [.foreground]
)

let snoozeAction = UNNotificationAction(
    identifier: "SNOOZE_ACTION",
    title: "Remind in 10 min",
    options: []
)

let category = UNNotificationCategory(
    identifier: "TIMER_COMPLETE",
    actions: [completeAction, snoozeAction],
    intentIdentifiers: []
)

UNUserNotificationCenter.current().setNotificationCategories([category])
```

---

## 🎨 Settings UI Integration

### App Settings - Notifications Section

```swift
Section(header: Text("Notifications")) {
    // Master toggle
    Toggle("Enable Notifications", isOn: $notificationsEnabled)
        .onChange(of: notificationsEnabled) { newValue in
            if newValue && notificationService.permissionStatus == .denied {
                showPermissionAlert = true
            }
        }

    // Sound toggle
    Toggle("Sound", isOn: $soundEnabled)
        .disabled(!notificationsEnabled)

    // Test button
    Button("Test Notification") {
        notificationService.sendTestNotification()
    }
    .disabled(!notificationsEnabled || notificationService.permissionStatus != .authorized)
}
footer: {
    if notificationService.permissionStatus == .denied {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications are disabled in iOS Settings.")
                .foregroundColor(.secondary)

            Button("Open Settings") {
                notificationService.openSettings()
            }
            .foregroundColor(.accentColor)
        }
    } else {
        Text("Get notified when laundry cycles complete")
    }
}
```

---

## 🔔 Notification Scenarios

### Scenario 1: Happy Path (Permission Granted)

```
1. User creates first pet
2. User taps "Start Wash"
3. System requests notification permission
4. User taps "Allow"
5. Timer starts, notification scheduled
6. User closes app
7. 45 minutes pass
8. iOS delivers notification: "Wash Complete! Snowy is ready for the dryer!"
9. User taps notification
10. App opens directly to Snowy's detail view
11. "Start Dryer" button ready
```

### Scenario 2: Permission Denied

```
1. User creates first pet
2. User taps "Start Wash"
3. System requests notification permission
4. User taps "Don't Allow"
5. Timer still starts (in-app progress works)
6. App shows subtle message: "Notifications disabled - keep app open to see progress"
7. User can re-enable in Settings → Notifications → Open iOS Settings
```

### Scenario 3: Multiple Pets, Multiple Notifications

```
1. User has 3 pets
2. User starts wash for Pet A (Snowy) → Notification scheduled for 2:00 PM
3. User starts wash for Pet B (Fluffy) → Notification scheduled for 2:15 PM
4. User starts dry for Pet C (Buddy) → Notification scheduled for 2:30 PM
5. App closed
6. iOS delivers:
   - 2:00 PM: "Wash Complete! Snowy is ready for the dryer!"
   - 2:15 PM: "Wash Complete! Fluffy is ready for the dryer!"
   - 2:30 PM: "Dry Complete! Time to fold Buddy's laundry!"
7. Badge count: 3
8. User opens app → Badge clears
```

### Scenario 4: Timer Cancelled

```
1. User starts wash timer
2. Notification scheduled
3. User changes mind, taps "Stop Timer"
4. PetTimerService.stopTimer() called
5. NotificationService.cancelNotification() called
6. Notification removed from iOS queue
7. No notification delivered
```

---

## 🧪 Testing Checklist

### Functional Tests

- [ ] **Permission Request**: Request appears when expected
- [ ] **Permission Granted**: Notifications schedule successfully
- [ ] **Permission Denied**: App continues to work
- [ ] **Notification Delivery**: Notification appears at correct time
- [ ] **Notification Content**: Title, body, and pet name correct
- [ ] **Notification Tap**: Opens app to correct pet
- [ ] **Multiple Notifications**: All pets' notifications deliver
- [ ] **Notification Cancellation**: Cancelled timers don't notify
- [ ] **Badge Count**: Badge updates correctly
- [ ] **Badge Clear**: Badge clears when app opened
- [ ] **Sound Toggle**: Sound respects settings
- [ ] **Test Notification**: Test button sends notification
- [ ] **Settings Link**: Opens iOS Settings correctly

### Edge Case Tests

- [ ] **App Force Quit**: Notifications still deliver
- [ ] **Device Restart**: Notifications still deliver after reboot
- [ ] **Time Zone Change**: Notifications adjust to new time zone
- [ ] **System Time Change**: Notifications recalculate correctly
- [ ] **Low Power Mode**: Notifications still deliver
- [ ] **Do Not Disturb**: Notifications queue and deliver when DND ends
- [ ] **Airplane Mode**: Notifications deliver (local, no network needed)
- [ ] **Permission Revoked**: App handles gracefully, shows settings prompt

### Performance Tests

- [ ] **Scheduling Speed**: < 50ms to schedule notification
- [ ] **No Memory Leaks**: Observers properly managed
- [ ] **Battery Impact**: Negligible (notifications are system-managed)
- [ ] **Accuracy**: Notifications deliver within ±2 seconds of target time

---

## 🐛 Common Issues & Solutions

### Issue: Notifications Not Appearing

**Symptoms**: Timer completes but no notification shows

**Debugging Steps**:

1. Check permission status: `notificationService.permissionStatus`
2. Check if notification was scheduled: `notificationService.debugPrintPendingNotifications()`
3. Verify trigger time is in future, not past
4. Check iOS Settings → Notifications → LaundryTime → Allow Notifications
5. Check Do Not Disturb is off
6. Check notification center for delivered notifications

**Common Causes**:

- Permission denied
- Notification scheduled with past timestamp
- iOS Settings notifications disabled
- Do Not Disturb enabled

### Issue: Duplicate Notifications

**Symptoms**: Multiple notifications for same timer

**Debugging Steps**:

1. Check if notification properly cancelled before rescheduling
2. Verify unique identifiers for each notification
3. Check if multiple timer services created for same pet

**Solution**:

```swift
// Always cancel before scheduling
cancelNotification(for: petID, type: timerType)
scheduleTimerNotification(...)
```

### Issue: Badge Count Incorrect

**Symptoms**: Badge shows wrong number

**Debugging Steps**:

1. Check when badge is updated
2. Verify badge cleared on app foreground
3. Check if all notification completions update badge

**Solution**:

```swift
// Clear badge when app becomes active
func appDidBecomeActive() {
    NotificationService.shared.clearBadge()
}
```

---

## 📊 Notification Analytics (Future)

### Metrics to Track (Privacy-Preserving)

**Engagement**:

- Notification delivery rate (scheduled vs. delivered)
- Notification tap rate (delivered vs. tapped)
- Time from notification to app open
- Actions taken after notification (complete cycle vs. dismiss)

**Permission**:

- Permission request acceptance rate
- Permission request timing impact
- Re-engagement after denial

**Implementation Note**:
Only track locally, no external analytics. Use UserDefaults counters. Example:

```swift
// Local counters only
private func logNotificationTapped() {
    let count = UserDefaults.standard.integer(forKey: "notificationTapCount")
    UserDefaults.standard.set(count + 1, forKey: "notificationTapCount")
}
```

---

## ✅ Notification System Checklist

### Implementation

- [x] NotificationService singleton created
- [x] Permission request at appropriate time
- [x] Handle all permission states
- [x] Schedule timer completion notifications
- [x] Cancel notifications when timer stopped
- [x] Badge management
- [x] Test notification feature
- [x] Settings UI integration
- [x] iOS Settings deep link

### User Experience

- [ ] Permission request feels natural
- [ ] Clear value proposition shown
- [ ] Works without permission granted
- [ ] Notification content is helpful
- [ ] Deep linking works correctly
- [ ] Settings clearly explain status

### Testing

- [ ] All functional tests pass
- [ ] Edge cases handled
- [ ] Performance acceptable
- [ ] No memory leaks
- [ ] Accurate delivery timing

---

## 🎯 Success Criteria

**Notification system is successful when**:

- ✅ 80%+ users grant notification permission
- ✅ 95%+ scheduled notifications deliver on time
- ✅ 90%+ notification taps result in app open
- ✅ Zero crashes related to notifications
- ✅ < 5% user reports of missed notifications

**User feedback should indicate**:

- "I never forget laundry anymore"
- "Notifications are helpful, not annoying"
- "Love that I get notified exactly when done"
- "Notifications make the app actually useful"

---

## 🚀 Future Enhancements

### V1.1 - Enhanced Notifications

- Notification actions ("Mark Folded", "Snooze 10 min")
- Rich notifications with pet image
- Custom notification sounds per pet
- Notification scheduling based on user patterns

### V1.2 - Smart Notifications

- Quiet hours (no notifications at night)
- Location-based notifications (only notify when home)
- Notification grouping (combine multiple pets)
- Critical alerts for very neglected pets

### V2.0 - Advanced Features

- Apple Watch notifications
- Live Activities (Dynamic Island)
- Lock Screen widgets with timer
- Siri shortcuts for marking complete

---

**The notification system turns LaundryTime from a simple app into an indispensable tool.** 🔔✨
