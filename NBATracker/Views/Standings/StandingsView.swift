import SwiftUI

@MainActor
final class StandingsViewModel: ObservableObject {
    @Published var standings: [Standing] = []
    @Published var isLoading = false
    @Published var error: String?

    var east: [Standing] {
        standings.filter { $0.conference.contains("East") }
                 .sorted { $0.wins > $1.wins }
    }
    var west: [Standing] {
        standings.filter { $0.conference.contains("West") }
                 .sorted { $0.wins > $1.wins }
    }

    func load() async {
        isLoading = true; error = nil
        do { standings = try await NBAService.shared.fetchStandings() }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

struct StandingsView: View {
    @StateObject private var vm = StandingsViewModel()
    @State private var selectedConference = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                if vm.isLoading { LoadingView() }
                else if let err = vm.error { ErrorView(message: err, retry: { Task { await vm.load() } }) }
                else { content }
            }
            .navigationTitle("Standings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { HamburgerButton() }
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Picker("Conference", selection: $selectedConference) {
                Text("Eastern").tag(0)
                Text("Western").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.nbaBG)

            ScrollView {
                LazyVStack(spacing: 0) {
                    columnHeader
                    let list = selectedConference == 0 ? vm.east : vm.west
                    ForEach(Array(list.enumerated()), id: \.element.id) { idx, s in
                        StandingRow(standing: s, rank: idx + 1)
                        if idx < list.count - 1 {
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 60)
                        }
                    }
                }
                .background(Color.nbaCard)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 28, alignment: .center)
            Text("Team").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 50)
            Text("W").frame(width: 32, alignment: .center)
            Text("L").frame(width: 32, alignment: .center)
            Text("PCT").frame(width: 46, alignment: .center)
            Text("L10").frame(width: 40, alignment: .center)
            Text("STK").frame(width: 40, alignment: .center)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.nbaSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}
