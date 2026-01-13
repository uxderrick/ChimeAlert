# Testing ChimeAlert as a 3rd Party Library

This guide shows you how to test and integrate ChimeAlert into your own projects.

## Quick Test - Included Test App

A ready-to-run test app is included at `/Users/uxderrick-mac/Development/ChimeAlertTestApp/`.

### Run the Test App

```bash
cd /Users/uxderrick-mac/Development/ChimeAlertTestApp
swift run
```

**What happens:**
1. App launches and prints configuration
2. 5-second countdown
3. Full-screen alert appears with pulsating red border
4. Test meeting: "Q4 Planning Meeting"
5. Attribution badge: "Powered by Chime" in bottom-right (clickable, opens usechime.app)
6. Keyboard shortcuts work (⌘S snooze, ⌘↩ join, Esc dismiss)

### Verify Package Integrity

```bash
cd /Users/uxderrick-mac/Development/ChimeAlertTestApp
swift test-api.swift
```

This checks that all ChimeAlert files and resources are present.

## Integration Steps for Your App

### 1. Add ChimeAlert as a Dependency

#### Local Development (Before Publishing)

In your `Package.swift`:

```swift
dependencies: [
    .package(path: "/Users/uxderrick-mac/Development/ChimeAlert")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ChimeAlert"]
    )
]
```

#### After Publishing to GitHub

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/ChimeAlert.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ChimeAlert"]
    )
]
```

### 2. Import ChimeAlert

```swift
import ChimeAlert
import SwiftUI
```

### 3. Make Your Model Conform to AlertItem

```swift
extension YourMeeting: AlertItem {
    var id: String { self.meetingID }
    var title: String { self.meetingTitle }
    var startTime: Date { self.startDate }
    var endTime: Date { self.endDate }
    var notes: String? { self.meetingNotes }
    var actionURL: URL? { self.zoomLink }
    var actionButtonTitle: String? {
        actionURL != nil ? "Join" : nil
    }
    var attendees: [AlertAttendee]? {
        self.participants.map {
            AlertAttendee(name: $0.name, isOrganizer: $0.isHost)
        }
    }
    var isRecurring: Bool { self.recurrence != nil }
    var recurrenceDescription: String? { self.recurrence }
    var priority: AlertPriority { .high }
    var type: AlertType { .meeting }
}
```

### 4. Implement AlertDelegate (Optional)

```swift
@MainActor
class MyAlertDelegate: AlertDelegate {
    func alertDidShow(_ item: AlertItem) {
        // Track analytics
        Analytics.track("alert_shown", properties: [
            "title": item.title
        ])
    }

    func alertDidTapAction(_ item: AlertItem) {
        // Handle Join/Complete action
        if let url = item.actionURL {
            NSWorkspace.shared.open(url)
        }
    }

    func alertDidSnooze(_ item: AlertItem, duration: TimeInterval) {
        // Track snooze
        Analytics.track("alert_snoozed", properties: [
            "duration_minutes": Int(duration / 60)
        ])
    }

    func alertShouldTrackStats() -> Bool {
        return true
    }

    func alertDidTrackStat(event: String, properties: [String: Any]) {
        // Forward to your analytics system
        Analytics.track(event, properties: properties)
    }

    func alertShouldShow(_ item: AlertItem) async -> Bool {
        // Optional: Validate item is still valid
        // (e.g., check if task still exists in API)
        return true
    }
}
```

### 5. Configure and Show Alerts

```swift
@MainActor
class YourAppDelegate: NSApplicationDelegate {
    let alertDelegate = MyAlertDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure AlertManager
        AlertManager.shared.delegate = alertDelegate
        AlertManager.shared.configuration.soundVolume = 0.9
        AlertManager.shared.configuration.maxSnoozeAttempts = 5
        AlertManager.shared.monitorPreference = .allMonitors

        // Show an alert
        let meeting = YourMeeting(...)
        AlertManager.shared.showAlert(for: meeting)
    }
}
```

## Customization Examples

### Change Alert Appearance

```swift
// Custom border colors (ADHD-friendly pulsating)
AlertManager.shared.configuration.borderColors = [.orange, .red]

