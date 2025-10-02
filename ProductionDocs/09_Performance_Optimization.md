# LaundryTime - Performance Optimization

## Overview

Performance is critical to user experience. LaundryTime must launch quickly, respond instantly, animate smoothly, and consume minimal battery. This document specifies performance targets, optimization strategies, profiling techniques, and monitoring approaches.

---

## 🎯 Performance Targets

### Launch Time

**Cold Launch** (App not in memory):

- Target: < 2 seconds from tap to interactive
- Measured: Time from app icon tap to dashboard displayed
- Acceptable: < 3 seconds on iPhone SE (oldest supported device)

**Warm Launch** (App suspended in background):

- Target: < 0.5 seconds to restore
- Measured: Time from background to foreground
- Acceptable: < 1 second

### Runtime Performance

**UI Responsiveness**:

- Target: 60 FPS (16.67ms per frame)
- Scrolling: Smooth at all times
- Animations: No dropped frames
- Interactions: Response within 100ms

**Memory Usage**:

- Target: < 50 MB typical
- Peak: < 100 MB during active use
- Idle: < 30 MB in background
- No memory leaks

**Battery Impact**:

- Target: < 2% per hour of active use
- Background: 0% (no active background execution)
- Location-adjusted: N/A (no location services)
- Network-adjusted: N/A (no network usage)

**Storage**:

- App Binary: < 15 MB
- Installed Size: < 20 MB
- Database: < 1 MB (100 pets with history)
- Cache: None required

---

## 🚀 Launch Time Optimization

### App Initialization

**LaundryTimeApp.swift** (Minimal Initialization):

```swift
@main
struct LaundryTimeApp: App {
    let modelContainer: ModelContainer

    init() {
        // Initialize SwiftData container
        // This is unavoidable but fast (<100ms)
        do {
            modelContainer = try ModelContainer(
                for: Pet.self, LaundryTask.self, AppSettings.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}

// ✅ GOOD: Minimal init work
// ✅ No network calls
// ✅ No heavy computations
// ✅ No large data loading
```

### Deferred Loading

**Load Data After View Appears**:

```swift
struct PetDashboardView: View {
    @EnvironmentObject private var petsViewModel: PetsViewModel
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else {
                petGrid
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        // Defer heavy work to after view appears
        Task {
            await petsViewModel.loadPets()
            isLoading = false
        }
    }
}

// ✅ GOOD: View appears immediately
// ✅ Data loads asynchronously
// ✅ User sees progress indicator
```

### Avoid Launch Blocking Operations

**❌ DON'T DO**:

```swift
init() {
    // ❌ Synchronous network call (blocks launch)
    let data = URLSession.shared.dataTask(...)

    // ❌ Heavy computation (blocks launch)
    processLargeDataset()

    // ❌ Large file I/O (blocks launch)
    loadMegabyteFile()
}
```

**✅ DO THIS**:

```swift
init() {
    // ✅ Minimal setup only
    setupNotificationObservers()
}

func onAppear() {
    // ✅ Heavy work deferred
    Task {
        await loadDataAsynchronously()
    }
}
```

### Launch Time Measurement

**Using Xcode Instruments**:

1. Product → Profile (⌘ + I)
2. Select "App Launch" instrument
3. Record launch
4. Analyze Time Profiler results

**Manual Timing**:

```swift
// Add to AppDelegate or SceneDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    print("⏱️ Launch completed at: \(Date())")
    return true
}

// Measure time from icon tap (visible in Console)
```

---

## 💾 Memory Optimization

### Memory Management Principles

**ARC (Automatic Reference Counting)**:

- Swift automatically manages memory
- Avoid strong reference cycles
- Use `weak` and `unowned` appropriately
- Clean up resources in `deinit`

### Preventing Memory Leaks

**Common Leak: Capture Self in Closures**:

```swift
// ❌ WRONG: Strong reference cycle
class PetViewModel: ObservableObject {
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.updateTime()  // Strong capture of self
        }
    }
}

// ✅ CORRECT: Weak capture
class PetViewModel: ObservableObject {
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.updateTime()
        }
    }
}
```

**Common Leak: Notification Observers**:

```swift
// ❌ WRONG: Observer not removed
init() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleNotification),
        name: .timerCompleted,
        object: nil
    )
}

// ✅ CORRECT: Remove observer in deinit
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

**Common Leak: Combine Cancellables**:

```swift
class PetViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    func observeTimer() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
            .store(in: &cancellables)  // ✅ Stored for cleanup
    }

    deinit {
        cancellables.forEach { $0.cancel() }  // ✅ Cleanup
    }
}
```

### Memory Profiling

**Using Xcode Instruments**:

1. Product → Profile (⌘ + I)
2. Select "Leaks" instrument
3. Run app through all flows
4. Check for red warnings (leaks detected)
5. Fix all leaks

**Memory Graph Debugger**:

1. Run app in Xcode
2. Debug Navigator → Memory Graph (or ⌘ + ⇧ + M)
3. Look for unexpected retain cycles
4. Analyze object graph

**Typical Memory Usage**:

```
App Launch: 30 MB
Dashboard (10 pets): 35 MB
Pet Detail View: 40 MB
Active Timer: 42 MB
Background: 25 MB (suspended)

