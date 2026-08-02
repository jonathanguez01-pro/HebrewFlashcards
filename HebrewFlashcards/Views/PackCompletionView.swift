//
//  PackCompletionView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Pack-complete overlay with confetti burst and study-again actions.
//

import SwiftUI

struct PackCompletionView: View {
    let packTitle: String
    let levelName: String
    let levelColor: Color
    let cardCount: Int
    let reduceMotion: Bool
    let onStudyAgain: () -> Void
    let onShuffle: () -> Void

    var body: some View {
        ZStack {
            Color.primary.opacity(0.35)
                .ignoresSafeArea()

            ConfettiBurst(colors: [levelColor, Brand.accent, .white, Brand.charcoal], reduceMotion: reduceMotion)

            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(levelColor)

                Text("Pack complete")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.charcoal)

                Text("You finished all \(cardCount) cards in \(packTitle).")
                    .font(.subheadline)
                    .foregroundStyle(Brand.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Shuffle", action: onShuffle)
                        .buttonStyle(.bordered)
                        .tint(Brand.charcoal)

                    Button("Study again", action: onStudyAgain)
                        .buttonStyle(.borderedProminent)
                        .tint(levelColor)
                        .foregroundStyle(LevelTheme.contrastingInk(for: levelName))
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: Brand.charcoal.opacity(0.2), radius: 24, y: 12)
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var scale: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
}

struct ConfettiBurst: View {
    let colors: [Color]
    let reduceMotion: Bool

    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Capsule()
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .scaleEffect(piece.scale)
                        .rotationEffect(.degrees(piece.rotation + (animate ? 180 : 0)))
                        .position(
                            x: piece.x,
                            y: animate ? piece.y + geo.size.height * 0.85 : piece.y
                        )
                        .opacity(animate ? 0.15 : 1)
                }
            }
            .onAppear {
                spawn(in: geo.size)
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 2.2)) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let count = reduceMotion ? 12 : 48
        pieces = (0..<count).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -40...(size.height * 0.35)),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.7...1.3),
                color: colors.randomElement() ?? Brand.accent,
                width: CGFloat.random(in: 6...10),
                height: CGFloat.random(in: 10...18)
            )
        }
    }
}
