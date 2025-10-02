# LaundryTime - Complete Screen Specifications

## Overview

This document provides pixel-perfect specifications for every screen in LaundryTime, including layouts, dimensions, states, interactions, and edge cases. Designers and developers can use this as the single source of truth for implementation.

---

## 📱 Screen Inventory

### Primary Screens

1. **Pet Dashboard** - Main screen with all pets
2. **Pet Detail View** - Individual pet with laundry controls
3. **Pet Settings** - Per-pet configuration
4. **App Settings** - Global app configuration
5. **Create Pet Modal** - New pet creation flow

### Supporting Screens

6. **Empty State** - First launch, no pets yet
7. **Delete Confirmation** - Destructive action alert

---

## 1️⃣ Pet Dashboard

### Purpose

Main navigation hub showing all pets at a glance with health status and quick actions.

### Layout Specifications

**Navigation Bar**:

```
Height: 44pt (standard iOS)
Background: .backgroundLight / .backgroundDark
Title: "My Laundry Pets"
Style: .large (expands when scrolled to top)

Left Item: None
Right Items:
  - Add Pet Button (+)
    • SF Symbol: "plus.circle.fill"
    • Size: 28pt
    • Color: .accentColor
    • Tap Area: 44×44pt
    • Action: Present CreatePetModal

  - Settings Button (gear)
    • SF Symbol: "gear"
    • Size: 24pt
    • Color: .textSecondary
    • Tap Area: 44×44pt
    • Spacing from Add: 12pt
    • Action: Present AppSettingsView
```

**Content Area (Has Pets)**:

```
ScrollView:
  Top Padding: 0pt (below navigation)
  Bottom Padding: spacing4 (16pt)
  Horizontal Padding: spacing4 (16pt)

  Pet Cards Grid:
    Layout: LazyVGrid
    Columns: 2 (iPhone), 3 (iPad)
    Spacing: spacing3 (12pt) horizontal & vertical

    Each Card:
      Width: (screen width - 16*2 - 12) / 2 ≈ 171pt on iPhone 12
      Height: 160pt (fixed)
      Corner Radius: 16pt
      Background: .surface
      Shadow: radius 8pt, offset (0, 2), opacity 0.05
      Padding: spacing3 (12pt) internal

      Content (VStack, spacing 12pt):
        1. Pet Icon Circle
           • Size: 60×60pt
           • Background: petState.color.opacity(0.2)
           • SF Symbol: petState.symbolName
           • Icon Size: 30pt
           • Icon Color: petState.color

        2. Pet Name
           • Font: .headlineSmall (18pt Semibold)
           • Color: .textPrimary
           • Max Lines: 1
           • Truncation: tail

        3. Health Bar
           • Height: 4pt
           • Corner Radius: 2pt
           • Background: .textTertiary.opacity(0.2)
           • Fill: petState.color
           • Fill Width: (health / 100) * total width
           • Animation: 0.3s ease-in-out

        4. Status Text
           • Font: .caption (12pt Medium)
           • Color: .textSecondary
           • Max Lines: 1
           • Text: petState.displayText

      Interaction:
        • Tap: Navigate to PetDetailView
        • Long Press: Context Menu
        • Haptic: Light impact on tap

      Context Menu:
        • Delete Pet (destructive, red)
          Icon: trash
          Action: Show confirmation alert
```

**Content Area (Empty State)**:

```
Centered VStack (spacing 24pt):

  1. Icon
     • SF Symbol: "pawprint.circle.fill"
     • Size: 80pt
     • Color: .accentColor.opacity(0.6)

  2. Title
     • Text: "No Pets Yet"
     • Font: .displayMedium (28pt Bold Rounded)
     • Color: .textPrimary

  3. Subtitle
     • Text: "Create your first laundry pet to get started!"
     • Font: .bodyLarge (17pt Regular)
     • Color: .textSecondary
     • Alignment: center
     • Max Width: screen width - 64pt

  4. Create Button
     • Label: "Create Pet"
     • Icon: plus.circle.fill
     • Font: .headlineMedium (20pt Semibold)
     • Foreground: .white
     • Background: Capsule, .accentColor
     • Padding: Horizontal 24pt, Vertical 12pt
     • Action: Present CreatePetModal
     • Haptic: Medium impact
```

