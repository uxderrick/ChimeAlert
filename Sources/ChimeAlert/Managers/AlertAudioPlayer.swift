//
//  AlertAudioPlayer.swift
//  ChimeAlert
//
//  Manages alert sound playback with ADHD-friendly features like sound rotation.
//  Extracted from Chime's AlertSoundManager.
//

import AVFoundation
import AppKit
import Combine
import Foundation

/// Handles playback of alert sounds with rotation and volume control.
///
/// Sounds are managed via `AlertConfiguration` and automatically loaded from bundle resources.
@MainActor
class AlertAudioPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var lastPlayedSoundIndex = 0

    // Reference to parent AlertManager for configuration access
    private weak var alertManager: AlertManager?

    /// Available sounds (matching the bundled .m4a files)
    private let availableSounds: [(id: String, name: String)] = [
        ("marimba", "Magic Marimba"),
        ("bells", "Happy Bells"),
        ("flute", "Melodic Flute"),
        ("doorbell", "Doorbell"),
        ("button", "Light Button"),
    ]

    init(alertManager: AlertManager) {
        self.alertManager = alertManager
    }

    /// Plays an alert sound based on priority and configuration
    /// - Parameter priority: Priority level (affects sound selection in future versions)
    func playAlertSound(for priority: AlertPriority? = nil) {
        guard let config = alertManager?.configuration, config.soundEnabled else {
            return
        }

        let soundToPlay: String

        if config.rotateSounds {
            // Rotate through sounds to prevent habituation (ADHD-friendly)
            soundToPlay = availableSounds[lastPlayedSoundIndex].id
            lastPlayedSoundIndex = (lastPlayedSoundIndex + 1) % availableSounds.count

            // Track via delegate
            alertManager?.delegate?.alertDidTrackStat(
                event: "sound_rotated",
                properties: [
                    "sound": soundToPlay,
                    "index": lastPlayedSoundIndex
                ]
            )
        } else {
            // Use first sound as default (or could be made configurable)
            soundToPlay = availableSounds[0].id
        }

        playSound(named: soundToPlay, volume: config.soundVolume)
    }

    /// Plays a specific sound by ID (for previewing)
    /// - Parameter soundId: ID of the sound to play
    func previewSound(_ soundId: String) {
        guard let config = alertManager?.configuration else { return }
        playSound(named: soundId, volume: config.soundVolume)
    }

    /// Internal method to play a sound file
    private func playSound(named soundId: String, volume: Float) {
        // Try to find the sound file in the bundle (prefer m4a)
        guard let soundURL = Bundle.module.url(forResource: soundId, withExtension: "m4a")
                ?? Bundle.module.url(forResource: soundId, withExtension: "mp3")
                ?? Bundle.module.url(forResource: soundId, withExtension: "wav")
        else {
            #if DEBUG
            print("⚠️ ChimeAlert: Sound file '\(soundId)' not found, using system beep")
            #endif

            // Fallback to system beep
            NSSound.beep()

            // Track missing sound via delegate
            alertManager?.delegate?.alertDidTrackStat(
                event: "sound_file_missing",
                properties: ["sound_id": soundId]
            )
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.play()

            #if DEBUG
            print("🔊 ChimeAlert: Playing sound '\(soundId)' at volume \(Int(volume * 100))%")
            #endif

        } catch {
            #if DEBUG
            print("❌ ChimeAlert: Error playing sound '\(soundId)': \(error)")
            #endif

            // Fallback to system beep on error
            NSSound.beep()

            // Track error via delegate
            alertManager?.delegate?.alertDidTrackStat(
                event: "sound_playback_error",
                properties: [
                    "sound_id": soundId,
                    "error": error.localizedDescription
                ]
            )
        }
    }

    /// Returns list of available sound IDs and names
    var availableSoundList: [(id: String, name: String)] {
        availableSounds
    }
}