// Custom gradients for each type
AlertManager.shared.configuration.meetingGradient = [
    Color(red: 0.2, green: 0.4, blue: 0.8),
    Color(red: 0.1, green: 0.2, blue: 0.6)
]

AlertManager.shared.configuration.reminderGradient = [
    Color(red: 0.75, green: 0.35, blue: 0.95),
    Color(red: 0.45, green: 0.15, blue: 0.65)
]

AlertManager.shared.configuration.taskGradient = [
    Color(red: 0.89, green: 0.27, blue: 0.2),
    Color(red: 0.7, green: 0.15, blue: 0.1)
]
```

### Adjust Animation Timings

```swift
// Slower pulse (less intense)
AlertManager.shared.configuration.pulseDuration = 2.0

// Faster entrance
AlertManager.shared.configuration.entranceAnimationDuration = 0.2

// Slower glow
AlertManager.shared.configuration.glowDuration = 4.0
```

### Configure Snooze Behavior

```swift
// Custom snooze options (in seconds)
AlertManager.shared.configuration.snoozeOptions = [
    60,    // 1 minute
    300,   // 5 minutes
    600,   // 10 minutes
    1800   // 30 minutes
]

// Default snooze duration
AlertManager.shared.configuration.defaultSnoozeInterval = 300 // 5 minutes

// Max snooze attempts before blocking snooze button
AlertManager.shared.configuration.maxSnoozeAttempts = 10
```

### Sound Settings

```swift
// Disable sound completely
AlertManager.shared.configuration.soundEnabled = false

// Adjust volume (0.0 to 1.0)
AlertManager.shared.configuration.soundVolume = 0.5

// Disable sound rotation (use first sound only)
AlertManager.shared.configuration.rotateSounds = false
```

### Monitor Preference

```swift
// Show on all monitors (default)
AlertManager.shared.monitorPreference = .allMonitors

// Show on primary monitor only
AlertManager.shared.monitorPreference = .primaryOnly

// Show on external monitors only (good for presentations)
AlertManager.shared.monitorPreference = .externalOnly

// Show on monitor where mouse cursor is located
AlertManager.shared.monitorPreference = .mouseLocation
```

### Trial Badge (Optional)

```swift
// Show trial countdown badge
AlertManager.shared.configuration.trialBadge = TrialBadgeInfo(
    text: "7d trial left",
    color: Color.orange
)

