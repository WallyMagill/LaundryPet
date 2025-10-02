# LaundryTime - Onboarding & First Launch Experience

## Overview

This document defines the complete first-time user experience, from app launch through completing their first laundry cycle. The goal is to quickly demonstrate value while teaching core mechanics naturally.

---

## 🎯 Onboarding Goals

### Primary Objectives

1. **Immediate Value**: User understands what the app does within 10 seconds
2. **Quick Setup**: User has first pet created within 30 seconds
3. **First Success**: User completes first cycle within first laundry load
4. **Habit Formation**: User returns for second load voluntarily

### Design Principles

- **Show, Don't Tell**: Demonstrate features through interaction, not text
- **Progressive Disclosure**: Teach features when needed, not all at once
- **Minimal Friction**: Skip optional steps, no accounts, no surveys
- **Immediate Engagement**: Start with pet creation, not lengthy explanations

---

## 📱 First Launch Flow

### State Detection

```swift
enum AppLaunchState {
    case firstLaunch           // Never opened before
    case hasSeenOnboarding     // Saw onboarding but no pets
    case hasActivePets         // Normal usage
    case returningUser         // Had pets before, deleted all
}

func detectLaunchState() -> AppLaunchState {
    let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    // Fetch existing pets
    let descriptor = FetchDescriptor<Pet>(
        predicate: #Predicate { $0.isActive == true }
    )
    let petCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    
    if !hasLaunchedBefore {
        return .firstLaunch
    } else if hasCompletedOnboarding && petCount == 0 {
        return .returningUser
    } else if petCount > 0 {
        return .hasActivePets
    } else {
        return .hasSeenOnboarding
    }
}
```

### Launch Routing

```swift
struct ContentView: View {
    @State private var launchState: AppLaunchState = .firstLaunch
    
    var body: some View {
        Group {
            switch launchState {
            case .firstLaunch:
                OnboardingFlow()
            case .hasSeenOnboarding, .returningUser:
                PetDashboardView(showWelcomeBack: true)
            case .hasActivePets:
                PetDashboardView(showWelcomeBack: false)
            }
        }
        .onAppear {
            launchState = detectLaunchState()
        }
    }
}
```

---

## 🌟 Onboarding Screens

### Screen 1: Welcome & Value Prop (3 seconds)

**Purpose**: Immediate understanding of app purpose

**Layout**:
```
┌─────────────────────────────┐
│                             │
│    [Large Pet Icon]         │
│         🧺                  │
│                             │
│   "Never Forget             │
│    Your Laundry Again"      │
│                             │
│   Keep your virtual pet     │
│   happy by completing       │
│   your laundry cycles       │
│                             │
│   [Continue] ──────────────►│
│                             │
│   Skip  (small, subtle)     │
│                             │
└─────────────────────────────┘
```

**Implementation**:

```swift
struct WelcomeScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero Image
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "basket.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryBlue)
            }
            
            // Value Prop
            VStack(spacing: 16) {
                Text("Never Forget\nYour Laundry Again")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textPrimary)
                
                Text("Keep your virtual pet happy by completing your laundry cycles")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // CTA
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryBlue)
                        .cornerRadius(16)
                }
                
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
```

**Analytics** (if added later):
- View duration
- Skip rate
- Continue tap

---

### Screen 2: How It Works (5 seconds)

**Purpose**: Explain core mechanic simply

**Layout**:
```
┌─────────────────────────────┐
│                             │
│   How It Works              │
│                             │
│   [Icon] 1. Create Pet      │
│   Give your laundry pet     │
│   a name                    │
│                             │
│   [Icon] 2. Start Cycle     │
│   Begin wash → dry → fold   │
│                             │
│   [Icon] 3. Stay Happy      │
│   Complete cycles to keep   │
│   your pet healthy          │
│                             │
│   [Get Started] ───────────►│
│                             │
│   Back                      │
│                             │
└─────────────────────────────┘
```

**Implementation**:

```swift
struct HowItWorksScreen: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            // Steps
            VStack(spacing: 32) {
                OnboardingStep(
                    number: "1",
                    icon: "plus.circle.fill",
                    title: "Create Pet",
                    description: "Give your laundry pet a name"
                )
                
                OnboardingStep(
                    number: "2",
                    icon: "play.circle.fill",
                    title: "Start Cycle",
                    description: "Begin wash → dry → fold"
                )
                
                OnboardingStep(
                    number: "3",
                    icon: "heart.fill",
                    title: "Stay Happy",
                    description: "Complete cycles to keep your pet healthy"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // CTA
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryBlue)
                        .cornerRadius(16)
                }
                
                Button(action: onBack) {
                    Text("Back")
                        .font(.subheadline)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingStep: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(Color.primaryBlue)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.primaryBlue)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}
```

