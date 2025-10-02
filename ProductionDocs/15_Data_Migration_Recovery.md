# LaundryTime - Data Migration Strategy

## Overview

This document defines the comprehensive data migration strategy for LaundryTime, covering schema changes, version upgrades, data integrity, and rollback procedures. While V1.0 doesn't require migrations, planning ahead ensures smooth future updates.

---

## 🎯 Migration Philosophy

### Core Principles

1. **Never Lose User Data**: Data preservation is the highest priority
2. **Automatic & Silent**: Migrations happen transparently to users
3. **Fast Execution**: Migrations complete in < 1 second for typical data
4. **Rollback Ready**: Can revert if migration fails
5. **Progressive Enhancement**: New features don't break old data

### Migration Types

**Type 1: Additive** (Safest)
- Adding new properties with default values
- Adding new entities
- No risk to existing data

**Type 2: Transformative** (Moderate Risk)
- Renaming properties
- Changing data types
- Restructuring relationships
- Requires careful testing

**Type 3: Destructive** (Highest Risk)
- Removing properties
- Deleting entities
- Changing core data structures
- Requires backup and user notification

---

## 🗄️ SwiftData Schema Versioning

### Version Schema Definition

```swift
// V1 Schema (Current - V1.0.0)
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Pet.self, LaundryTask.self, AppSettings.self]
    }
    
    @Model
    final class Pet {
        var id: UUID
        var name: String
        var createdDate: Date
        var currentState: PetState
        var lastLaundryDate: Date?
        var isActive: Bool
        var health: Int?
        var lastHealthUpdate: Date?
        var totalCyclesCompleted: Int
        var currentStreak: Int
        var longestStreak: Int
        var cycleFrequencyDays: Int
        var washDurationMinutes: Int
        var dryDurationMinutes: Int
        
        // Initializer...
    }
    
    // Other models...
}

// V2 Schema (Future - Example)
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Pet.self, LaundryTask.self, AppSettings.self, Achievement.self]  // New model
    }
    
    @Model
    final class Pet {
        // All V1 properties...
        
        // NEW: Pet customization
        var colorTheme: String?  // New optional property
        var characterType: String?  // New optional property
        
        // Initializer with defaults for new properties...
    }
    
    @Model
    final class Achievement {  // New entity
        var id: UUID
        var type: AchievementType
        var unlockedDate: Date
        var petID: UUID
        
        // Initializer...
    }
}
```

### Container Configuration

```swift
struct LaundryTimeApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            container = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

---

## 🔄 Migration Plans

### V1 → V2 Migration Plan (Example)

```swift
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Pre-migration tasks
            print("📦 Starting migration V1 → V2")
            
            // Create backup
            try? backupDatabase(context: context)
            
            // Validate existing data
            try validatePreMigrationData(context: context)
        },
        didMigrate: { context in
            // Post-migration tasks
            print("✅ Migration V1 → V2 complete")
            
            // Set default values for new properties
            let pets = try context.fetch(FetchDescriptor<SchemaV2.Pet>())
            
            for pet in pets {
                if pet.colorTheme == nil {
                    pet.colorTheme = "default"
                }
                if pet.characterType == nil {
                    pet.characterType = "classic"
                }
            }
            
            try context.save()
            
            // Log migration success
            logMigrationSuccess(from: SchemaV1.self, to: SchemaV2.self)
        }
    )
    
    // Helper functions
    static func backupDatabase(context: ModelContext) throws {
        // Implementation in backup section below
    }
    
    static func validatePreMigrationData(context: ModelContext) throws {
        // Validate all pets have required fields
        let descriptor = FetchDescriptor<SchemaV1.Pet>()
        let pets = try context.fetch(descriptor)
        
        for pet in pets {
            guard !pet.name.isEmpty else {
                throw MigrationError.invalidData(reason: "Pet has empty name")
            }
        }
    }
    
    static func logMigrationSuccess(from: any VersionedSchema.Type, to: any VersionedSchema.Type) {
        UserDefaults.standard.set(Date(), forKey: "lastMigrationDate")
        UserDefaults.standard.set("\(from.versionIdentifier)", forKey: "lastMigrationFrom")
        UserDefaults.standard.set("\(to.versionIdentifier)", forKey: "lastMigrationTo")
    }
}

