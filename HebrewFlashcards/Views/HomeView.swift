import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView("Loading vocabulary…")
                        .tint(Brand.accent)
                        .foregroundStyle(Brand.charcoal)
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
                        .tint(Brand.accent)
                        .foregroundStyle(Brand.charcoal)
                    }
                case .loaded(let source):
                    loadedContent(source: source)
                }
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("Citizen Café")
            .toolbarBackground(Brand.canvas, for: .navigationBar)
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.load()
                }
            }
        }
        .tint(Brand.accent)
    }

    @ViewBuilder
    private func loadedContent(source: VocabLoadSource) -> some View {
        Form {
            Section {
                Picker("Tier", selection: tierBinding) {
                    ForEach(viewModel.availableTiers, id: \.self) { tier in
                        Text(tier).tag(Optional(tier))
                    }
                }
                .pickerStyle(.segmented)

                Picker("Level", selection: levelBinding) {
                    ForEach(viewModel.levelsForSelectedTier, id: \.self) { level in
                        Text(level).tag(Optional(level))
                    }
                }

                if viewModel.needsTypePicker {
                    Picker("Content Pack", selection: typeBinding) {
                        ForEach(viewModel.availableTypes, id: \.self) { type in
                            Text("Pack \(type)").tag(Optional(type))
                        }
                    }
                    .pickerStyle(.segmented)
                }
            } header: {
                Label("Study Path", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            } footer: {
                Text(sourceFooter(source))
            }

            Section {
                if let level = viewModel.selectedVocabLevel {
                    NavigationLink {
                        FlashcardScreen(level: level)
                    } label: {
                        Label("Study \(level.displayTitle)", systemImage: "rectangle.on.rectangle.angled")
                    }
                    .disabled(!viewModel.canStartStudying)
                } else {
                    Text("Select a tier and level to begin.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var tierBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedTier },
            set: { if let value = $0 { viewModel.selectTier(value) } }
        )
    }

    private var levelBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedLevelName },
            set: { if let value = $0 { viewModel.selectLevel(value) } }
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