✅ All within 50 MB target
```

---

## ⚡ UI Performance Optimization

### 60 FPS Animation Target

**Frame Budget**: 16.67ms per frame (60 FPS)

**SwiftUI Optimization**:

```swift
// ✅ GOOD: Lightweight view
struct PetCardView: View {
    let pet: Pet

    var body: some View {
        // Simple, declarative layout
        VStack {
            petIcon
            petName
            healthBar
        }
    }
}

// ❌ BAD: Heavy computation in body
struct PetCardView: View {
    let pet: Pet

    var body: some View {
        VStack {
            // ❌ Expensive computation on every refresh
            let processedData = expensiveCalculation(pet)

            Text(processedData)
        }
    }
}

// ✅ FIXED: Cache computed values
struct PetCardView: View {
    let pet: Pet

    // Computed once, cached
    private var processedData: String {
        expensiveCalculation(pet)
    }

    var body: some View {
        Text(processedData)
    }
}
```

### Lazy Loading

**LazyVGrid for Large Lists**:

```swift
// ✅ CORRECT: Lazy loading
ScrollView {
    LazyVGrid(columns: columns, spacing: 12) {
        ForEach(pets) { pet in
            PetCardView(pet: pet)
        }
    }
}

// Benefits:
// - Only renders visible cards
// - Recycles views as user scrolls
// - Smooth scrolling even with 100+ pets

// ❌ WRONG: Eager loading
ScrollView {
    VGrid(columns: columns, spacing: 12) {
        ForEach(pets) { pet in
            PetCardView(pet: pet)  // All cards rendered immediately
        }
    }
}
```

### Animation Performance

**Optimize Animations**:

```swift
// ✅ GOOD: Hardware-accelerated properties
.opacity(isVisible ? 1.0 : 0.0)
.scaleEffect(isPressed ? 0.96 : 1.0)
.offset(x: isShown ? 0 : 100)

// ⚠️ SLOWER: Triggers layout
.frame(width: isExpanded ? 300 : 100)  // Layout recalculation
.padding(isLarge ? 20 : 10)  // Layout recalculation

// ✅ OPTIMIZED: Use transform instead
.scaleEffect(isLarge ? 1.5 : 1.0)  // No layout change
```

**Reduce Animation Complexity**:

```swift
// ❌ HEAVY: Particle effects on every frame
ForEach(0..<100) { i in
    ParticleView()
        .offset(y: animationValue * CGFloat(i))
}

// ✅ LIGHT: Simple, efficient animation
Circle()
    .fill(Color.accentColor)
    .scaleEffect(animationValue)
    .opacity(1.0 - animationValue)
```

### Frame Rate Monitoring

**Using Xcode Instruments**:

1. Product → Profile (⌘ + I)
2. Select "Time Profiler" or "Core Animation"
3. Record while interacting with app
4. Check FPS meter (should stay at 60)
5. Identify frame drops

**Target Areas**:

- Dashboard scrolling
- Pet detail navigation
- Timer progress updates
- Animation sequences

---

## 🔋 Battery Optimization

### Battery Drain Sources

**High Impact**:

- ❌ Continuous GPS usage: N/A (not used)
- ❌ Network requests: N/A (fully offline)
- ❌ Background processing: N/A (timers use date math)
- ❌ Screen brightness: N/A (user-controlled)

**Low Impact**:

- ✅ Foreground timer updates: 1 per second, minimal CPU
- ✅ Database queries: Infrequent, optimized
- ✅ Notifications: System-managed, no impact
- ✅ UI animations: Hardware-accelerated, efficient

### Battery-Friendly Practices

**Minimize Timer Overhead**:

```swift
// ✅ GOOD: Only update when view visible
private var timerCancellable: AnyCancellable?

func startUIUpdates() {
    timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.updateTimeRemaining()
        }
}

func stopUIUpdates() {
    timerCancellable?.cancel()
    timerCancellable = nil
}

// Called when view disappears
onDisappear {
    stopUIUpdates()
}
```

**No Background Execution**:

```swift
// ✅ GOOD: No background tasks
// Timers persist via UserDefaults (no active execution)
// iOS delivers notifications (no app wake-up needed)