### States

**Loading** (Initial Launch):

```
Navigation: Visible immediately
Content: ProgressView (center) for < 1s
Then: Transitions to empty or populated state
```

**Empty** (No Pets):

```
See Empty State spec above
Quick access to create first pet
```

**Populated** (1+ Pets):

```
Grid of pet cards
Scrollable if > 6 pets (2 rows on iPhone)
All pets visible at once (no pagination)
```

**Refreshing** (Pull to Refresh - Future):

```
Not implemented in V1
Future: Pull down to manually refresh health
```

### Accessibility

**VoiceOver**:

```
Navigation Title: "My Laundry Pets, Heading"
Add Button: "Add new pet, Button"
Settings Button: "App settings, Button"
Pet Card: "{PetName}, {health}% health, {state}, Button"
Empty State Button: "Create pet, Button"
```

**Dynamic Type**:

```
All text scales appropriately
Pet cards maintain fixed 160pt height
Card content may wrap or truncate at largest sizes
```

---

## 2️⃣ Pet Detail View

### Purpose

Primary interaction screen for individual pet, showing status, timer, and laundry controls.

### Layout Specifications

**Navigation Bar**:

```
Height: 44pt (standard)
Background: .backgroundLight / .backgroundDark
Title: {petName} (e.g., "Snowy")
Style: .inline (compact)

Left Item:
  - Back Button
    • iOS standard < with "My Laundry Pets"
    • Action: Pop navigation

Right Item:
  - Pet Settings Button
    • SF Symbol: "gear"
    • Size: 20pt
    • Color: .textSecondary
    • Tap Area: 44×44pt
    • Action: Present PetSettingsView
```

**Content Area**:

```
ScrollView (always scrollable for consistency):
  Top Padding: spacing8 (32pt)
  Bottom Padding: spacing6 (24pt)
  Horizontal Padding: spacing4 (16pt)

  VStack (spacing spacing6 = 24pt):

    1. Pet Character View
       • Height: 200pt
       • Width: Full width (centered content)
       • Content: See Pet Character Component spec

    2. Status Banner
       • Full width
       • Height: Auto (min 60pt)
       • Content: See Status Banner Component spec

    3. Primary Action Button
       • Full width (max 400pt on iPad)
       • Height: 56pt
       • Content: See Action Button Component spec
       • Text varies by state:
         - Idle: "Start Wash"
         - Washing: "Washing..." (disabled)
         - Ready for dryer: "Start Dryer"
         - Drying: "Drying..." (disabled)
         - Ready to fold: "Mark Folded"

    4. Timer Progress View (Conditional)
       • Only visible when timer active
       • Appears with fade-in (0.3s)
       • Full width (centered 140pt circle)
       • Content: See Timer Progress Component spec

    5. Stats Cards Row
       • HStack with 3 equal-width cards
       • Spacing: spacing3 (12pt)
       • Each card:
         - Height: Auto (min 80pt)
         - Background: .surface
         - Corner Radius: 12pt
         - Shadow: subtle
         - Padding: spacing3 (12pt)
         - Content:
           ┌──────────────┐
           │ CYCLES    [●]│ ← Label + color dot
           │ 12           │ ← Value (large)
           │ Total        │ ← Subtitle
           └──────────────┘

       Cards:
         A. Cycles
            Label: "CYCLES" (caption, uppercase)
            Value: totalCyclesCompleted (headlineMedium)
            Subtitle: "Total" (caption)
            Color: .primaryBlue

         B. Streak
            Label: "STREAK" (caption, uppercase)
            Value: currentStreak (headlineMedium)
            Subtitle: "Current" (caption)
            Color: .happyGreen

         C. Health
            Label: "HEALTH" (caption, uppercase)
            Value: "\(health)%" (headlineMedium)
            Subtitle: petState.displayText (caption, truncated)
            Color: pet state color
```

