import SwiftUI

struct FlipCardView: View {
    let hebrew: String
    let english: String
    let isFlipped: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            cardFace(text: hebrew, subtitle: "Hebrew", style: .prompt)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 90 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )

            cardFace(text: english, subtitle: "English", style: .answer)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .foregroundStyle(style == .answer ? Brand.charcoal.opacity(0.55) : Brand.charcoal.opacity(0.45))

            Text(text)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Brand.charcoal)
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, style == .prompt ? .rightToLeft : .leftToRight)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(style == .answer ? Brand.accent : Color.white.opacity(0.92))
                .shadow(color: Brand.charcoal.opacity(0.12), radius: 14, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.charcoal.opacity(style == .answer ? 0.08 : 0.06), lineWidth: 1)
        )
    }
}
