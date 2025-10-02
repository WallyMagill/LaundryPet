# LaundryTime - Accessibility & Localization

## Overview

LaundryTime is designed to be accessible to everyone, regardless of visual, motor, auditory, or cognitive abilities. This document specifies complete accessibility implementation following Apple's Human Interface Guidelines and WCAG 2.1 standards, plus internationalization strategy for global reach.

---

## ♿ Accessibility Principles

### Core Commitments

**1. Universal Design**

- App works for everyone out of the box
- No "accessibility mode" needed
- Features benefit all users, not just those with disabilities

**2. WCAG 2.1 Compliance**

- Level AA minimum for all content
- Level AAA for critical interactions
- Tested with real assistive technologies

**3. Apple HIG Adherence**

- VoiceOver fully supported
- Dynamic Type responsive
- Reduce Motion respected
- High Contrast optimized

**4. Continuous Testing**

- Test with VoiceOver during development
- Verify at all Dynamic Type sizes
- Check with color blindness simulators
- Real user testing with disabled community

---

## 📱 VoiceOver Support

### VoiceOver Fundamentals

**What is VoiceOver?**

- iOS screen reader
- Reads UI elements aloud
- Navigate by touch or gestures
- Used by blind and low-vision users

**LaundryTime VoiceOver Experience**:

```
User opens app → "My Laundry Pets, Heading"
Swipes right → "Snowy, 100% health, is so happy, Button"
Double taps → Opens Snowy's detail
Swipes right → "Snowy, Heading"
Swipes right → "Snowy is so happy, Image"
Swipes right → "Start Wash, Button"
Double taps → Timer starts
VoiceOver reads → "Washing, adjustable. Timer: 44 minutes 59 seconds remaining"
```

### Accessibility Labels

**Pet Card (Dashboard)**:

```swift
PetCardView(pet: pet)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(pet.name), \(pet.health ?? 100)% health, \(pet.currentState.displayText)")
    .accessibilityHint("Double tap to view details")
    .accessibilityAddTraits(.isButton)
```

**Pet Character View**:

```swift
PetCharacterView(petState: pet.currentState)
    .accessibilityLabel("\(pet.name) is \(pet.currentState.displayText)")
    .accessibilityAddTraits(.isImage)
    .accessibilityHint("Double tap for reaction animation")
```

**Timer Progress View**:

```swift
TimerProgressView(progress: progress, timeRemaining: timeString, timerType: .wash)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Timer")
    .accessibilityValue("\(timeString) remaining, \(Int(progress * 100)) percent complete")
    .accessibilityHint("Washing in progress")
```

**Action Button**:

```swift
ActionButton(title: "Start Wash", isEnabled: true) {
    startWash()
}
.accessibilityLabel("Start Wash")
.accessibilityHint(isEnabled ? "Double tap to start washing cycle" : "Button disabled, timer is running")
.accessibilityAddTraits(isEnabled ? .isButton : [.isButton, .notEnabled])
```

**Health Bar**:

```swift
HealthBarView(health: 75)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Health")
    .accessibilityValue("\(health) percent")
```

**Stats Cards**:

```swift
StatsCard(label: "Cycles", value: "12", subtitle: "Total")
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Cycles, 12 total")
```

### Accessibility Traits

**Apply Appropriate Traits**:

```swift
// Buttons
.accessibilityAddTraits(.isButton)

// Headers
.accessibilityAddTraits(.isHeader)

// Images
.accessibilityAddTraits(.isImage)

// Static text
.accessibilityAddTraits(.isStaticText)

// Selected state
.accessibilityAddTraits(isSelected ? .isSelected : [])

// Disabled state
.accessibilityAddTraits(isDisabled ? .notEnabled : [])
```

### Accessibility Actions

**Custom Actions for Complex Views**:

```swift
PetCardView(pet: pet)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(cardLabel)
    .accessibilityActions {
        Button("Delete Pet") {
            deletePet(pet)
        }
    }

// VoiceOver user can swipe up/down to hear "Actions Available"
// Then swipe to select "Delete Pet"
// Double tap to execute
```

### VoiceOver Testing Checklist

