//
//  MonitorPreference.swift
//  ChimeAlert
//
//  Enum defining which monitor(s) should display alerts.
//

import Foundation

/// Defines which monitor(s) alerts should appear on in multi-monitor setups.
public enum MonitorPreference: String, CaseIterable, Sendable {
    /// Show alerts on all connected monitors simultaneously
    case allMonitors = "all"

    /// Show alert only on the primary/main monitor
    case primaryOnly = "primary"

    /// Show alert only on external (non-primary) monitors
    case externalOnly = "external"

    /// Show alert on whichever monitor the mouse cursor is currently on
    case mouseLocation = "mouse"

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .allMonitors: return "All Monitors"
        case .primaryOnly: return "Primary Monitor Only"
        case .externalOnly: return "External Monitors Only"
        case .mouseLocation: return "Where Mouse Is Located"
        }
    }
}