### Pet Character Component

```
ZStack (200pt height, centered):

  1. Background Circle
     • Size: 180×180pt
     • Fill: petState.color.opacity(0.1)
     • Shadow: radius 8pt, offset (0, 4), opacity 0.1

  2. Pet Character
     • SF Symbol: petState.symbolName
     • Size: 80pt
     • Color: petState.color
     • Animation: Idle breathing
       - Scale: 1.0 ↔ 1.05
       - Duration: 2.0s
       - Repeat: Forever, autoreverses
       - Easing: .easeInOut

  3. State-Specific Overlay (optional)
     • Washing: Bubble particles floating up
     • Drying: Steam/heat lines rising
     • Dead: X_X eyes overlay

  Interaction:
    • Tap: Pet "reacts" (scale 1.1 bounce, 0.4s)
    • Haptic: Medium impact
    • No functional effect (easter egg)
```

### Status Banner Component

```
HStack (spacing 12pt):

  1. State Indicator Dot
     • Size: 12×12pt
     • Fill: petState.color
     • Shape: Circle

  2. Status Text (VStack, spacing 2pt)
     • Pet Name
       - Font: .headlineSmall (18pt Medium)
       - Color: .textPrimary
       - Text: petName

     • State Description
       - Font: .bodySmall (13pt Regular)
       - Color: .textSecondary
       - Text: petState.displayText

  3. Spacer (pushes content left)

Background:
  • RoundedRectangle, radius 12pt
  • Fill: petState.color.opacity(0.1)
  • Stroke: petState.color.opacity(0.3), width 1pt
  • Padding: spacing4 (16pt) internal

Animation:
  • Color transitions: 0.3s ease-in-out
  • State changes: Smooth color morph
```

### Timer Progress Component

```
VStack (centered, spacing 16pt):

  1. Circular Progress Ring
     ZStack (140×140pt):

       A. Background Ring
          • Circle stroke
          • Color: .textTertiary.opacity(0.3)
          • Line Width: 8pt

       B. Progress Ring
          • Circle trim (0 to progress)
          • Color: timerColor (.washBlue or .dryYellow)
          • Line Width: 8pt
          • Line Cap: .round
          • Rotation: -90° (starts at top)
          • Animation: 0.5s ease-in-out on change

       C. Center Content (VStack, spacing 4pt)
          • Time Remaining
            - Font: .timerText (24pt Medium Monospaced)
            - Color: .textPrimary
            - Format: "MM:SS" (e.g., "42:15")
            - Tabular Numbers: true (no layout shift)

          • Timer Type Label
            - Font: .caption (12pt Medium)
            - Color: .textSecondary
            - Text: "Washing" or "Drying"

  2. Progress Percentage
     • Font: .bodyMedium (15pt Regular)
     • Color: .textSecondary
     • Text: "\(Int(progress * 100))%"
     • Example: "73%"

Appearance:
  • Fade in: 0.3s when timer starts
  • Fade out: 0.3s when timer completes
  • Updates: Every 1 second (smooth)
```

### Action Button Component