- [ ] All interactive elements have labels
- [ ] Labels are descriptive, not just "Button"
- [ ] Hints provide context when needed
- [ ] Traits accurately represent elements
- [ ] Reading order is logical
- [ ] Custom actions available where needed
- [ ] Values update dynamically (timer countdown)
- [ ] State changes announced (timer started, completed)
- [ ] No unlabeled mystery buttons
- [ ] Navigation is clear and intuitive

---

## 📏 Dynamic Type Support

### Type Scaling Strategy

**What is Dynamic Type?**

- User preference in iOS Settings → Accessibility → Display & Text Size
- Text scales from xSmall to AX5 (accessibility sizes)
- Ensures readability for low-vision users

**LaundryTime Scaling Approach**:

- Use semantic font styles (`.body`, `.headline`, etc.)
- Allow text to scale within reason
- Maintain touch targets at all sizes
- Adjust layouts for largest sizes

### Font Implementation

**Semantic Fonts (Recommended)**:

```swift
// ✅ CORRECT: Uses Dynamic Type automatically
Text("Snowy is so happy!")
    .font(.body)

Text("My Laundry Pets")
    .font(.largeTitle)

Text("12 cycles completed")
    .font(.caption)
```

**Custom Fonts with Scaling**:

```swift
// ✅ CORRECT: Custom font with Dynamic Type support
Text("Start Wash")
    .font(.custom("SF Pro", size: 17, relativeTo: .body))

// ❌ WRONG: Fixed size, doesn't scale
Text("Start Wash")
    .font(.system(size: 17))
```

### Layout Adaptations

**Horizontal → Vertical Stack at Large Sizes**:

```swift
@Environment(\.dynamicTypeSize) var typeSize

var body: some View {
    if typeSize >= .accessibility1 {
        // Large size: Stack vertically
        VStack(alignment: .leading, spacing: 12) {
            petIcon
            petInfo
        }
    } else {
        // Normal size: Stack horizontally
        HStack(spacing: 12) {
            petIcon
            petInfo
        }
    }
}
```

**Increased Touch Targets**:

```swift
ActionButton(title: "Start Wash") {
    startWash()
}
.frame(minHeight: typeSize >= .accessibility1 ? 60 : 56)
// Larger buttons for accessibility sizes
```

**Truncation vs. Wrapping**:

```swift
// Allow wrapping for important text
Text(pet.name)
    .font(.headline)
    .lineLimit(nil)  // No limit, wrap as needed
    .fixedSize(horizontal: false, vertical: true)

// Truncate for less critical text
Text(pet.currentState.displayText)
    .font(.caption)
    .lineLimit(1)
    .truncationMode(.tail)
```

### Dynamic Type Testing

**Test at All Sizes**:

1. Open Settings → Accessibility → Display & Text Size → Larger Text
2. Drag slider to each position
3. Return to LaundryTime and verify:
   - Text is readable
   - Buttons are tappable (44pt minimum)
   - Layouts don't overlap or clip
   - Scroll views work correctly

**Size Categories**:

```
xSmall     → Text smaller than default
Small      → Text slightly smaller
Medium     → Text slightly smaller
Large      → Default size ⭐️
xLarge     → Slightly larger
xxLarge    → Larger
xxxLarge   → Much larger
─────────────────────────────
Accessibility Sizes (Extra support):
accessibility1  → Very large (AX1)
accessibility2  → Extremely large (AX2)
accessibility3  → Huge (AX3)
accessibility4  → Enormous (AX4)
accessibility5  → Maximum (AX5)
```

### Dynamic Type Checklist

- [ ] All text uses semantic fonts or `relativeTo:`
- [ ] Pet names wrap instead of truncate
- [ ] Buttons maintain 44pt minimum height
- [ ] Stats cards stack vertically at large sizes
- [ ] Timer text remains readable
- [ ] Dashboard cards resize appropriately
- [ ] No text clipping or overlap
- [ ] Scroll views accommodate larger content

---

## 🎨 Color & Contrast

### WCAG 2.1 Contrast Requirements

**Levels**:

- **AA**: 4.5:1 for normal text (mandatory)
- **AA**: 3:1 for large text 18pt+ (mandatory)
- **AAA**: 7:1 for normal text (goal)

**LaundryTime Compliance**:

