//
//  HomeView.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Study-path UI with glass panels, level-adaptive colours, and navigation to flashcards.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    private var levelColor: Color {
        LevelTheme.color(for: viewModel.selectedLevelName)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView("Loading vocabulary…")
                        .tint(levelColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't Load Vocabulary", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(levelColor)
                    }
                case .loaded(let source):
                    loadedContent(source: source)
                }
            }
            .background(AdaptiveBackdrop(levelColor: levelColor).animation(.easeInOut(duration: 0.35), value: viewModel.selectedLevelName))
            .navigationTitle("Citizen Café")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            // Initial fetch is started from ContentView under the splash.
            // Keep this as a safety net if Home is ever shown while still idle.
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.load()
                }
            }
        }
        .tint(levelColor)
    }

    @ViewBuilder
    private func loadedContent(source: VocabLoadSource) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Study Path", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.charcoal.opacity(0.7))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tier")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Picker("Tier", selection: tierBinding) {
                                ForEach(viewModel.availableTiers, id: \.self) { tier in
                                    Text(tier).tag(Optional(tier))
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Level")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            levelMenu
                        }

                        if viewModel.needsTypePicker {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content Pack")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Picker("Content Pack", selection: typeBinding) {
                                    ForEach(viewModel.availableTypes, id: \.self) { type in
                                        Text("Pack \(type)").tag(Optional(type))
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        Text(sourceFooter(source))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let level = viewModel.selectedVocabLevel {
                    NavigationLink {
                        FlashcardScreen(level: level)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .font(.title3.weight(.semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Study \(level.displayTitle)")
                                    .font(.headline)
                                Text("\(level.pairs.count) cards")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .opacity(0.7)
                        }
                        .foregroundStyle(LevelTheme.contrastingInk(for: level.level))
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(levelColor.gradient)
                                .shadow(color: levelColor.opacity(0.35), radius: 16, y: 8)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canStartStudying)
                }
            }
            .padding(20)
        }
    }

    private var levelMenu: some View {
        Menu {
            ForEach(viewModel.levelsForSelectedTier, id: \.self) { level in
                Button {
                    viewModel.selectLevel(level)
                } label: {
                    Label(level, systemImage: viewModel.selectedLevelName == level ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(levelColor.gradient)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                Text(viewModel.selectedLevelName ?? "Choose level")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.charcoal)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(levelColor.opacity(0.35), lineWidth: 1.5)
                    }
            }
        }
    }

    private var tierBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedTier },
            set: { if let value = $0 { viewModel.selectTier(value) } }
        )
    }

    private var typeBinding: Binding<Int?> {
        Binding(
            get: { viewModel.selectedType },
            set: { if let value = $0 { viewModel.selectType(value) } }
        )
    }

    private func sourceFooter(_ source: VocabLoadSource) -> String {
        switch source {
        case .remote:
            return "Vocabulary refreshed from Citizen Hub."
        case .diskCache:
            return "You're offline — showing the last saved vocabulary."
        case .bundledFallback:
            return "You're offline — showing the bundled starter vocabulary."
        }
    }
}
