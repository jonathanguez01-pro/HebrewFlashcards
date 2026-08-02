//
//  ContentView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Root SwiftUI container that owns HomeViewModel and presents HomeView.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @State private var showSplash = true

    private let minimumSplashDuration: TimeInterval = 1.35

    init(repository: any VocabRepositoryProtocol) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    private var isInitialLoadInFlight: Bool {
        switch homeViewModel.loadState {
        case .idle, .loading:
            return true
        case .loaded, .failed:
            return false
        }
    }

    var body: some View {
        ZStack {
            HomeView(viewModel: homeViewModel)
                .opacity(showSplash ? 0 : 1)
                .allowsHitTesting(!showSplash)

            if showSplash {
                SplashView(isStillLoading: isInitialLoadInFlight)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await runLaunchSequence()
        }
    }

    /// Loads vocabulary under the splash; keeps splash visible for a short minimum time.
    private func runLaunchSequence() async {
        let started = Date()

        if case .idle = homeViewModel.loadState {
            await homeViewModel.load()
        }

        let elapsed = Date().timeIntervalSince(started)
        let remaining = minimumSplashDuration - elapsed
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            showSplash = false
        }
    }
}
