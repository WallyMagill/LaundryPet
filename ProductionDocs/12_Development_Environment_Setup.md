# LaundryTime - Development Environment Setup

## Overview

This document specifies the complete development environment setup for LaundryTime, including IDE configuration, build tools, debugging setup, and recommended extensions. While Xcode is the primary IDE for iOS development, this guide also covers VSCode setup for developers who prefer it for documentation and non-UI code editing.

---

## 🎯 Primary Development Environment

### Xcode (Required)

**Minimum Version**: Xcode 15.0+
**Recommended Version**: Latest stable release
**Download**: Mac App Store or https://developer.apple.com/xcode/

**Why Xcode is Primary**:

- Native iOS development environment
- SwiftUI canvas and preview
- Interface Builder for assets
- Best Swift/SwiftUI autocomplete
- Instruments for profiling
- Built-in simulator management
- App Store submission integration

**Xcode Setup**:

```bash
# Install Xcode Command Line Tools (if not already installed)
xcode-select --install

# Set Xcode path (if multiple versions installed)
sudo xcode-select -s /Applications/Xcode.app

# Verify installation
xcodebuild -version
# Should output: Xcode 15.x
```

**Xcode Preferences**:

```
Preferences → Text Editing:
  ✓ Line numbers
  ✓ Code folding ribbon
  ✓ Page guide at column: 100
  ✓ Indent width: 4 spaces
  ✓ Tab width: 4 spaces
  ✓ Prefer indent using: Spaces

Preferences → Navigation:
  ✓ Uses Focused Editor
  ✓ Command-click on Code: Jumps to Definition

Preferences → Behaviors:
  ✓ Starts: Show navigator (Command + 0)
  ✓ Generates output: Show debugger with console view
```

---

## 💻 VSCode Setup (Optional - For Documentation & Scripts)

### When to Use VSCode

**✅ Good For**:

- Editing markdown documentation
- Writing shell scripts
- Git operations
- Multi-file search and replace
- Lightweight code browsing
- Editing configuration files

**❌ Not Ideal For**:

- SwiftUI development (no preview)
- UI debugging
- Storyboards/XIBs
- Asset management
- Simulator management
- App profiling

### VSCode Installation

```bash
# Install VSCode
# Download from: https://code.visualstudio.com/

# Install via Homebrew (optional)
brew install --cask visual-studio-code
```

### Current VSCode Configuration

**Location**: `.vscode/` directory in project root

**Files**:

- `settings.json` - Editor settings and Swift configuration
- `launch.json` - Debug configurations
- `tasks.json` - Build tasks
- `extensions.json` - Recommended extensions
- `c_cpp_properties.json` - C/C++ intellisense (unnecessary for Swift project)

---

## ⚙️ VSCode Configuration Breakdown

### settings.json

**Current Configuration**:

```json
{
  // Swift Language Server Configuration
  "swift.path": "/usr/bin/swift",
  "swift.buildPath": "/usr/bin/swift",
  "swift.sourcekit-lsp.serverPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
  "swift.sourcekit-lsp.serverArguments": [
    "-Xswiftc",
    "-sdk",
    "-Xswiftc",
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
  ],

  // File Associations
  "files.associations": {
    "*.swift": "swift"
  },

  // Editor Settings
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit"
  },

  // Swift Build Configuration
  "swift.autoGenerateMain": false,
  "swift.buildArguments": [
    "-Xswiftc",
    "-sdk",
    "-Xswiftc",
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
  ],

  // File Explorer Exclusions
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/.build": true,
    "**/DerivedData": true
  },

  // Search Exclusions
  "search.exclude": {
    "**/.build": true,
    "**/DerivedData": true,
    "**/Pods": true
  }
}
```

**Configuration Explanation**:

**Swift Language Server**:

- Points to Xcode's SourceKit-LSP for Swift intellisense
- Configured for iOS Simulator SDK
- Enables code completion and navigation

**Editor Settings**:

- 4 spaces per indent (Swift standard)
- 100 character ruler (readability guideline)
- Format on save (automatic code formatting)
- Organize imports on save (cleanup)

**File Exclusions**:

