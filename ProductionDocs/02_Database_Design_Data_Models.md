# LaundryTime - Database Design & Data Models

## Overview

LaundryTime uses **SwiftData** (Apple's declarative data persistence framework) for all local data storage. This document provides comprehensive specifications for the database schema, model relationships, query patterns, and data management strategies.

---

## 🗄️ Database Architecture

### SwiftData Framework Choice

**Why SwiftData?**

- Native Apple framework (iOS 17+ optimizations, backward compatible to iOS 15)
- Declarative `@Model` macro for automatic persistence
- Type-safe queries with `#Predicate`
- Automatic relationship management
- iCloud sync ready (future enhancement)
- SwiftUI integration via `@Query` property wrapper
- No external dependencies (Core Data successor)

**Database Location**:

- SQLite database stored in app's Documents directory
- Path: `~/Documents/default.store`
- Automatic file system management
- Encrypted at rest (iOS file system encryption)

---

## 📊 Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                              Pet                                 │
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ PK  id: UUID                                                     │
│     name: String                                                 │
│     createdDate: Date                                            │
│     currentState: PetState (enum)                                │
│     lastLaundryDate: Date?                                       │
│     isActive: Bool                                               │
│     health: Int? (0-100)                                         │
│     lastHealthUpdate: Date?                                      │
│     totalCyclesCompleted: Int                                    │
│     currentStreak: Int                                           │
│     longestStreak: Int                                           │
│     cycleFrequencyDays: Int                                      │
│     washDurationMinutes: Int                                     │
│     dryDurationMinutes: Int                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N (One Pet → Many Tasks)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         LaundryTask                              │
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ PK  id: UUID                                                     │
│ FK  petID: UUID                                                  │
│     startDate: Date                                              │
│     currentStage: LaundryStage (enum)                            │
│     isCompleted: Bool                                            │
│     washStartTime: Date?                                         │
│     washEndTime: Date?                                           │
│     dryStartTime: Date?                                          │
│     dryEndTime: Date?                                            │
│     foldCompletedTime: Date?                                     │
│     washDurationMinutes: Int                                     │
│     dryDurationMinutes: Int                                      │
│     additionalDryMinutes: Int?                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         AppSettings                              │
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ (Singleton - Only one instance in database)                     │
│     notificationsEnabled: Bool                                   │
│     soundEnabled: Bool                                           │
│     hapticsEnabled: Bool                                         │
│     appearanceMode: AppearanceMode (enum)                        │
└─────────────────────────────────────────────────────────────────┘
```

**Key Relationship**:

- `Pet` → `LaundryTask`: One-to-Many via `petID` foreign key
- Cascade delete: Deleting a Pet removes all associated LaundryTasks
- No relationship between Pet and AppSettings (global vs. per-pet)

---

## 📋 Model Specifications

### Pet Model

**Purpose**: Represents a virtual pet with independent state, health, statistics, and settings.

**Swift Implementation**:

```swift
import Foundation
import SwiftData

@Model
final class Pet {
    // ========================================
    // MARK: - Identity
    // ========================================

    /// Unique identifier (primary key)
    var id: UUID

    /// User-defined pet name (e.g., "Snowy", "Fluffy")
    /// Constraints: 1-30 characters, display in UI
    var name: String

    /// Timestamp when pet was created
    /// Used for sorting ("oldest pet first")
    var createdDate: Date

    // ========================================
    // MARK: - State
    // ========================================

    /// Current emotional/activity state
    /// Determines UI presentation (animation, color, text)
    var currentState: PetState

    /// Last time a laundry cycle was completed
    /// nil = never completed laundry
    /// Used for health decay calculation
    var lastLaundryDate: Date?

    /// Whether pet is active in the system
    /// Soft delete: isActive = false instead of hard delete
    /// Allows "reactivating" pets without data loss
    var isActive: Bool

    // ========================================
    // MARK: - Health System
    // ========================================

    /// Current health level (0-100)
    /// 100 = perfectly healthy (recent laundry)
    /// 0 = dead (too long without laundry)
    /// Decreases over time based on cycleFrequencyDays
    var health: Int?

    /// Last time health was updated
    /// Used to prevent redundant calculations
    /// Updated every 30 seconds by HealthUpdateService
    var lastHealthUpdate: Date?

    // ========================================
    // MARK: - Statistics
    // ========================================

    /// Total laundry cycles completed (lifetime)
    /// Incremented when user taps "Mark Folded"
    /// Never decreases (even if streak broken)
    var totalCyclesCompleted: Int

    /// Current consecutive streak
    /// Incremented on completion if cycle finished on time
    /// Reset to 0 if pet dies or cycle abandoned
    var currentStreak: Int

    /// Longest streak ever achieved
    /// High score for user motivation
    /// Only increases, never decreases
    var longestStreak: Int

    // ========================================
    // MARK: - Per-Pet Settings (INDEPENDENT!)
    // ========================================

    /// How often this pet needs laundry (in days)
    /// 0 = testing mode (immediate decay)
    /// 1 = daily laundry
    /// 7 = weekly laundry
    /// Affects health decay rate
    var cycleFrequencyDays: Int

    /// Wash timer duration (in minutes)
    /// Default: 45 minutes (typical washing machine)
    /// Range: 1-120 minutes
    /// INDEPENDENT per pet (not global setting!)
    var washDurationMinutes: Int

    /// Dry timer duration (in minutes)
    /// Default: 60 minutes (typical dryer)
    /// Range: 1-180 minutes
    /// INDEPENDENT per pet (not global setting!)
    var dryDurationMinutes: Int

    // ========================================
    // MARK: - Initializer
    // ========================================

    init(name: String = "Snowy") {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.currentState = .neutral
        self.isActive = true
        self.health = 100
        self.lastHealthUpdate = Date()
        self.totalCyclesCompleted = 0
        self.currentStreak = 0
        self.longestStreak = 0

        // Default settings (can be customized per pet)
        self.cycleFrequencyDays = 0  // 0 = testing (5 min cycles)
        self.washDurationMinutes = 1  // 1 min for testing
        self.dryDurationMinutes = 1   // 1 min for testing
    }
}
```

**Field Constraints & Validation**:

| Field                  | Type     | Nullable | Default        | Validation                |
| ---------------------- | -------- | -------- | -------------- | ------------------------- |
| `id`                   | UUID     | No       | Auto-generated | N/A (system-managed)      |
| `name`                 | String   | No       | "Snowy"        | 1-30 characters, no empty |
| `createdDate`          | Date     | No       | `Date()`       | Cannot be future date     |
| `currentState`         | PetState | No       | `.neutral`     | Valid enum case           |
| `lastLaundryDate`      | Date?    | Yes      | `nil`          | Cannot be future date     |
| `isActive`             | Bool     | No       | `true`         | N/A                       |
| `health`               | Int?     | Yes      | `100`          | 0-100 range               |
| `lastHealthUpdate`     | Date?    | Yes      | `Date()`       | Cannot be future date     |
| `totalCyclesCompleted` | Int      | No       | `0`            | >= 0                      |
| `currentStreak`        | Int      | No       | `0`            | >= 0                      |
| `longestStreak`        | Int      | No       | `0`            | >= 0                      |
| `cycleFrequencyDays`   | Int      | No       | `0`            | 0-365 range               |
| `washDurationMinutes`  | Int      | No       | `1`            | 1-120 range               |
| `dryDurationMinutes`   | Int      | No       | `1`            | 1-180 range               |

---

### PetState Enum

**Purpose**: Defines all possible emotional and activity states for a pet.

**Swift Implementation**:

```swift
import Foundation

/// Pet emotional and activity states
/// Determines UI presentation (color, animation, text)
enum PetState: String, CaseIterable, Codable {
    // ========================================
    // MARK: - Emotional States
    // ========================================

    /// Pet is very happy (recent laundry completed)
    /// Health: 100-75%
    /// Color: Green
    /// Animation: Bouncing/dancing
    case happy = "happy"

    /// Pet is content (laundry somewhat recent)
    /// Health: 74-50%
    /// Color: Blue
    /// Animation: Idle swaying
    case neutral = "neutral"

    /// Pet needs attention (laundry overdue)
    /// Health: 49-25%
    /// Color: Orange
    /// Animation: Sad expression
    case sad = "sad"

    /// Pet is very neglected (critically needs laundry)
    /// Health: 24-1%
    /// Color: Red
    /// Animation: Very sad, possibly crying
    case verySad = "verySad"

    /// Pet has died from neglect
    /// Health: 0%
    /// Color: Gray
    /// Animation: None (static sad face)
    /// Can be revived by completing laundry
    case dead = "dead"

    // ========================================
    // MARK: - Activity States
    // ========================================

    /// Pet is currently being washed (timer active)
    /// Temporary state during wash cycle
    /// Color: Blue with bubbles
    /// Animation: Washing motion
    case washing = "washing"

    /// Pet is currently being dried (timer active)
    /// Temporary state during dry cycle
    /// Color: Yellow/orange with heat lines
    /// Animation: Spinning/drying motion
    case drying = "drying"

    /// Pet is being folded (final step)
    /// Temporary state before completion
    /// Color: Green
    /// Animation: Folding motion
    case folding = "folding"

    // ========================================
    // MARK: - Display Text
    // ========================================

    /// User-facing text shown below pet
    var displayText: String {
        switch self {
        case .happy: return "is so happy!"
        case .neutral: return "is doing okay"
        case .sad: return "needs some laundry love"
        case .verySad: return "is very sad and neglected"
        case .dead: return "has died from neglect"
        case .washing: return "is getting clean!"
        case .drying: return "is drying off"
        case .folding: return "is being folded"
        }
    }

    /// Animation asset name (if using Lottie)
    var animationName: String {
        return "pet_\(rawValue)"
    }

    /// Color associated with state
    var color: Color {
        switch self {
        case .happy: return .happyGreen
        case .neutral: return .primaryBlue
        case .sad: return .neutralOrange
        case .verySad: return .sadRed
        case .dead: return .textTertiary
        case .washing: return .washBlue
        case .drying: return .dryYellow
        case .folding: return .happyGreen
        }
    }
}
```

**State Transition Rules**:

```
Happy → Neutral → Sad → VerySad → Dead (health decay over time)
      ↑                               ↓
      └─────── Complete Laundry ──────┘

Any State → Washing → Drying → Folding → Happy (laundry cycle)
```

---

### LaundryTask Model

**Purpose**: Represents a single laundry cycle for a specific pet.

**Swift Implementation**:

```swift
import Foundation
import SwiftData

@Model
final class LaundryTask {
    // ========================================
    // MARK: - Identity & Relationship
    // ========================================

    /// Unique identifier (primary key)
    var id: UUID

    /// Foreign key to Pet
    /// Links this task to a specific pet
    /// CASCADE DELETE: If pet deleted, all tasks deleted
    var petID: UUID

    /// When this task was created
    /// Used for sorting and statistics
    var startDate: Date

    // ========================================
    // MARK: - State
    // ========================================

    /// Current stage in the laundry workflow
    /// Determines which action button to show
    var currentStage: LaundryStage

    /// Whether the entire cycle is complete
    /// true = all stages done, pet is happy
    /// false = still in progress or abandoned
    var isCompleted: Bool

    // ========================================
    // MARK: - Timing (Audit Trail)
    // ========================================

    /// When wash stage started
    /// nil = not started yet
    var washStartTime: Date?

    /// When wash stage ended
    /// nil = not finished yet or skipped
    var washEndTime: Date?

    /// When dry stage started
    /// nil = not started yet
    var dryStartTime: Date?

    /// When dry stage ended
    /// nil = not finished yet or skipped
    var dryEndTime: Date?

    /// When folding was marked complete
    /// nil = not folded yet
    /// When set, isCompleted = true
    var foldCompletedTime: Date?

    // ========================================
    // MARK: - Duration Settings
    // ========================================

    /// Wash duration (in minutes)
    /// Copied from Pet.washDurationMinutes at task creation
    /// Stored here so changing pet settings doesn't affect active tasks
    var washDurationMinutes: Int

    /// Dry duration (in minutes)
    /// Copied from Pet.dryDurationMinutes at task creation
    var dryDurationMinutes: Int

    /// Additional dry time if user needs more (optional feature)
    /// nil = no additional time requested
    /// Used for "Dry 10 More Minutes" button
    var additionalDryMinutes: Int?

    // ========================================
    // MARK: - Initializer
    // ========================================

    init(petID: UUID, washDuration: Int = 45, dryDuration: Int = 60) {
        self.id = UUID()
        self.petID = petID
        self.startDate = Date()
        self.currentStage = .cycle
        self.isCompleted = false
        self.washDurationMinutes = washDuration
        self.dryDurationMinutes = dryDuration
    }
}
```

**Field Constraints & Validation**:

| Field                  | Type         | Nullable | Default        | Validation                 |
| ---------------------- | ------------ | -------- | -------------- | -------------------------- |
| `id`                   | UUID         | No       | Auto-generated | N/A                        |
| `petID`                | UUID         | No       | Required       | Must match existing Pet.id |
| `startDate`            | Date         | No       | `Date()`       | Cannot be future date      |
| `currentStage`         | LaundryStage | No       | `.cycle`       | Valid enum case            |
| `isCompleted`          | Bool         | No       | `false`        | N/A                        |
| `washStartTime`        | Date?        | Yes      | `nil`          | If set, >= startDate       |
| `washEndTime`          | Date?        | Yes      | `nil`          | If set, >= washStartTime   |
| `dryStartTime`         | Date?        | Yes      | `nil`          | If set, >= washEndTime     |
| `dryEndTime`           | Date?        | Yes      | `nil`          | If set, >= dryStartTime    |
| `foldCompletedTime`    | Date?        | Yes      | `nil`          | If set, >= dryEndTime      |
| `washDurationMinutes`  | Int          | No       | `45`           | 1-120 range                |
| `dryDurationMinutes`   | Int          | No       | `60`           | 1-180 range                |
| `additionalDryMinutes` | Int?         | Yes      | `nil`          | 1-60 range                 |

---

### LaundryStage Enum

**Purpose**: Defines stages in the laundry workflow.

**Swift Implementation**:

```swift
import Foundation

/// Laundry workflow stages
enum LaundryStage: String, CaseIterable, Codable {
    /// Background cycle timer (time between laundries)
    /// This is the "waiting" state before laundry is needed
    case cycle = "cycle"

    /// Wash timer active
    /// User has started washing, timer counting down
    case washing = "washing"

    /// Dry timer active
    /// User has moved clothes to dryer, timer counting down
    case drying = "drying"

    /// Cycle complete, ready to fold
    /// Timer finished, waiting for user to mark as folded
    case completed = "completed"

    /// Display text for current stage
    var displayText: String {
        switch self {
        case .cycle: return "Ready to start laundry"
        case .washing: return "Washing in progress..."
        case .drying: return "Drying in progress..."
        case .completed: return "Time to fold!"
        }
    }

    /// Action button text for current stage
    var actionButtonText: String {
        switch self {
        case .cycle: return "Start Wash"
        case .washing: return "Washing..."
        case .drying: return "Move to Dryer"
        case .completed: return "Mark Folded"
        }
    }

    /// Whether action button should be enabled
    var isActionable: Bool {
        switch self {
        case .cycle: return true
        case .washing: return false // Wait for timer
        case .drying: return false // Wait for timer
        case .completed: return true
        }
    }
}
```

**Stage Transition Flow**:

```
cycle → washing → drying → completed → (task archived, new task created at cycle)
```

---

### AppSettings Model

**Purpose**: Global app-level configuration (NOT per-pet settings).

**Swift Implementation**:

```swift
import Foundation
import SwiftData

@Model
final class AppSettings {
    // ========================================
    // MARK: - Notification Settings
    // ========================================

    /// Master notification toggle
    /// false = no notifications scheduled (respect user preference)
    var notificationsEnabled: Bool

    /// Play sound with notifications
    /// Requires notificationsEnabled = true
    var soundEnabled: Bool

    /// Enable haptic feedback for interactions
    /// Affects button taps, timer completions, etc.
    var hapticsEnabled: Bool

    // ========================================
    // MARK: - App Settings
    // ========================================

    /// App appearance mode
    /// .light, .dark, or .system (follow iOS setting)
    var appearanceMode: AppearanceMode

    // ========================================
    // MARK: - Initializer
    // ========================================

    init() {
        self.notificationsEnabled = true
        self.soundEnabled = true
        self.hapticsEnabled = true
        self.appearanceMode = .system
    }
}
```

**AppearanceMode Enum**:

```swift
import Foundation

/// App appearance mode
enum AppearanceMode: String, CaseIterable, Codable {
    case light = "light"   // Always light mode
    case dark = "dark"     // Always dark mode
    case system = "system" // Follow iOS setting (recommended)

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil // SwiftUI auto-detects
        }
    }
}
```

**Singleton Pattern**: Only ONE AppSettings instance should exist in the database.

---

## 🔗 Relationships & Foreign Keys

### Pet → LaundryTask (One-to-Many)

**Relationship Type**: One Pet can have many LaundryTasks

**Implementation**:

```swift
// Querying tasks for a specific pet
let petID: UUID = somePet.id
let descriptor = FetchDescriptor<LaundryTask>(
    predicate: #Predicate { task in
        task.petID == petID
    },
    sortBy: [SortDescriptor(\.startDate, order: .reverse)]
)
let tasks = try modelContext.fetch(descriptor)
```

**Cascade Delete**:

```swift
// When deleting a pet, manually delete all associated tasks
func deletePet(_ pet: Pet, modelContext: ModelContext) {
    // Fetch all tasks for this pet
    let descriptor = FetchDescriptor<LaundryTask>(
        predicate: #Predicate { $0.petID == pet.id }
    )
    let tasks = try? modelContext.fetch(descriptor)

    // Delete all tasks
    tasks?.forEach { modelContext.delete($0) }

    // Delete the pet
    modelContext.delete(pet)

    // Save changes
    try? modelContext.save()
}
```

**Orphan Prevention**: LaundryTasks MUST have valid petID. Never create a task without a pet.

---

## 🔍 Query Patterns

### Common Query Operations

#### 1. Fetch All Active Pets

```swift
let descriptor = FetchDescriptor<Pet>(
    predicate: #Predicate { pet in
        pet.isActive == true
    },
    sortBy: [SortDescriptor(\.createdDate, order: .forward)]
)
let activePets = try modelContext.fetch(descriptor)
```

#### 2. Fetch Pet by ID

```swift
let targetID: UUID = ...
let descriptor = FetchDescriptor<Pet>(
    predicate: #Predicate { pet in
        pet.id == targetID
    }
)
let pet = try modelContext.fetch(descriptor).first
```

#### 3. Fetch Current Task for Pet

```swift
let petID: UUID = somePet.id
let descriptor = FetchDescriptor<LaundryTask>(
    predicate: #Predicate { task in
        task.petID == petID && task.isCompleted == false
    },
    sortBy: [SortDescriptor(\.startDate, order: .reverse)]
)
let currentTask = try modelContext.fetch(descriptor).first
```

#### 4. Fetch Completed Tasks (History)

```swift
let petID: UUID = somePet.id
let descriptor = FetchDescriptor<LaundryTask>(
    predicate: #Predicate { task in
        task.petID == petID && task.isCompleted == true
    },
    sortBy: [SortDescriptor(\.foldCompletedTime, order: .reverse)]
)
let completedTasks = try modelContext.fetch(descriptor)
```

#### 5. Fetch Pets with Low Health (< 25%)

```swift
let descriptor = FetchDescriptor<Pet>(
    predicate: #Predicate { pet in
        pet.health ?? 0 < 25 && pet.isActive == true
    },
    sortBy: [SortDescriptor(\.health, order: .forward)]
)
let lowHealthPets = try modelContext.fetch(descriptor)
```

#### 6. Fetch AppSettings (Singleton)

```swift
let descriptor = FetchDescriptor<AppSettings>()
let settings = try modelContext.fetch(descriptor).first ?? AppSettings()
```

---

## 💾 Data Persistence Strategies

### Insert Operations

**Create New Pet**:

```swift
func createPet(name: String, modelContext: ModelContext) -> Pet {
    let pet = Pet(name: name)
    modelContext.insert(pet)
    try? modelContext.save()
    return pet
}
```

**Create New Task**:

```swift
func createTask(for pet: Pet, modelContext: ModelContext) -> LaundryTask {
    let task = LaundryTask(
        petID: pet.id,
        washDuration: pet.washDurationMinutes,
        dryDuration: pet.dryDurationMinutes
    )
    modelContext.insert(task)
    try? modelContext.save()
    return task
}
```

### Update Operations

**Update Pet State**:

```swift
func updatePetState(_ pet: Pet, to newState: PetState, modelContext: ModelContext) {
    pet.currentState = newState
    try? modelContext.save()
}
```

**Update Pet Health**:

```swift
func updateHealth(_ pet: Pet, newHealth: Int, modelContext: ModelContext) {
    pet.health = max(0, min(100, newHealth)) // Clamp 0-100
    pet.lastHealthUpdate = Date()
    try? modelContext.save()
}
```

**Update Task Stage**:

```swift
func updateTaskStage(_ task: LaundryTask, to stage: LaundryStage, modelContext: ModelContext) {
    task.currentStage = stage

    // Update timestamps based on stage
    switch stage {
    case .washing:
        task.washStartTime = Date()
    case .drying:
        task.washEndTime = Date()
        task.dryStartTime = Date()
    case .completed:
        task.dryEndTime = Date()
    case .cycle:
        break
    }

    try? modelContext.save()
}
```

### Delete Operations

**Soft Delete Pet** (Preferred):

```swift
func deactivatePet(_ pet: Pet, modelContext: ModelContext) {
    pet.isActive = false
    try? modelContext.save()
}
```

**Hard Delete Pet** (with cascade):

```swift
func deletePet(_ pet: Pet, modelContext: ModelContext) {
    // Delete all associated tasks
    let descriptor = FetchDescriptor<LaundryTask>(
        predicate: #Predicate { $0.petID == pet.id }
    )
    let tasks = try? modelContext.fetch(descriptor)
    tasks?.forEach { modelContext.delete($0) }

    // Delete the pet
    modelContext.delete(pet)
    try? modelContext.save()
}
```

**Delete Old Completed Tasks** (Data Cleanup):

```swift
func deleteOldCompletedTasks(olderThan days: Int, modelContext: ModelContext) {
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

    let descriptor = FetchDescriptor<LaundryTask>(
        predicate: #Predicate { task in
            task.isCompleted == true &&
            task.foldCompletedTime ?? Date() < cutoffDate
        }
    )

    let oldTasks = try? modelContext.fetch(descriptor)
    oldTasks?.forEach { modelContext.delete($0) }
    try? modelContext.save()
}
```

---

## 🔄 Data Migration Strategies

### Version 1.0 → Version 1.1 (Example)

**Scenario**: Adding new field `petAvatarIndex: Int` to Pet model.

**Migration Strategy**:

```swift
// Old model (v1.0)
@Model
final class Pet {
    var id: UUID
    var name: String
    // ... other fields
}

