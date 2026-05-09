import SwiftUI

@MainActor
final class StandingsViewModel: ObservableObject {
    @Published var standings: [Standing] = []
    @Published var isLoading = false
    @Published var error: String?

    var eastStandings: [Standing] {
        standings.filter { $0.conference.lowercased() == "east" }
                 .sorted { $0.conferenceRank < $1.conferenceRank }
    }

    var westStandings: [Standing] {
        standings.filter { $0.conference.lowercased() == "west" }
                 .sorted { $0.conferenceRank < $1.conferenceRank }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            standings = try await NBAService.shared.fetchStandings()
        } catch {
            self.error = error.localizedDescription
        }
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
                    standingsHeader
                    let list = selectedConference == 0 ? vm.eastStandings : vm.westStandings
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, standing in
                        StandingRow(standing: standing, rank: index + 1)
                        if index < list.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 56)
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

    private var standingsHeader: some View {
        HStack {
            Text("#")
                .frame(width: 30)
            Text("Team")
            Spacer()
            Group {
                Text("W").frame(width: 32)
                Text("L").frame(width: 32)
                Text("PCT").frame(width: 50)
                Text("GB").frame(width: 40)
            }
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.nbaSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.nbaCard)
    }
}
