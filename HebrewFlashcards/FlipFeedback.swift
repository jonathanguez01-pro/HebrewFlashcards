//
//  FlipFeedback.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Haptic + short system sound played when a flashcard flips.
//

import AudioToolbox
import UIKit

enum FlipFeedback {
    static func play() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Soft system "tock" — works on device; Simulator may be silent.
        AudioServicesPlaySystemSound(1104)
    }

    static func celebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
    }
}
