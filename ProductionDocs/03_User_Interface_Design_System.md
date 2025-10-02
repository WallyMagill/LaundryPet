# LaundryTime - User Interface Design System

## Overview

This design system defines the complete visual language for LaundryTime, creating a cohesive Tamagotchi-inspired experience that feels both nostalgic and modern while adhering to Apple's Human Interface Guidelines.

---

## 🎨 Design Philosophy

### Core Principles

**1. Pet-Centric Design**

- Pet character is the hero of every screen
- Centered layout with generous breathing room
- Emotional states clearly communicated through visuals
- Minimal UI chrome to maximize focus on pet

**2. Emotional Engagement**

- Color psychology: green = happy, orange = warning, red = urgent
- Smooth animations that delight without distracting
- Haptic feedback reinforces important interactions
- Progress indicators create anticipation

**3. Tamagotchi-Inspired Nostalgia**

- Rounded corners and soft shapes
- Playful but not childish aesthetic
- Character-based interactions
- Simple, direct controls

**4. iOS Native Excellence**

- Platform-standard components where appropriate
- Consistent with Apple HIG
- Dark mode as first-class citizen
- Accessibility built-in from the start

---

## 🎨 Color System

### Brand Colors

**Primary Palette**:

```swift
// Primary Brand Color
Color.primaryBlue = #3399FF
RGB(51, 153, 255)
HSL(210°, 100%, 60%)
Usage: Primary actions, navigation accents, app icon

Color.primaryBlueDark = #1A66CC
RGB(26, 102, 204)
HSL(210°, 77%, 45%)
Usage: Pressed states, dark mode accent
```

### Emotional State Colors

**Pet State Indicators**:

```swift
// Happy State
Color.happyGreen = #33CC66
RGB(51, 204, 102)
HSL(140°, 60%, 50%)
Usage: Happy pet, success states, completion

// Neutral State
Color.neutralOrange = #FF9933
RGB(255, 153, 51)
HSL(30°, 100%, 60%)
Usage: Neutral pet, mild warnings

// Sad State
Color.sadRed = #FF4D4D
RGB(255, 77, 77)
HSL(0°, 100%, 65%)
Usage: Sad pet, urgent states, errors
```

### Laundry Stage Colors

**Activity-Specific Colors**:

```swift
// Washing
Color.washBlue = #66CCFF
RGB(102, 204, 255)
HSL(200°, 100%, 70%)
Usage: Wash timer, water-related UI

// Drying
Color.dryYellow = #FFCC33
RGB(255, 204, 51)
HSL(45°, 100%, 60%)
Usage: Dry timer, heat-related UI

// Folding
Color.foldPurple = #9966FF
RGB(153, 102, 255)
HSL(260°, 100%, 70%)
Usage: Fold stage, completion celebration
```

### Neutral Palette

**Light Mode**:

```swift
// Backgrounds
Color.backgroundLight = #FAFAFF
RGB(250, 250, 255)
Usage: Main app background

Color.surfaceLight = #FFFFFF
RGB(255, 255, 255)
Usage: Cards, modals, elevated content

// Text
Color.textPrimaryLight = #1A1A1A
RGB(26, 26, 26)
Contrast Ratio: 15.8:1 ✅ WCAG AAA
Usage: Primary text

Color.textSecondaryLight = #666666
RGB(102, 102, 102)
Contrast Ratio: 4.6:1 ✅ WCAG AA
Usage: Secondary text, captions

Color.textTertiaryLight = #999999
RGB(153, 153, 153)
Contrast Ratio: 2.8:1
Usage: Disabled text, placeholders
```

**Dark Mode**:

```swift
// Backgrounds
Color.backgroundDark = #0D0D14
RGB(13, 13, 20)
Usage: Main app background

Color.surfaceDark = #1A1A1F
RGB(26, 26, 31)
Usage: Cards, modals, elevated content

// Text
Color.textPrimaryDark = #F2F2F2
RGB(242, 242, 242)
Contrast Ratio: 14.2:1 ✅ WCAG AAA
Usage: Primary text

Color.textSecondaryDark = #B3B3B3
RGB(179, 179, 179)
Contrast Ratio: 7.1:1 ✅ WCAG AAA
Usage: Secondary text, captions

Color.textTertiaryDark = #808080
RGB(128, 128, 128)
Contrast Ratio: 3.5:1 ✅ WCAG AA Large
Usage: Disabled text, placeholders
```

### Semantic Colors

**System States**:

```swift
// Success
Color.success = Color.happyGreen
Usage: Completed actions, positive feedback

// Warning
Color.warning = Color.neutralOrange
Usage: Caution states, moderate urgency

// Error
Color.error = Color.sadRed
Usage: Errors, destructive actions, critical states

// Info
Color.info = Color.primaryBlue
Usage: Informational messages, help hints
```

### Color Usage Guidelines

**Accessibility Standards**:

- All text meets WCAG 2.1 AA minimum (4.5:1 for normal text)
- Important text meets AAA standard (7:1)
- Never use color alone to convey information
- Test with color blindness simulators (protanopia, deuteranopia, tritanopia)

**Dark Mode Strategy**:

- All colors have dark mode variants
- Semantic colors adapt automatically
- Avoid pure black (#000000) - use #0D0D14 for depth
- Reduce saturation slightly in dark mode for comfort

---

## 📝 Typography System

### Font Family

**System Font: SF Pro (iOS Native)**

- SF Pro Display: Display sizes (28pt+)
- SF Pro Text: Body sizes (< 28pt)
- SF Pro Rounded: Pet names, playful elements
- SF Mono: Timer displays (fixed-width)

### Type Scale

**Display Sizes** (Titles, Headlines):

```swift
.displayLarge
Size: 32pt
Weight: Bold
Design: Rounded
Line Height: 38pt
Letter Spacing: -0.5pt
Usage: Large titles, onboarding headlines

.displayMedium
Size: 28pt
Weight: Bold
Design: Rounded
Line Height: 34pt
Letter Spacing: -0.3pt
Usage: Pet status messages, modal titles

.displaySmall
Size: 24pt
Weight: Semibold
Design: Rounded
Line Height: 30pt
Letter Spacing: 0pt
Usage: Screen titles, section headers
```

**Headline Sizes** (Subheadings):

```swift
.headlineLarge
Size: 22pt
Weight: Semibold
Design: Default
Line Height: 28pt
Usage: Card titles, important labels

.headlineMedium
Size: 20pt
Weight: Semibold
Design: Default
Line Height: 26pt
Usage: List section headers

.headlineSmall
Size: 18pt
Weight: Medium
Design: Default
Line Height: 24pt
Usage: Button labels, tab bar labels
```

**Body Sizes** (Content):

```swift
.bodyLarge
Size: 17pt (iOS standard body)
Weight: Regular
Design: Default
Line Height: 22pt
Usage: Primary content, descriptions

.bodyMedium
Size: 15pt
Weight: Regular
Design: Default
Line Height: 20pt
Usage: Secondary content, list items

.bodySmall
Size: 13pt
Weight: Regular
Design: Default
Line Height: 18pt
Usage: Tertiary content, metadata
```

**Support Sizes** (Captions, Labels):

```swift
.caption
Size: 12pt
Weight: Medium
Design: Default
Line Height: 16pt
Letter Spacing: 0.5pt
Usage: Timestamps, stats labels, footnotes

.overline
Size: 11pt
Weight: Semibold
Design: Default
Line Height: 16pt
Letter Spacing: 1pt
Text Transform: UPPERCASE
Usage: Section labels, categories

.timerText
Size: 24pt
Weight: Medium
Design: Monospaced
Line Height: 30pt
Tabular Numbers: true
Usage: Countdown timers (prevents layout shift)

.buttonText
Size: 17pt
Weight: Semibold
Design: Default
Line Height: 22pt
Usage: All button labels
```

### Dynamic Type Support

**Type Scale Mapping**:

| Style           | xSmall | Small | Medium | Large (Default) | xLarge | xxLarge | xxxLarge |
| --------------- | ------ | ----- | ------ | --------------- | ------ | ------- | -------- |
| Display Large   | 28pt   | 30pt  | 32pt   | 32pt            | 34pt   | 36pt    | 40pt     |
| Headline Medium | 17pt   | 18pt  | 19pt   | 20pt            | 22pt   | 24pt    | 26pt     |
| Body Large      | 14pt   | 15pt  | 16pt   | 17pt            | 19pt   | 21pt    | 23pt     |
| Caption         | 10pt   | 11pt  | 11pt   | 12pt            | 13pt   | 14pt    | 15pt     |

**Implementation**:

```swift
extension Font {
    static var displayLarge: Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    static var bodyLarge: Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    // Supports Dynamic Type scaling
    static var adaptiveBody: Font {
        .system(.body, design: .default)
    }
}
```

---

## 📐 Spacing & Layout

### Spacing Scale

**8-Point Grid System**:

```swift
// Base unit: 8pt
spacing1 = 4pt   // 0.5× - Tight spacing within elements
spacing2 = 8pt   // 1× - Base unit, related elements
spacing3 = 12pt  // 1.5× - Comfortable element spacing
spacing4 = 16pt  // 2× - Screen margins, component spacing
spacing5 = 20pt  // 2.5× - Loose spacing
spacing6 = 24pt  // 3× - Section spacing
spacing8 = 32pt  // 4× - Large section breaks
spacing10 = 40pt // 5× - Screen top/bottom margins
spacing12 = 48pt // 6× - Extra large spacing
spacing16 = 64pt // 8× - Special layouts
spacing20 = 80pt // 10× - Hero spacing
```

### Layout Dimensions

**Screen Margins**:

```swift
// Horizontal margins
screenMarginX = spacing4 (16pt)

// Vertical margins
screenMarginTop = spacing6 (24pt) // Below navigation
screenMarginBottom = spacing4 (16pt) // Above tab bar

// Safe area padding
safeAreaPadding = spacing4 (16pt) // All edges inside safe area
```

**Component Spacing**:

```swift
// Between major components (cards, sections)
componentSpacing = spacing4 (16pt)

// Between related elements (label and value)
elementSpacing = spacing3 (12pt)

// Within a component (icon and text)
internalSpacing = spacing2 (8pt)

// Tight spacing (multi-line text)
tightSpacing = spacing1 (4pt)
```

**Touch Targets**:

```swift
// Minimum touch target (Apple HIG)
minTouchTarget = 44pt × 44pt

// Recommended touch target
recommendedTouchTarget = 48pt × 48pt

// Button height
standardButtonHeight = 56pt

// Small button height
smallButtonHeight = 44pt
```

### Pet Character Area

**Dimensions**:

```swift
// Pet container
petContainerHeight = 250pt (iPhone) / 300pt (iPad)
petContainerWidth = full screen width - (screenMarginX × 2)

// Pet character
petCharacterSize = 120pt × 120pt
petBackgroundCircle = 180pt diameter

// Spacing
petTopMargin = spacing8 (32pt) from navigation
petBottomMargin = spacing6 (24pt) to status banner
```

### Card Layout

**Standard Card**:

```swift
// Dimensions
cardMinHeight = 120pt
cardPadding = spacing4 (16pt)
cardCornerRadius = 16pt

// Shadow
cardShadow = {
    color: .black.opacity(0.05)
    radius: 8pt
    x: 0pt
    y: 2pt
}

// Spacing
cardSpacing = spacing4 (16pt) between cards
```

**Compact Card** (Dashboard):

```swift
// Dimensions
compactCardHeight = 160pt
compactCardPadding = spacing3 (12pt)
compactCardCornerRadius = 12pt

// Grid
gridColumns = 2 (iPhone)
gridSpacing = spacing3 (12pt)
```

---

## 🧩 Component Library

### 1. Action Button (Primary)

**Specifications**:

```swift
Component: ActionButton
Dimensions: Height 56pt, Full width (max 400pt)
Corner Radius: 16pt
Padding: Horizontal spacing4 (16pt)

States:
- Default: primaryBlue background, white text
- Pressed: primaryBlueDark background, scale 0.98
- Disabled: textTertiary background, 60% opacity
- Loading: ProgressView + text, disabled interaction

Typography: buttonText (17pt Semibold)
Haptics: Medium impact on press
Animation: 0.2s ease-in-out scale + color
```

**Implementation**:

```swift
struct ActionButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }

                Text(title)
                    .font(.buttonText)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(16)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var backgroundColor: Color {
        isEnabled ? .primaryBlue : .textTertiary
    }
}
```

### 2. Pet Character View

**Specifications**:

```swift
Component: PetCharacterView
Dimensions: 200pt height, centered
Character Size: 120pt × 120pt
Background Circle: 180pt diameter

States:
- Happy: Green tint, bouncing animation
- Neutral: Blue tint, gentle sway
- Sad: Orange tint, drooping posture
- Very Sad: Red tint, crying animation
- Dead: Gray tint, static
- Washing: Blue with bubbles, spinning
- Drying: Yellow with steam, tumbling

Animation: 2s loop, .easeInOut
Haptics: Light impact on tap
```

**Implementation**:

```swift
struct PetCharacterView: View {
    let petState: PetState
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 180, height: 180)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            // Pet character (SF Symbol or custom image)
            Image(systemName: petState.symbolName)
                .font(.system(size: 80))
                .foregroundColor(petState.color)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
        }
        .frame(height: 200)
        .onAppear {
            startAnimation()
        }
    }

    private var backgroundColor: Color {
        petState.color.opacity(0.1)
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}
```

### 3. Timer Progress View

**Specifications**:

```swift
Component: TimerProgressView
Dimensions: 140pt × 140pt circular
Line Width: 8pt
Progress Range: 0.0 to 1.0

Elements:
- Background ring: textTertiary.opacity(0.3)
- Progress ring: Color based on timer type
- Time remaining: timerText (24pt Mono)
- Stage label: caption (12pt)
- Percentage: bodyMedium (15pt)

Animation: 0.5s ease-in-out on progress change
Colors: washBlue for wash, dryYellow for dry
```

**Implementation**:

```swift
struct TimerProgressView: View {
    let progress: Double // 0.0 to 1.0
    let timeRemaining: String
    let timerType: TimerType

    var body: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.textTertiary.opacity(0.3), lineWidth: 8)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Center content
                VStack(spacing: 4) {
                    Text(timeRemaining)
                        .font(.timerText)
                        .foregroundColor(.textPrimary)

                    Text(timerType.displayName)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
    }

    private var timerColor: Color {
        switch timerType {
        case .wash: return .washBlue
        case .dry: return .dryYellow
        }
    }
}
```

### 4. Pet Card View (Dashboard)

**Specifications**:

```swift
Component: PetCardView
Dimensions: 160pt height, adaptive width
Corner Radius: 16pt
Padding: spacing3 (12pt)

Elements:
- Pet icon/image (60pt)
- Pet name (headlineSmall, 18pt)
- Health bar (4pt height)
- Current state text (caption, 12pt)
- Stats badge (optional)

States:
- Default: surface background
- Pressed: scale 0.98, slight opacity
- Low health: subtle red border pulse

Shadow: Subtle depth
Haptics: Light impact on tap
```

**Implementation**:

```swift
struct PetCardView: View {
    let pet: Pet
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Pet indicator
            Circle()
                .fill(pet.currentState.color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: pet.currentState.symbolName)
                        .font(.system(size: 30))
                        .foregroundColor(pet.currentState.color)
                )

            // Pet name
            Text(pet.name)
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
                .lineLimit(1)

            // Health bar
            HealthBarView(health: pet.health ?? 100)

            // State text
            Text(pet.currentState.displayText)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .padding(.spacing3)
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            healthWarningBorder,
            alignment: .topTrailing
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Pet", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var healthWarningBorder: some View {
        if (pet.health ?? 100) < 25 {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.error, lineWidth: 2)
                .opacity(0.3)
        }
    }
}
```

### 5. Health Bar View

**Specifications**:

```swift
Component: HealthBarView
Dimensions: Full width × 4pt height
Corner Radius: 2pt

Colors:
- 100-75%: happyGreen
- 74-50%: neutralOrange
- 49-25%: sadRed
- 24-0%: sadRed with pulse

Animation: 0.3s ease-in-out on change
Background: textTertiary.opacity(0.2)
```

**Implementation**:

```swift
struct HealthBarView: View {
    let health: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.textTertiary.opacity(0.2))

                // Health fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(healthColor)
                    .frame(width: geometry.size.width * healthPercentage)
                    .animation(.easeInOut(duration: 0.3), value: health)
            }
        }
        .frame(height: 4)
    }

    private var healthPercentage: CGFloat {
        CGFloat(max(0, min(100, health))) / 100.0
    }

    private var healthColor: Color {
        switch health {
        case 75...100: return .happyGreen
        case 50..<75: return .primaryBlue
        case 25..<50: return .neutralOrange
        default: return .sadRed
        }
    }
}
```

### 6. Status Banner

**Specifications**:

```swift
Component: StatusBanner
Dimensions: Full width × auto height
Corner Radius: 12pt
Padding: spacing4 (16pt)

Elements:
- State indicator dot (12pt)
- Pet name (headlineSmall, 18pt)
- State text (bodySmall, 13pt)

Background: State color at 10% opacity
Border: State color at 30% opacity, 1pt
```

**Implementation**:

```swift
struct StatusBanner: View {
    let petName: String
    let petState: PetState

    var body: some View {
        HStack(spacing: 12) {
            // State indicator
            Circle()
                .fill(petState.color)
                .frame(width: 12, height: 12)

            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(petName)
                    .font(.headlineSmall)
                    .foregroundColor(.textPrimary)

                Text(petState.displayText)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(.spacing4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(petState.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(petState.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
```

---

## 🎬 Animation Guidelines

### Animation Principles

**1. Purposeful Motion**

- Every animation should have a clear purpose
- Animations guide attention to important changes
- Duration should feel natural, not rushed or sluggish

**2. Consistency**

- Use standardized durations and easing curves
- Similar interactions should have similar animations
- Maintain animation style across the app

**3. Performance**

- Target 60fps on all supported devices
- Use hardware-accelerated properties (opacity, transform)
- Avoid animating layout when possible
- Test on oldest supported device (iPhone SE)

**4. Respect User Preferences**

- Honor Reduce Motion accessibility setting
- Provide instant alternatives for decorative animations
- Keep critical animations but simplify them

### Standard Durations

```swift
// Animation durations (seconds)
let durationInstant = 0.15     // Micro-interactions
let durationFast = 0.2         // Button presses, small changes
let durationMedium = 0.3       // Standard transitions
let durationSlow = 0.5         // Emphasis animations
let durationDeliberate = 0.8   // Loading states, celebrations

// Easing curves
let easingStandard = Animation.easeInOut
let easingEnter = Animation.easeOut     // Elements appearing
let easingExit = Animation.easeIn       // Elements disappearing
let easingSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
let easingBounce = Animation.spring(response: 0.3, dampingFraction: 0.6)
```

### Animation Catalog

**Button Interactions**:

```swift
// Button press
Scale: 1.0 → 0.96 → 1.0
Duration: 0.15s (down), 0.2s (up)
Easing: .easeInOut
Haptic: Light impact on press

// Button state change (enabled/disabled)
Opacity: 1.0 → 0.6 or 0.6 → 1.0
Duration: 0.2s
Easing: .easeInOut
```

**Pet Animations**:

```swift
// Idle breathing
Scale: 1.0 → 1.05 → 1.0
Duration: 2.0s
Repeat: Forever, autoreverses
Easing: .easeInOut

// State transition (happy → sad)
Color: happyGreen → sadRed
Scale: 1.1 → 1.0
Duration: 0.5s
Easing: .easeInOut

// Celebration (cycle complete)
Scale: 1.0 → 1.3 → 1.0
Rotation: 0° → 15° → -15° → 0°
Duration: 0.8s
Easing: .spring
Haptic: Heavy impact
```

**Timer Progress**:

```swift
// Progress ring update
Trim: current → new value
Duration: 0.5s
Easing: .easeInOut

// Countdown text update
Opacity: 1.0 → 0.0 → 1.0 (crossfade)
Duration: 0.3s
Easing: .easeInOut

// Timer completion
Scale: 1.0 → 1.2 → 1.0
Color: timerColor → success
Duration: 0.6s
Easing: .spring
```

**Screen Transitions**:

```swift
// Push navigation
Transition: Slide from trailing edge
Duration: 0.3s
Easing: .easeInOut

// Modal presentation
Transition: Slide from bottom
Duration: 0.3s
Easing: .easeOut

// Dismissal
Transition: Slide to bottom/trailing
Duration: 0.25s
Easing: .easeIn
```

**Health Bar Updates**:

```swift
// Health increase/decrease
Width: current → new value
Color: current → new color (if threshold crossed)
Duration: 0.3s
Easing: .easeInOut

// Critical health warning (< 25%)
Opacity: 1.0 → 0.5 → 1.0 (pulse)
Duration: 1.5s
Repeat: Forever
Easing: .easeInOut
```

### Reduced Motion Alternatives

**When Reduce Motion is enabled**:

```swift
// Replace scaling animations with opacity
Scale 1.0 → 1.2 → 1.0
becomes
Opacity 0.8 → 1.0

// Replace rotation with fade
Rotation + bounce
becomes
Quick fade in

// Keep functional animations
Timer progress → Keep (functional)
Health bar updates → Keep (functional)
Navigation transitions → Simplify to crossfade

// Remove decorative animations
Pet idle breathing → Static
Celebration bounces → Single flash
Pulse effects → Solid color
```

**Implementation**:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.5)
}
```

---

## ♿ Accessibility

### VoiceOver Support

**Accessibility Labels**:

```swift
// Pet character
.accessibilityLabel("\(petName) is \(petState.displayText)")
.accessibilityHint("Double tap to view details")