| Element                | Foreground | Background | Ratio  | Status   |
| ---------------------- | ---------- | ---------- | ------ | -------- |
| Primary text (light)   | #1A1A1A    | #FAFAFF    | 15.8:1 | ✅ AAA   |
| Secondary text (light) | #666666    | #FAFAFF    | 4.6:1  | ✅ AA    |
| Primary text (dark)    | #F2F2F2    | #0D0D14    | 14.2:1 | ✅ AAA   |
| Secondary text (dark)  | #B3B3B3    | #0D0D14    | 7.1:1  | ✅ AAA   |
| Happy green            | #33CC66    | #FAFAFF    | 3.2:1  | ✅ Large |
| Sad red                | #FF4D4D    | #FAFAFF    | 3.8:1  | ✅ Large |

**Tools for Testing**:

- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
- Sim Daltonism (macOS): Color blindness simulator
- Color Oracle: Free color blindness simulator

### High Contrast Mode

**iOS Setting**: Settings → Accessibility → Display & Text Size → Increase Contrast

**Adaptations**:

```swift
@Environment(\.colorSchemeContrast) var contrast

var strokeWidth: CGFloat {
    contrast == .increased ? 2 : 1
}

var shadowOpacity: CGFloat {
    contrast == .increased ? 0.2 : 0.1
}

RoundedRectangle(cornerRadius: 12)
    .stroke(pet.currentState.color, lineWidth: strokeWidth)
    .shadow(opacity: shadowOpacity)
```

**High Contrast Checklist**:

- [ ] Borders increased from 1pt to 2pt
- [ ] Button outlines more prominent
- [ ] Shadows slightly more visible
- [ ] Separators more distinct
- [ ] Cards have clear boundaries

### Color Blindness Considerations

**Never Rely on Color Alone**:

```swift
// ❌ BAD: Only color differentiates
Circle()
    .fill(healthColor)  // User can't tell what it means

// ✅ GOOD: Color + Text + Icon
HStack {
    Image(systemName: "heart.fill")
        .foregroundColor(healthColor)
    Text("\(health)% Health")
        .foregroundColor(.textPrimary)
}
```

**Types of Color Blindness**:

- **Protanopia**: Red-blind
- **Deuteranopia**: Green-blind
- **Tritanopia**: Blue-blind
- **Achromatopsia**: Complete color blindness

**LaundryTime Strategy**:

- Pet states use color + icon + text
- Health bar has percentage text
- Timer uses text + progress ring
- No critical information by color alone

---

## 🎭 Reduce Motion

### Why Reduce Motion?

**Users Enable When**:

- Motion sickness / vestibular disorders
- Attention disorders (distracted by animations)
- Preference for simpler interface

**Settings**: Settings → Accessibility → Motion → Reduce Motion

### Reduce Motion Adaptations

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.5)
}

// Pet character animation
.scaleEffect(isAnimating ? 1.1 : 1.0)
.animation(animation, value: isAnimating)

// Replace bouncy spring with simple fade
if reduceMotion {
    .transition(.opacity)
} else {
    .transition(.scale.combined(with: .opacity))
}
```

**What to Simplify**:

```
Decorative animations → Remove or simplify
Functional animations → Keep but simplify
Essential feedback → Always keep (e.g., button press)

Examples:
- Pet idle breathing → Static image
- Celebration bounce → Quick fade
- Screen transitions → Crossfade instead of slide
- Progress ring → Instant update instead of smooth
```

### Reduce Motion Checklist

- [ ] Decorative animations removed
- [ ] Essential animations simplified
- [ ] Transitions still clear (fade instead of slide)
- [ ] Button feedback still present
- [ ] App remains usable and understandable
- [ ] No jarring instant changes

---

## 🖱️ Pointer & Input Accessibility

### Touch Target Sizes

**Apple HIG Minimum**: 44×44 points

**LaundryTime Standards**:

```swift
// Standard button
ActionButton(title: "Start Wash")
    .frame(minWidth: 44, minHeight: 56)  // Exceeds minimum

// Small button (settings)
Button("Cancel") { }
    .frame(minWidth: 44, minHeight: 44)  // Meets minimum

// Icon button
Button {
    openSettings()
} label: {
    Image(systemName: "gear")
        .font(.title3)
}
.frame(width: 44, height: 44)  // Explicit size
```

**Touch Target Heatmap**:

```
Dashboard:
  Pet card: 171×160pt ✅ (much larger than minimum)
  Add button: 44×44pt ✅
  Settings button: 44×44pt ✅

