//
//  AlertContentView.swift
//  ChimeAlert
//
//  Main full-screen alert view with pulsating border and ADHD-friendly animations.
//  Extracted from Chime's FullScreenAlertView.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

/// The main alert content view displayed full-screen with pulsating red border.
struct AlertContentView: View {
    let item: AlertItem
    let configuration: AlertConfiguration
    let onAction: () -> Void
    let onDismiss: () -> Void
    let onSnooze: (TimeInterval) -> Void

    @State private var pulseAnimation = false
    @State private var glowAnimation = false
    @State private var alertScale = 0.9
    @State private var backgroundOpacity = 0.0
    @State private var currentTime = Date()
    @State private var currentTimeTimer: Timer? = nil

    // Staggered animation states
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showTime = false
    @State private var showButtons = false
    @State private var showTrialBadge = false
    @State private var keyMonitor: Any? = nil

    // Snooze counter for limit enforcement
    @State private var snoozeCount: Int = 0

    // MARK: - Computed Properties

    /// Gradient colors based on alert type
    private var gradientColors: [Color] {
        switch item.type {
        case .meeting:
            return configuration.meetingGradient
        case .reminder:
            return configuration.reminderGradient
        case .task:
            return configuration.taskGradient
        case .custom(let colorComponents, _):
            return colorComponents.map { Color(red: $0.red, green: $0.green, blue: $0.blue) }
        }
    }

    /// Icon name based on alert type
    private var iconName: String {
        switch item.type {
        case .meeting:
            return item.actionURL != nil ? "video.fill" : "calendar"
        case .reminder:
            return "bell.fill"
        case .task:
            return "checkmark.circle.fill"
        case .custom(_, let icon):
            return icon
        }
    }

    /// Time until the event starts
    private var timeUntilStart: String {
        let interval = item.startTime.timeIntervalSince(currentTime)

        if interval <= 0 {
            return "Now"
        } else if interval < 60 {
            let seconds = Int(interval)
            return "\(seconds) sec"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            return seconds > 0 ? "\(minutes) min \(seconds) sec" : "\(minutes) min"
        } else {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }

    /// Meeting duration text (only for meetings, not reminders/tasks)
    private var durationText: String? {
        guard item.type == .meeting else { return nil }

        let duration = item.endTime.timeIntervalSince(item.startTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 && minutes > 0 {
            return "(\(hours)h \(minutes)m long meeting)"
        } else if hours > 0 {
            return "(\(hours)h long meeting)"
        } else {
            return "(\(minutes)m long meeting)"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - translucent dark blur
            Color.black.opacity(0.5 * backgroundOpacity)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(backgroundOpacity * 0.8))

            // Trial badge (if configured)
            if let trialBadge = configuration.trialBadge {
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(trialBadge.text)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(trialBadge.color.opacity(0.9))
                        )
                        .padding(.leading, 40)
                        .padding(.top, 40)
                        .opacity(showTrialBadge ? 1 : 0)
                        .offset(y: showTrialBadge ? 0 : -10)

                        Spacer()
                    }
                    Spacer()
                }
            }

