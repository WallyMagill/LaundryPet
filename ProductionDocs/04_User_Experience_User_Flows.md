# LaundryTime - User Experience & User Flows

## Overview

This document defines the complete user experience for LaundryTime, including detailed user journeys, interaction patterns, screen flows, and error handling strategies. Every user touchpoint is designed to be intuitive, delightful, and effective.

---

## 🎯 UX Design Principles

### Core Experience Tenets

**1. Zero Friction**

- No tutorial required for first-time users
- Obvious next steps at every stage
- One-tap actions for common tasks
- Minimal configuration needed to start

**2. Emotional Resonance**

- Pet character creates immediate connection
- Visual feedback confirms every action
- Progress is visible and satisfying
- Mistakes are reversible and forgiving

**3. Habit Formation**

- Notifications gently remind without nagging
- Streaks encourage consistency
- Progress tracking shows improvement
- Positive reinforcement at every completion

**4. Respect User Time**

- Fast app launch (< 2 seconds)
- No unnecessary loading states
- Information at a glance
- Deep links from notifications

---

##

🗺️ Complete User Journeys

### Journey 1: First-Time User (Cold Start)

**Goal**: User downloads app, creates first pet, completes first laundry cycle

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: App Launch                                              │
├─────────────────────────────────────────────────────────────────┤
│ • User taps app icon                                            │
│ • Splash screen (< 1 second)                                    │
│ • App checks for existing data → None found                     │
│ • Navigate to Dashboard                                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Empty State Dashboard                                   │
├─────────────────────────────────────────────────────────────────┤
│ Screen Elements:                                                 │
│ • Large paw print icon (friendly, inviting)                     │
│ • "No Pets Yet" headline                                        │
│ • "Create your first laundry pet to get started!" subtext      │
│ • Prominent "Create Pet" button (primary blue)                  │
│ • Settings icon in navigation bar (dimmed, optional)            │
│                                                                  │
│ User Action: Taps "Create Pet"                                  │
│ System Response: Sheet slides up from bottom (0.3s animation)   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Create Pet Modal                                        │
├─────────────────────────────────────────────────────────────────┤
│ Screen Elements:                                                 │
│ • "New Pet" navigation title                                    │
│ • "Cancel" button (leading)                                     │
│ • Text field: "Pet name" (auto-focused, keyboard appears)      │
│ • Placeholder: "Enter a name for your pet"                     │
│ • Footer: "Give your laundry pet a unique name"                │
│ • "Create Pet" button (disabled until name entered)            │
│                                                                  │
│ User Action: Types "Snowy"                                      │
│ System Response:                                                 │
│   • Create button enables (color changes to blue)               │
│   • Haptic feedback on button state change                      │
│                                                                  │
│ User Action: Taps "Create Pet"                                  │
│ System Response:                                                 │
│   • Haptic feedback (medium impact)                             │
│   • Pet created in database                                     │
│   • Modal dismisses (0.25s slide down)                          │
│   • Dashboard appears with new pet card                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Dashboard with First Pet                                │
├─────────────────────────────────────────────────────────────────┤
│ Screen Elements:                                                 │
│ • "My Laundry Pets" navigation title                            │
│ • Pet card with "Snowy"                                         │
│   - Neutral state icon (blue circle)                            │
│   - Health bar at 100%                                          │
│   - "is doing okay" status text                                │
│ • "+" button in navigation (to add more pets)                   │
│ • Settings icon                                                  │
│                                                                  │
│ User Action: Taps pet card                                      │
│ System Response:                                                 │
│   • Haptic feedback (light impact)                              │
│   • Navigate to Pet Detail (slide from right, 0.3s)            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: Pet Detail View (First Time)                            │
├─────────────────────────────────────────────────────────────────┤
│ Screen Elements:                                                 │
│ • "Snowy" navigation title                                      │
│ • Back button (< My Laundry Pets)                               │
│ • Settings icon (gear, per-pet settings)                        │
│                                                                  │
│ • Large pet character (120pt, centered)                         │
│   - Neutral blue background circle                              │
│   - Gentle breathing animation                                  │
│                                                                  │
│ • Status banner:                                                 │
│   - "Snowy is doing okay"                                       │
│   - Blue indicator dot                                          │
│                                                                  │
│ • Primary action button:                                        │
│   - "Start Wash" (large, blue, enabled)                         │
│   - Full width, 56pt height                                     │
│                                                                  │
│ • Stats cards (below button):                                   │
│   - Cycles: 0 | Streak: 0 | Health: 100%                       │
│                                                                  │
│ User Action: Taps "Start Wash"                                  │
│ System Response:                                                 │
│   • Haptic feedback (medium impact)                             │
│   • Request notification permission (first time only)           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: Notification Permission Request                         │
├─────────────────────────────────────────────────────────────────┤
│ System Alert (iOS native):                                      │
│ • ""LaundryTime" Would Like to Send You Notifications"         │
│ • "Notifications will remind you when laundry cycles complete"  │
│ • [Don't Allow] [Allow] buttons                                 │
│                                                                  │
│ User Action: Taps "Allow"                                       │
│ System Response:                                                 │
│   • Permission granted                                           │
│   • Alert dismisses                                              │
│   • Wash timer starts immediately                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: Wash Timer Active                                       │
├─────────────────────────────────────────────────────────────────┤
│ Screen Changes:                                                  │
│ • Pet character:                                                 │
│   - Color changes to wash blue                                  │
│   - Animation changes to washing motion (spinning/bubbles)      │
│                                                                  │
│ • Status banner:                                                 │
│   - "Snowy is getting clean!"                                   │
│   - Wash blue indicator dot                                     │
│                                                                  │
│ • Timer progress appears:                                        │
│   - Circular progress ring (wash blue)                          │
│   - "0:45" countdown (monospaced font)                          │
│   - "Washing" label                                              │
│   - "100%" progress text                                        │
│                                                                  │
│ • Action button changes:                                         │
│   - "Washing..." (disabled, grayed)                             │
│   - No interaction possible                                      │
│                                                                  │
│ Timer Behavior:                                                  │
│   • Updates every second                                         │
│   • Progress ring animates smoothly                              │
│   • Time counts down: 0:59 → 0:58 → ... → 0:01 → 0:00         │
│                                                                  │
│ User Action: Waits or closes app                                │
│ System Response:                                                 │
│   • Timer continues in background (saved to UserDefaults)       │
│   • Notification scheduled for completion                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 8: Timer Completion (App Closed)                           │
├─────────────────────────────────────────────────────────────────┤
│ System Behavior:                                                 │
│ • Timer reaches 0:00                                             │
│ • iOS delivers notification:                                     │
│   - Title: "Wash Complete!"                                     │
│   - Body: "Snowy is ready for the dryer!"                       │
│   - Sound plays (if enabled)                                     │
│   - Badge appears on app icon                                    │
│                                                                  │
│ User Action: Taps notification                                  │
│ System Response:                                                 │
│   • App launches (or foregrounds)                                │
│   • Navigates directly to Snowy's detail view                   │
│   • Timer marked complete, UI updated                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 9: Ready for Dryer                                         │
├─────────────────────────────────────────────────────────────────┤
│ Screen Changes:                                                  │
│ • Pet character:                                                 │
│   - Returns to neutral state                                     │
│   - Idle breathing animation                                     │
│                                                                  │
│ • Status banner:                                                 │
│   - "Snowy is doing okay"                                       │
│                                                                  │
│ • Timer progress:                                                 │
│   - Disappears (smooth fade out)                                 │
│                                                                  │
│ • Action button:                                                 │
│   - "Start Dryer" (enabled, blue)                               │
│   - Clear call to action                                         │
│                                                                  │
│ User Action: Taps "Start Dryer"                                 │
│ System Response:                                                 │
│   • Same flow as wash timer                                      │
│   • Dry timer starts (1 minute in testing mode)                │
│   • Pet animation changes to drying                              │
│   • Progress ring shows dry yellow color                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 10: Dry Timer Complete                                     │
├─────────────────────────────────────────────────────────────────┤
│ System Behavior:                                                 │
│ • Notification: "Dry Complete! Time to fold Snowy's laundry!"  │
│                                                                  │
│ User Action: Opens app                                          │
│ System Response:                                                 │
│   • Action button shows "Mark Folded"                            │
│   • Pet looks expectant                                          │
│                                                                  │
│ User Action: Taps "Mark Folded"                                 │
│ System Response:                                                 │
│   • ✨ Celebration sequence:                                     │
│     1. Haptic feedback (heavy impact)                            │
│     2. Pet character scales up & spins (0.8s spring animation)  │
│     3. Color changes to happy green                              │
│     4. Confetti or sparkle effect (subtle)                      │
│   • Health restored to 100%                                      │
│   • Cycle count: 0 → 1                                          │
│   • Streak: 0 → 1                                               │
│   • Status: "Snowy is so happy!"                                │
│   • Action button: "Start Wash" (ready for next cycle)         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SUCCESS: First Cycle Complete! 🎉                               │
├─────────────────────────────────────────────────────────────────┤
│ User has now:                                                    │
│ ✅ Created their first pet                                      │
│ ✅ Completed a full laundry cycle                               │
│ ✅ Experienced wash → dry → fold flow                           │
│ ✅ Seen pet happiness increase                                  │
│ ✅ Earned their first stat (1 cycle, 1 streak)                 │
│ ✅ Enabled notifications                                         │
│                                                                  │
│ Next Actions Available:                                          │
│ • Start another cycle for this pet                              │
│ • Create additional pets for different laundry types           │
│ • Customize pet settings (wash/dry times)                       │
│ • View dashboard to manage multiple pets                        │
└─────────────────────────────────────────────────────────────────┘
```

**Duration**: 2-3 minutes for complete first cycle
**Completion Rate Target**: 70%+

---

### Journey 2: Returning User (Daily Usage)

**Goal**: User opens app, checks pet health, starts laundry as needed

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: App Launch from Home Screen                             │
├─────────────────────────────────────────────────────────────────┤
│ • User taps app icon                                            │
│ • App launches to Dashboard (< 2 seconds)                       │
│ • Loads all pets from database                                  │
│ • Health updates automatically if stale                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Dashboard Overview                                      │
├─────────────────────────────────────────────────────────────────┤
│ User sees at a glance:                                           │
│ • Pet 1 "Snowy": Happy (100% health, green)                     │
│ • Pet 2 "Fluffy": Sad (35% health, orange)                      │
│ • Pet 3 "Buddy": Washing (timer active, blue)                   │
│                                                                  │
│ Decision Points:                                                 │
│ • Snowy: No action needed, recently completed                   │
│ • Fluffy: Needs attention (visual indicator: pulse border)      │
│ • Buddy: In progress (shows remaining time on card)             │
│                                                                  │
│ User Action: Taps Fluffy (needs laundry)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Pet Detail - Needs Attention                            │
├─────────────────────────────────────────────────────────────────┤
│ Visual Cues:                                                     │
│ • Pet character: Sad expression, orange tint                    │
│ • Health bar: 35% (orange color)                                │
│ • Status: "Fluffy needs some laundry love"                      │
│ • Action button: "Start Wash" (emphasized, pulsing)             │
│                                                                  │
│ User Action: Taps "Start Wash"                                  │
│ System Response: Timer starts immediately (no permission modal) │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Multi-Pet Scenario                                      │
├─────────────────────────────────────────────────────────────────┤
│ User navigates back to dashboard                                │
│ • Fluffy: Now washing (timer shows 0:59 remaining)              │
│ • Buddy: Still drying (timer shows 0:23 remaining)              │
│ • Snowy: Still happy (no action needed)                         │
│                                                                  │
│ Key UX Feature:                                                  │
│ • Two timers running simultaneously (independent!)              │
│ • No interference between pets                                  │
│ • Dashboard shows status of all pets at once                    │
└─────────────────────────────────────────────────────────────────┘
```

**Duration**: 30 seconds to 2 minutes
**Frequency**: 1-3 times per day

---

### Journey 3: Notification-Driven Re-engagement

**Goal**: User receives notification, returns to app, completes next step

```
┌─────────────────────────────────────────────────────────────────┐
│ TRIGGER: Timer Completion Notification                          │
├─────────────────────────────────────────────────────────────────┤
│ Notification Appears:                                            │
│ • Lock Screen / Notification Center / Banner                    │
│ • Title: "Dry Complete!"                                        │
│ • Body: "Buddy is ready to be folded!"                          │
│ • App icon badge: 1                                             │
│ • Sound (if enabled)                                             │
│                                                                  │
│ User Action: Taps notification                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DEEP LINK: Direct to Buddy's Pet View                           │
├─────────────────────────────────────────────────────────────────┤
│ App Behavior:                                                    │
│ • Launches app (if closed)                                      │
│ • OR foregrounds app (if backgrounded)                          │
│ • Navigates directly to Buddy's detail view                     │
│ • Skips dashboard (saves user a tap)                            │
│ • Action button ready: "Mark Folded"                            │
│                                                                  │
│ User Action: Taps "Mark Folded"                                 │
│ System Response: Celebration + stats update                      │
│                                                                  │
│ User Action: Swipes back or taps Done                           │
│ System Response: Returns to dashboard or closes app             │
└─────────────────────────────────────────────────────────────────┘
```

**Duration**: 10-20 seconds
**Engagement Rate Target**: 80%+ from notification

---

### Journey 4: Settings Configuration

**Goal**: User customizes wash/dry times for a specific pet

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Access Pet Settings                                     │
├─────────────────────────────────────────────────────────────────┤
│ From Pet Detail View:                                            │
│ • User taps gear icon (top right)                               │
│ • Pet Settings sheet slides up                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Pet Settings Screen                                     │
├─────────────────────────────────────────────────────────────────┤
│ Form Layout (Grouped Style):                                    │
│                                                                  │
│ Section: Pet Information                                         │
│ • Pet Name: "Snowy" [editable text field]                       │
│   Footer: "Give your pet a unique name"                         │
│                                                                  │
│ Section: Laundry Timers                                          │
│ • Wash Time: 45 minutes [>]                                     │
│ • Dry Time: 60 minutes [>]                                      │
│   Footer: "Customize how long each cycle takes"                 │
│                                                                  │
│ Section: Cycle Frequency                                         │
│ • How often: Every 4 days [>]                                   │
│   Footer: "How often this pet needs laundry"                    │
│                                                                  │
│ Section: Danger Zone                                             │
│ • Delete Pet [red text]                                         │
│   Footer: "This cannot be undone"                               │
│                                                                  │
│ User Action: Taps "Wash Time"                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Time Picker                                             │
├─────────────────────────────────────────────────────────────────┤
│ Picker Screen:                                                   │
│ • "Wash Time" navigation title                                  │
│ • Back button to return                                          │
│ • Picker wheel with minute values: 1-120                        │
│   (1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, ...)      │
│ • Currently selected: 45 minutes                                │
│                                                                  │
│ User Action: Scrolls to 30 minutes                              │
│ System Response: Haptic feedback on selection change            │
│                                                                  │
│ User Action: Taps back                                          │
│ System Response:                                                 │
│   • Value saves automatically                                    │
│   • Pet Settings updates: "Wash Time: 30 minutes"              │
│   • Future cycles use new time                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎛️ Interaction Patterns

### Primary Actions

**Start Laundry**:

```
Trigger: User taps "Start Wash" or "Start Dryer"
Pre-conditions: Pet not in active timer state
Confirmation: None needed (reversible via Stop)

Flow:
1. User taps button
2. Haptic feedback (medium impact)
3. Button animates (scale down 0.96)
4. Timer starts immediately
5. UI updates (0.3s transition)
   - Pet character changes
   - Status banner updates
   - Timer progress appears
   - Button disables

Duration: < 0.5s total
```

**Mark Folded**:

```
Trigger: User taps "Mark Folded" after dry complete
Pre-conditions: Dry stage complete
Confirmation: None (instant gratification desired)

Flow:
1. User taps button
2. Haptic feedback (heavy impact)
3. Celebration animation (0.8s)
   - Pet scales & rotates
   - Color changes to green
   - Optional particle effects
4. Stats update visible
   - Cycle count +1
   - Streak +1 (with animation)
   - Health → 100%
5. Button resets to "Start Wash"

Duration: ~1s total
```

### Secondary Actions

**Delete Pet**:

```
Trigger: User taps "Delete Pet" in settings
Pre-conditions: Confirmation required (destructive)

Flow:
1. User taps "Delete Pet"
2. Alert appears (iOS standard):
   Title: "Delete Snowy?"
   Message: "This will permanently delete this pet and all its data. This cannot be undone."
   Buttons: [Cancel] [Delete (red)]
3. User taps "Delete"
4. Haptic feedback (medium impact)
5. Database deletion (pet + tasks)
6. Settings sheet dismisses
7. Navigate back to dashboard
8. Pet card removes with animation (fade + scale)
9. Dashboard updates layout

Duration: User-paced (requires confirmation)
```

**Edit Pet Name**:

```
Trigger: User taps Pet Name field in settings
Pre-conditions: None

Flow:
1. User taps text field
2. Keyboard appears (0.25s)
3. Text field enters edit mode (cursor blinking)
4. User types new name
5. Character count validates (1-30 chars)
6. User taps Return or elsewhere
7. Keyboard dismisses
8. Name saves automatically
9. Updates throughout app (detail title, dashboard card)

Duration: User-paced
```

---

## ⚠️ Error States & Edge Cases

### Network Not Required

- App functions 100% offline
- No error states for connectivity
- All data local

### Low Battery Mode

```
Detection: ProcessInfo.processInfo.isLowPowerModeEnabled
Adaptations:
- Reduce animation frame rate (60fps → 30fps)
- Simplify particle effects
- Dim brightness slightly in dark mode
- Continue all core functionality
```

### Notification Permission Denied

```
Scenario: User denies notification permission
Handling:
- App continues to function normally
- Timer UI shows progress in-app
- Settings shows "Notifications: Off"
- Gentle reminder in settings:
  "Enable notifications in iOS Settings to get reminders when laundry is done"
- Link to iOS Settings (openURL)
```

### Timer Interrupted (App Force Quit)

```
Scenario: User force quits app during timer
Handling:
- Timer saved to UserDefaults persists
- Notification still scheduled in iOS
- On next launch:
  1. Restore timer state from UserDefaults
  2. Calculate elapsed time
  3. If timer complete, update UI
  4. If timer running, resume countdown
- No data loss
```

### Pet Dies (Health Reaches 0)

```
Scenario: User neglects pet for too long
Visual State:
- Pet character: Gray, sad expression
- Status: "has died from neglect"
- Health: 0%

Recovery Flow:
- Action button: "Revive with Laundry"
- User completes normal cycle
- Pet "comes back to life" with animation
- Health restored to 100%
- Streak resets to 0 (consequence of neglect)
- Total cycles maintained (not punished)

Philosophy: Forgiving, not punishing
```

### Database Corruption

```
Scenario: Rare SwiftData corruption
Detection: Model fetch throws error
Handling:
1. Log error (for debugging)
2. Show alert:
   "Data Error"
   "We're having trouble loading your pets. You can reset the app data or contact support."
   [Reset Data] [Cancel]
3. If user resets:
   - Delete database file
   - Recreate fresh container
   - Navigate to empty state
4. If user cancels:
   - Try loading again on next launch
```

### Multiple Rapid Taps

```
Scenario: User taps action button multiple times quickly
Handling:
- Button disabled immediately on first tap
- Additional taps ignored (no effect)
- Visual feedback only on first tap
- Prevents duplicate timer starts
- Prevents double-submission bugs
```

---

## 🎭 Micro-Interactions

### Button Press Feedback

```
Trigger: User presses any button
Response:
- Visual: Scale to 0.96 (0.15s ease-in-out)
- Haptic: Light impact
- Audio: System tap sound (if enabled)

Release:
- Visual: Scale to 1.0 (0.2s ease-in-out)
- Haptic: Selection feedback (on successful action)
```

### Pet Character Tap

```
Trigger: User taps pet character
Response:
- Visual: Scale to 1.1 with bounce (0.4s spring)
- Haptic: Medium impact
- Animation: Pet "reacts" (brief special animation)
- No functional change (easter egg)
```

### Health Bar Update

```
Trigger: Health value changes
Response:
- Visual: Width animates to new value (0.3s ease-in-out)
- Color: Transitions if threshold crossed (green → orange)
- No haptic (passive update)
```

### Timer Second Tick

```
Trigger: Every second during active timer
Response:
- Visual: Time text updates (no animation, monospaced prevents shift)
- Progress ring: Smooth decrement (0.1s linear)
- No haptic (would be annoying)
```

### Streak Increment

```
Trigger: User completes cycle
Response:
- Visual: Number counts up (0.5s with easing)
- Color: Flash green briefly (0.3s)
- Haptic: Success feedback
- Particle: Optional sparkle effect
```

---

## 🔄 State Transitions

### Pet State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│ STATE: HAPPY (health 75-100%)                                   │
│ Visual: Green, bouncing animation                               │
│ Actions: Start Wash available                                    │
│ Duration: Until health decays below 75%                         │
└─────────────────────────────────────────────────────────────────┘
           ↓ (time passes, no laundry)
┌─────────────────────────────────────────────────────────────────┐
│ STATE: NEUTRAL (health 50-74%)                                  │
│ Visual: Blue, gentle sway                                       │
│ Actions: Start Wash available                                    │
│ Duration: Until health decays below 50% or laundry done        │
└─────────────────────────────────────────────────────────────────┘
           ↓ (time passes) / ↑ (laundry done)
┌─────────────────────────────────────────────────────────────────┐
│ STATE: SAD (health 25-49%)                                      │
│ Visual: Orange, drooping                                         │
│ Actions: Start Wash available (emphasized)                       │
│ Duration: Until health decays below 25% or laundry done        │
└─────────────────────────────────────────────────────────────────┘
           ↓ (time passes) / ↑ (laundry done)
┌─────────────────────────────────────────────────────────────────┐
│ STATE: VERY SAD (health 1-24%)                                  │
│ Visual: Red, very sad expression                                │
│ Actions: Start Wash available (pulsing urgency)                 │
│ Duration: Until health reaches 0 or laundry done                │
└─────────────────────────────────────────────────────────────────┘
           ↓ (time passes) / ↑ (laundry done)
┌─────────────────────────────────────────────────────────────────┐
│ STATE: DEAD (health 0%)                                         │
│ Visual: Gray, static sad face                                   │
│ Actions: "Revive with Laundry" available                        │
│ Duration: Until laundry done                                     │
└─────────────────────────────────────────────────────────────────┘
           ↑ (laundry done)
           Back to HAPPY
```

### Timer State Machine

```
IDLE → WASHING → WASH_COMPLETE → DRYING → DRY_COMPLETE → IDLE

IDLE:
- No active timer
- Action: "Start Wash"
- Pet in emotional state (happy/sad/etc.)

WASHING:
- Wash timer active
- Action: "Washing..." (disabled)
- Progress ring visible
- Pet animation: washing

WASH_COMPLETE:
- Wash finished
- Action: "Start Dryer"
- Pet animation: neutral
- Notification delivered

DRYING:
- Dry timer active
- Action: "Drying..." (disabled)
- Progress ring visible
- Pet animation: drying

DRY_COMPLETE:
- Dry finished
- Action: "Mark Folded"
- Pet animation: excited
- Notification delivered

→ Mark Folded → back to IDLE
```

---

## 📱 Platform-Specific Behaviors

### iOS Notifications

```
User can interact with notifications:
- Tap: Opens app to relevant pet
- Swipe: Reveals actions (future: "Mark Folded" action)
- Dismiss: Notification cleared, app unaffected
- Badge: Shows count of pending notifications
```

### Background App Refresh

```
Not required: Timers use absolute time (Date)
If enabled: Can update pet health preemptively
If disabled: Health updates on app launch
```

### Multitasking

```
App supports:
- Split View (iPad): Full functionality in compact size
- Slide Over (iPad): Compact view, core actions available
- Picture-in-Picture: Not applicable (no video)
```

---

## ✅ UX Quality Checklist

### Usability

- [ ] Zero tutorials needed (self-evident)
- [ ] Primary actions obvious at all times
- [ ] Error states are helpful, not blaming
- [ ] All actions reversible or confirmed
- [ ] Loading states never block user
- [ ] No dead ends (always way forward)

### Accessibility

- [ ] VoiceOver announces all state changes
- [ ] Dynamic Type scales all text
- [ ] Color not only indicator (+ text/icons)
- [ ] Minimum 44pt touch targets
- [ ] Reduced Motion alternatives
- [ ] High Contrast mode supported

### Performance

- [ ] App launches < 2 seconds
- [ ] All animations 60fps
- [ ] No dropped frames during interactions
- [ ] Haptics fire within 100ms
- [ ] Database queries < 50ms

### Delight

- [ ] Micro-interactions feel responsive
- [ ] Celebrations are satisfying
- [ ] Progress is visible and rewarding
- [ ] Pets feel "alive" through animation
- [ ] App feels polished, not rushed

---

## 🎯 UX Success Metrics

### Engagement

- **First cycle completion**: 70%+ of new users
- **Daily active users**: 30%+ of installs
- **Average sessions per day**: 2-3
- **Session duration**: 1-2 minutes (efficient)

### Satisfaction

- **App Store rating**: 4.5+ stars
- **Review sentiment**: Positive mentions of "fun", "helpful"
- **Support requests**: < 5% of users
- **Churn rate**: < 20% monthly

### Effectiveness

- **Laundry cycles completed**: 80%+ completion rate
- **Streak maintenance**: 50%+ users have 3+ streak
- **Multi-pet adoption**: 40%+ create 2+ pets
- **Settings usage**: 60%+ customize timers

**LaundryTime delivers an exceptional user experience that makes laundry management effortless and enjoyable.** 🎉