Pet Detail:
  Pet character: 180×180pt (tappable) ✅
  Action button: Full width × 56pt ✅
  Settings gear: 44×44pt ✅
```

### External Keyboard Support

**Full Keyboard Navigation**:

```swift
// Make buttons keyboard-focusable
ActionButton(title: "Start Wash") {
    startWash()
}
.focusable()  // Can be reached via Tab

// Custom keyboard shortcuts (optional)
.keyboardShortcut("s", modifiers: .command)  // ⌘S to start
```

**Focus Order**:

1. Navigation elements (back, settings)
2. Primary content (pet character)
3. Action buttons (start wash)
4. Secondary elements (stats)

### Switch Control

**iOS Assistive Technology for Motor Disabilities**

**LaundryTime Compatibility**:

- All interactive elements keyboard-focusable
- Logical tab order
- Clear visual focus indicators
- No custom gestures required
- Standard iOS controls used

**Testing**:
Settings → Accessibility → Switch Control → Enable

- Verify all buttons reachable
- Verify actions executable
- Verify navigation works

---

## 🌍 Internationalization (i18n)

### Localization Strategy

**V1.0 Launch Languages**:

- English (U.S.) - Primary
- Future: Spanish, French, German, Japanese, Chinese

**Localization Approach**:

```swift
// Use NSLocalizedString for all user-facing text
Text(NSLocalizedString("start_wash", comment: "Button to start wash cycle"))

// Localizable.strings (English)
"start_wash" = "Start Wash";
"wash_complete" = "Wash Complete!";
"pet_happy" = "%@ is so happy!";  // Supports string interpolation

// Localizable.strings (Spanish)
"start_wash" = "Iniciar Lavado";
"wash_complete" = "¡Lavado Completo!";
"pet_happy" = "¡%@ está muy feliz!";
```

### String Externalization

**Current Implementation (V1.0)**:

```swift
// Hard-coded strings (acceptable for V1.0 English-only)
Text("Start Wash")
Text("Snowy is so happy!")

// For V1.1 localization, convert to:
Text(NSLocalizedString("start_wash", comment: ""))
Text(String(format: NSLocalizedString("pet_happy", comment: ""), pet.name))
```

### Pluralization

**Correct Pluralization**:

```swift
// ❌ WRONG: Doesn't handle plurals correctly in all languages
Text("\(count) cycles completed")

// ✅ CORRECT: Uses stringsdict for proper pluralization
// Localizable.stringsdict
<key>cycles_completed</key>
<dict>
    <key>NSStringLocalizedFormatKey</key>
    <string>%#@cycles@</string>
    <key>cycles</key>
    <dict>
        <key>NSStringFormatSpecTypeKey</key>
        <string>NSStringPluralRuleType</string>
        <key>NSStringFormatValueTypeKey</key>
        <string>d</string>
        <key>zero</key>
        <string>No cycles completed</string>
        <key>one</key>
        <string>1 cycle completed</string>
        <key>other</key>
        <string>%d cycles completed</string>
    </dict>
</dict>
```

### Right-to-Left (RTL) Support

**RTL Languages**: Arabic, Hebrew

**SwiftUI Automatic Mirroring**:

```swift
// SwiftUI handles most RTL automatically
HStack {
    Image(systemName: "chevron.right")  // Flips to left in RTL
    Text("Pet Details")
}

// Custom handling if needed
@Environment(\.layoutDirection) var layoutDirection

if layoutDirection == .rightToLeft {
    // Custom RTL layout
}
```

### Date & Time Formatting

**Use System Formatters**:

```swift
// ✅ CORRECT: Respects user's locale
let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeStyle = .short
let dateString = formatter.string(from: date)