            // Current time in top right corner
            VStack {
                HStack {
                    Spacer()
                    Text(
                        currentTime,
                        format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)
                            .hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 40)
                    .padding(.top, 40)
                }
                Spacer()
            }

            // Gradient glow effect
            LinearGradient(
                colors: gradientColors.map { $0.opacity(glowAnimation ? 0.25 : 0.15) },
                startPoint: .top,
                endPoint: .bottom
            )
            .blur(radius: configuration.gradientBlur)
            .frame(height: 280)
            .offset(y: -100)
            .animation(
                Animation.easeInOut(duration: configuration.glowDuration)
                    .repeatForever(autoreverses: true),
                value: glowAnimation
            )

            // Pulsating red border (ADHD-friendly)
            Rectangle()
                .strokeBorder(
                    configuration.borderColors.first ?? Color.red,
                    lineWidth: pulseAnimation ? configuration.borderWidth.max : configuration.borderWidth.min
                )
                .opacity(pulseAnimation ? configuration.borderOpacity.max : configuration.borderOpacity.min)
                .blur(radius: pulseAnimation ? configuration.blurRadius.max : configuration.blurRadius.min)
                .ignoresSafeArea()
                .animation(
                    Animation.easeInOut(duration: configuration.pulseDuration)
                        .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            // Main alert content
            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)
                    .opacity(showIcon ? 1 : 0)
                    .offset(y: showIcon ? 0 : 20)

                // Title with duration
                VStack(spacing: 4) {
                    if let duration = durationText {
                        Text(duration)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text(item.title)
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    // Recurring indicator
                    if item.isRecurring, let recurrence = item.recurrenceDescription {
                        HStack(spacing: 6) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text(recurrence)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                    }
                }
                .frame(maxWidth: 550)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)

                // Time until start
                VStack(spacing: 4) {
                    Text(item.type == .reminder || item.type == .task ? "DUE" : "MEETING STARTS IN")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(timeUntilStart)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.bottom, 32)
                .padding(.top, 32)
                .opacity(showTime ? 1 : 0)
                .offset(y: showTime ? 0 : 20)

                // Notes (if available)
                if let notes = item.notes, !notes.isEmpty {
                    VStack(spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(1.2)

                        Text(notes)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .frame(maxWidth: 600)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 24)
                    .opacity(showTime ? 1 : 0)
                    .offset(y: showTime ? 0 : 20)
                }

                // Attendees list (only for meetings with attendees)
                if item.type == .meeting, let attendees = item.attendees, !attendees.isEmpty {
                    CompactAttendeesView(
                        attendees: attendees,
                        totalCount: attendees.count
                    )
                    .padding(.bottom, 32)
                    .opacity(showTime ? 1 : 0)
                    .offset(y: showTime ? 0 : 20)
                }

                // Snooze limit warning
                if snoozeCount >= configuration.maxSnoozeAttempts {
                    VStack(spacing: 4) {
                        Text("⚠️ Maximum Snoozes Reached")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("You've snoozed this \(configuration.maxSnoozeAttempts) times. Take action or dismiss to continue.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 24)
                    .opacity(showTime ? 1 : 0)
                    .offset(y: showTime ? 0 : 20)
                }

                // Action buttons
                HStack(spacing: 40) {
                    // Snooze (hide if limit reached)
                    if snoozeCount < configuration.maxSnoozeAttempts {
                        CircularActionButton(
                            icon: "clock.arrow.circlepath",
                            label: "snooze (\(Int(configuration.defaultSnoozeInterval / 60))min)",
                            backgroundColor: Color.white.opacity(0.15),
                            keyboardHint: "⌘S",
                            action: { handleSnooze() }
                        )
                        .keyboardShortcut("s", modifiers: .command)
                    }

                    // Primary action (Join/Complete/Open)
                    if let actionTitle = item.actionButtonTitle {
                        CircularActionButton(
                            icon: actionIconName,
                            label: actionTitle.lowercased(),
                            backgroundColor: .green,
                            keyboardHint: "⌘↩",
                            action: onAction
                        )
                        .keyboardShortcut(.return, modifiers: .command)
                    }

                    // Dismiss
                    CircularActionButton(
                        icon: "xmark",
                        label: "dismiss",
                        backgroundColor: Color(red: 1.0, green: 0.267, blue: 0.267),
                        keyboardHint: "esc",
                        action: onDismiss
                    )
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.bottom, 60)
                .padding(.top, 60)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)

                Spacer()
            }
            .scaleEffect(alertScale)

            // Attribution badge (mandatory, non-removable)
            AttributionBadge()
        }
        .onAppear {
            startAnimations()
            startTimer()
            setupKeyboardMonitor()
        }
        .onDisappear {
            cleanup()
        }
    }

    // MARK: - Helper Methods

    private var actionIconName: String {
        switch item.type {
        case .meeting where item.actionURL != nil:
            return "video.fill"
        case .reminder, .task:
            return "checkmark.circle.fill"
        default:
            return "arrow.right.circle.fill"
        }
    }

    private func startAnimations() {
        pulseAnimation = true
        glowAnimation = true

        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration)) {
            backgroundOpacity = 1.0
            alertScale = 1.0
        }

        // Staggered entrance
        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration).delay(0.05)) {
            showIcon = true
        }
        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration).delay(0.15)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration).delay(0.25)) {
            showTime = true
        }
        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration).delay(0.35)) {
            showButtons = true
        }
        withAnimation(.easeOut(duration: configuration.entranceAnimationDuration).delay(0.05)) {
            showTrialBadge = true
        }
    }

    private func startTimer() {
        currentTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func setupKeyboardMonitor() {
        #if os(macOS)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+S for Snooze
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "s" {
                if snoozeCount < configuration.maxSnoozeAttempts {
                    handleSnooze()
                }
                return nil
            }
            // Cmd+Return for action
            if event.modifierFlags.contains(.command) && event.keyCode == 36 {
                onAction()
                return nil
            }
            // Escape for dismiss
            if event.keyCode == 53 {
                onDismiss()
                return nil
            }
            return event
        }
        #endif
    }

    private func handleSnooze() {
        snoozeCount += 1
        onSnooze(configuration.defaultSnoozeInterval)
    }

    private func cleanup() {
        currentTimeTimer?.invalidate()
        currentTimeTimer = nil

        #if os(macOS)
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        #endif
    }
}
