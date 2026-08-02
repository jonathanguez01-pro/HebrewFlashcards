//
//  FlashcardView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Flashcard screen: progress, flip card, swipe-to-next, shuffle/next controls, level theming.
//

import SwiftUI

struct FlashcardScreen: View {
    @StateObject private var viewModel: FlashcardViewModel
    private let level: VocabLevel

    init(level: VocabLevel) {
        self.level = level
        _viewModel = StateObject(wrappedValue: FlashcardViewModel(level: level))
    }

    var body: some View {
        FlashcardView(viewModel: viewModel, levelName: level.level, title: level.displayTitle)
    }
}

struct FlashcardView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    let levelName: String
    let title: String

    @AppStorage("hebrewSpeechEnabled") private var speechEnabled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swipeOffset: CGFloat = 0

    private var levelColor: Color {
        LevelTheme.color(for: levelName)
    }

    private var swipeToNextGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard !viewModel.didCompletePack else { return }
                // Only follow horizontal left swipes (next).
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) else {
                    swipeOffset = 0
                    return
                }
                swipeOffset = min(0, dx)
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        swipeOffset = 0
                    }
                }
                guard !viewModel.didCompletePack else { return }

                let dx = value.translation.width
                let dy = value.translation.height
                let predicted = value.predictedEndTranslation.width

                // Swipe left → Next / Finish
                let isHorizontal = abs(dx) > abs(dy)
                let shouldAdvance = isHorizontal && (dx < -80 || predicted < -120)
                guard shouldAdvance else { return }

                withAnimation(.easeInOut(duration: 0.18)) {
                    swipeOffset = -140
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    viewModel.next()
                    swipeOffset = 0
                }
            }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                GlassPanel {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(levelColor.gradient)
                                .frame(width: 10, height: 10)
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.charcoal)
                        }
                        Spacer()
                        Text(viewModel.progressText)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(levelColor)
                            .accessibilityLabel("Card \(viewModel.progressText)")
                    }
                }

                if let card = viewModel.currentCard {
                    FlipCardView(
                        hebrew: card.hebrew,
                        english: card.english,
                        isFlipped: viewModel.isShowingEnglish,
                        levelColor: levelColor,
                        onTap: flipCard
                    )
                    .offset(x: swipeOffset)
                    .simultaneousGesture(swipeToNextGesture)
                    .accessibilityHint("Double tap to flip. Swipe left for next card.")

                    if speechEnabled {
                        Button {
                            speakCurrentHebrew()
                        } label: {
                            Label("Hear Hebrew", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(levelColor)
                    }
                } else {
                    ContentUnavailableView(
                        "No Cards",
                        systemImage: "rectangle.slash",
                        description: Text("This level has no word pairs.")
                    )
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.shuffle()
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(Brand.charcoal)
                    .disabled(!viewModel.hasCards || viewModel.didCompletePack)

                    Button {
                        viewModel.next()
                    } label: {
                        Label(viewModel.isOnLastCard ? "Finish" : "Next", systemImage: viewModel.isOnLastCard ? "checkmark" : "arrow.right")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(levelColor)
                    .foregroundStyle(LevelTheme.contrastingInk(for: levelName))
                    .disabled(!viewModel.hasCards || viewModel.didCompletePack)
                }
                .padding(.horizontal, 2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AdaptiveBackdrop(levelColor: levelColor))

            if viewModel.didCompletePack {
                PackCompletionView(
                    packTitle: title,
                    levelName: levelName,
                    levelColor: levelColor,
                    cardCount: viewModel.cards.count,
                    reduceMotion: reduceMotion,
                    onStudyAgain: {
                        viewModel.studyAgain()
                        if speechEnabled { speakCurrentHebrew() }
                    },
                    onShuffle: {
                        viewModel.shuffle()
                        if speechEnabled { speakCurrentHebrew() }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .tint(levelColor)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.didCompletePack)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $speechEnabled) {
                    Image(systemName: speechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .toggleStyle(.button)
                .accessibilityLabel(speechEnabled ? "Hebrew speech on" : "Hebrew speech off")
            }
        }
        .onAppear {
            if speechEnabled {
                speakCurrentHebrew()
            }
        }
        .onChange(of: viewModel.index) { _, _ in
            if speechEnabled {
                speakCurrentHebrew()
            }
        }
        .onChange(of: speechEnabled) { _, enabled in
            if enabled {
                speakCurrentHebrew()
            } else {
                HebrewSpeech.shared.stop()
            }
        }
        .onChange(of: viewModel.didCompletePack) { _, completed in
            if completed {
                HebrewSpeech.shared.stop()
                FlipFeedback.celebrate()
            }
        }
        .onDisappear {
            HebrewSpeech.shared.stop()
        }
    }

    private func flipCard() {
        FlipFeedback.play()
        if reduceMotion {
            viewModel.flip()
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                viewModel.flip()
            }
        }
    }

    private func speakCurrentHebrew() {
        guard speechEnabled, let hebrew = viewModel.currentCard?.hebrew else { return }
        HebrewSpeech.shared.speak(hebrew)
    }
}
