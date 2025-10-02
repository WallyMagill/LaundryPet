# LaundryTime - Visual Flows Complete Index

## 📊 Overview

This document indexes all visual flow diagrams that explain LaundryTime's functionality. Each diagram is interactive and can be viewed in detail.

**Total Diagrams**: 8 comprehensive flows  
**Coverage**: 100% of app functionality  
**Format**: Mermaid diagrams (interactive, zoom-able)

---

## 🗺️ Flow Diagram Catalog

### 01 - Complete User Journey Flow
**Purpose**: End-to-end user experience from first launch to ongoing usage  
**Complexity**: High  
**Audience**: Everyone - Product, Design, Development, QA

**What It Shows**:
- First launch onboarding (5 screens)
- Pet creation and dashboard
- Complete laundry cycle: wash → dry → fold
- Notification triggers and user returns
- Background persistence and recovery
- First cycle celebration
- Health updates and state changes

**Key Insights**:
- Users can complete cycle in ~90 minutes (30min wash + 60min dry)
- App works even when closed (timer persists)
- Notifications bring users back at right time
- First cycle gets special celebration

**Use This When**:
- Explaining app to stakeholders
- Planning user research
- Understanding complete flow
- Training customer support

---

### 02 - Timer State Machine Flow
**Purpose**: Detailed timer lifecycle and state transitions  
**Complexity**: Medium-High  
**Audience**: Developers, QA Engineers

**What It Shows**:
- Timer states: Idle → Washing → WashComplete → Drying → DryComplete → Folding → CycleComplete
- Internal timer operations (save, restore, validate)
- UserDefaults persistence mechanism
- Recovery from app close/crash
- Health decay concurrent process
- Pet death scenario

**Key Insights**:
- Timers use absolute time (endTime: Date), not countdown
- State saved to UserDefaults every update
- Recovery checks if timer already expired
- Health decays continuously in all states
- Dead state is permanent

**Use This When**:
- Implementing timer logic
- Debugging timer issues
- Testing background persistence
- Understanding state transitions

---

### 03 - Multi-Pet Independence Flow
**Purpose**: How multiple pets operate completely independently  
**Complexity**: Medium  
**Audience**: Developers, Architects, QA

**What It Shows**:
- Dashboard with 3 example pets (Fluffy, Buddy, Snowy)
- Separate ViewModel instances per pet
- Separate TimerService instances per pet
- Unique UserDefaults keys per pet
- Unique notification IDs per pet
- Separate database records
- Independence guarantees visualization

**Key Insights**:
- Each pet has its own PetViewModel when viewed
- Each PetViewModel creates its own PetTimerService
- Timer keys: `pet_timer_{petID}`
- Notification IDs: `timer_{petID}_{type}`
- Zero shared state between pets
- Can run unlimited simultaneous timers

**Use This When**:
- Understanding isolation architecture
- Implementing new pet
- Testing multi-pet scenarios
- Debugging interference issues (there should be none!)

---

### 04 - Notification Lifecycle Flow
**Purpose**: Complete notification system from scheduling to delivery  
**Complexity**: High  
**Audience**: Developers, QA

**What It Shows**:
- Permission request flow
- Budget management (64 notification limit)
- Priority-based scheduling
- Smart eviction when at limit
- Content creation and trigger setup
- Delivery scenarios (foreground/background)
- User response handling
- Cancellation scenarios
- Error scenarios (permission denied, delivery failures)

**Key Insights**:
- iOS limits: 64 pending notifications per app
- Budget manager tracks current count
- Low-priority notifications evicted when needed
- Notifications work even if permission denied later
- Multiple cancellation triggers (user action, completion, cleanup)

**Use This When**:
- Implementing notification logic
- Testing notification scenarios
- Debugging notification failures
- Understanding budget constraints

---

### 05 - Health Decay & State Transitions
**Purpose**: Pet health mechanics and emotional state changes  
**Complexity**: Medium  
**Audience**: Developers, Game Designers, QA

**What It Shows**:
- Health calculation formula
- State transitions: Happy → Neutral → Sad → Very Sad → Dead
- Health thresholds (100-75%, 75-50%, 50-25%, 25-0%, 0%)
- 30-second update cycle
- Cycle completion resets health to 100%
- Warning states at low health
- Death is permanent
- User-configurable decay rate (cycleFrequencyDays)