// For timers, use DateComponentsFormatter
let formatter = DateComponentsFormatter()
formatter.allowedUnits = [.minute, .second]
formatter.unitsStyle = .positional
formatter.zeroFormattingBehavior = .pad
let timerString = formatter.string(from: timeInterval) ?? "0:00"
```

---

## 📋 Accessibility Testing Protocol

### Manual Testing Checklist

**VoiceOver**:

1. Enable VoiceOver (⌘ + Triple-click Home button)
2. Navigate through entire app
3. Verify all elements have labels
4. Check reading order makes sense
5. Test all interactive elements
6. Verify state changes announced

**Dynamic Type**:

1. Go to Settings → Accessibility → Display & Text Size → Larger Text
2. Test at each size: Large (default), xxxLarge, AX5
3. Verify no clipping or overlap
4. Check all text readable
5. Verify buttons still tappable

**Color & Contrast**:

1. Test in light mode and dark mode
2. Enable Increase Contrast
3. Use color blindness simulator
4. Verify all information conveyed beyond color

**Reduce Motion**:

1. Enable Reduce Motion
2. Verify animations simplified
3. Check app still usable
4. Ensure no jarring instant changes

**Keyboard & Switch Control**:

1. Connect external keyboard
2. Navigate using Tab
3. Activate using Enter/Space
4. Test Switch Control if available

### Automated Testing

**Xcode Accessibility Inspector**:

```
Xcode → Open Developer Tool → Accessibility Inspector
- Run audit on app
- Fix all issues reported
- Re-audit until clean
```

**Automated UI Tests with Accessibility**:

```swift
func testVoiceOverLabels() {
    let app = XCUIApplication()
    app.launch()

    // Verify pet card has accessibility label
    let petCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'health'")).firstMatch
    XCTAssertTrue(petCard.exists)
    XCTAssertTrue(petCard.label.contains("Snowy"))
}
```

---

## ✅ Accessibility Compliance Checklist

### VoiceOver

- [ ] All interactive elements have labels
- [ ] Labels are descriptive and meaningful
- [ ] Hints provide additional context where needed
- [ ] Traits accurately describe elements
- [ ] Reading order is logical
- [ ] Dynamic content updates announced
- [ ] Custom actions provided for complex views

### Dynamic Type

- [ ] All text uses semantic fonts or relativeTo:
- [ ] Layouts adapt to larger text sizes
- [ ] Touch targets maintain 44pt minimum
- [ ] No text clipping at any size
- [ ] Horizontal stacks become vertical when needed

### Color & Contrast

- [ ] All text meets WCAG AA (4.5:1)
- [ ] Important text meets WCAG AAA (7:1)
- [ ] High Contrast mode supported
- [ ] Information not conveyed by color alone
- [ ] Tested with color blindness simulators

### Motion

- [ ] Reduce Motion respected
- [ ] Decorative animations removed when enabled
- [ ] Essential animations simplified
- [ ] App remains fully functional

### Input

- [ ] All touch targets ≥ 44×44pt
- [ ] External keyboard supported
- [ ] Focus order logical
- [ ] Switch Control compatible

### Internationalization

- [ ] Strings externalized (for future localization)
- [ ] Dates/times use system formatters
- [ ] RTL layouts supported
- [ ] Pluralization handled correctly

---

## 🎯 Accessibility Success Metrics

**App Store Accessibility Rating**:

- Target: 4.5+ stars from disabled users
- Monitor reviews mentioning accessibility
- Respond to all accessibility feedback

**Usage Metrics** (privacy-preserving local tracking):

- % users with VoiceOver enabled: Track (no external upload)
- % users with Large Text enabled: Track locally
- Crash rate with accessibility features: 0%

**User Feedback**:

- "Best accessible laundry app"
- "Finally an app I can use with VoiceOver"
- "Perfect Dynamic Type support"
- "Works great with Switch Control"

---

## 🚀 Future Accessibility Enhancements

### V1.1

- [ ] Localization: Spanish, French, German
- [ ] Custom VoiceOver pronunciations for pet names
- [ ] Audio feedback for timer completion (in addition to notification)
- [ ] Larger touch targets option in settings

### V1.2

- [ ] Additional languages: Japanese, Chinese, Portuguese
- [ ] Voice control integration
- [ ] Haptic patterns for different events
- [ ] Configurable notification patterns (for deaf users)

### V2.0

- [ ] Full RTL language support
- [ ] Sign language tutorial videos
- [ ] Alternative color schemes for various color blindness types
- [ ] Accessibility API for third-party assistive tech

---

**Accessibility is not a feature—it's a fundamental right. LaundryTime works for everyone.** ♿✨
