import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel: HomeViewModel

    init(repository: any VocabRepositoryProtocol) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        HomeView(viewModel: homeViewModel)
    }
}
