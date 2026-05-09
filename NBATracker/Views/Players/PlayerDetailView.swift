import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    let team: Team?

    var body: some View {
        ZStack {
            Color.nbaBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    infoGrid
                    if player.isInjured { injuryBanner }
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
                colors: [Color(hex: team?.color ?? "1D428A").opacity(0.35), Color.nbaBG],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 14) {
                PlayerHeadshotView(player: player, size: 110)
                Text(player.fullName).font(.title2.bold()).foregroundColor(.white)
                HStack(spacing: 12) {
                    badge(player.position, color: .nbaGold)
                    Text("#\(player.jersey)").font(.caption.bold()).foregroundColor(.white)
                    if let team {
                        HStack(spacing: 4) {
                            TeamLogoView(team: team, size: 20)
                            Text(team.abbreviation).font(.caption.bold()).foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.vertical, 28)
        }
    }

    private var infoGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Profile")
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                infoCell("Height",  player.displayHeight)
                infoCell("Weight",  player.displayWeight)
                if let age = player.age { infoCell("Age", "\(age)") }
                if let college = player.college, !college.isEmpty { infoCell("College", college) }
                if let city = player.birthCity, let country = player.birthCountry {
                    infoCell("Hometown", "\(city), \(country)")
                } else if let country = player.birthCountry {
                    infoCell("Country", country)
                }
            }
            .background(Color.nbaCard).cornerRadius(14).padding(.horizontal)
        }
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.nbaSecondary)
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.nbaCard)
    }

    private var injuryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "cross.fill")
                .font(.system(size: 16))
                .foregroundColor(.nbaRed)
                .frame(width: 36, height: 36)
                .background(Color.nbaRed.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(player.injuryStatus ?? "Injured")
                    .font(.subheadline.bold()).foregroundColor(.nbaRed)
                if let detail = player.injuryDetail, !detail.isEmpty {
                    Text(detail).font(.caption).foregroundColor(.nbaSecondary).lineLimit(3)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.nbaRed.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.nbaRed.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold()).foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15)).cornerRadius(8)
    }
}
