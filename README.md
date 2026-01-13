# ChimeAlert

**An ADHD-friendly, impossible-to-miss full-screen alert system for macOS**

ChimeAlert provides pulsating red-bordered alerts with multi-monitor support, sound rotation, and keyboard shortcuts - perfect for time-sensitive notifications, meetings, reminders, and tasks.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

✅ **Full-screen alerts** with pulsating red border (prevents habituation)
✅ **Multi-monitor support** (all, primary, external, or mouse location)
✅ **Sleep/wake recovery** (prevents UI freezing after system sleep)
✅ **Keyboard shortcuts** (⌘S snooze, ⌘↩ action, Esc dismiss)
✅ **5 ADHD-friendly sounds** with automatic rotation
✅ **Highly customizable** (colors, animations, timings, sounds)
✅ **Snooze limits** (default 3x, configurable)
✅ **Unified handling** for meetings, reminders, tasks
✅ **Delegate pattern** for analytics and custom behavior

## Installation

### Swift Package Manager

Add ChimeAlert to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/ChimeAlert.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter repository URL: `https://github.com/YOUR_USERNAME/ChimeAlert.git`
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
    var actionURL: URL?  // Zoom/Teams/Meet link
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

// Set global configuration
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

## Customization

### Colors & Animations

```swift
// Customize pulsating border
AlertManager.shared.configuration.borderColors = [.red, .orange]
AlertManager.shared.configuration.pulseDuration = 1.5

// Customize type-specific gradients
AlertManager.shared.configuration.meetingGradient = [
    Color(red: 0.2, green: 0.4, blue: 0.8),
    Color(red: 0.1, green: 0.2, blue: 0.6)
]

// Adjust animation speeds
AlertManager.shared.configuration.glowDuration = 3.0
AlertManager.shared.configuration.entranceAnimationDuration = 0.5
```

### Sound Settings

```swift
// Disable sound
AlertManager.shared.configuration.soundEnabled = false

// Adjust volume (0.0 to 1.0)
AlertManager.shared.configuration.soundVolume = 0.5

// Disable sound rotation (use first sound only)
AlertManager.shared.configuration.rotateSounds = false
```

### Snooze Behavior

```swift
// Change default snooze duration (in seconds)
AlertManager.shared.configuration.defaultSnoozeInterval = 300 // 5 minutes

// Customize available snooze options
AlertManager.shared.configuration.snoozeOptions = [60, 300, 600, 1800] // 1min, 5min, 10min, 30min

// Adjust max snooze attempts
AlertManager.shared.configuration.maxSnoozeAttempts = 5
```

### Multi-Monitor Display

```swift
// Show on all monitors
AlertManager.shared.monitorPreference = .allMonitors

// Show on primary monitor only
AlertManager.shared.monitorPreference = .primaryOnly

// Show on external monitors only (useful for presentations)
AlertManager.shared.monitorPreference = .externalOnly

// Show on whichever monitor has the mouse cursor
AlertManager.shared.monitorPreference = .mouseLocation
```

## Delegate Integration

Implement `AlertDelegate` to track analytics, handle actions, and customize behavior:

```swift
class MyAlertDelegate: AlertDelegate {
    func alertDidShow(_ item: AlertItem) {
        print("Alert shown for: \(item.title)")
        // Track to your analytics system
    }

    func alertDidTapAction(_ item: AlertItem) {
        // Handle Join/Complete/Open action
        if let url = item.actionURL {
            NSWorkspace.shared.open(url)
        }
    }

    func alertDidSnooze(_ item: AlertItem, duration: TimeInterval) {
        print("Alert snoozed for \(Int(duration / 60)) minutes")
    }

    func alertShouldTrackStats() -> Bool {
        return true // Enable stats tracking
    }

    func alertDidTrackStat(event: String, properties: [String: Any]) {
        // Forward to your analytics system (PostHog, Mixpanel, etc.)
        print("📊 Event: \(event), Properties: \(properties)")
    }

    func alertShouldShow(_ item: AlertItem) async -> Bool {
        // Optional: Validate alert should still be shown
        // Useful for checking external state (e.g., task still pending in API)
        return true
    }
}

// Set the delegate
AlertManager.shared.delegate = MyAlertDelegate()
```

## Alert Types

ChimeAlert supports multiple alert types with different visual styling:

### Meeting Alerts (Blue Gradient)
```swift
struct Meeting: AlertItem {
    var type: AlertType { .meeting }
    // Blue/green gradient, "Join" button, attendees list
}
```

### Reminder Alerts (Purple Gradient)
```swift
struct Reminder: AlertItem {
    var type: AlertType { .reminder }
    // Purple gradient, "Complete" button, no attendees
}
```

### Task Alerts (Red Gradient)
```swift
struct Task: AlertItem {
    var type: AlertType { .task }
    // Red gradient (Todoist-inspired), "Complete" button
}
```

### Custom Alerts
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

## Trial Badge (Optional)

Display a trial countdown badge (e.g., "7d trial left"):

```swift
AlertManager.shared.configuration.trialBadge = TrialBadgeInfo(
    text: "7d trial left",
    color: Color.orange
)

// Remove trial badge
AlertManager.shared.configuration.trialBadge = nil
```

## Advanced: Sleep/Wake Recovery

ChimeAlert automatically handles system sleep/wake transitions. To integrate with your app's sleep monitoring:

```swift
import Foundation

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
        // Give system 5 seconds to recover
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            AlertManager.isSystemRecovering = false
        }
    }
}
```

## Attribution

**This library includes a non-removable "Powered by Chime" badge** in the bottom-right corner of all alerts. This is a requirement for using the open-source version.

The badge is subtle, non-intrusive, and respects the ADHD-friendly design philosophy of the library. When clicked, it opens [usechime.app](https://usechime.app) in the user's browser.

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later
- Xcode 15.0 or later (for development)

## Example Projects

See the `Examples/` directory for sample implementations:
- **BasicAlert** - Simple alert demonstration
- **CustomStyling** - Advanced customization
- **DelegateIntegration** - Analytics and action handling

## Roadmap

- [ ] Combined alerts for conflicting items (multiple meetings at same time)
- [ ] More sound options
- [ ] Accessibility improvements (VoiceOver, reduced motion)
- [ ] Custom fonts support
- [ ] Animation presets (subtle, standard, intense)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure `swift test` passes
5. Submit a pull request

## License

ChimeAlert is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

Extracted from [Chime](https://github.com/YOUR_USERNAME/chime) - an ADHD-friendly meeting reminder app for macOS.

Built with ❤️ for the ADHD community.

---

**Have questions or feedback?** Open an issue on [GitHub](https://github.com/YOUR_USERNAME/ChimeAlert/issues).
