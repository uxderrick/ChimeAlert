# ChimeAlert

A full-screen alert system for macOS with multi-monitor support, keyboard shortcuts, and extensive customization options.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Full-screen alerts** with animated pulsating border
- **Multi-monitor support** (all monitors, primary only, external only, or mouse location)
- **Sleep/wake recovery** handling to prevent UI freezing
- **Keyboard shortcuts** (⌘S snooze, ⌘↩ action, Esc dismiss)
- **Sound playback** with 5 bundled sounds and rotation support
- **Highly customizable** (colors, animations, timings, sounds)
- **Snooze management** with configurable limits
- **Delegate pattern** for analytics and custom behavior
- **Multiple alert types** (meetings, reminders, tasks, custom)

## Installation

### Swift Package Manager

Add ChimeAlert to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/uxderrick/ChimeAlert.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter repository URL: `https://github.com/uxderrick/ChimeAlert.git`
3. Select version and add to target

## Quick Start

### 1. Conform Your Model to AlertItem

```swift
import ChimeAlert
import Foundation

struct MyMeeting: AlertItem {
    var id: String
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String?
    var actionURL: URL?  // Optional action URL (e.g., Zoom link)
    var actionButtonTitle: String? { actionURL != nil ? "Join" : nil }
    var attendees: [AlertAttendee]?
    var isRecurring: Bool
    var recurrenceDescription: String?
    var priority: AlertPriority { .high }
    var type: AlertType { .meeting }
}
```

### 2. Configure AlertManager

```swift
import ChimeAlert

// Configure global settings
AlertManager.shared.configuration.soundVolume = 0.9
AlertManager.shared.configuration.maxSnoozeAttempts = 5
AlertManager.shared.monitorPreference = .allMonitors
```

### 3. Show an Alert

```swift
let meeting = MyMeeting(
    id: "meeting-123",
    title: "Q4 Planning Meeting",
    startTime: Date().addingTimeInterval(300), // 5 minutes from now
    endTime: Date().addingTimeInterval(3900),  // 1 hour later
    notes: "Discuss roadmap and budget",
    actionURL: URL(string: "https://zoom.us/j/123456789"),
    attendees: [
        AlertAttendee(name: "Alice Chen", isOrganizer: true),
        AlertAttendee(name: "Bob Smith")
    ],
    isRecurring: false,
    recurrenceDescription: nil
)

AlertManager.shared.showAlert(for: meeting)
```

## Configuration

### Visual Customization

```swift
// Pulsating border
AlertManager.shared.configuration.borderColors = [.red, .orange]
AlertManager.shared.configuration.pulseDuration = 1.5

// Type-specific gradients
AlertManager.shared.configuration.meetingGradient = [
    Color(red: 0.2, green: 0.4, blue: 0.8),
    Color(red: 0.1, green: 0.2, blue: 0.6)
]

// Animation speeds
AlertManager.shared.configuration.glowDuration = 3.0
AlertManager.shared.configuration.entranceAnimationDuration = 0.5
```

### Sound Configuration

```swift
// Enable/disable sound
AlertManager.shared.configuration.soundEnabled = false

// Volume (0.0 to 1.0)
AlertManager.shared.configuration.soundVolume = 0.5

// Sound rotation
AlertManager.shared.configuration.rotateSounds = false
```

### Snooze Behavior

```swift
// Default snooze duration (seconds)
AlertManager.shared.configuration.defaultSnoozeInterval = 300 // 5 minutes

// Available snooze options
AlertManager.shared.configuration.snoozeOptions = [60, 300, 600, 1800]

// Maximum snooze attempts before disabling snooze button
AlertManager.shared.configuration.maxSnoozeAttempts = 5
```

### Multi-Monitor Configuration

```swift
// Show on all monitors
AlertManager.shared.monitorPreference = .allMonitors

// Show on primary monitor only
AlertManager.shared.monitorPreference = .primaryOnly

// Show on external monitors only
AlertManager.shared.monitorPreference = .externalOnly

// Show on monitor where mouse cursor is located
AlertManager.shared.monitorPreference = .mouseLocation
```

## Delegate Integration

Implement `AlertDelegate` to handle lifecycle events, track analytics, and customize behavior:

```swift
@MainActor
class MyAlertDelegate: AlertDelegate {
    func alertDidShow(_ item: AlertItem) {
        // Track alert display
        Analytics.track("alert_shown", properties: ["title": item.title])
    }

    func alertDidTapAction(_ item: AlertItem) {
        // Handle action button tap (Join/Complete/Open)
        if let url = item.actionURL {
            NSWorkspace.shared.open(url)
        }
    }

    func alertDidSnooze(_ item: AlertItem, duration: TimeInterval) {
        // Track snooze action
        Analytics.track("alert_snoozed", properties: ["duration": duration])
    }

    func alertShouldTrackStats() -> Bool {
        return true // Enable internal stat tracking
    }

    func alertDidTrackStat(event: String, properties: [String: Any]) {
        // Forward to your analytics system
        Analytics.track(event, properties: properties)
    }

    func alertShouldShow(_ item: AlertItem) async -> Bool {
        // Optional: Validate if alert should still be shown
        // Useful for checking external state (e.g., task deleted)
        return true
    }
}

// Set the delegate
AlertManager.shared.delegate = MyAlertDelegate()
```

## Alert Types

ChimeAlert supports multiple alert types with different visual styling:

### Meeting (Blue Gradient)
```swift
struct Meeting: AlertItem {
    var type: AlertType { .meeting }
    // Blue/green gradient, "Join" button, shows attendees
}
```

### Reminder (Purple Gradient)
```swift
struct Reminder: AlertItem {
    var type: AlertType { .reminder }
    // Purple gradient, "Complete" button
}
```

### Task (Red Gradient)
```swift
struct Task: AlertItem {
    var type: AlertType { .task }
    // Red gradient, "Complete" button
}
```

### Custom
```swift
struct CustomAlert: AlertItem {
    var type: AlertType {
        .custom(
            gradient: [
                ColorComponents(red: 1.0, green: 0.5, blue: 0.0),
                ColorComponents(red: 0.8, green: 0.3, blue: 0.0)
            ],
            iconName: "star.fill"
        )
    }
}
```

## Advanced Features

### Trial Badge (Optional)

Display a countdown badge for trial periods:

```swift
AlertManager.shared.configuration.trialBadge = TrialBadgeInfo(
    text: "7d trial left",
    color: Color.orange
)

// Remove badge
AlertManager.shared.configuration.trialBadge = nil
```

### Sleep/Wake Recovery

ChimeAlert automatically handles system sleep/wake transitions. To integrate with your app's sleep monitoring:

```swift
func setupSleepWakeNotifications() {
    NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.willSleepNotification,
        object: nil,
        queue: .main
    ) { _ in
        AlertManager.isSystemRecovering = true
    }

    NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification,
        object: nil,
        queue: .main
    ) { _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            AlertManager.isSystemRecovering = false
        }
    }
}
```

## Attribution

This library includes a non-removable "Powered by Chime" badge in the bottom-right corner of all alerts. The badge links to [usechime.app](https://usechime.app) when clicked. This is a requirement for using the open-source version.

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later
- Xcode 15.0 or later (for development)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure `swift test` passes
5. Submit a pull request

## License

ChimeAlert is released under the MIT License. See [LICENSE](LICENSE) for details.

## Credits

Extracted from [Chime](https://github.com/uxderrick/chime) - a meeting reminder app for macOS.

---

**Questions or feedback?** Open an issue on [GitHub](https://github.com/uxderrick/ChimeAlert/issues).
