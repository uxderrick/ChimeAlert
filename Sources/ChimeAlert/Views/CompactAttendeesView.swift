//
//  CompactAttendeesView.swift
//  ChimeAlert
//
//  Displays a compact list of attendees with organizer indication.
//  Extracted from Chime's FullScreenAlertView.
//

import SwiftUI

/// Displays up to 3 attendees with organizer crown icon, plus overflow count.
struct CompactAttendeesView: View {
    let attendees: [AlertAttendee]
    let totalCount: Int

    var body: some View {
        VStack(spacing: 8) {
            // "Attendees" label
            Text("Attendees")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.2)

            // Show first 3 attendees
            VStack(spacing: 6) {
                ForEach(Array(attendees.prefix(3)), id: \.name) { attendee in
                    HStack(spacing: 6) {
                        // Crown icon for organizer
                        if attendee.isOrganizer {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow.opacity(0.8))
                        }

                        Text(attendee.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        // (Organizer) label
                        if attendee.isOrganizer {
                            Text("(Organizer)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                // "+X more" if there are additional attendees
                if totalCount > 3 {
                    Text("+\(totalCount - 3) more")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CompactAttendeesView(
            attendees: [
                AlertAttendee(name: "Sarah Chen", isOrganizer: true),
                AlertAttendee(name: "Michael Rodriguez", isOrganizer: false),
                AlertAttendee(name: "Emily Thompson", isOrganizer: false),
            ],
            totalCount: 12
        )
    }
    .frame(width: 400, height: 300)
}