---

### Screen 3: Notifications Permission (3 seconds)

**Purpose**: Request notification permission with context

**Layout**:
```
┌─────────────────────────────┐
│                             │
│   [Bell Icon]               │
│       🔔                    │
│                             │
│   Stay Updated              │
│                             │
│   Get notified when your    │
│   laundry cycles are        │
│   complete                  │
│                             │
│   Your pet will remind you  │
│   when it's time to fold!   │
│                             │
│   [Enable Notifications]    │
│                             │
│   Skip (I'll enable later)  │
│                             │
└─────────────────────────────┘
```

**Implementation**:

```swift
struct NotificationPermissionScreen: View {
    let onEnable: () -> Void
    let onSkip: () -> Void
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.primaryBlue)
            }
            
            // Content
            VStack(spacing: 16) {
                Text("Stay Updated")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 12) {
                    Text("Get notified when your laundry cycles are complete")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.textSecondary)
                    
                    Text("Your pet will remind you when it's time to fold!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // CTA
            VStack(spacing: 12) {
                Button(action: {
                    isRequesting = true
                    Task {
                        await requestNotifications()
                    }
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Enable Notifications")
                            .font(.buttonText)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryBlue)
                    .cornerRadius(16)
                }
                .disabled(isRequesting)
                
                Button(action: onSkip) {
                    Text("Skip (I'll enable later)")
                        .font(.subheadline)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func requestNotifications() async {
        let granted = await NotificationService.shared.requestPermission()
        
        // Haptic feedback
        if granted {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        // Continue to next step
        onEnable()
    }
}
```