**Key Insights**:
- Health = 100 × (1 - daysSince / expectedDays)
- Default: 7 days until health reaches 0%
- Global timer updates all pets every 30 seconds
- Completing cycle restores health to 100%
- Pet can recover from "Very Sad" but not "Dead"

**Use This When**:
- Implementing health system
- Balancing game mechanics
- Testing decay rates
- Understanding emotional states

---

### 06 - Error Handling & Recovery Flow
**Purpose**: Comprehensive error management across all systems  
**Complexity**: Very High  
**Audience**: Developers, QA, Support

**What It Shows**:
- Database errors (save, fetch, delete failures)
- Timer errors (start, restore, persist failures)
- Notification errors (permission, scheduling, budget)
- Storage errors (disk space)
- Retry logic (up to 3 attempts)
- User recovery actions
- Error UI presentation
- Logging strategy

**Key Insights**:
- Database: do-catch with user feedback
- Timers: Detect corruption, auto-reset
- Notifications: Graceful degradation, continue without
- Storage: Proactive space checking
- No silent failures - always inform user
- Development: Verbose logs, Production: Minimal

**Use This When**:
- Implementing error handling
- Debugging crashes or failures
- Testing edge cases
- Writing error messages
- Planning error recovery

---

### 07 - Data Persistence & Migration Flow
**Purpose**: Database initialization, loading, and version migrations  
**Complexity**: Very High  
**Audience**: Senior Developers, Architects

**What It Shows**:
- App launch version detection
- Fresh install (V1 schema)
- Normal app start (load existing data)
- Major version migration (V1 → V2 example)
- Pre-migration backup process
- Data validation and repair
- Migration execution and verification
- Timer state restoration
- Notification state restoration
- Health system initialization
- Continuous persistence during usage
- Backup schedule (daily, pre-migration, manual)

**Key Insights**:
- SwiftData handles schema management
- Always backup before migration
- Validate data before and after migration
- Migration can be rolled back
- Timers restored from UserDefaults on launch
- Health system starts after data load
- Automatic saves during usage

**Use This When**:
- Planning schema changes
- Implementing migrations
- Testing upgrade scenarios
- Understanding app initialization
- Debugging launch issues

---

### 08 - Complete Architecture Layers
**Purpose**: High-level system architecture showing all components  
**Complexity**: High  
**Audience**: Developers, Architects, Technical Leads

**What It Shows**:
- 5 distinct layers: Presentation, ViewModel, Service, Data, System
- Component relationships and dependencies
- Data flow patterns
- Timer flow specifics
- Notification flow specifics
- Health decay flow specifics
- Independence guarantees
- Key architectural patterns
- Error handling strategy

**Key Insights**:
- Clean separation of concerns (MVVM + Services)
- ViewModels own TimerService instances
- SwiftData for persistence, UserDefaults for timer state
- Combine for reactive updates
- iOS frameworks at system layer
- No shared mutable state between pets

**Use This When**:
- Onboarding new developers
- Architecture reviews
- Planning new features
- Understanding system design
- Explaining technical approach

---

## 🎯 Quick Reference: Which Flow to Use

### For Understanding User Experience
→ **Flow 01**: Complete User Journey

### For Implementing Timers
→ **Flow 02**: Timer State Machine  
→ **Flow 03**: Multi-Pet Independence

### For Implementing Notifications
→ **Flow 04**: Notification Lifecycle

### For Implementing Health System
→ **Flow 05**: Health Decay & State Transitions

### For Error Handling
→ **Flow 06**: Error Handling & Recovery

### For Data/Database Work
→ **Flow 07**: Data Persistence & Migration

### For Architecture Overview
→ **Flow 08**: Complete Architecture Layers

---

## 📈 Flow Complexity Guide

**Low Complexity** (< 20 nodes):
- None - All flows are comprehensive!

**Medium Complexity** (20-40 nodes):
- Flow 03: Multi-Pet Independence
- Flow 05: Health Decay

**High Complexity** (40-80 nodes):
- Flow 01: Complete User Journey
- Flow 02: Timer State Machine
- Flow 04: Notification Lifecycle
- Flow 08: Complete Architecture

**Very High Complexity** (80+ nodes):
- Flow 06: Error Handling & Recovery
- Flow 07: Data Persistence & Migration

---

## 🎨 Visual Legend

### Color Coding