// Remove trial badge
AlertManager.shared.configuration.trialBadge = nil
```

## Testing Different Alert Types

### Meeting Alert (Blue Gradient)

```swift
struct Meeting: AlertItem {
    // ... required properties ...
    var type: AlertType { .meeting }
}
```

**Features:**
- Blue/green gradient
- Green "Join" button (if actionURL present)
- Shows attendees list
- Duration display

### Reminder Alert (Purple Gradient)

```swift
struct Reminder: AlertItem {
    // ... required properties ...
    var type: AlertType { .reminder }
}
```

**Features:**
- Purple gradient
- Green "Complete" button (checkmark icon)
- No attendees section
- "DUE" label instead of "MEETING STARTS IN"

### Task Alert (Red Gradient)

```swift
struct Task: AlertItem {
    // ... required properties ...
    var type: AlertType { .task }
}
```

**Features:**
- Red gradient (Todoist-inspired)
- Green "Complete" button
- No attendees section
- "DUE" label

### Custom Alert (Custom Colors)

```swift
struct CustomAlert: AlertItem {
    // ... required properties ...
    var type: AlertType {
        .custom(
            gradient: [
                ColorComponents(red: 1.0, green: 0.5, blue: 0.0),
                ColorComponents(red: 0.8, green: 0.3, blue: 0.0)
            ],
            iconName: "flame.fill"
        )
    }
}
```

**Features:**
- Fully custom gradient colors
- Custom SF Symbol icon
- All other features same as reminder/task

## Test Scenarios to Verify

### Basic Functionality
- ✅ Alert appears full-screen
- ✅ Pulsating red border visible
- ✅ Sound plays (if enabled)
- ✅ Countdown timer updates every second
- ✅ Attribution badge visible in bottom-right
- ✅ Attribution badge is clickable and opens usechime.app
- ✅ Attribution badge highlights on hover

### Keyboard Shortcuts
- ✅ **⌘S** - Snooze alert
- ✅ **⌘↩** - Trigger action (Join/Complete)
- ✅ **Esc** - Dismiss alert

### Multi-Monitor
- ✅ Alert appears on all monitors (if `.allMonitors`)
- ✅ Alert appears on primary only (if `.primaryOnly`)
- ✅ Alert appears on external only (if `.externalOnly`)
- ✅ Alert follows mouse cursor (if `.mouseLocation`)

### Snooze Behavior
- ✅ Alert re-appears after snooze duration
- ✅ Snooze count increments
- ✅ Snooze button disabled after max attempts
- ✅ Warning message shown at snooze limit

### Delegate Callbacks
- ✅ `alertWillShow()` called before display
- ✅ `alertDidShow()` called after display
- ✅ `alertDidDismiss()` called with correct reason
- ✅ `alertDidTapAction()` called on Join/Complete
- ✅ `alertDidSnooze()` called with duration
- ✅ `alertDidTrackStat()` called (if stats enabled)

### Sleep/Wake Recovery
- ✅ Alerts blocked during system recovery (first 5-10 seconds after wake)
- ✅ Timer-based alerts rescheduled correctly

## Troubleshooting

### Alert Doesn't Appear

**Check:**
1. Is `startTime` in the future (or very recent past)?
2. Is `NSApplication.shared` initialized?
3. Check console for `isSystemRecovering` flag
4. Verify no errors in console

**Fix:**
```swift
// Ensure NSApp is initialized
let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Then show alert
AlertManager.shared.showAlert(for: item)
```

### Sound Doesn't Play

**Check:**
1. Is sound enabled? `configuration.soundEnabled`
2. Is volume above 0? `configuration.soundVolume`
3. Is system volume muted?
4. Check console for AVAudioPlayer errors

**Fix:**
```swift
AlertManager.shared.configuration.soundEnabled = true
AlertManager.shared.configuration.soundVolume = 0.8
```

### Keyboard Shortcuts Don't Work

**Check:**
1. Is alert window frontmost?
2. Click on alert to ensure focus
3. Check if another app is intercepting shortcuts

**Fix:**
- Click directly on the alert window
- Make sure no other modal windows are open

### Attribution Badge Not Visible or Clickable

**Check:**
1. Badge should always be visible (non-removable)
2. Check bottom-right corner
3. May be hidden by macOS Dock - try hiding Dock
4. Hover over badge - should brighten slightly
5. Click badge - should open usechime.app in browser

**Note:** The attribution badge is a **required** component and cannot be removed. This is intentional for the open-source license. The badge links to [usechime.app](https://usechime.app) when clicked.

## Next Steps

1. **Test the included app** - Run `/Users/uxderrick-mac/Development/ChimeAlertTestApp`
2. **Read the README** - Comprehensive docs in `/Users/uxderrick-mac/Development/ChimeAlert/README.md`
3. **Integrate into your app** - Follow steps above
4. **Customize appearance** - Match your app's design
5. **Implement delegate** - Add analytics/logging
6. **Test thoroughly** - Verify all scenarios above

## Support

For issues, questions, or feature requests:
- GitHub Issues: https://github.com/YOUR_USERNAME/ChimeAlert/issues
- Documentation: https://github.com/YOUR_USERNAME/ChimeAlert#readme

## License

ChimeAlert is released under the MIT License. See [LICENSE](LICENSE) for details.

**Attribution requirement:** The "Powered by Chime" badge must remain visible in all alerts and link to [usechime.app](https://usechime.app). This is a non-negotiable requirement for using the open-source version.
