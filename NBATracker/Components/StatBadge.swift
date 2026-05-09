import SwiftUI

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.nbaSecondary)
        }
        .frame(minWidth: 60)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.nbaCard)
        .cornerRadius(10)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .nbaGold))
                .scaleEffect(1.3)
            Text("Loading...")
                .foregroundColor(.nbaSecondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nbaBG)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.nbaRed)
            Text(message)
                .foregroundColor(.nbaSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again", action: retry)
                .font(.headline)
                .foregroundColor(.nbaBG)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.nbaGold)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nbaBG)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.nbaGold)
                .frame(width: 4, height: 18)
                .cornerRadius(2)
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.nbaGold)
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal)
    }
}