enum MigrationError: Error {
    case invalidData(reason: String)
    case backupFailed
    case migrationFailed(underlyingError: Error)
}
```

---

## 💾 Backup Strategy

### Pre-Migration Backup

```swift
struct DatabaseBackup {
    static func createBackup() throws -> URL {
        // Get database location
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databasePath = documentsPath.appendingPathComponent("default.store")
        
        guard FileManager.default.fileExists(atPath: databasePath.path) else {
            throw BackupError.databaseNotFound
        }
        
        // Create backup directory
        let backupDirectory = documentsPath.appendingPathComponent("backups")
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        // Create timestamped backup
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupPath = backupDirectory.appendingPathComponent("backup_\(timestamp).store")
        
        // Copy database
        try FileManager.default.copyItem(at: databasePath, to: backupPath)
        
        print("✅ Backup created: \(backupPath.lastPathComponent)")
        
        return backupPath
    }
    
    static func restoreBackup(from backupURL: URL) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databasePath = documentsPath.appendingPathComponent("default.store")
        
        // Remove current database
        if FileManager.default.fileExists(atPath: databasePath.path) {
            try FileManager.default.removeItem(at: databasePath)
        }
        
        // Restore backup
        try FileManager.default.copyItem(at: backupURL, to: databasePath)
        
        print("✅ Backup restored: \(backupURL.lastPathComponent)")
    }
    
    static func listBackups() -> [URL] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDirectory = documentsPath.appendingPathComponent("backups")
        
        guard let backups = try? FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        return backups.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    static func cleanOldBackups(keepRecent: Int = 3) throws {
        let backups = listBackups()
        
        // Keep only most recent backups
        if backups.count > keepRecent {
            for backup in backups.dropFirst(keepRecent) {
                try FileManager.default.removeItem(at: backup)
                print("🗑️ Deleted old backup: \(backup.lastPathComponent)")
            }
        }
    }
}

enum BackupError: Error {
    case databaseNotFound
    case backupFailed
    case restoreFailed
}
```

### Automatic Backup Triggers

```swift
struct BackupManager {
    static func shouldCreateBackup() -> Bool {
        // Check last backup date
        if let lastBackup = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date {
            // Backup once per day
            return Date().timeIntervalSince(lastBackup) > 24 * 3600
        }
        
        return true
    }
    
    static func createBackupIfNeeded() {
        guard shouldCreateBackup() else { return }
        
        do {
            let backupURL = try DatabaseBackup.createBackup()
            UserDefaults.standard.set(Date(), forKey: "lastBackupDate")
            UserDefaults.standard.set(backupURL.path, forKey: "lastBackupPath")
            
            // Clean old backups
            try DatabaseBackup.cleanOldBackups()
        } catch {
            print("❌ Backup failed: \(error)")
        }
    }
}

// Call in app lifecycle
struct LaundryTimeApp: App {
    init() {
        // ... container setup ...
        
        // Create backup before potential migrations
        BackupManager.createBackupIfNeeded()
    }
}
```

---

## 🧪 Migration Testing

### Test Cases

```swift
final class MigrationTests: XCTestCase {
    