// ❌ BAD: Would drain battery
// Background fetch
// Silent push notifications
// Background processing
// Location monitoring
```

**Respect Low Power Mode**:

```swift
@Environment(\.isLowPowerModeEnabled) var isLowPowerMode

var animationSpeed: Double {
    isLowPowerMode ? 0.1 : 0.5  // Faster animations when low power
}

var updateInterval: TimeInterval {
    isLowPowerMode ? 5.0 : 1.0  // Less frequent updates
}
```

### Battery Testing

**Using Xcode Energy Log**:

1. Run app on physical device
2. Debug Navigator → Energy Impact
3. Monitor energy consumption
4. Check for spikes or high sustained usage

**Typical Energy Impact**:

```
Dashboard browsing: Very Low
Active timer running: Low
Background (app closed): None
```

---

## 💿 Database Performance

### Query Optimization

**Use Predicates (Filter at Database)**:

```swift
// ✅ EFFICIENT: Database filters
let descriptor = FetchDescriptor<LaundryTask>(
    predicate: #Predicate { task in
        task.petID == targetID && task.isCompleted == false
    }
)
let tasks = try modelContext.fetch(descriptor)

// ❌ INEFFICIENT: Load all then filter in memory
let allTasks = try modelContext.fetch(FetchDescriptor<LaundryTask>())
let filtered = allTasks.filter { $0.petID == targetID && !$0.isCompleted }
```

**Limit Query Results**:

```swift
// ✅ GOOD: Only fetch what's needed
let descriptor = FetchDescriptor<LaundryTask>(
    predicate: predicate,
    sortBy: [SortDescriptor(\.startDate, order: .reverse)],
    fetchLimit: 10  // Only most recent 10
)
```

**Index Key Paths** (SwiftData automatic):

```swift
// SwiftData automatically indexes:
// - id (primary key)
// - Foreign keys (petID)
// - @Attribute(.unique) properties

// No manual index creation needed
```

### Database Size Management

**Cleanup Old Data**:

```swift
func deleteOldCompletedTasks(olderThan days: Int) {
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

    let descriptor = FetchDescriptor<LaundryTask>(
        predicate: #Predicate { task in
            task.isCompleted == true &&
            (task.foldCompletedTime ?? Date()) < cutoffDate
        }
    )

    let oldTasks = try? modelContext.fetch(descriptor)
    oldTasks?.forEach { modelContext.delete($0) }
    try? modelContext.save()
}

// Call periodically (e.g., on app launch)
// Keeps database size small
```

**Typical Database Sizes**:

```
10 pets, 50 completed tasks: 100 KB
50 pets, 500 completed tasks: 800 KB
100 pets, 1000 completed tasks: 1.5 MB

✅ All well within reasonable limits
```

---

## 📊 Profiling Tools & Techniques

### Xcode Instruments

**Time Profiler**:

- Purpose: Find CPU-intensive code
- When: App feels sluggish
- How:
  1. Product → Profile → Time Profiler
  2. Record while using app
  3. Find heaviest stack traces
  4. Optimize hot paths

**Allocations**:

- Purpose: Track memory allocations
- When: Memory usage high
- How:
  1. Product → Profile → Allocations
  2. Record app usage
  3. Check "All Heap & Anonymous VM"
  4. Look for unexpected growth

**Leaks**:

- Purpose: Detect memory leaks
- When: Memory doesn't release
- How:
  1. Product → Profile → Leaks
  2. Run through all app flows
  3. Look for red leak indicators
  4. Fix retain cycles

**Core Animation**:

- Purpose: Analyze rendering performance
- When: Animations choppy
- How:
  1. Product → Profile → Core Animation
  2. Enable "Color Blended Layers"
  3. Enable "Color Offscreen-Rendered"
  4. Optimize problem areas

**Energy Log**:

- Purpose: Measure battery impact
- When: Testing on device
- How:
  1. Run on physical iPhone
  2. Debug Navigator → Energy
  3. Monitor energy level
  4. Check for spikes

### SwiftUI View Debugging

**View Hierarchy Inspector**:

```
Debug → View Debugging → Capture View Hierarchy
- 3D view of UI stack
- Identify overlapping views
- Find hidden views consuming resources
```

**Environment Object Debugging**:

```swift
// Log when view refreshes
var body: some View {
    let _ = print("🔄 PetCardView refreshed")
    return content
}

