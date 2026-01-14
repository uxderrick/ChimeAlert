//
//  AlertDelegate.swift
//  ChimeAlert
//
//  Protocol for handling alert lifecycle events and actions.
//

import Foundation

/// Delegate protocol for handling alert lifecycle events, user actions, and custom behavior.
///
/// Implement this protocol to track analytics, handle user actions, and integrate with your app's logic.
@MainActor
public protocol AlertDelegate: AnyObject {
    // MARK: - Lifecycle Events

    /// Called just before an alert is displayed
    /// - Parameter item: The alert item that will be shown
    func alertWillShow(_ item: AlertItem)

    /// Called after an alert has been successfully displayed
    /// - Parameter item: The alert item that was shown
    func alertDidShow(_ item: AlertItem)

    /// Called when an alert is dismissed
    /// - Parameters:
    ///   - item: The alert item that was dismissed
    ///   - reason: Why the alert was dismissed
    func alertDidDismiss(_ item: AlertItem, reason: DismissalReason)

    // MARK: - User Actions

    /// Called when the user taps the primary action button (Join, Complete, Open, etc.)
    /// - Parameter item: The alert item for which the action was triggered
    func alertDidTapAction(_ item: AlertItem)

    /// Called when the user snoozes an alert
    /// - Parameters:
    ///   - item: The alert item that was snoozed
    ///   - duration: How long the alert was snoozed for (in seconds)
    func alertDidSnooze(_ item: AlertItem, duration: TimeInterval)

    // MARK: - Analytics & Tracking (Optional)

    /// Whether to track statistics and analytics events
    /// - Returns: true to enable tracking, false to disable
    func alertShouldTrackStats() -> Bool

    /// Called when a stat/analytics event occurs (if tracking is enabled)
    /// - Parameters:
    ///   - event: Name of the event
    ///   - properties: Event properties/metadata
    func alertDidTrackStat(event: String, properties: [String: Any])

    // MARK: - Validation (Optional)

    /// Called before showing an alert to verify it should still be displayed
    ///
    /// Useful for async validation (e.g., checking if a task is still pending in an external system).
    /// - Parameter item: The alert item to validate
    /// - Returns: true to show the alert, false to skip it
    func alertShouldShow(_ item: AlertItem) async -> Bool
}

/// Reason why an alert was dismissed
public enum DismissalReason {
    /// User explicitly dismissed the alert
    case userDismissed

    /// User took an action (Join, Complete, etc.)
    case actionTaken

    /// Alert was auto-dismissed because snooze limit was reached
    case snoozeLimitReached

    /// Alert was skipped because system is recovering from sleep
    case systemRecovering
}

// MARK: - Default Implementations (All methods optional)

public extension AlertDelegate {
    func alertWillShow(_ item: AlertItem) {}
    func alertDidShow(_ item: AlertItem) {}
    func alertDidDismiss(_ item: AlertItem, reason: DismissalReason) {}
    func alertDidTapAction(_ item: AlertItem) {}
    func alertDidSnooze(_ item: AlertItem, duration: TimeInterval) {}

    func alertShouldTrackStats() -> Bool { false }
    func alertDidTrackStat(event: String, properties: [String: Any]) {}

    func alertShouldShow(_ item: AlertItem) async -> Bool { true }
}