    func testV1ToV2Migration() throws {
        // 1. Setup V1 database with test data
        let v1Container = try createV1Container()
        let context = v1Container.mainContext
        
        let pet = SchemaV1.Pet(name: "Test Pet")
        context.insert(pet)
        try context.save()
        
        // 2. Perform migration
        let v2Container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV2.self),
            migrationPlan: MigrationPlan.self
        )
        
        // 3. Verify data integrity
        let v2Context = v2Container.mainContext
        let descriptor = FetchDescriptor<SchemaV2.Pet>()
        let pets = try v2Context.fetch(descriptor)
        
        XCTAssertEqual(pets.count, 1)
        XCTAssertEqual(pets.first?.name, "Test Pet")
        
        // 4. Verify new properties have defaults
        XCTAssertEqual(pets.first?.colorTheme, "default")
        XCTAssertEqual(pets.first?.characterType, "classic")
    }
    
    func testMigrationWithMultiplePets() throws {
        // Test with realistic data volume
        let v1Container = try createV1Container()
        let context = v1Container.mainContext
        
        // Create 100 pets
        for i in 1...100 {
            let pet = SchemaV1.Pet(name: "Pet \(i)")
            pet.totalCyclesCompleted = Int.random(in: 0...50)
            context.insert(pet)
        }
        try context.save()
        
        // Measure migration time
        let startTime = Date()
        
        let v2Container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV2.self),
            migrationPlan: MigrationPlan.self
        )
        
        let migrationTime = Date().timeIntervalSince(startTime)
        
        // Verify migration was fast
        XCTAssertLessThan(migrationTime, 2.0, "Migration took too long")
        
        // Verify all pets migrated
        let v2Context = v2Container.mainContext
        let count = try v2Context.fetchCount(FetchDescriptor<SchemaV2.Pet>())
        XCTAssertEqual(count, 100)
    }
    
    func testMigrationRollback() throws {
        // 1. Create backup
        let backupURL = try DatabaseBackup.createBackup()
        
        // 2. Attempt migration (simulate failure)
        do {
            // Force migration to fail
            throw MigrationError.migrationFailed(underlyingError: NSError(domain: "test", code: -1))
        } catch {
            // 3. Rollback
            try DatabaseBackup.restoreBackup(from: backupURL)
        }
        
        // 4. Verify data intact
        let container = try createV1Container()
        let context = container.mainContext
        let pets = try context.fetch(FetchDescriptor<SchemaV1.Pet>())
        
        XCTAssertGreaterThan(pets.count, 0, "Data should be restored")
    }
    
    func testCorruptDataHandling() throws {
        // Create pet with invalid data
        let container = try createV1Container()
        let context = container.mainContext
        
        let pet = SchemaV1.Pet(name: "")  // Invalid: empty name
        context.insert(pet)
        try context.save()
        
        // Migration should detect and fix
        do {
            try MigrationPlan.validatePreMigrationData(context: context)
            XCTFail("Should have thrown validation error")
        } catch MigrationError.invalidData {
            // Expected
        }
    }
    
    // Helper
    func createV1Container() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
```

---

## 🚨 Migration Error Handling

### Error Detection

```swift
struct MigrationMonitor {
    static func detectMigrationFailure() -> Bool {
        // Check if app crashed during last migration
        let isMigrating = UserDefaults.standard.bool(forKey: "isMigrating")
        let lastVersion = UserDefaults.standard.string(forKey: "lastSuccessfulVersion")
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        return isMigrating || (lastVersion != currentVersion && lastVersion != nil)
    }
    
    static func setMigrationInProgress(_ inProgress: Bool) {
        UserDefaults.standard.set(inProgress, forKey: "isMigrating")
        UserDefaults.standard.synchronize()
    }
    
    static func markMigrationSuccess() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        UserDefaults.standard.set(version, forKey: "lastSuccessfulVersion")
        UserDefaults.standard.set(false, forKey: "isMigrating")
        UserDefaults.standard.synchronize()
    }
}
```

### Recovery Flow

```swift
struct MigrationRecovery {
    static func handleFailedMigration() {
        // Show alert to user
        let alert = UIAlertController(
            title: "Update Issue",
            message: "There was a problem updating your data. We can try again or restore from backup.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            attemptMigrationRetry()
        })
        
        alert.addAction(UIAlertAction(title: "Restore Backup", style: .default) { _ in
            restoreFromBackup()
        })
        
        alert.addAction(UIAlertAction(title: "Reset Data", style: .destructive) { _ in
            resetAllData()
        })
        
        // Present alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    static func attemptMigrationRetry() {
        MigrationMonitor.setMigrationInProgress(true)
        
