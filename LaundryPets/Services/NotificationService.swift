//
//  NotificationService.swift
//  LaundryPets
//
//  Comprehensive notification service for timer completions and health warnings
//  Handles permission management, scheduling, cancellation, and badge management
//

import Foundation
import UserNotifications
import SwiftUI

/// Health threshold levels that trigger notifications
enum HealthThreshold: Int, CaseIterable {
    case critical = 25    // "Your pet needs attention soon!"
    case urgent = 10      // "Your pet really needs laundry!"
    case severe = 5       // "Your pet is in critical condition!"
    case dead = 0         // "Your pet has died 😢"
    
    /// User-friendly description for notification content
    var notificationTitle: String {
        switch self {
        case .critical:
            return "⚠️ Needs Laundry Soon"
        case .urgent:
            return "🚨 Really Needs Laundry!"
        case .severe:
            return "💔 Critical Condition!"
        case .dead:
            return "😢 Pet Has Died"
        }
    }
    
    /// User-friendly body text for notification content
    func notificationBody(petName: String) -> String {
        switch self {
        case .critical:
            return "\(petName)'s health at 25% - start a laundry cycle soon!"
        case .urgent:
            return "\(petName)'s health at 10% - urgent attention needed!"
        case .severe:
            return "\(petName)'s health at 5% - immediate action required!"
        case .dead:
            return "Start a new laundry cycle to revive \(petName)."
        }
    }
}