// Timer progress
.accessibilityLabel("Timer: \(timeRemaining) remaining")
.accessibilityValue("\(Int(progress * 100)) percent complete")

// Action button
.accessibilityLabel(title)
.accessibilityHint(isEnabled ? "Double tap to \(action)" : "Disabled")

// Health bar
.accessibilityLabel("Health")
.accessibilityValue("\(health) percent")
```

**Accessibility Traits**:

```swift
// Buttons
.accessibilityAddTraits(.isButton)

// Headers
.accessibilityAddTraits(.isHeader)

// Images
.accessibilityAddTraits(.isImage)

// Static text
.accessibilityAddTraits(.isStaticText)
```

### Dynamic Type

**Scaling Strategy**:

- Use `.font(.body)`, `.font(.headline)` for standard text
- Use `.dynamicTypeSize(.xSmall ... .xxxLarge)` for limits if needed
- Test at largest size (XXXL)
- Allow multiline text to wrap
- Increase touch targets proportionally

**Layout Adaptations**:

```swift
// Stack direction changes based on content size
@Environment(\.dynamicTypeSize) var typeSize

var layout: AnyLayout {
    typeSize >= .xxxLarge ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
}
```

### Color Contrast

**Minimum Requirements**:

- Normal text: 4.5:1 contrast ratio (WCAG AA)
- Large text (18pt+): 3:1 contrast ratio (WCAG AA)
- Interactive elements: 3:1 contrast ratio

**High Contrast Mode**:

- Increase border weights from 1pt → 2pt
- Increase color saturation by 20%
- Add outlines to borderless buttons
- Test with "Increase Contrast" accessibility setting

### Touch Targets

**Minimum Sizes**:

```swift
// Standard touch target (Apple HIG)
minimumTouchTarget = 44pt × 44pt

