//
//  SplashView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Branded launch splash shown until the first vocabulary load settles.
//

import SwiftUI

struct SplashView: View {
    let isStillLoading: Bool

    var body: some View {
        ZStack {
            AdaptiveBackdrop(levelColor: Brand.accent)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Brand.accent)
                        .frame(width: 108, height: 108)
                        .rotationEffect(.degrees(-8))
                        .opacity(0.9)

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 108, height: 108)
                        .overlay {
                            Text("א")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(Brand.charcoal)
                        }
                        .shadow(color: Brand.charcoal.opacity(0.18), radius: 20, y: 10)
                }

                VStack(spacing: 8) {
                    Text("Citizen Café")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.charcoal)

                    Text("FlashcardsApp")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.charcoal.opacity(0.65))
                }

                Spacer()

                if isStillLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(Brand.accent)
                        Text("Loading vocabulary…")
                            .font(.footnote)
                            .foregroundStyle(Brand.charcoal.opacity(0.55))
                    }
                    .padding(.bottom, 36)
                } else {
                    Color.clear.frame(height: 60)
                        .padding(.bottom, 36)
                }
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("FlashcardsApp")
    }
}
