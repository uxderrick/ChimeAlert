//
//  ChimeAlert.swift
//  ChimeAlert
//
//  An ADHD-friendly, impossible-to-miss full-screen alert system for macOS.
//
//  Homepage: https://github.com/YOUR_USERNAME/ChimeAlert
//  Documentation: https://github.com/YOUR_USERNAME/ChimeAlert#readme
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Main entry point for ChimeAlert - use `AlertManager.shared` to show alerts.
///
/// Example usage:
/// ```swift
/// import ChimeAlert
///
/// // Configure
/// AlertManager.shared.configuration.soundVolume = 0.9
/// AlertManager.shared.monitorPreference = .allMonitors
///
/// // Set delegate (optional)
/// AlertManager.shared.delegate = myDelegate
///
/// // Show alert
/// AlertManager.shared.showAlert(for: myAlertItem)
/// ```
@MainActor
public class AlertManager: NSObject, ObservableObject {
    /// Shared singleton instance
    public static let shared = AlertManager()

    /// Delegate for handling alert lifecycle events and actions
    public weak var delegate: AlertDelegate?

    /// Configuration for customizing alert appearance and behavior
    public var configuration = AlertConfiguration()

    /// Which monitor(s) to display alerts on
    @Published public var monitorPreference: MonitorPreference {
        didSet {
            configuration.monitorPreference = monitorPreference
        }
    }

    // Private state
    private var alertWindows: [NSWindow] = []
    private var screenChangeObserver: Any?
    private var isShowingAlert = false
    private var audioPlayer: AlertAudioPlayer!

    // Snooze state tracking
    private var snoozedItems: [String: (item: AlertItem, count: Int, timer: DispatchWorkItem?)] = [:]

    // CRITICAL: System recovery flag to prevent alerts during sleep/wake transition
    nonisolated(unsafe) public static var isSystemRecovering = false

    private override init() {
        self.monitorPreference = .allMonitors
        super.init()
        self.audioPlayer = AlertAudioPlayer(alertManager: self)
    }

    // MARK: - Public API

    /// Shows a full-screen alert for the given item
    /// - Parameter item: The alert item to display
    public func showAlert(for item: AlertItem) {
        #if os(macOS)
        // CRITICAL: Check if system is recovering from sleep
        if Self.isSystemRecovering {
            #if DEBUG
            print("⚠️ ChimeAlert: System recovering from sleep, skipping alert")
            #endif
            delegate?.alertDidDismiss(item, reason: .systemRecovering)
            return
        }

        // Call delegate lifecycle method
        delegate?.alertWillShow(item)

        // Play sound
        audioPlayer.playAlertSound(for: item.priority)

        // Create content view
        let contentView = AlertContentView(
            item: item,
            configuration: configuration,
            onAction: { [weak self] in
                self?.handleAction(for: item)
            },
            onDismiss: { [weak self] in
                self?.handleDismiss(for: item)
            },
            onSnooze: { [weak self] duration in
                self?.handleSnooze(for: item, duration: duration)
            }
        )

        // Show the alert window
        showAlertWindow(with: AnyView(contentView))

        // Call delegate after showing
        delegate?.alertDidShow(item)

        // Track stats if enabled
        if delegate?.alertShouldTrackStats() == true {
            delegate?.alertDidTrackStat(event: "alert_shown", properties: [
                "item_id": item.id,
                "title": item.title,
                "type": String(describing: item.type),
                "priority": String(describing: item.priority)
            ])
        }
        #endif
    }

    /// Shows a full-screen alert for multiple conflicting items
    /// - Parameter items: Array of alert items to display simultaneously
    public func showCombinedAlert(for items: [AlertItem]) {
        guard !items.isEmpty else { return }

        if items.count == 1 {
            showAlert(for: items[0])
            return
        }

        // TODO: Implement combined alert view (Phase 3)
        // For now, show the first item
        showAlert(for: items[0])
    }

    /// Dismisses the currently displayed alert(s)
    public func dismissAlert() {
        #if os(macOS)
        removeScreenChangeObserver()

        for window in alertWindows {
            window.orderOut(nil)
        }
        alertWindows.removeAll()

        #if DEBUG
        print("✅ ChimeAlert: Dismissed all alert windows")
        #endif
        #endif
    }

    // MARK: - Private Methods

    #if os(macOS)
    private func showAlertWindow(with contentView: AnyView) {
        // Prevent concurrent alert creation
        guard !isShowingAlert else {
            #if DEBUG
            print("⚠️ ChimeAlert: Alert creation already in progress, skipping")
            #endif
            return
        }

        isShowingAlert = true
        defer { isShowingAlert = false }

        // Dismiss any existing alert
        dismissAlert()

        // Get screens based on preference
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            #if DEBUG
            print("❌ ChimeAlert: No screens found")
            #endif
            return
        }

        let screensToUse = selectScreens(from: screens)