- `.git`: Version control internals
- `.DS_Store`: macOS file system metadata
- `.build`: Swift Package Manager build artifacts
- `DerivedData`: Xcode build artifacts

---

### launch.json

**Current Configuration**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch iOS Simulator",
      "type": "lldb",
      "request": "launch",
      "program": "${workspaceFolder}/LaundryTime.xcodeproj",
      "args": [],
      "cwd": "${workspaceFolder}",
      "preLaunchTask": "build-ios"
    },
    {
      "name": "Attach to iOS Simulator",
      "type": "lldb",
      "request": "attach",
      "program": "${workspaceFolder}/LaundryTime.xcodeproj"
    }
  ]
}
```

**Configuration Explanation**:

**Launch iOS Simulator**:

- Builds and launches app in simulator
- Uses LLDB debugger (Apple's debugger)
- Runs `build-ios` task before launching

**Attach to iOS Simulator**:

- Attaches debugger to already-running app
- Useful for debugging without restarting

**⚠️ Note**: These configurations are **experimental** for Swift/iOS in VSCode. Xcode is strongly recommended for actual debugging.

---

### tasks.json

**Current Configuration**:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build-ios",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project",
        "LaundryTime.xcodeproj",
        "-scheme",
        "LaundryTime",
        "-destination",
        "platform=iOS Simulator,name=iPhone 15",
        "build"
      ],
      "group": "build"
    },
    {
      "label": "clean-ios",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project",
        "LaundryTime.xcodeproj",
        "-scheme",
        "LaundryTime",
        "clean"
      ],
      "group": "build"
    },
    {
      "label": "run-ios-simulator",
      "type": "shell",
      "command": "xcrun",
      "args": ["simctl", "boot", "iPhone 15"],
      "group": "build"
    }
  ]
}
```

**Configuration Explanation**:

**build-ios**:

- Compiles LaundryTime for iOS Simulator
- Targets iPhone 15 simulator
- Can be run via Command Palette: "Tasks: Run Build Task"

**clean-ios**:

- Cleans build artifacts
- Use when build is corrupted or after major changes

**run-ios-simulator**:

- Boots iPhone 15 simulator
- Useful for starting simulator before build

**⚠️ Note**: Building from command line is slower than Xcode. Use Xcode for primary development.

---

### extensions.json

**Current Configuration**:

```json
{
  "recommendations": [
    "sswg.swift-lang",
    "vknabel.vscode-swift-development-environment",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-eslint"
  ]
}
```

**Extension Analysis**:

| Extension                                      | Purpose                 | Necessary?  | Notes                       |
| ---------------------------------------------- | ----------------------- | ----------- | --------------------------- |
| `sswg.swift-lang`                              | Swift language support  | ✅ Yes      | Essential for Swift editing |
| `vknabel.vscode-swift-development-environment` | Swift development tools | ✅ Yes      | Helpful for Swift projects  |
| `ms-vscode.vscode-json`                        | JSON support            | ✅ Yes      | For editing config files    |
| `redhat.vscode-yaml`                           | YAML support            | ⚠️ Optional | Not used in LaundryTime     |
| `ms-vscode.vscode-typescript-next`             | TypeScript support      | ❌ No       | Not used in Swift project   |
| `bradlc.vscode-tailwindcss`                    | Tailwind CSS            | ❌ No       | Not used in native iOS      |
| `esbenp.prettier-vscode`                       | Code formatting         | ❌ No       | Not for Swift               |
| `ms-vscode.vscode-eslint`                      | JavaScript linting      | ❌ No       | Not used in Swift project   |

**Recommendations**: Remove unnecessary extensions (TypeScript, Tailwind, Prettier, ESLint).

---

## 🧹 Cleaned-Up VSCode Configuration

### Recommended settings.json

**Optimized for LaundryTime**:

```json
{
  // Swift Language Server Configuration
  "swift.path": "/usr/bin/swift",
  "swift.buildPath": "/usr/bin/swift",
  "swift.sourcekit-lsp.serverPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
  "swift.sourcekit-lsp.serverArguments": [
    "-Xswiftc",
    "-sdk",
    "-Xswiftc",
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
  ],

  // File Associations
  "files.associations": {
    "*.swift": "swift",
    "*.md": "markdown"
  },

  // Editor Settings (Match Xcode)
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.rulers": [100],
  "editor.formatOnSave": false, // Let Xcode handle formatting
  "editor.wordWrap": "wordWrapColumn",
  "editor.wordWrapColumn": 100,

  // Swift-Specific
  "swift.autoGenerateMain": false,

  // File Explorer Exclusions
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/.build": true,
    "**/DerivedData": true,
    "**/*.xcodeproj/project.xcworkspace": true,
    "**/*.xcodeproj/xcuserdata": true
  },

  // Search Exclusions
  "search.exclude": {
    "**/.build": true,
    "**/DerivedData": true,
    "**/*.xcodeproj": true,
    "**/Pods": true
  },

  // Markdown Settings (For Documentation)
  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.quickSuggestions": false,
    "editor.formatOnSave": true
  }
}
```

### Recommended extensions.json

**Minimal, Swift-Focused**:

```json
{
  "recommendations": [
    "sswg.swift-lang",
    "vknabel.vscode-swift-development-environment",
    "ms-vscode.vscode-json",
    "yzhang.markdown-all-in-one",
    "davidanson.vscode-markdownlint"
  ]
}
```

**Extension Purposes**:

- **Swift Language**: Swift syntax highlighting and LSP
- **Swift Development Environment**: Additional Swift tools
- **JSON**: For editing configuration files
- **Markdown All in One**: For documentation editing
- **Markdown Lint**: Keep documentation consistent

### Remove c_cpp_properties.json

**Why**: This file configures C/C++ IntelliSense, which is unnecessary for a Swift-only project.

**Action**: Delete `.vscode/c_cpp_properties.json`

---

## 🛠️ Development Workflow

### Recommended Workflow

**Day-to-Day Development**:

```
1. Use Xcode for:
   - Writing Swift code
   - UI development (SwiftUI)
   - Debugging
   - Testing
   - Profiling
   - Simulator management

2. Use VSCode for:
   - Editing documentation (*.md files)
   - Writing scripts (*.sh files)
   - Git operations (better diff view)
   - Multi-file search/replace
   - Quick file browsing
```

**Project Organization**:

```
LaundryTime/
├── .vscode/              # VSCode config (development only)
├── ProductionDocs/       # Documentation (edit in VSCode)
├── LaundryTime/          # Source code (edit in Xcode)
├── LaundryTime.xcodeproj/ # Xcode project (open in Xcode)
└── *.sh                  # Scripts (edit in VSCode)
```

---

## 🚀 Getting Started

### First-Time Setup

**For New Developer Joining Project**:

1. **Clone Repository**:

```bash
git clone [repository-url]
cd LaundryTime
```

2. **Install Xcode** (if not installed):

```bash
# Download from Mac App Store
# Or from: https://developer.apple.com/xcode/

# Install Command Line Tools
xcode-select --install
```

3. **Open in Xcode**:

```bash
open LaundryTime.xcodeproj
```

4. **Select Scheme**:

- Xcode → Scheme → LaundryTime
- Xcode → Destination → iPhone 15 (or any simulator)

5. **Build & Run**:

- Press ⌘ + R (or Product → Run)
- App should launch in simulator

6. **Optional: Configure VSCode**:

```bash
# Install VSCode
brew install --cask visual-studio-code

# Open project in VSCode
code .

# Install recommended extensions
# VSCode will prompt you to install recommended extensions
```

---

## 🧪 Testing Setup

### Unit Testing

**Run in Xcode**:

- Press ⌘ + U (or Product → Test)
- View results in Test Navigator (⌘ + 6)

**Run from Command Line**:

```bash
xcodebuild test \
  -project LaundryTime.xcodeproj \
  -scheme LaundryTime \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Testing

**Run in Xcode**:

- Open Test Navigator (⌘ + 6)
- Run specific UI tests

**Record UI Test**:

- Test Navigator → + → New UI Test
- Click record button
- Interact with app
- Xcode generates test code

---

## 🔍 Debugging Setup

### Xcode Debugging

**Breakpoints**:

- Click line number gutter to add breakpoint
- Right-click breakpoint for conditions
- Breakpoint Navigator (⌘ + 8) to manage all

**LLDB Commands** (in debug console):

```
po pet                    # Print object description
p pet.name                # Print property
expr pet.health = 100     # Modify during runtime
frame variable            # Show all local variables
bt                        # Backtrace (call stack)
```

**View Debugging**:

- Debug → View Debugging → Capture View Hierarchy
- 3D visualization of UI layers

### Instruments Profiling

**Launch Instruments**:

- Product → Profile (⌘ + I)
- Select instrument:
  - Time Profiler (CPU usage)
  - Allocations (memory usage)
  - Leaks (memory leaks)
  - Energy Log (battery impact)

---

## 📦 Build Configuration

### Debug vs. Release

**Debug Build** (Default):

- Optimizations: None (-Onone)
- Assertions: Enabled
- Symbols: Full debug info
- Use for: Development

**Release Build**:

- Optimizations: Full (-O)
- Assertions: Disabled
- Symbols: Minimal
- Use for: App Store submission

**Switch Configuration**:

- Edit Scheme (⌘ + <)
- Run → Build Configuration → Release

### Build Settings (Xcode)

**Important Settings**:

```
General:
  Display Name: LaundryTime
  Bundle Identifier: com.yourcompany.laundrytime
  Version: 1.0.0
  Build: 1

Signing & Capabilities:
  Team: [Your Team]
  Signing Certificate: Apple Development
  Provisioning Profile: Xcode Managed

Build Settings:
  Swift Language Version: Swift 5
  iOS Deployment Target: 15.0
  Supported Platforms: iOS
  Swift Compiler - Code Generation:
    Optimization Level (Debug): No Optimization [-Onone]
    Optimization Level (Release): Optimize for Speed [-O]
```

---

## 🔒 Git Configuration

### .gitignore

**Current Exclusions**:

```
# Xcode
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
DerivedData/
*.xcuserstate

# macOS
.DS_Store

# VSCode
.vscode/c_cpp_properties.json  # Auto-generated, not needed