```
Dimensions:
  • Height: 56pt (standard touch target)
  • Width: Full width (max 400pt centered on iPad)
  • Corner Radius: 16pt

Content (HStack, spacing 8pt):
  • Loading Indicator (conditional)
    - ProgressView, scale 0.8
    - Tint: .white
    - Only visible when isLoading = true

  • Button Text
    - Font: .buttonText (17pt Semibold)
    - Color: .white
    - Text: Varies by state (see states below)

Background:
  • RoundedRectangle
  • Fill: isEnabled ? .primaryBlue : .textTertiary
  • Opacity: isEnabled ? 1.0 : 0.6

States:
  • Enabled:
    - Background: .primaryBlue
    - Opacity: 1.0
    - Tap active: YES
    - Scale: 1.0

  • Disabled:
    - Background: .textTertiary
    - Opacity: 0.6
    - Tap active: NO
    - Scale: 0.98

  • Loading:
    - Background: .primaryBlue
    - Opacity: 1.0
    - Tap active: NO
    - ProgressView visible
    - Text: Same as enabled state

Animation:
  • Press: Scale 0.96 (0.15s ease-in)
  • Release: Scale 1.0 (0.2s ease-out)
  • State change: 0.2s ease-in-out (color, opacity, scale)
  • Haptic: Medium impact on successful press
```

### States

**Idle (No Active Task)**:

```
Pet Character: Emotional state based on health
Status Banner: Current emotional state
Action Button: "Start Wash" (enabled, blue)
Timer Progress: Not visible
Stats: Current values
```

**Washing (Timer Active)**:

```
Pet Character: Washing animation, blue tint
Status Banner: "is getting clean!" (wash blue dot)
Action Button: "Washing..." (disabled, gray)
Timer Progress: Visible, wash blue, counting down
Stats: Current values
```

**Ready for Dryer (Wash Complete)**:

```
Pet Character: Neutral state
Status Banner: Current state
Action Button: "Start Dryer" (enabled, blue)
Timer Progress: Fades out (0.3s)
Stats: Current values
```

**Drying (Timer Active)**:

```
Pet Character: Drying animation, yellow tint
Status Banner: "is drying off" (dry yellow dot)
Action Button: "Drying..." (disabled, gray)
Timer Progress: Visible, dry yellow, counting down
Stats: Current values
```

**Ready to Fold (Dry Complete)**:

```
Pet Character: Excited animation, green tint
Status Banner: Current state
Action Button: "Mark Folded" (enabled, emphasized)
Timer Progress: Fades out (0.3s)
Stats: Current values
```

**Completing Cycle (Animation)**:

```
Duration: 0.8s
Pet Character: Scales up, spins, changes to green
Status Banner: Transitions to "is so happy!"
Action Button: Briefly disabled during animation
Stats: Values increment with animation:
  - Cycles: +1 (count-up animation)
  - Streak: +1 (count-up animation)
  - Health: → 100% (bar fills with animation)
Haptic: Heavy impact at start
Particle Effect: Optional sparkles/confetti
Then: Returns to Idle state with "Start Wash"
```

### Accessibility

**VoiceOver**:

```
Pet Character: "{PetName} is {state}, Image. Double tap for reaction."
Status Banner: "{PetName} is {state}"
Action Button: "{ButtonText}, Button. {isEnabled ? 'Double tap to activate' : 'Disabled'}"
Timer Progress: "Timer: {timeRemaining} remaining, {percentage}% complete"
Stats Cards: "{Label}: {Value} {Subtitle}"
```

**Dynamic Type**:

```
Pet Character: Fixed size (scales proportionally on iPad)
Status Banner: Text scales, min height 60pt
Action Button: Height fixed 56pt, text may scale slightly
Timer Progress: Fixed size, text scales within circle
Stats: Height adjusts to fit scaled text
```

---

## 3️⃣ Pet Settings

### Purpose

Configure per-pet settings: name, timer durations, cycle frequency, and deletion.

### Layout Specifications

**Presentation**:

```
Style: Sheet (.medium detent on iOS 16+, full screen on iOS 15)
Dismissal: Swipe down or Cancel button
Background: .backgroundLight / .backgroundDark
```

**Navigation Bar**:

```
Style: .inline
Title: "Pet Settings"
Left Item: Cancel button (dismisses sheet)
Right Item: None (auto-save)
```