// Recommended for primary actions
recommendedTouchTarget = 48pt × 48pt

// Implementation
Button("Label") { }
    .frame(minWidth: 44, minHeight: 44)
```

---

## 📱 Platform-Specific Guidelines

### iPhone Layouts

**Screen Size Adaptation**:

```swift
// iPhone SE (375pt width)
- Compact pet view (smaller character)
- Single column dashboard
- Reduced margins (12pt)

// iPhone Pro/Plus (390-428pt width)
- Standard pet view
- 2-column dashboard
- Standard margins (16pt)

// Safe Area
- Respect top safe area (navigation + status bar)
- Respect bottom safe area (home indicator)
- Add extra padding (16pt) inside safe area
```

### iPad Layouts (Compatibility Mode)

**Adaptations**:

```swift
// Center content in larger canvas
maxContentWidth = 600pt
Centered horizontally

// Larger pet character
petCharacterSize = 150pt × 150pt
petBackgroundCircle = 220pt

// 3-column dashboard grid
gridColumns = 3

// Modal presentations
Use .formSheet instead of .fullScreen
```

---

## 🎨 Design Assets

### SF Symbols Usage

**Pet State Icons**:

```swift
// Happy
"face.smiling.fill" → Happy pet
"sparkles" → Celebration

// Neutral
"face.dashed" → Neutral pet

