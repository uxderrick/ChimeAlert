//
//  AttributionBadge.swift
//  ChimeAlert
//
//  Mandatory attribution badge displayed on all alerts.
//  This is a requirement for using the open-source version of ChimeAlert.
//

import SwiftUI

/// Displays a non-removable "Powered by ChimeAlert" badge in the bottom-right corner.
///
/// This attribution is required for all users of the open-source ChimeAlert library.
struct AttributionBadge: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("Powered by ChimeAlert")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        AttributionBadge()
    }
    .frame(width: 800, height: 600)
}