/// Notification categories for different types of notifications
enum NotificationCategory: String {
    case timerComplete = "TIMER_COMPLETE"
    case healthWarning = "HEALTH_WARNING"
    case petDead = "PET_DEAD"
}


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
        setupNotificationCategories()
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
        timerType: SimpleTimerType,
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
            content.title = "🫧 Wash Complete!"
            content.body = "\(petName) is ready for the dryer!"
        case .dry:
            content.title = "🌬️ Dry Complete!"
            content.body = "Time to fold \(petName)'s laundry!"
        case .extraDry:
            content.title = "🔥 Extra Dry Complete!"
            content.body = "\(petName)'s laundry is super dry!"
        case .cycle:
            content.title = "🧺 Laundry Time!"
            content.body = "\(petName) needs attention!"
        }
        
        // Configure notification
        content.sound = soundEnabled ? .default : nil
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = NotificationCategory.timerComplete.rawValue
        content.userInfo = [
            "petID": petID.uuidString,
            "timerType": timerType.rawValue,
            "notificationType": "timer"
        ]
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, timeInterval),
            repeats: false
        )
        
        // Create request
        let identifier = timerNotificationIdentifier(for: petID, type: timerType)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule timer notification: \(error)")
            } else {
                print("✅ Timer notification scheduled: \(identifier) in \(Int(timeInterval))s")
            }
        }
    }
    
    /// Cancel specific timer notification
    func cancelTimerNotification(for petID: UUID, type: SimpleTimerType) {
        let identifier = timerNotificationIdentifier(for: petID, type: type)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🚫 Cancelled timer notification: \(identifier)")
    }
    
    /// Cancel all timer notifications for a pet
    func cancelAllTimerNotifications(for petID: UUID) {
        let identifiers = SimpleTimerType.allCases.map { timerNotificationIdentifier(for: petID, type: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 Cancelled all timer notifications for pet: \(petID)")
    }
    
    // MARK: - Health-Based Notifications
    
    /// Schedule health warning notification for a specific threshold
    func scheduleHealthWarning(for petID: UUID, petName: String, healthLevel: Int, triggerDate: Date) {
        guard permissionStatus == .authorized else {
            print("⚠️ Cannot schedule health notification: Permission not granted")
            return
        }
        
        guard notificationsEnabled else {
            print("⚠️ Cannot schedule health notification: Notifications disabled in app settings")
            return
        }
        
        guard let threshold = HealthThreshold(rawValue: healthLevel) else {
            print("❌ Invalid health level for notification: \(healthLevel)")
            return
        }
        
        // Don't schedule if trigger date is in the past
        guard triggerDate > Date() else {
            print("⚠️ Health notification trigger date is in the past: \(triggerDate)")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = threshold.notificationTitle
        content.body = threshold.notificationBody(petName: petName)
        
        // Configure notification
        content.sound = soundEnabled ? .default : nil
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = healthLevel == 0 ? NotificationCategory.petDead.rawValue : NotificationCategory.healthWarning.rawValue
        content.userInfo = [
            "petID": petID.uuidString,
            "healthLevel": healthLevel,
            "notificationType": "health"
        ]
        
        // Create date trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request
        let identifier = healthNotificationIdentifier(for: petID, healthLevel: healthLevel)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule health notification: \(error)")
            } else {
                print("✅ Health notification scheduled: \(identifier) for \(triggerDate)")
            }
        }
    }
    
    /// Cancel health notifications for a pet
    func cancelHealthNotifications(for petID: UUID) {
        let identifiers = HealthThreshold.allCases.map { healthNotificationIdentifier(for: petID, healthLevel: $0.rawValue) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 Cancelled all health notifications for pet: \(petID)")
    }
    
    /// Cancel specific health notification
    func cancelSpecificHealthNotification(for petID: UUID, healthLevel: Int) {
        let identifier = healthNotificationIdentifier(for: petID, healthLevel: healthLevel)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🚫 Cancelled health notification: \(identifier)")
    }
    
    /// Reset health notifications when pet health improves (e.g., after laundry)
    func resetHealthNotifications(for petID: UUID, petName: String, currentHealth: Int) {
        // Cancel all existing health notifications
        cancelHealthNotifications(for: petID)
        
        // Mark all thresholds as not sent (reset tracking)
        resetHealthNotificationTracking(for: petID)
        
        // Schedule new notifications for remaining thresholds
        scheduleProactiveHealthNotifications(for: petID, petName: petName, currentHealth: currentHealth)
    }
    
    // MARK: - Proactive Health Notification Scheduling
    
    /// Schedule health notifications based on current health and cycle frequency
    func scheduleProactiveHealthNotifications(for petID: UUID, petName: String, currentHealth: Int, cycleFrequencyDays: Int, referenceDate: Date) {
        guard currentHealth > 0 else { return }
        
        let thresholds = [25, 10, 5, 0]
        
        for threshold in thresholds {
            // Skip if already passed this threshold
            guard currentHealth > threshold else { continue }
            
            // Skip if already sent this notification
            guard !hasHealthNotificationBeenSent(for: petID, healthLevel: threshold) else { continue }
            
            // Calculate days needed to decay to this threshold
            let healthToLose = currentHealth - threshold
            let daysToThreshold = (Double(healthToLose) / 100.0) * Double(cycleFrequencyDays)
            
            // Calculate trigger date
            let triggerDate = referenceDate.addingTimeInterval(daysToThreshold * 24 * 3600)
            
            // Only schedule if trigger date is in the future
            guard triggerDate > Date() else { continue }
            
            // Schedule notification
            scheduleHealthWarning(for: petID, petName: petName, healthLevel: threshold, triggerDate: triggerDate)
            
            // Mark as sent
            markHealthNotificationAsSent(for: petID, healthLevel: threshold)
        }
    }
    
    /// Simplified version for immediate scheduling
    private func scheduleProactiveHealthNotifications(for petID: UUID, petName: String, currentHealth: Int) {
        // This would need pet data - for now, we'll use a default cycle frequency
        // In real implementation, this should be called with pet data
        scheduleProactiveHealthNotifications(for: petID, petName: petName, currentHealth: currentHealth, cycleFrequencyDays: 7, referenceDate: Date())
    }
    
    // MARK: - Health Notification Tracking
    
    /// Track which health notifications have been sent to avoid duplicates
    private func healthNotificationTrackingKey(for petID: UUID) -> String {
        return "pet_health_notifications_\(petID.uuidString)"
    }
    
    /// Check if a health notification has been sent for a specific threshold
    private func hasHealthNotificationBeenSent(for petID: UUID, healthLevel: Int) -> Bool {
        let key = healthNotificationTrackingKey(for: petID)
        let sentNotifications = UserDefaults.standard.object(forKey: key) as? [Int] ?? []
        return sentNotifications.contains(healthLevel)
    }
    
    /// Mark a health notification as sent
    private func markHealthNotificationAsSent(for petID: UUID, healthLevel: Int) {
        let key = healthNotificationTrackingKey(for: petID)
        var sentNotifications = UserDefaults.standard.object(forKey: key) as? [Int] ?? []
        if !sentNotifications.contains(healthLevel) {
            sentNotifications.append(healthLevel)
            UserDefaults.standard.set(sentNotifications, forKey: key)
        }
    }
    
    /// Reset health notification tracking (when health improves)
    private func resetHealthNotificationTracking(for petID: UUID) {
        let key = healthNotificationTrackingKey(for: petID)
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    /// Clear health notification tracking when pet is deleted
    func clearHealthNotificationTracking(for petID: UUID) {
        resetHealthNotificationTracking(for: petID)
        cancelHealthNotifications(for: petID)
    }
    
    // MARK: - Badge Management
    
    /// Update app icon badge count based on pets needing attention
    func updateAppBadge(pets: [Pet]) {
        let healthUpdateService = HealthUpdateService.shared
        let needsAttention = pets.filter { pet in
            let health = healthUpdateService.calculateCurrentHealth(for: pet)
            return health <= 25 || pet.currentState == .dead
        }.count
        
        updateBadgeCount(needsAttention)
    }
    
    /// Update app icon badge count
    func updateBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            // Use modern UNUserNotificationCenter API
            center.setBadgeCount(count) { error in
                if let error = error {
                    print("❌ Failed to update badge count: \(error)")
                }
            }
        } else {
            // Fallback for older iOS versions
            UIApplication.shared.applicationIconBadgeNumber = count
        }
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
    
    // MARK: - Notification Categories Setup
    
    /// Setup notification categories with actions
    private func setupNotificationCategories() {
        // Timer completion actions
        let startWashAction = UNNotificationAction(
            identifier: "START_WASH",
            title: "Start Wash",
            options: [.foreground]
        )
        
        let viewPetAction = UNNotificationAction(
            identifier: "VIEW_PET",
            title: "View Pet",
            options: [.foreground]
        )
        
        let timerCategory = UNNotificationCategory(
            identifier: NotificationCategory.timerComplete.rawValue,
            actions: [startWashAction, viewPetAction],
            intentIdentifiers: []
        )
        
        // Health warning actions
        let startCycleAction = UNNotificationAction(
            identifier: "START_CYCLE",
            title: "Start Laundry",
            options: [.foreground]
        )
        
        let healthCategory = UNNotificationCategory(
            identifier: NotificationCategory.healthWarning.rawValue,
            actions: [startCycleAction, viewPetAction],
            intentIdentifiers: []
        )
        
        let petDeadCategory = UNNotificationCategory(
            identifier: NotificationCategory.petDead.rawValue,
            actions: [startCycleAction, viewPetAction],
            intentIdentifiers: []
        )
        
        center.setNotificationCategories([timerCategory, healthCategory, petDeadCategory])
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
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🚫 Cancelled all pending notifications")
    }
    
    // MARK: - Helper Methods
    
    private func timerNotificationIdentifier(for petID: UUID, type: SimpleTimerType) -> String {
        "timer_\(petID.uuidString)_\(type.rawValue)"
    }
    
    private func healthNotificationIdentifier(for petID: UUID, healthLevel: Int) -> String {
        "health_\(petID.uuidString)_\(healthLevel)"
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

// MARK: - Supporting Extensions

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