        do {
            // Retry migration
            let container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV2.self),
                migrationPlan: MigrationPlan.self
            )
            
            MigrationMonitor.markMigrationSuccess()
            
            // Restart app
            restartApp()
        } catch {
            print("❌ Migration retry failed: \(error)")
            handleFailedMigration()
        }
    }
    
    static func restoreFromBackup() {
        do {
            let backups = DatabaseBackup.listBackups()
            guard let latestBackup = backups.first else {
                throw BackupError.backupFailed
            }
            
            try DatabaseBackup.restoreBackup(from: latestBackup)
            
            MigrationMonitor.setMigrationInProgress(false)
            
            // Restart app
            restartApp()
        } catch {
            print("❌ Restore failed: \(error)")
            // Last resort: reset
            resetAllData()
        }
    }
    
    static func resetAllData() {
        // Delete database
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databasePath = documentsPath.appendingPathComponent("default.store")
        
        try? FileManager.default.removeItem(at: databasePath)
        
        // Clear UserDefaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Restart app
        restartApp()
    }
    
    static func restartApp() {
        exit(0)  // iOS will restart app when user relaunches
    }
}
```

---

## 📋 Migration Checklist

### Pre-Release
- [ ] Schema version incremented
- [ ] Migration plan written
- [ ] Migration tests passing
- [ ] Backup mechanism tested
- [ ] Rollback procedure tested
- [ ] Migration time profiled (< 2s)
- [ ] Large dataset tested (1000+ records)
- [ ] Error handling implemented

### Beta Testing
- [ ] TestFlight users test migration
- [ ] Monitor crash reports
- [ ] Check migration success rate
- [ ] Gather performance data
- [ ] Test on various iOS versions
- [ ] Test on various device models

### Production Release
- [ ] Migration monitoring enabled
- [ ] Backup automatic
- [ ] Error recovery tested
- [ ] Support documentation ready
- [ ] Rollback plan documented

---

## 📊 Migration Monitoring

### Metrics to Track

```swift
struct MigrationMetrics {
    static func recordMigration(
        fromVersion: String,
        toVersion: String,
        duration: TimeInterval,
        recordCount: Int,
        success: Bool
    ) {
        let metric = [
            "fromVersion": fromVersion,
            "toVersion": toVersion,
            "duration": duration,
            "recordCount": recordCount,
            "success": success,
            "timestamp": Date(),
            "iosVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model
        ] as [String : Any]
        
        // Store locally for debugging
        var metrics = UserDefaults.standard.array(forKey: "migrationMetrics") as? [[String: Any]] ?? []
        metrics.append(metric)
        
        // Keep only last 10 migrations
        if metrics.count > 10 {
            metrics = Array(metrics.suffix(10))
        }
        
        UserDefaults.standard.set(metrics, forKey: "migrationMetrics")
    }
    
    static func getMigrationHistory() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "migrationMetrics") as? [[String: Any]] ?? []
    }
}
```

---

## 🔮 Future Migration Scenarios

### V1 → V2: Add Pet Customization

**Changes**:
- Add `colorTheme: String?` to Pet
- Add `characterType: String?` to Pet
- Add new `Achievement` entity

**Migration**: Additive (Safe)
- Default values for new properties
- No data transformation needed

### V2 → V3: Restructure Statistics

**Changes**:
- Move statistics from Pet to new `Statistics` entity
- Add detailed cycle history

**Migration**: Transformative (Moderate)
- Create Statistics entities
- Copy data from Pet
- Maintain relationships

**Plan**:
```swift
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: { context in
        // Backup
        try DatabaseBackup.createBackup()
    },
    didMigrate: { context in
        // For each pet, create Statistics entity
        let pets = try context.fetch(FetchDescriptor<SchemaV3.Pet>())
        
        for pet in pets {
            let stats = SchemaV3.Statistics(petID: pet.id)
            stats.totalCycles = pet.totalCyclesCompleted
            stats.currentStreak = pet.currentStreak
            stats.longestStreak = pet.longestStreak
            
            context.insert(stats)
        }
        
        try context.save()
    }
)
```

### V3 → V4: Add iCloud Sync

**Changes**:
- Add sync metadata to all entities
- Add conflict resolution fields

**Migration**: Additive with logic (Moderate)
- Add sync fields with defaults
- Mark all existing data as "local only"

---

## ✅ Best Practices

### Do's ✅
- Always create backups before migrations
- Test migrations with realistic data volumes
- Provide default values for new properties
- Log all migration steps
- Monitor migration success rates
- Plan rollback procedures
- Test on multiple iOS versions

### Don'ts ❌
- Don't delete data without user consent
- Don't perform slow migrations (> 2 seconds)
- Don't migrate without backups
- Don't ignore migration failures
- Don't force users to update immediately
- Don't lose user's custom settings
- Don't break old app versions

---

**Well-planned migrations preserve user trust and data integrity across all app updates.** 🔄✨