// New model (v1.1)
@Model
final class Pet {
    var id: UUID
    var name: String
    var petAvatarIndex: Int // NEW FIELD
    // ... other fields
}

// SwiftData automatically handles lightweight migrations
// Default value: 0 (applied to all existing pets)
```

**Lightweight Migration**: SwiftData handles automatically for:

- Adding optional properties
- Adding properties with default values
- Removing properties
- Renaming properties (with `@Attribute` annotation)

**Heavy Migration**: Required for:

- Changing property types
- Adding non-optional properties without defaults
- Complex relationship changes

**Migration Implementation**:

```swift
// In LaundryTimeApp.swift
let container: ModelContainer = {
    let schema = Schema([Pet.self, LaundryTask.self, AppSettings.self])

    let configuration = ModelConfiguration(
        schema: schema,
        // Migration policy
        isStoredInMemoryOnly: false,
        allowsSave: true
    )

    do {
        return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

---

## 📈 Data Integrity Rules

### Validation Rules

**Pet Name Validation**:

```swift
func validatePetName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && trimmed.count <= 30
}
```

**Health Range Validation**:

```swift
func validateHealth(_ health: Int?) -> Bool {
    guard let health = health else { return true } // nil is valid
    return health >= 0 && health <= 100
}
```

**Date Validation**:

```swift
func validateDate(_ date: Date?) -> Bool {
    guard let date = date else { return true } // nil is valid
    return date <= Date() // Cannot be in future
}
```

### Consistency Rules

**Rule 1**: Pet with `currentState = .washing` must have active LaundryTask with `currentStage = .washing`

**Rule 2**: LaundryTask with `isCompleted = true` must have `foldCompletedTime != nil`

**Rule 3**: Pet with `health = 0` must have `currentState = .dead`

**Rule 4**: Only ONE active LaundryTask per Pet at a time

### Enforcement

**Pre-save Validation**:

```swift
func validateBeforeSave(pet: Pet) throws {
    // Name validation
    guard validatePetName(pet.name) else {
        throw ValidationError.invalidName
    }

    // Health validation
    guard validateHealth(pet.health) else {
        throw ValidationError.invalidHealth
    }

    // State consistency
    if pet.health == 0 && pet.currentState != .dead {
        throw ValidationError.inconsistentState
    }
}

enum ValidationError: Error {
    case invalidName
    case invalidHealth
    case inconsistentState
}
```

---

## 🧪 Test Data Generation

### Development Testing

**Create Sample Pets**:

```swift
func createSamplePets(modelContext: ModelContext) {
    let pets = [
        Pet(name: "Snowy"),
        Pet(name: "Fluffy"),
        Pet(name: "Buddy")
    ]

    pets.forEach { pet in
        pet.health = Int.random(in: 20...100)
        pet.totalCyclesCompleted = Int.random(in: 0...50)
        modelContext.insert(pet)
    }

    try? modelContext.save()
}
```

**Create Sample Tasks**:

```swift
func createSampleTask(for pet: Pet, stage: LaundryStage, modelContext: ModelContext) {
    let task = LaundryTask(petID: pet.id)
    task.currentStage = stage

    // Set timestamps based on stage
    switch stage {
    case .washing:
        task.washStartTime = Date()
    case .drying:
        task.washStartTime = Date().addingTimeInterval(-1800)
        task.washEndTime = Date().addingTimeInterval(-1800)
        task.dryStartTime = Date()
    case .completed:
        task.washStartTime = Date().addingTimeInterval(-3600)
        task.washEndTime = Date().addingTimeInterval(-1800)
        task.dryStartTime = Date().addingTimeInterval(-1800)
        task.dryEndTime = Date()
    case .cycle:
        break
    }

    modelContext.insert(task)
    try? modelContext.save()
}
```

---

## 📊 Database Performance

### Optimization Strategies

**Indexed Fields** (Automatic in SwiftData):

- `Pet.id` (primary key)
- `LaundryTask.id` (primary key)
- `LaundryTask.petID` (foreign key)

**Query Optimization**:

- Always use `#Predicate` for filtering (compiled, type-safe)
- Limit results with `fetchLimit` for large datasets
- Sort in database, not in memory

**Example Optimized Query**:

```swift
let descriptor = FetchDescriptor<Pet>(
    predicate: #Predicate { $0.isActive == true },
    sortBy: [SortDescriptor(\.createdDate)],
    fetchLimit: 50 // Max 50 pets at a time
)
```

### Performance Benchmarks

**Expected Performance** (iPhone 12 baseline):

- Insert pet: < 10ms
- Fetch all pets (< 100): < 20ms
- Update pet state: < 5ms
- Complex query with predicates: < 30ms
- Database size (10 pets, 100 tasks): < 1 MB

---

## 🔒 Data Security & Privacy

### Local-Only Storage

- All data stored locally on device
- No cloud sync (Version 1.0)
- No network transmission
- Encrypted at rest (iOS file system encryption)

### Data Export (Future Feature)

```swift
func exportData(modelContext: ModelContext) -> Data? {
    let pets = try? modelContext.fetch(FetchDescriptor<Pet>())
    let tasks = try? modelContext.fetch(FetchDescriptor<LaundryTask>())
    let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first

    let exportData = [
        "pets": pets,
        "tasks": tasks,
        "settings": settings
    ]

    return try? JSONEncoder().encode(exportData)
}
```

### Data Deletion

```swift
func deleteAllData(modelContext: ModelContext) {
    // Delete all pets (cascade deletes tasks)
    let pets = try? modelContext.fetch(FetchDescriptor<Pet>())
    pets?.forEach { modelContext.delete($0) }

    // Delete all tasks (if any orphaned)
    let tasks = try? modelContext.fetch(FetchDescriptor<LaundryTask>())
    tasks?.forEach { modelContext.delete($0) }

    // Reset settings
    let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first
    if let settings = settings {
        modelContext.delete(settings)
    }

    try? modelContext.save()
}
```

---

## ✅ Database Best Practices

### Do's ✅

- ✅ Always use `#Predicate` for type-safe queries
- ✅ Call `modelContext.save()` after mutations
- ✅ Use `@MainActor` for UI-bound model operations
- ✅ Validate data before saving
- ✅ Use cascade deletes for relationships
- ✅ Limit query results for performance
- ✅ Use descriptive variable names
- ✅ Handle errors gracefully (try?)

### Don'ts ❌

- ❌ Don't query on background threads without context isolation
- ❌ Don't store large binary data (images) in SwiftData
- ❌ Don't create circular relationships
- ❌ Don't ignore validation errors
- ❌ Don't fetch all data at once (use pagination)
- ❌ Don't store sensitive passwords (use Keychain instead)
- ❌ Don't mutate @Model objects from multiple threads
- ❌ Don't rely on lazy loading for critical data

---

## 🎯 Summary

LaundryTime's database architecture is designed for:

- **Simplicity**: Clear models, straightforward relationships
- **Performance**: Optimized queries, minimal storage
- **Reliability**: Type-safe SwiftData, automatic persistence
- **Scalability**: Supports unlimited pets and tasks
- **Privacy**: Local-only, no cloud dependencies
- **Maintainability**: Well-documented, follows best practices

The three-model design (Pet, LaundryTask, AppSettings) provides a clean separation of concerns while supporting complex multi-pet scenarios with complete independence between pets.