        #if DEBUG
        print("📺 ChimeAlert: Creating alert windows for \(screensToUse.count) screen(s)")
        #endif

        // Create window for each selected screen
        for screen in screensToUse {
            guard screen.frame.width > 0 && screen.frame.height > 0 else {
                continue
            }

            let hostingView = NSHostingView(rootView: contentView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            // Configure window to be unmissable
            window.contentView = hostingView
            window.backgroundColor = NSColor.clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.styleMask.remove(.miniaturizable)
            window.styleMask.remove(.closable)
            window.setFrame(screen.frame, display: true)

            autoreleasepool {
                window.makeKeyAndOrderFront(nil)
                window.makeKey()
            }

            alertWindows.append(window)
        }

        setupScreenChangeObserver()
        NSApp.activate(ignoringOtherApps: true)
        NSSound.beep()
    }

    private func selectScreens(from screens: [NSScreen]) -> [NSScreen] {
        switch monitorPreference {
        case .primaryOnly:
            return [NSScreen.main ?? screens[0]]

        case .externalOnly:
            var externalScreens = screens.filter { $0 != NSScreen.main }
            if externalScreens.isEmpty {
                externalScreens = [NSScreen.main ?? screens[0]]
            }
            return externalScreens

        case .mouseLocation:
            let mouseLocation = NSEvent.mouseLocation
            if let screenWithMouse = screens.first(where: { $0.frame.contains(mouseLocation) }) {
                return [screenWithMouse]
            }
            return [NSScreen.main ?? screens[0]]

        case .allMonitors:
            return screens
        }
    }

    private func setupScreenChangeObserver() {
        removeScreenChangeObserver()

        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }
    }

    private func removeScreenChangeObserver() {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            screenChangeObserver = nil
        }
    }

    private func handleScreenChange() {
        guard !alertWindows.isEmpty else { return }

        let currentScreens = NSScreen.screens
        var windowsToRemove: [NSWindow] = []

        for window in alertWindows {
            let windowFrame = window.frame
            let screenStillExists = currentScreens.contains { $0.frame.intersects(windowFrame) }

            if !screenStillExists {
                window.orderOut(nil)
                windowsToRemove.append(window)
            }
        }

        alertWindows.removeAll { windowsToRemove.contains($0) }

        if alertWindows.isEmpty {
            dismissAlert()
        }
    }

    private func handleAction(for item: AlertItem) {
        dismissAlert()
        delegate?.alertDidTapAction(item)
        delegate?.alertDidDismiss(item, reason: .actionTaken)

        if delegate?.alertShouldTrackStats() == true {
            delegate?.alertDidTrackStat(event: "alert_action_taken", properties: [
                "item_id": item.id,
                "action": item.actionButtonTitle ?? "default"
            ])
        }
    }

    private func handleDismiss(for item: AlertItem) {
        dismissAlert()
        delegate?.alertDidDismiss(item, reason: .userDismissed)

        if delegate?.alertShouldTrackStats() == true {
            delegate?.alertDidTrackStat(event: "alert_dismissed", properties: [
                "item_id": item.id
            ])
        }
    }

    private func handleSnooze(for item: AlertItem, duration: TimeInterval) {
        dismissAlert()

        // Track snooze count
        var snoozeData = snoozedItems[item.id] ?? (item: item, count: 0, timer: nil)
        snoozeData.timer?.cancel()
        snoozeData.count += 1

        // Check snooze limit
        if snoozeData.count >= configuration.maxSnoozeAttempts {
            #if DEBUG
            print("⚠️ ChimeAlert: Maximum snooze limit reached for \(item.title)")
            #endif

            delegate?.alertDidDismiss(item, reason: .snoozeLimitReached)

            if delegate?.alertShouldTrackStats() == true {
                delegate?.alertDidTrackStat(event: "snooze_limit_reached", properties: [
                    "item_id": item.id,
                    "snooze_count": snoozeData.count
                ])
            }

            snoozedItems.removeValue(forKey: item.id)
            return
        }

        // Schedule re-alert
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                // Check if item should still be shown
                if await self?.delegate?.alertShouldShow(item) ?? true {
                    self?.showAlert(for: item)
                } else {
                    #if DEBUG
                    print("⏭️ ChimeAlert: Snoozed alert skipped (no longer valid)")
                    #endif
                }
                self?.snoozedItems.removeValue(forKey: item.id)
            }
        }

        snoozeData.timer = workItem
        snoozedItems[item.id] = snoozeData

        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)

        delegate?.alertDidSnooze(item, duration: duration)

        if delegate?.alertShouldTrackStats() == true {
            delegate?.alertDidTrackStat(event: "alert_snoozed", properties: [
                "item_id": item.id,
                "duration_seconds": duration,
                "snooze_count": snoozeData.count
            ])
        }
    }
    #endif

    deinit {
        #if os(macOS)
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }
}
