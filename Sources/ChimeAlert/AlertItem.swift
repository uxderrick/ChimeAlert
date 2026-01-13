//
//  AlertItem.swift
//  ChimeAlert
//
//  Protocol defining the data structure for displayable alerts.
//

import Foundation

/// Protocol that defines the structure of an alert item that can be displayed by ChimeAlert.
///
/// Conform your data models to this protocol to show full-screen alerts for meetings,
/// reminders, tasks, or any time-sensitive event.
public protocol AlertItem {
    /// Unique identifier for this alert
    var id: String { get }

    /// Title displayed prominently in the alert
    var title: String { get }

    /// When the event starts/is due
    var startTime: Date { get }

    /// When the event ends (used for duration calculation)
    var endTime: Date { get }

    /// Optional notes or description
    var notes: String? { get }

    /// Optional URL for primary action (e.g., Zoom link, task URL)
    var actionURL: URL? { get }

    /// Label for the primary action button (e.g., "Join", "Complete", "Open")
    var actionButtonTitle: String? { get }

    /// List of attendees (for meetings/events with participants)
    var attendees: [AlertAttendee]? { get }

    /// Whether this is a recurring event
    var isRecurring: Bool { get }

    /// Human-readable recurrence description (e.g., "Repeats Daily")
    var recurrenceDescription: String? { get }

    /// Priority level affects alert timing and styling
    var priority: AlertPriority { get }

    /// Type of alert (determines visual styling and behavior)
    var type: AlertType { get }
}

/// Represents an attendee/participant in an alert item
public struct AlertAttendee {
    /// Full name of the attendee
    public let name: String

    /// Whether this person is the organizer/host
    public let isOrganizer: Bool

    public init(name: String, isOrganizer: Bool = false) {
        self.name = name
        self.isOrganizer = isOrganizer
    }
}

/// Priority level for alerts (affects timing and visual emphasis)
public enum AlertPriority {
    /// Low priority - less urgent
    case low

    /// Normal priority - standard alerts
    case normal

    /// High priority - urgent/important alerts
    case high
}

/// Type of alert (determines visual styling, colors, and behavior)
public enum AlertType: Equatable {
    /// Meeting/event with potential attendees
    case meeting

    /// Personal reminder or to-do item
    case reminder

    /// Task from task management system
    case task

    /// Custom alert type with specific colors and icon
    case custom(gradient: [ColorComponents], iconName: String)

    public static func == (lhs: AlertType, rhs: AlertType) -> Bool {
        switch (lhs, rhs) {
        case (.meeting, .meeting), (.reminder, .reminder), (.task, .task):
            return true
        case (.custom(let g1, let i1), .custom(let g2, let i2)):
            return i1 == i2 && g1.count == g2.count // Simple comparison
        default:
            return false
        }
    }
}

/// RGB color components for custom alert types (avoids SwiftUI.Color dependency in protocol)
public struct ColorComponents {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

// MARK: - Default Implementations

public extension AlertItem {
    /// Default: no attendees
    var attendees: [AlertAttendee]? { nil }

    /// Default: not recurring
    var isRecurring: Bool { false }

    /// Default: no recurrence description
    var recurrenceDescription: String? { nil }

    /// Default: normal priority
    var priority: AlertPriority { .normal }

    /// Default: meeting type
    var type: AlertType { .meeting }
}