// Sad
"face.frown.fill" → Sad pet

// Very Sad
"exclamationmark.triangle.fill" → Warning

// Dead
"xmark.circle.fill" → Critical state

// Washing
"circle.hexagongrid.fill" → Bubbles
"drop.fill" → Water

// Drying
"flame.fill" → Heat
"wind" → Air circulation

// Actions
"play.fill" → Start
"pause.fill" → Pause
"checkmark.circle.fill" → Complete
"gear" → Settings
"plus.circle.fill" → Add
"trash.fill" → Delete
```

### App Icon

**Design Specifications**:

```
Size: 1024× 1024px (App Store)
Format: PNG, no alpha channel
Content: Centered pet character on gradient background
Colors: Primary blue → Happy green gradient
Corner Radius: iOS applies automatically
Shadow: None (iOS applies automatically)

Additional sizes (generated automatically):
- 180×180 (iPhone @3x)
- 120×120 (iPhone @2x)
- 167×167 (iPad Pro @2x)
- 152×152 (iPad @2x)
- 76×76 (iPad @1x)
- 60×60 (iPhone Spotlight @3x)
- 40×40 (iPhone Spotlight @2x)
```

---

## ✅ Design System Checklist

### Implementation Checklist

- [ ] Color palette defined in Assets.xcassets with light/dark variants
- [ ] Typography scale implemented as Font extensions
- [ ] Spacing constants defined in central file
- [ ] All components use semantic colors (not hard-coded hex)
- [ ] All text supports Dynamic Type
- [ ] All touch targets meet 44pt minimum
- [ ] All colors meet WCAG AA contrast requirements
- [ ] VoiceOver labels for all interactive elements
- [ ] Haptic feedback for all significant interactions
- [ ] Animations respect Reduce Motion setting
- [ ] Dark mode fully supported
- [ ] High Contrast mode tested
- [ ] Layouts adapt to all iPhone sizes
- [ ] iPad compatibility verified

---

## 🎯 Design Excellence

This design system ensures LaundryTime delivers:

✅ **Visual Consistency**: Every screen feels cohesive
✅ **Emotional Connection**: Colors and animations reinforce pet care
✅ **Accessibility**: Usable by everyone, including assistive technology users
✅ **Platform Native**: Feels like a true iOS app
✅ **Scalability**: Easy to extend with new features
✅ **Performance**: Smooth 60fps animations on all devices
✅ **Delight**: Thoughtful micro-interactions create joy

**Ready for App Store review and user delight.** 🎨