**Blue** (#3399FF): Primary actions, happy paths, user flows  
**Green** (#33CC66): Success states, completed operations  
**Orange** (#FF9933): Warning states, retry logic  
**Red** (#FF4D4D): Error states, failures, urgent situations  
**Purple** (#9966FF): Special events, celebrations, notifications  
**Yellow** (#FFCC33): In-progress states, timers running  
**Gray**: Inactive, dead, or disabled states

### Shape Meanings

**Rectangle**: Process or action  
**Diamond**: Decision point  
**Rounded Rectangle**: Start/end points  
**Cylinder**: Database/storage  
**Subgraph**: Grouped related processes

### Line Styles

**Solid arrow** (→): Primary flow  
**Dotted arrow** (-.→): Secondary flow, background process  
**Bold connection**: Critical path

---

## 💡 Tips for Reading Flows

### Start Points
Most flows begin with a clear start point (rounded rectangle) in blue

### Follow the Happy Path First
Follow solid arrows through success states (green) to understand normal operation

### Then Explore Edge Cases
Follow dotted arrows and orange/red paths to understand error handling

### Use Subgraphs for Context
Grouped sections (subgraphs) show related operations that happen together

### Read Top to Bottom, Left to Right
Flows generally progress downward and rightward

### Look for Decision Diamonds
Diamond shapes show where flow branches based on conditions

---

## 🔄 Flow Relationships

### Flows That Reference Each Other

**Flow 01** (User Journey) references:
- Flow 02 (Timer states)
- Flow 04 (Notifications)
- Flow 05 (Health decay)

**Flow 02** (Timer) references:
- Flow 03 (Multi-pet isolation)
- Flow 06 (Error handling)

**Flow 04** (Notifications) references:
- Flow 03 (Per-pet IDs)
- Flow 06 (Error handling)

**Flow 07** (Persistence) references:
- Flow 02 (Timer restoration)
- Flow 04 (Notification restoration)
- Flow 06 (Error handling)

---

## 📚 Related Documentation

Each flow corresponds to detailed written documentation:

- **Flow 01** → Doc 04: User Experience & User Flows, Doc 14: Onboarding
- **Flow 02** → Doc 05: Timer & Background System
- **Flow 03** → Doc 07: Multi-Pet Architecture
- **Flow 04** → Doc 06: Notification System, Doc 16: Notification Limits
- **Flow 05** → Doc 08: Health & Statistics System
- **Flow 06** → Doc 13: Error Handling & Recovery
- **Flow 07** → Doc 15: Data Migration Strategy
- **Flow 08** → Doc 01: System Architecture Overview

---

## ✅ Using These Flows

### For Development
1. Review relevant flow before implementing feature
2. Use flow as checklist during development
3. Test all paths shown in flow
4. Update flow if behavior changes

### For Testing
1. Use flow to generate test cases
2. Ensure every path is tested
3. Focus on error paths (red/orange)
4. Test edge cases shown in flows

### For Documentation
1. Reference flows in code comments
2. Link to flows in PRs
3. Use flows in design docs
4. Include in onboarding materials

### For Troubleshooting
1. Find relevant flow
2. Trace user's path through flow
3. Identify where actual behavior differs
4. Check error handling paths

---

## 🎓 Learning Path

**Week 1: Understanding**
- Day 1: Flow 08 (Architecture overview)
- Day 2: Flow 01 (User journey)
- Day 3: Flow 03 (Multi-pet independence)

**Week 2: Core Systems**
- Day 1: Flow 02 (Timer system)
- Day 2: Flow 04 (Notifications)
- Day 3: Flow 05 (Health decay)

**Week 3: Advanced Topics**
- Day 1: Flow 06 (Error handling)
- Day 2: Flow 07 (Data persistence)
- Day 3: Review all flows

---

## 🚀 Next Steps

1. **Review Architecture**: Start with Flow 08 for big picture
2. **Understand User Journey**: Read Flow 01 to see user perspective
3. **Deep Dive**: Pick flows relevant to your work
4. **Reference During Development**: Keep flows open while coding
5. **Update as Needed**: Flows should evolve with app

---

## 📊 Flow Statistics

**Total Nodes**: ~500 across all flows  
**Total Connections**: ~700 arrows  
**Total Subgraphs**: ~40 grouped sections  
**Coverage**: 100% of app functionality  
**Accuracy**: Matches implementation specs exactly  

---

**These visual flows complement the 16 written documents to provide complete, multi-format documentation covering every aspect of LaundryTime.** 📊✨

**Last Updated**: October 2025  
**Version**: 2.0  
**Status**: Complete ✅