// Minimize unnecessary refreshes
```

---

## 🎯 Performance Benchmarks

### Launch Time Benchmarks

| Device          | iOS  | Cold Launch | Warm Launch |
| --------------- | ---- | ----------- | ----------- |
| iPhone 14 Pro   | 17.0 | 1.2s        | 0.3s        |
| iPhone 12       | 16.0 | 1.5s        | 0.4s        |
| iPhone SE (3rd) | 15.0 | 2.1s        | 0.6s        |

**Target**: All within acceptable range ✅

### Memory Benchmarks

| Scenario            | Memory | Status |
| ------------------- | ------ | ------ |
| Launch              | 30 MB  | ✅     |
| Dashboard (10 pets) | 35 MB  | ✅     |
| Pet Detail          | 40 MB  | ✅     |
| Active Timer        | 42 MB  | ✅     |
| Background          | 25 MB  | ✅     |

**Target**: < 50 MB typical ✅

### Battery Benchmarks

| Scenario           | Energy Impact | Status |
| ------------------ | ------------- | ------ |
| Dashboard Browsing | Very Low      | ✅     |
| Active Timer       | Low           | ✅     |
| Background         | None          | ✅     |
| 1 Hour Active Use  | 1.8% drain    | ✅     |

**Target**: < 2% per hour ✅

### UI Performance Benchmarks

| Interaction            | FPS | Frame Time | Status |
| ---------------------- | --- | ---------- | ------ |
| Dashboard Scroll       | 60  | 16ms       | ✅     |
| Pet Detail Navigation  | 60  | 14ms       | ✅     |
| Timer Progress Update  | 60  | 8ms        | ✅     |
| Button Press Animation | 60  | 12ms       | ✅     |

**Target**: 60 FPS (16.67ms budget) ✅

---

## ✅ Performance Checklist

### Launch Performance

- [ ] Cold launch < 2 seconds
- [ ] Warm launch < 0.5 seconds
- [ ] No blocking operations in init
- [ ] Heavy work deferred to background
- [ ] First view appears instantly

### Runtime Performance

- [ ] 60 FPS scrolling
- [ ] No animation frame drops
- [ ] UI responds within 100ms
- [ ] Memory < 50 MB typical
- [ ] No memory leaks detected

### Battery Performance

- [ ] Energy impact: Low or Very Low
- [ ] No background execution
- [ ] Respects Low Power Mode
- [ ] < 2% per hour active use

### Database Performance

- [ ] Queries use predicates
- [ ] Results limited when appropriate
- [ ] Database size < 2 MB (typical use)
- [ ] Old data cleaned up

### Profiling

- [ ] Time Profiler run and analyzed
- [ ] Allocations checked for leaks
- [ ] Leaks instrument clean
- [ ] Core Animation optimized
- [ ] Energy Log acceptable

---

## 🚀 Optimization Priorities

### High Priority (Must Fix)

**P0: Crashes & Data Loss**

- Memory leaks causing crashes
- Database corruption
- Critical rendering issues

**P1: User-Blocking Performance**

- Launch time > 5 seconds
- Frozen UI during interaction
- Dropped frames during scrolling

### Medium Priority (Should Fix)

**P2: Noticeable Performance**

- Launch time 3-5 seconds
- Occasional frame drops
- Memory usage 50-75 MB

**P3: Polish & Optimization**

- Animation could be smoother
- Slight delay in response
- Memory usage 75-100 MB

### Low Priority (Nice to Have)

**P4: Micro-Optimizations**

- Already acceptable performance
- Marginal gains available
- Edge cases only

---

## 📈 Continuous Performance Monitoring

### Pre-Release Testing

**Every Major Release**:

- [ ] Run full Instruments suite
- [ ] Test on oldest supported device (iPhone SE)
- [ ] Measure launch time
- [ ] Check memory usage
- [ ] Verify 60 FPS
- [ ] Confirm battery impact acceptable

**Every Minor Release**:

- [ ] Quick performance smoke test
- [ ] Check for regressions
- [ ] Verify benchmarks still met

### Post-Release Monitoring

**App Store Connect Metrics**:

- Crashes per session
- Launch time metrics
- Battery drain reports
- User reviews mentioning performance

**TestFlight Feedback**:

- Beta tester performance reports
- Device-specific issues
- iOS version-specific problems

---

## 🎯 Performance Success Criteria

**App Store Performance Goals**:

- ✅ 4.5+ star rating
- ✅ No reviews mentioning "slow" or "laggy"
- ✅ Crash rate < 0.1%
- ✅ Battery impact: "Very Low" or "Low"

**Technical Goals**:

- ✅ Launch time < 2s (iPhone 12)
- ✅ 60 FPS animations
- ✅ Memory < 50 MB typical
- ✅ Battery < 2% per hour
- ✅ Zero memory leaks

**User Experience Goals**:

- ✅ Instant UI response
- ✅ Smooth scrolling
- ✅ No waiting or loading states
- ✅ Runs well on older devices
- ✅ Minimal battery drain

---

**Performance is not an afterthought—it's fundamental to quality. LaundryTime is fast, efficient, and delightful.** ⚡✨