**Form Content**:

```
Form (iOS standard grouped style):

  Section 1: Pet Information
    Header: "Pet Information"
    Footer: "Give your pet a unique name"

    Row: Pet Name
      • Label: "Pet Name"
      • Control: TextField
      • Placeholder: "Enter pet name"
      • Current Value: pet.name
      • Font: .bodyLarge (17pt)
      • Auto-capitalize: Words
      • Keyboard: Default
      • Max Length: 30 characters
      • Validation: Real-time, non-empty
      • Save: On edit end (automatic)

  Section 2: Laundry Timers
    Header: "Laundry Timers"
    Footer: "Customize how long each cycle takes"

    Row: Wash Time
      • Label: "Wash Time"
      • Value: "\(washDurationMinutes) minutes"
      • Accessory: Chevron (>)
      • Action: Navigate to Picker
      • Font: .bodyLarge (17pt)

    Row: Dry Time
      • Label: "Dry Time"
      • Value: "\(dryDurationMinutes) minutes"
      • Accessory: Chevron (>)
      • Action: Navigate to Picker
      • Font: .bodyLarge (17pt)

  Section 3: Cycle Frequency
    Header: "Cycle Frequency"
    Footer: "How often this pet needs laundry"

    Row: Frequency
      • Label: "How often"
      • Value: "Every \(cycleFrequencyDays) days"
      • Accessory: Chevron (>)
      • Action: Navigate to Picker
      • Font: .bodyLarge (17pt)

  Section 4: Danger Zone
    Header: None
    Footer: "This cannot be undone"

    Row: Delete Pet
      • Label: "Delete Pet"
      • Font: .bodyLarge (17pt)
      • Color: .red
      • Action: Show confirmation alert
      • Haptic: Warning on tap
```

### Time Picker Screen

**When Navigated From**: Wash Time or Dry Time row

**Layout**:

```
Navigation Bar:
  Title: "Wash Time" or "Dry Time"
  Left: Back button (auto-saves on back)
  Right: None

Content:
  Picker (Wheel style):
    • Values: 1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
              65, 70, 75, 80, 90, 100, 110, 120
    • Suffix: " minutes"
    • Selection: Current value highlighted
    • Haptic: Selection feedback on change

  Footer Text (below picker):
    • "For testing: Use 1-5 minutes"
    • "For real laundry: 30-60 minutes (wash), 45-75 minutes (dry)"
    • Font: .caption (12pt)
    • Color: .textSecondary
    • Alignment: Center
    • Padding: 16pt

Auto-save:
  • Value updates immediately on selection
  • Persists to Pet model in database
  • No explicit "Save" button needed
```

### Delete Confirmation Alert

**Trigger**: Tap "Delete Pet" in settings

**Alert Content**:

```
Style: UIAlertController.Style.alert
Title: "Delete {PetName}?"
Message: "This will permanently delete this pet and all its data. This cannot be undone."

Buttons:
  1. Cancel
     • Style: .cancel
     • Action: Dismiss alert

  2. Delete
     • Style: .destructive (red text)
     • Action:
       - Haptic: Medium impact
       - Delete pet from database (cascade tasks)
       - Dismiss settings sheet
       - Pop navigation to dashboard
       - Remove pet card with animation
```

### Accessibility

**VoiceOver**:

```
Pet Name Field: "Pet name, {current name}, Text field. Double tap to edit."
Timer Rows: "Wash time, {value} minutes, Button. Double tap to change."
Delete Button: "Delete pet, Button. Warning: This cannot be undone."
Picker: "{value} minutes, Adjustable. Swipe up or down to adjust."
```

---

## 4️⃣ App Settings

### Purpose

Global app configuration: notifications, appearance, sounds, haptics.

### Layout Specifications

**Presentation**:

```
Style: Sheet (.medium detent, swipe to dismiss)
Background: .backgroundLight / .backgroundDark
```

