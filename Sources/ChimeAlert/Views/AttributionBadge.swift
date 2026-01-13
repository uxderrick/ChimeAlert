//
//  AttributionBadge.swift
//  ChimeAlert
//
//  Mandatory attribution badge displayed on all alerts.
//  This is a requirement for using the open-source version of ChimeAlert.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Displays a non-removable "Powered by Chime" badge in the bottom-right corner.
///
/// This attribution is required for all users of the open-source ChimeAlert library.
/// When clicked, opens usechime.app in the default browser.
struct AttributionBadge: View {
    @State private var isHovered = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                Button(action: openChimeWebsite) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(isHovered ? 0.9 : 0.6))

                        Text("Powered by Chime")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(isHovered ? 0.9 : 0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(isHovered ? 0.5 : 0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
                .help("Visit usechime.app")
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func openChimeWebsite() {
        #if os(macOS)
        if let url = URL(string: "https://usechime.app") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

#Preview {
    ZStack {
        Color.black
        AttributionBadge()
    }
    .frame(width: 800, height: 600)
}
