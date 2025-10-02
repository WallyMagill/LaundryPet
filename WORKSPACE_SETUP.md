# 🚀 LaundryTime Workspace Configuration Guide

This guide explains the Cursor AI and VS Code workspace configurations created for the LaundryTime iOS app project.

## 📁 What Was Created

### `.cursor/` Directory
AI-assisted development configuration:
- **`rules`** - Comprehensive coding guidelines for Cursor AI, including architectural patterns, code quality standards, and anti-patterns
- **`context`** - Project overview and technical context for AI understanding

### `.vscode/` Directory
VS Code/Cursor editor configuration:
- **`settings.json`** - Workspace settings (Swift LSP, formatting, exclusions)
- **`extensions.json`** - Recommended extensions for iOS/Swift development
- **`launch.json`** - Debug configurations for iOS Simulator
- **`tasks.json`** - Build tasks (Debug, Release, Clean, Tests, SwiftLint)
- **`snippets/swift.json`** - Code snippets for common patterns
- **`keybindings.json`** - Custom keyboard shortcuts

### Root Configuration Files
- **`.swiftlint.yml`** - SwiftLint rules for code quality enforcement
- **`.swiftformat`** - SwiftFormat configuration for consistent code formatting
- **`.gitignore`** - Standard iOS/Swift project exclusions

---

## 🎯 First-Time Setup

### 1. Open Project in Cursor
```bash
cd ~/Code/LaundryPets
cursor .
```

### 2. Install Recommended Extensions
When prompted, click **"Install All"** for recommended extensions:
- Swift Language Support
- Markdown All-in-One
- Mermaid Diagram Preview
- GitLens

### 3. Install Development Tools
```bash
# Install SwiftLint (optional but recommended)
brew install swiftlint

# Install SwiftFormat (optional but recommended)
brew install swiftformat
```

### 4. Verify Swift LSP
- Open any `.swift` file
- Check bottom-right corner for "Swift" language indicator
- Code completion should work automatically

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+B` | Build iOS Debug |
| `Cmd+Shift+B` | Clean Build |
| `Cmd+U` | Run Tests |
| `Cmd+Shift+L` | Run SwiftLint |

---

## 🤖 Working with Cursor AI

### Best Practices

#### 1. **Reference Documentation**
Always start AI prompts with documentation references:
```
Following the patterns in @ProductionDocs/01_System_Architecture_Overview.md, 
create a ViewModel for managing pet timers...
```

#### 2. **Use Specific Doc References**
Reference specific documentation files for context:
- `@ProductionDocs/02_Database_Design_Data_Models.md` - For data models
- `@ProductionDocs/03_User_Interface_Design_System.md` - For UI components
- `@ProductionDocs/05_Timer_Background_System.md` - For timer implementation

#### 3. **Check Rules Before Code Generation**
Ask AI to verify against rules:
```
Check this implementation against .cursor/rules and ensure it follows 
the multi-pet independence pattern
```

#### 4. **Request Pattern Explanations**
```
Explain how this code follows the MVVM + Services pattern described 
in our documentation
```

### Example Prompts

#### Creating a New ViewModel
```
Following @ProductionDocs/01_System_Architecture_Overview.md, create a 
PetDetailViewModel that manages a single pet's state. Use the patterns 
from .cursor/rules including proper error handling and @MainActor.
```

#### Implementing Timer Logic
```
Reference @ProductionDocs/05_Timer_Background_System.md and implement 
timer persistence using absolute time (Date) instead of countdown timers. 
Ensure UserDefaults keys are unique per pet as specified in .cursor/rules.
```

#### Creating UI Components
```
Using the design system from @ProductionDocs/03_User_Interface_Design_System.md, 
create a PetCard component with proper spacing, typography, and semantic colors.
```

---

## 🛠️ Code Snippets

Type these prefixes and press Tab:

| Prefix | Description |
|--------|-------------|
| `swiftui-view` | Create SwiftUI View with preview |
| `viewmodel` | Create ViewModel with error handling |
| `service` | Create Service class |
| `swiftdata-model` | Create SwiftData Model |
| `error-handling` | Add proper error handling block |
| `fetch-descriptor` | Create SwiftData FetchDescriptor |

### Example Usage
1. Type `viewmodel` in a Swift file
2. Press Tab
3. Fill in the placeholders (ViewModelName, property, etc.)

---

## 📋 Build Tasks

### Using Command Palette (Cmd+Shift+P)
1. Press `Cmd+Shift+P`
2. Type "Tasks: Run Task"
3. Select from:
   - Build iOS Debug
   - Build iOS Release
   - Clean Build
   - Run Tests
   - SwiftLint
   - Format Swift Code

### Using Keyboard Shortcuts
- `Cmd+B` - Quick build (default debug)
- `Cmd+Shift+B` - Clean build
- `Cmd+U` - Run tests
- `Cmd+Shift+L` - Run SwiftLint

---

## 🔍 SwiftLint & SwiftFormat

### SwiftLint
Enforces code quality rules:
```bash
# Run manually
swiftlint lint

# Auto-fix issues
swiftlint --fix
```

### SwiftFormat
Formats code consistently:
```bash
# Format all Swift files
swiftformat .

