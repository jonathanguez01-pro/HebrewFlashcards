//
//  Brand.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Shared design tokens, level colour themes, glass panel, and adaptive backdrop.
//

import SwiftUI

/// Citizen Café–inspired palette from the Design Bible, via the asset catalog.
/// `Charcoal` and `WarmOffWhite` include Dark Appearance values in the asset catalog.
enum Brand {
    /// Primary text / icons on the canvas (light in dark mode).
    static let charcoal = Color("Charcoal")
    /// Brand yellow — CTA / accent (`#F5C518`).
    static let accent = Color("AccentColor")
    /// Screen background (warm off-white ↔ deep charcoal).
    static let canvas = Color("WarmOffWhite")

    /// Always-dark ink for text sitting on yellow / pale level colours.
    static let inkOnLightFill = Color(red: 28 / 255, green: 28 / 255, blue: 28 / 255)
}

/// Colour-coded curriculum levels → adaptive UI accents.
enum LevelTheme {
    static func color(for levelName: String?) -> Color {
        switch levelName {
        case "Red": return Color(red: 0.86, green: 0.22, blue: 0.22)
        case "Orange": return Color(red: 0.95, green: 0.55, blue: 0.18)
        case "Pink": return Color(red: 0.92, green: 0.42, blue: 0.62)
        case "Yellow": return Color(red: 0.96, green: 0.77, blue: 0.09)
        case "Light Blue": return Color(red: 0.45, green: 0.72, blue: 0.92)
        case "Blue": return Color(red: 0.22, green: 0.48, blue: 0.86)
        case "Lime": return Color(red: 0.62, green: 0.86, blue: 0.22)
        case "Green": return Color(red: 0.22, green: 0.68, blue: 0.38)
        case "Dark Green": return Color(red: 0.12, green: 0.45, blue: 0.28)
        case "Turquoise": return Color(red: 0.18, green: 0.72, blue: 0.72)
        case "Indigo": return Color(red: 0.35, green: 0.28, blue: 0.72)
        case "Purple": return Color(red: 0.58, green: 0.28, blue: 0.72)
        default: return Brand.accent
        }
    }

    /// Readable ink on top of a saturated level colour (stable across light/dark).
    static func contrastingInk(for levelName: String?) -> Color {
        switch levelName {
        case "Yellow", "Lime", "Light Blue", "Pink", "Orange":
            return Brand.inkOnLightFill
        default:
            return .white
        }
    }
}

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 22
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: strokeColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                        radius: 18,
                        y: 10
                    )
            }
    }

    private var strokeColors: [Color] {
        if colorScheme == .dark {
            return [Color.white.opacity(0.28), Color.white.opacity(0.06)]
        }
        return [Color.white.opacity(0.55), Color.white.opacity(0.12)]
    }
}

struct AdaptiveBackdrop: View {
    let levelColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Brand.canvas

            RadialGradient(
                colors: [
                    levelColor.opacity(colorScheme == .dark ? 0.34 : 0.42),
                    levelColor.opacity(colorScheme == .dark ? 0.10 : 0.12),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    Brand.accent.opacity(colorScheme == .dark ? 0.12 : 0.18),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: colorScheme)
    }
}
