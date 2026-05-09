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

// Tappable news article row — opens link in Safari or shows reading sheet
struct ArticleRow: View {
    let article: Article
    @State private var showReader = false

    var body: some View {
        Button {
            if article.link != nil { showReader = true }
        } label: {
            HStack(spacing: 12) {
                if let url = article.imageURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFill() }
                        else { Color.nbaCard }
                    }
                    .frame(width: 80, height: 60)
                    .clipped()
                    .cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.headline)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if !article.description.isEmpty {
                        Text(article.description)
                            .font(.caption2)
                            .foregroundColor(.nbaSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Text(article.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.nbaSecondary)
                        if article.link != nil {
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption2)
                                .foregroundColor(.nbaGold)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.nbaCard)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showReader) {
            if let link = article.link {
                ArticleReaderSheet(article: article, url: link)
            }
        }
    }
}

struct ArticleReaderSheet: View {
    let article: Article
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let imgURL = article.imageURL {
                        AsyncImage(url: imgURL) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFit()
                            } else { EmptyView() }
                        }
                        .cornerRadius(12)
                    }
                    Text(article.headline)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text(article.timeAgo)
                        .font(.caption)
                        .foregroundColor(.nbaSecondary)
                    if !article.description.isEmpty {
                        Text(article.description)
                            .font(.body)
                            .foregroundColor(Color(white: 0.85))
                            .lineSpacing(5)
                    }
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "safari.fill")
                            Text("Read full article on ESPN")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.nbaBG)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nbaGold)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
            .background(Color.nbaBG.ignoresSafeArea())
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.nbaGold)
                }
            }
        }
    }
}