**Key Points**:
- Explain WHY notifications are helpful
- Make skipping easy (no dark patterns)
- Use system permission dialog (can't customize)
- Handle both granted and denied gracefully

---

### Screen 4: Create First Pet (Immediate)

**Purpose**: Get user to create their first pet immediately

**Layout**:
```
┌─────────────────────────────┐
│                             │
│   Create Your First Pet     │
│                             │
│   [Pet Preview Circle]      │
│        😊                   │
│                             │
│   ┌─────────────────────┐   │
│   │ Enter name...       │   │
│   └─────────────────────┘   │
│                             │
│   Your pet will help you    │
│   remember to complete      │
│   each laundry cycle        │
│                             │
│   [Create Pet] ────────────►│
│                             │
└─────────────────────────────┘
```

**Implementation**:

```swift
struct CreateFirstPetScreen: View {
    @State private var petName = ""
    @FocusState private var isTextFieldFocused: Bool
    let onCreate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            Text("Create Your First Pet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            // Pet Preview
            ZStack {
                Circle()
                    .fill(Color.happyGreen.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.happyGreen)
            }
            .scaleEffect(petName.isEmpty ? 1.0 : 1.1)
            .animation(.spring(response: 0.3), value: petName.isEmpty)
            
            // Name Input
            VStack(spacing: 12) {
                TextField("Enter name...", text: $petName)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surface)
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if !petName.isEmpty {
                            createPet()
                        }
                    }
                
                Text("Your pet will help you remember to complete each laundry cycle")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // CTA
            Button(action: createPet) {
                Text("Create Pet")
                    .font(.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(petName.isEmpty ? Color.textTertiary : Color.primaryBlue)
                    .cornerRadius(16)
            }
            .disabled(petName.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Auto-focus text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func createPet() {
        guard !petName.isEmpty else { return }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Trim whitespace
        let trimmedName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        onCreate(trimmedName)
    }
}
```

**Name Suggestions** (if empty after 3 seconds):

```swift
@State private var showSuggestions = false

// Show after delay
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        if petName.isEmpty {
            showSuggestions = true
        }
    }
}

// Suggestion UI
if showSuggestions {
    HStack(spacing: 8) {
        Text("Try:")
            .font(.caption)
            .foregroundColor(.textTertiary)
        
        ForEach(["Fluffy", "Buddy", "Snowy"], id: \.self) { suggestion in
            Button(suggestion) {
                petName = suggestion
                showSuggestions = false
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.surface)
            .cornerRadius(8)
        }
    }
}
```

---

### Screen 5: Quick Tutorial Overlay (First Cycle)

**Purpose**: Teach timer controls during actual use

**Shown**: When user first opens their new pet

**Implementation**: Overlay with pointers

```swift
struct FirstCycleTutorial: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Arrow pointing to wash button
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Tap 'Start Wash' when\nyou put laundry in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Got it button
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasSeenFirstCycleTutorial")
                    isPresented = false
                }) {
                    Text("Got It!")
                        .font(.buttonText)
                        .foregroundColor(.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// In PetView
@State private var showTutorial = false

.onAppear {
    let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenFirstCycleTutorial")
    if !hasSeenTutorial && viewModel.pet.totalCyclesCompleted == 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showTutorial = true
        }
    }
}
.overlay {
    if showTutorial {
        FirstCycleTutorial(isPresented: $showTutorial)
    }
}
```

---

## 🎊 Completion & Celebration

### First Cycle Completed

**Trigger**: When user completes fold for first time ever

**Celebration Screen**:

```swift
struct FirstCycleCompletionView: View {
    let petName: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Confetti animation (system or custom)
            Text("🎉")
                .font(.system(size: 100))
                .scaleEffect(1.0)
                .animation(.spring(response: 0.5), value: UUID())
            
            VStack(spacing: 16) {
                Text("First Cycle Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.happyGreen)
                
                Text("\(petName) is very happy!")
                    .font(.title3)
                    .foregroundColor(.textPrimary)
                
                Text("Keep completing cycles to maintain their health and build your streak")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Continue")
                    .font(.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.happyGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.background)
    }
}

// In PetViewModel
func completeFold() {
    // Existing fold completion logic...
    
    // Check if first ever cycle
    if pet.totalCyclesCompleted == 1 {
        NotificationCenter.default.post(
            name: .firstCycleCompleted,
            object: nil,
            userInfo: ["petName": pet.name]
        )
    }
}
```

---

## 📊 Onboarding Metrics

### Track These (Locally Only)

```swift
struct OnboardingMetrics {
    var startTime: Date
    var screen1ViewDuration: TimeInterval?
    var screen2ViewDuration: TimeInterval?
    var didSkipOnboarding: Bool
    var didEnableNotifications: Bool
    var firstPetCreationTime: TimeInterval?  // Time from launch to pet creation
    var timeToFirstCycleStart: TimeInterval?  // Time from launch to first wash
    var timeToFirstCycleComplete: TimeInterval?  // Time from launch to first fold
    
    // Save to UserDefaults (for internal analysis only)
    func save() {
        // Implementation...
    }
}
```

### Success Criteria

**Good Onboarding**:
- 80%+ complete onboarding (don't skip)
- 70%+ enable notifications
- 90%+ create first pet
- 50%+ start first cycle within 1 hour
- 30%+ complete first cycle within 24 hours

---

## 🔄 Returning User Experience

### User Deleted All Pets

**Scenario**: User returns after deleting all pets

**Experience**:

```swift
struct WelcomeBackView: View {
    let onCreatePet: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryBlue)
            
            VStack(spacing: 16) {
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Ready to create a new laundry pet?")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onCreatePet) {
                Text("Create New Pet")
                    .font(.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryBlue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
```

---

## 🎯 Onboarding Best Practices

### Do's ✅

- Show value immediately
- Let users skip everything
- Request permissions with context
- Celebrate first completion
- Use progressive disclosure
- Make creation effortless
- Provide clear next steps

### Don'ts ❌

- No long text walls
- No required email/account
- No forced tutorial
- No permission gates
- No surveys or demographics
- No multiple taps to start
- No overwhelming feature lists

---

## ✅ Implementation Checklist

### Flow Implementation
- [ ] Launch state detection working
- [ ] All 5 onboarding screens created
- [ ] Screen transitions smooth
- [ ] Skip functionality works
- [ ] Back navigation implemented

### Permission Handling
- [ ] Notification request at right time
- [ ] Graceful handling of denial
- [ ] Can request later from Settings
- [ ] No blocking if denied

### First Pet Creation
- [ ] Text field auto-focuses
- [ ] Name validation works
- [ ] Pet saves correctly to database
- [ ] Navigates to pet detail view

### Tutorial
- [ ] First cycle overlay displays
- [ ] Only shows once
- [ ] Can be dismissed
- [ ] Doesn't block interaction after

### Celebration
- [ ] First completion detected
- [ ] Celebration screen shown
- [ ] Only shows once
- [ ] Stats tracked correctly

---

**A great first experience leads to long-term retention. Make it delightful!** ✨🎉