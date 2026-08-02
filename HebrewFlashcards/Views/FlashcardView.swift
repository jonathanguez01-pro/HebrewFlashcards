import SwiftUI

struct FlashcardScreen: View {
    @StateObject private var viewModel: FlashcardViewModel

    init(level: VocabLevel) {
        _viewModel = StateObject(wrappedValue: FlashcardViewModel(level: level))
    }

    var body: some View {
        FlashcardView(viewModel: viewModel)
    }
}

struct FlashcardView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Text(viewModel.progressText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Brand.charcoal.opacity(0.7))
                .accessibilityLabel("Card \(viewModel.progressText)")

            if let card = viewModel.currentCard {
                FlipCardView(
                    hebrew: card.hebrew,
                    english: card.english,
                    isFlipped: viewModel.isShowingEnglish,
                    onTap: flipCard
                )
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
                }
                .buttonStyle(.bordered)
                .tint(Brand.charcoal)
                .disabled(!viewModel.hasCards)

                Button {
                    viewModel.next()
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.accent)
                .foregroundStyle(Brand.charcoal)
                .disabled(!viewModel.hasCards)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.canvas.ignoresSafeArea())
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.canvas, for: .navigationBar)
    }

    private func flipCard() {
        if reduceMotion {
            viewModel.flip()
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                viewModel.flip()
            }
        }
    }
}
