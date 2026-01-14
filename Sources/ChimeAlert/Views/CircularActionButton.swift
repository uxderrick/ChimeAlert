//
//  CircularActionButton.swift
//  ChimeAlert
//
//  Circular action button used in alert views (Join, Snooze, Dismiss, etc.)
//  Extracted from Chime's FullScreenAlertView.
//

import SwiftUI

/// A circular button with icon, label, and optional keyboard hint.
struct CircularActionButton: View {
    let icon: String
    let label: String
    var backgroundColor: Color = Color.white.opacity(0.15)
    var keyboardHint: String? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 90, height: 90)
                        .scaleEffect(isHovered ? 1.05 : 1.0)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            if let hint = keyboardHint {
                Text(hint)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        HStack(spacing: 40) {
            CircularActionButton(
                icon: "video.fill",
                label: "join",
                backgroundColor: .green,
                keyboardHint: "⌘↩",
                action: {}
            )

            CircularActionButton(
                icon: "clock.arrow.circlepath",
                label: "snooze (2min)",
                backgroundColor: Color.white.opacity(0.15),
                keyboardHint: "⌘S",
                action: {}
            )

            CircularActionButton(
                icon: "xmark",
                label: "dismiss",
                backgroundColor: Color(red: 1.0, green: 0.267, blue: 0.267),
                keyboardHint: "esc",
                action: {}
            )
        }
    }
    .frame(width: 600, height: 300)
}