# Build artifacts
.build/
*.ipa
*.app
```

### Git Workflow

**Recommended Branches**:

```
main          # Production-ready code
develop       # Integration branch
feature/*     # Feature branches
bugfix/*      # Bug fix branches
release/*     # Release preparation
```

**Commit Message Format**:

```
feat: Add multi-pet dashboard view
fix: Resolve timer persistence issue
docs: Update README with setup instructions
refactor: Extract PetService logic
test: Add unit tests for PetViewModel
```

---

## ✅ Development Environment Checklist

### Initial Setup

- [ ] Xcode 15+ installed
- [ ] Command Line Tools installed
- [ ] Project builds successfully
- [ ] App runs in simulator
- [ ] Tests pass

### Optional VSCode Setup

- [ ] VSCode installed
- [ ] Swift extension installed
- [ ] Markdown extensions installed
- [ ] Removed unnecessary extensions
- [ ] Can view and edit documentation
- [ ] Terminal integrated with zsh

### Team Setup

- [ ] Git configured with name/email
- [ ] SSH key added to GitHub
- [ ] Signing certificate configured
- [ ] Simulator devices downloaded
- [ ] Instruments profiles created

### Quality Tools

- [ ] SwiftLint configured (optional)
- [ ] SwiftFormat configured (optional)
- [ ] Accessibility Inspector tested
- [ ] Memory Graph Debugger tested
- [ ] Time Profiler tested

---

## 🎯 Recommended Tools

### Essential (Must Have)

**Xcode** (Free):

- Primary development environment
- https://developer.apple.com/xcode/

**SF Symbols** (Free):

- Browse iOS system icons
- https://developer.apple.com/sf-symbols/

**Simulator** (Included with Xcode):

- Test app on virtual devices

### Recommended (Nice to Have)

**VSCode** (Free):

- Lightweight code editor
- https://code.visualstudio.com/

**SourceTree** (Free):

- Git GUI client
- https://www.sourcetreeapp.com/

**Figma** (Free tier):

- Design mockups and assets
- https://www.figma.com/

**Postman** (Free):

- API testing (not used in LaundryTime V1.0)
- https://www.postman.com/

### Advanced (Power Users)

**SwiftLint** (Free):

```bash
brew install swiftlint
# Add Build Phase in Xcode to run on every build
```

**SwiftFormat** (Free):

```bash
brew install swiftformat
# Configure .swiftformat in project root
```

**Charles Proxy** (Paid):

- HTTP debugging
- https://www.charlesproxy.com/

---

## 🐛 Troubleshooting

### Common Issues

**Issue: "Command Line Tools Not Found"**

```bash
# Solution:
xcode-select --install

# If still not working:
sudo xcode-select -s /Applications/Xcode.app
```

**Issue: "Swift LSP Not Working in VSCode"**

```bash
# Solution:
# 1. Verify Xcode path
which swift
# Should output: /usr/bin/swift

# 2. Check SourceKit-LSP
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp --version

# 3. Reload VSCode window
# Command Palette → Developer: Reload Window
```

**Issue: "Build Failed in VSCode"**

```bash
# Solution: Use Xcode instead
# VSCode Swift support is experimental
# Build from Xcode for reliable results
```

**Issue: "Simulator Won't Boot"**

```bash
# Solution:
xcrun simctl shutdown all
xcrun simctl erase all
# Then restart Xcode
```

**Issue: "DerivedData Corruption"**

```bash
# Solution: Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/
# Then rebuild in Xcode
```

---

## 📝 Configuration File Summary

### Keep (Production)

- `.gitignore` - Git exclusions
- `README.md` - Project overview

### Keep (Development)

- `.vscode/settings.json` - Editor configuration
- `.vscode/extensions.json` - Recommended extensions (cleaned)
- `.vscode/tasks.json` - Build tasks (optional)

### Remove (Unnecessary)

- `.vscode/c_cpp_properties.json` - Not needed for Swift
- `.vscode/launch.json` - Experimental, use Xcode instead

### Not in Version Control

- `.vscode/*.log` - Logs
- `.DS_Store` - macOS metadata
- `DerivedData/` - Build artifacts
- `*.xcuserstate` - User-specific state

---

## 🎓 Learning Resources

### Official Documentation

- **Apple Developer Documentation**: https://developer.apple.com/documentation/
- **Swift Language Guide**: https://docs.swift.org/swift-book/
- **SwiftUI Tutorials**: https://developer.apple.com/tutorials/swiftui
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/

### Video Tutorials

- **WWDC Videos**: https://developer.apple.com/videos/
- **Stanford CS193p**: SwiftUI course on YouTube
- **Hacking with Swift**: https://www.hackingwithswift.com/

### Community

- **Swift Forums**: https://forums.swift.org/
- **Apple Developer Forums**: https://developer.apple.com/forums/
- **Stack Overflow**: Tag: [swift], [swiftui], [ios]

---

## 🚀 Quick Reference

### Xcode Shortcuts

```
Build:                ⌘ + B
Run:                  ⌘ + R
Test:                 ⌘ + U
Stop:                 ⌘ + .
Clean Build Folder:   ⌘ + Shift + K

Navigate:
Open Quickly:         ⌘ + Shift + O
Jump to Definition:   ⌘ + Click
Find in Project:      ⌘ + Shift + F
Show Navigator:       ⌘ + 0-9

Debug:
Step Over:            F6
Step Into:            F7
Step Out:             F8
Continue:             ⌘ + Control + Y
```

### Command Line Builds

```bash
# Build for simulator
xcodebuild -project LaundryTime.xcodeproj \
  -scheme LaundryTime \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# Run tests
xcodebuild test -project LaundryTime.xcodeproj \
  -scheme LaundryTime \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for App Store
xcodebuild archive -project LaundryTime.xcodeproj \
  -scheme LaundryTime \
  -archivePath build/LaundryTime.xcarchive
```

---

## ✅ Setup Complete

**Verify Your Setup**:

1. [ ] Xcode opens LaundryTime.xcodeproj
2. [ ] Project builds without errors (⌘ + B)
3. [ ] App runs in simulator (⌘ + R)
4. [ ] Tests pass (⌘ + U)
5. [ ] Can edit documentation in VSCode (optional)
6. [ ] Git commits work
7. [ ] Instruments can profile app

**If all checkboxes are complete, you're ready to develop!** 🎉

---

**The development environment is optimized for productivity, quality, and team collaboration.** 💻✨