# Check without modifying
swiftformat . --lint
```

### Auto-Format on Save
Swift files automatically format when you save (configured in `settings.json`).

---

## 🎨 Design System Quick Reference

### Semantic Colors
```swift
.foregroundColor(.primaryBlue)    // Primary actions
.foregroundColor(.happyGreen)     // Happy/success states
.foregroundColor(.sadOrange)      // Warning states
.foregroundColor(.criticalRed)    // Critical/error states
```

### Typography
```swift
.font(.displayLarge)  // Large titles
.font(.headline)      // Section headers
.font(.body)          // Body text
.font(.caption)       // Small text
```

### Spacing
```swift
.padding(.spacing1)  // 4pt
.padding(.spacing2)  // 8pt
.padding(.spacing3)  // 12pt
.padding(.spacing4)  // 16pt
.padding(.spacing5)  // 24pt
.padding(.spacing6)  // 32pt
.padding(.spacing7)  // 48pt
.padding(.spacing8)  // 64pt
```

---

## ✅ Code Review Checklist

Before committing code, verify:
- [ ] Follows MVVM + Services architecture
- [ ] Error handling present with user-friendly messages
- [ ] Multi-pet isolation maintained (if applicable)
- [ ] Timers use absolute time (if applicable)
- [ ] Design system colors/fonts used
- [ ] No force unwraps without justification
- [ ] Accessibility labels added
- [ ] References correct documentation
- [ ] Matches patterns in Developer_Quick_Reference.md
- [ ] SwiftLint passes (`Cmd+Shift+L`)
- [ ] Code formatted (`swiftformat .`)

---

## 🐛 Troubleshooting

### Swift LSP Not Working
1. Check Xcode is installed: `/Applications/Xcode.app`
2. Verify sourcekit-lsp path in `.vscode/settings.json`
3. Restart Cursor/VSCode
4. Run: `xcode-select --print-path`

### Build Task Fails
1. Ensure Xcode project name is correct in `tasks.json`
2. Update simulator name if needed (currently "iPhone 15")
3. Run `xcodebuild -list` to see available schemes

### Extensions Not Installing
1. Open Extensions panel (Cmd+Shift+X)
2. Search for extension name
3. Install manually

### SwiftLint/SwiftFormat Not Found
```bash
# Install via Homebrew
brew install swiftlint swiftformat

# Verify installation
which swiftlint
which swiftformat
```

---

## 📚 Documentation Reference

All technical specifications are in `ProductionDocs/`:

### Core Architecture
- `01_System_Architecture_Overview.md` - MVVM + Services pattern
- `02_Database_Design_Data_Models.md` - SwiftData models
- `03_User_Interface_Design_System.md` - Design system

### Systems
- `05_Timer_Background_System.md` - Timer implementation
- `06_Notification_System.md` - Notification handling
- `07_Multi_Pet_Architecture.md` - Multi-pet isolation

### Guides
- `13_Error_Handling_Recovery.md` - Error handling patterns
- `Developer_Quick_Reference.md` - Common patterns (coming soon)

### Visual Flows
- `01_Complete_User_Journey_Flow.mmd` - User journey
- `02_Timer_State_Machine_Flow.mmd` - Timer state machine
- `08_Complete_Architecture_Layers.mmd` - Architecture layers

---

## 🎓 Learning Resources

### Understanding the Codebase
1. **Start with**: `ProductionDocs/README.md`
2. **Architecture**: `01_System_Architecture_Overview.md`
3. **Data Models**: `02_Database_Design_Data_Models.md`
4. **UI Components**: `03_User_Interface_Design_System.md`

### Common Patterns
Check `.cursor/rules` for:
- MVVM + Services structure
- Multi-pet independence
- Timer implementation with absolute time
- Error handling strategies
- SwiftData patterns

---

## 🚀 Daily Workflow

### Starting Development
1. Open project: `cursor .`
2. Pull latest: `git pull`
3. Verify build: `Cmd+B`
4. Run tests: `Cmd+U`

### During Development
1. Use snippets for boilerplate (`viewmodel`, `service`, etc.)
2. Reference docs with `@ProductionDocs/` in AI prompts
3. Format on save (automatic)
4. Check errors in Problems panel

### Before Committing
1. Run SwiftLint: `Cmd+Shift+L`
2. Format code: `swiftformat .`
3. Run tests: `Cmd+U`
4. Review changes with GitLens

---

## 💡 Pro Tips

### 1. Multi-Cursor AI Sessions
Open multiple files and ask AI to implement consistent patterns across them.

### 2. Documentation-Driven Development
Always reference `@ProductionDocs/` when asking AI to generate code.

### 3. Use Git Blame with GitLens
Hover over code to see when/why it was added.

### 4. Quick Documentation Lookup
Use `Cmd+P` to quickly open any doc file:
```
> 05_Timer
```

### 5. Mermaid Diagram Preview
Open `.mmd` files and use preview to visualize flows.

---

## 🎯 Success Metrics

Your workspace is properly configured when:
- ✅ Swift code completion works
- ✅ Build tasks run successfully (Cmd+B)
- ✅ AI references documentation in responses
- ✅ Snippets expand with Tab
- ✅ SwiftLint shows warnings/errors
- ✅ Code formats automatically on save

---

## 🆘 Getting Help

### Configuration Issues
Check this file and `.vscode/settings.json` paths.

### AI Not Following Patterns
Remind it to check `.cursor/rules` and reference specific docs.

### Build Issues
Run `xcodebuild -list` to verify scheme names.

### General Questions
Reference `ProductionDocs/00_Documentation_Index_Complete.md` for doc overview.

---

**🎉 You're all set! Start building amazing features for LaundryTime with AI-assisted development.**

For questions or issues, refer to the documentation in `ProductionDocs/` or update this configuration as needed.

