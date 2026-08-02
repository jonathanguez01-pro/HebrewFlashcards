//
//  FlipCardView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  3D Y-axis card flip between Hebrew prompt and English answer.
//

import SwiftUI

struct FlipCardView: View {
    let hebrew: String
    let english: String
    let isFlipped: Bool
    let levelColor: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            cardFace(text: hebrew, subtitle: "Hebrew", style: .prompt)
                .modifier(CardSideFlip(progress: isFlipped ? 1 : 0, role: .front))

            cardFace(text: english, subtitle: "English", style: .answer)
                .modifier(CardSideFlip(progress: isFlipped ? 1 : 0, role: .back))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? "English: \(english)" : "Hebrew: \(hebrew)")
        .accessibilityHint("Double tap to flip the card")
        .accessibilityAddTraits(.isButton)
    }

    private enum FaceStyle {
        case prompt
        case answer
    }

    private func cardFace(text: String, subtitle: String, style: FaceStyle) -> some View {
        VStack(spacing: 18) {
            Text(subtitle.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(Brand.charcoal.opacity(0.45))

            Text(text)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Brand.charcoal)
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, style == .prompt ? .rightToLeft : .leftToRight)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(faceWash(for: style))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.7),
                                    levelColor.opacity(0.35),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .shadow(
                    color: levelColor.opacity(colorScheme == .dark ? 0.4 : 0.28),
                    radius: 22,
                    y: 12
                )
        }
    }

    private func faceWash(for style: FaceStyle) -> Color {
        switch style {
        case .answer:
            return levelColor.opacity(colorScheme == .dark ? 0.45 : 0.55)
        case .prompt:
            return Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04)
        }
    }
}

/// Animates a two-sided Y flip without parking at exactly ±90°,
/// which triggers SwiftUI's "ignoring singular matrix" projection warning.
private struct CardSideFlip: ViewModifier, Animatable {
    enum Role {
        case front
        case back
    }

    var progress: Double
    let role: Role

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(safeAngle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.55
            )
    }

    private var opacity: Double {
        switch role {
        case .front:
            return progress <= 0.5 ? 1 : 0
        case .back:
            return progress >= 0.5 ? 1 : 0
        }
    }

    /// Keep rotation away from true ±90° (singular projection).
    private var safeAngle: Double {
        switch role {
        case .front:
            let raw = min(progress, 0.5) * 180
            return min(raw, 89)
        case .back:
            let raw = -90 + max(progress - 0.5, 0) * 180
            return max(raw, -89)
        }
    }
}