**Navigation Bar**:

```
Style: .inline
Title: "Settings"
Left: Done button (dismisses)
Right: None
```

**Form Content**:

```
Form (grouped style):

  Section 1: Notifications
    Header: "Notifications"
    Footer: "Get notified when laundry cycles complete"

    Row: Enable Notifications
      • Label: "Notifications"
      • Control: Toggle
      • Value: settings.notificationsEnabled
      • Action: Toggle + update settings
      • Note: If OS permission denied, show alert with link to Settings

    Row: Sound
      • Label: "Sound"
      • Control: Toggle
      • Value: settings.soundEnabled
      • Enabled: Only if notificationsEnabled = true
      • Color: Gray if disabled

    Row: Test Notification
      • Label: "Test Notification"
      • Accessory: None
      • Action: Send test notification (3s delay)
      • Color: .accentColor
      • Enabled: Only if notificationsEnabled = true

  Section 2: App Preferences
    Header: "App Preferences"
    Footer: None

    Row: Appearance
      • Label: "Appearance"
      • Value: settings.appearanceMode.displayName
      • Accessory: Chevron (>)
      • Action: Navigate to picker

    Row: Haptics
      • Label: "Haptics"
      • Control: Toggle
      • Value: settings.hapticsEnabled
      • Action: Toggle + trigger sample haptic

    Row: Sounds (Future)
      • Label: "Sounds"
      • Control: Toggle
      • Value: settings.soundEnabled
      • Action: Toggle + play sample sound

  Section 3: Data
    Header: "Data"
    Footer: "Permanently delete all pets and data"

    Row: Reset All Data
      • Label: "Reset All Data"
      • Font: .bodyLarge (17pt)
      • Color: .red
      • Action: Show confirmation alert
      • Haptic: Warning on tap

  Section 4: About
    Header: "About"
    Footer: None

    Row: Version
      • Label: "Version"
      • Value: "1.0.0 (1)" (from Bundle)
      • Accessory: None
      • Non-interactive

    Row: Support (Future)
      • Label: "Support"
      • Accessory: Chevron
      • Action: Open support URL
```

### Appearance Picker

**Layout**:

```
Navigation: Title "Appearance", back button
Content: List with radio buttons
  • Light Mode
  • Dark Mode
  • System (Recommended) [Default]

Selection: Checkmark on current
Action: Tap to change, immediate effect
Auto-save: Persists to AppSettings
```

### Reset Data Confirmation

**Alert**:

```
Title: "Reset All Data?"
Message: "This will delete all pets, laundry history, and settings. This cannot be undone."

Buttons:
  - Cancel (cancel style)
  - Reset (destructive, red)

Action on Reset:
  1. Delete all Pets (cascade to LaundryTasks)
  2. Reset AppSettings to defaults
  3. Clear UserDefaults (timer states)
  4. Dismiss settings sheet
  5. Navigate to dashboard → Empty state
  6. Show subtle confirmation: "Data reset"
```

---

## 5️⃣ Create Pet Modal

### Purpose

Quick pet creation flow, minimal friction.

### Layout Specifications

**Presentation**:

```
Style: Sheet (.medium detent, iOS 16+ | full screen iOS 15)
Dismissal: Cancel button or swipe
Background: .backgroundLight / .backgroundDark
```

**Navigation Bar**:

```
Style: .inline
Title: "New Pet"
Left: Cancel button (dismisses without saving)
Right: None
```

**Form Content**:

```
Form:

  Section: Pet Information
    Header: "Pet Information"
    Footer: "Give your laundry pet a unique name"

    Row: Pet Name Field
      • Control: TextField
      • Placeholder: "Enter pet name"
      • Font: .bodyLarge (17pt)
      • Auto-focus: YES (keyboard appears immediately)
      • Auto-capitalize: Words
      • Return Key: Done
      • Max Length: 30 characters
      • Clear Button: Always visible

  Section: Action
    Header: None
    Footer: None

    Row: Create Button
      • Label: "Create Pet"
      • Font: .headlineMedium (20pt Semibold)
      • Foreground: .white
      • Background: petName.isEmpty ? .gray : .accentColor
      • Padding: Vertical 8pt
      • Alignment: Center
      • Disabled: petName.isEmpty
      • Action:
        1. Create Pet in database
        2. Dismiss modal
        3. Dashboard updates with new pet card
        4. Optional: Navigate directly to new pet
      • Haptic: Medium impact on create
```

### Behavior

**On Appear**:

```
- Keyboard appears immediately (text field auto-focused)
- User can start typing without tapping
```

**Validation**:

```
- Real-time: Create button enabled/disabled
- Empty name → Button gray, disabled
- Valid name → Button blue, enabled
- No error messages (just button state)
```

**On Create**:

```
1. Validate name (non-empty, trimmed)
2. Create Pet(name: trimmedName)
3. Insert into SwiftData
4. Dismiss modal (0.25s slide down)
5. Dashboard appears with new pet
6. Pet card animates in (scale + fade)
```

**On Cancel**:

```
- Dismiss modal immediately
- No data created
- Return to previous screen
```

---

## 📐 Layout Measurements Summary

### Spacing Scale

```
spacing1:  4pt   (0.5×)
spacing2:  8pt   (1× base)
spacing3:  12pt  (1.5×)
spacing4:  16pt  (2× - screen margins)
spacing5:  20pt  (2.5×)
spacing6:  24pt  (3× - section spacing)
spacing8:  32pt  (4×)
spacing10: 40pt  (5×)
spacing12: 48pt  (6×)
```

### Component Sizes

```
Pet Character Circle: 180×180pt
Pet Character Icon: 80pt
Pet Card Height: 160pt
Pet Card Icon: 60×60pt
Action Button Height: 56pt
Small Button Height: 44pt
Timer Progress Ring: 140×140pt
Health Bar Height: 4pt
State Indicator Dot: 12×12pt
Navigation Bar: 44pt (compact), 96pt (large)
Touch Target Minimum: 44×44pt
```

### Screen Margins

```
Horizontal: 16pt (spacing4)
Top: 32pt (spacing8) in scrollable content
Bottom: 16pt (spacing4)
Between Sections: 24pt (spacing6)
Between Elements: 12pt (spacing3)
Within Component: 8pt (spacing2)
```

### Corner Radii

```
Large Cards: 16pt
Medium Cards: 12pt
Buttons: 16pt (large), 12pt (medium)
Small Elements: 8pt
Tiny Elements: 4pt (health bar)
Capsule: 50% (height / 2)
```

---

## ✅ Implementation Checklist

### Per Screen

- [ ] Navigation bar configured correctly
- [ ] Layout matches specifications
- [ ] All spacing uses design system values
- [ ] Colors use semantic names (not hard-coded)
- [ ] Fonts use type scale
- [ ] Touch targets meet 44pt minimum
- [ ] All states implemented
- [ ] Animations smooth (60fps)
- [ ] Haptic feedback appropriate
- [ ] VoiceOver labels present
- [ ] Dynamic Type support
- [ ] Dark mode fully supported
- [ ] Safe area respected
- [ ] iPad layout adapted
- [ ] Landscape support (if needed)

---

## 🎯 Design Consistency

All screens follow these principles:
✅ **Consistent spacing** using 8pt grid
✅ **Consistent colors** from design system
✅ **Consistent typography** from type scale
✅ **Consistent interactions** (taps, haptics, animations)
✅ **Consistent patterns** (navigation, forms, buttons)
✅ **Accessible** (VoiceOver, Dynamic Type, contrast)
✅ **Delightful** (smooth animations, satisfying feedback)

**Every screen delivers a premium, polished iOS experience.** 📱✨
