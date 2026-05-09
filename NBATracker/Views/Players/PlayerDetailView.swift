import SwiftUI

struct PlayerDetailView: View {
    let player: Player

    var body: some View {
        ZStack {
            Color.nbaBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    infoSection
                    statsUnavailableNote
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(player.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.nbaGold.opacity(0.2), Color.nbaBG],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nbaGold.opacity(0.4), Color.nbaRed.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(player.initials)
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.white)
                }
                Text(player.fullName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text(player.positionDisplay)
                        .font(.caption.bold())
                        .foregroundColor(.nbaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.nbaGold.opacity(0.15))
                        .cornerRadius(8)

                    if let jersey = player.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }

                    if let team = player.team {
                        HStack(spacing: 4) {
                            TeamLogoView(team: team, size: 20)
                            Text(team.abbreviation)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Profile")
                .padding(.bottom, 12)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                infoCell(label: "Height",  value: player.height  ?? "N/A")
                infoCell(label: "Weight",  value: player.weight.map { "\($0) lbs" } ?? "N/A")
                infoCell(label: "Country", value: player.country ?? "N/A")
                infoCell(label: "College", value: player.college ?? "N/A")
                if let year = player.draftYear {
                    infoCell(label: "Draft Year", value: "\(year)")
                    infoCell(
                        label: "Draft Pick",
                        value: player.draftNumber.map { "Round \(player.draftRound ?? 0), #\($0)" } ?? "N/A"
                    )
                }
            }
            .background(Color.nbaCard)
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.nbaSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.nbaCard)
    }

    private var statsUnavailableNote: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Season Stats")
                .padding(.horizontal)
            HStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.nbaGold)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stats require a premium API plan")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("Upgrade at balldontlie.io to unlock season averages")
                        .font(.caption)
                        .foregroundColor(.nbaSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.nbaCard)
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }
}
