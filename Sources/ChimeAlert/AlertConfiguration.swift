//
//  AlertConfiguration.swift
//  ChimeAlert
//
//  Configuration options for customizing alert appearance and behavior.
//

import SwiftUI

/// Configuration for customizing ChimeAlert's appearance, animations, and behavior.
///
/// Modify the `AlertManager.shared.configuration` property to customize alerts:
/// ```swift
/// AlertManager.shared.configuration.soundVolume = 0.9
/// AlertManager.shared.configuration.pulseDuration = 1.5
/// AlertManager.shared.configuration.maxSnoozeAttempts = 5
/// ```
public struct AlertConfiguration {
    // MARK: - Animation Settings

    /// Duration of the pulsating border animation (in seconds)
    public var pulseDuration: Double = 1.2

    /// Duration of the background glow animation (in seconds)
    public var glowDuration: Double = 2.5

    /// Duration of entrance animations for alert elements (in seconds)
    public var entranceAnimationDuration: Double = 0.3

    // MARK: - Visual Settings

    /// Colors for the pulsating border (ADHD-friendly attention grabber)
    public var borderColors: [Color] = [Color(red: 0.988, green: 0.475, blue: 0.475)]

    /// Opacity range for the pulsating border (min, max)
    public var borderOpacity: (min: Double, max: Double) = (0.5, 0.9)

    /// Width range for the pulsating border (min, max)
    public var borderWidth: (min: CGFloat, max: CGFloat) = (4, 8)

    /// Blur radius range for the border effect (min, max)
    public var blurRadius: (min: CGFloat, max: CGFloat) = (10, 20)

    /// Blur radius for the background gradient glow
    public var gradientBlur: CGFloat = 100

    // MARK: - Type-Specific Gradients

    /// Gradient colors for meeting alerts (blue theme)
    public var meetingGradient: [Color] = [
        Color(red: 0.529, green: 0.655, blue: 1.0),
        Color(red: 0.4, green: 0.5, blue: 0.9)
    ]

    /// Gradient colors for reminder alerts (purple theme)
    public var reminderGradient: [Color] = [
        Color(red: 0.75, green: 0.35, blue: 0.95),
        Color(red: 0.45, green: 0.15, blue: 0.65)
    ]

    /// Gradient colors for task alerts (red theme, Todoist-inspired)
    public var taskGradient: [Color] = [
        Color(red: 0.89, green: 0.27, blue: 0.2),
        Color(red: 0.7, green: 0.15, blue: 0.1)
    ]

    /// Gradient colors for conflict/combined alerts (orange theme)
    public var conflictGradient: [Color] = [
        Color(red: 1.0, green: 0.6, blue: 0.2),
        Color(red: 0.9, green: 0.4, blue: 0.1)
    ]

    // MARK: - Snooze Settings

    /// Available snooze durations (in seconds). Presented as menu options.
    public var snoozeOptions: [TimeInterval] = [60, 120, 300, 600] // 1, 2, 5, 10 min

    /// Default snooze duration when user clicks "Snooze" button without opening menu
    public var defaultSnoozeInterval: TimeInterval = 120 // 2 minutes

    /// Maximum number of times a user can snooze an alert before it's auto-dismissed
    public var maxSnoozeAttempts: Int = 3

    // MARK: - Sound Settings

    /// Whether alert sounds are enabled
    public var soundEnabled: Bool = true

    /// Volume for alert sounds (0.0 to 1.0)
    public var soundVolume: Float = 0.8

    /// Whether to rotate through different sounds (prevents habituation, ADHD-friendly)
    public var rotateSounds: Bool = true

    // MARK: - Monitor Preference

    /// Which monitor(s) to display alerts on
    public var monitorPreference: MonitorPreference = .allMonitors

    // MARK: - Optional Features

    /// Optional trial badge to display (e.g., "7d trial left")
    public var trialBadge: TrialBadgeInfo? = nil

    /// Public initializer with default values
    public init() {}
}

/// Optional trial badge configuration
public struct TrialBadgeInfo {
    /// Text to display in the badge (e.g., "7d trial left")
    public let text: String

    /// Badge background color
    public let color: Color

    public init(text: String, color: Color = Color(red: 1.0, green: 0.6, blue: 0.2)) {
        self.text = text
        self.color = color
    }
}

/// Helper to format snooze durations as human-readable strings
public extension AlertConfiguration {
    /// Formats a snooze interval as a readable string
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Formatted string (e.g., "2 min", "1 hour")
    static func formatSnoozeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}
