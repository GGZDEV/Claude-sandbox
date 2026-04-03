import SwiftUI

struct ArticleCardView: View {
    let article: Article
    let source: Source?

    @State private var showSafari = false

    var body: some View {
        Button { showSafari = true } label: {
            VStack(alignment: .leading, spacing: 0) {

                // Hero image
                if let imgURL = article.imageURL {
                    AsyncImage(url: imgURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                               .aspectRatio(16/9, contentMode: .fill)
                               .frame(maxWidth: .infinity)
                               .frame(height: 170)
                               .clipped()
                        default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {

                    // Source + date row
                    HStack(spacing: 6) {
                        if let src = source {
                            Circle()
                                .fill(typeColor(src.type))
                                .frame(width: 7, height: 7)
                            Text(src.flag + " " + src.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if let city = src.city {
                                Text("· \(city)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                        Spacer()
                        Text(article.relativeDate)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }

                    // Title
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Summary
                    if let summary = article.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Bottom row: score + affiliation + tags
                    HStack(alignment: .center, spacing: 6) {
                        ScoreBadge(score: article.finalScore)

                        if let affil = source?.affiliation {
                            AffiliationBadge(text: affil)
                        }

                        Spacer()

                        // Top 2 tags
                        if let tags = source?.tags.prefix(2) {
                            ForEach(Array(tags), id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }

                    // Clickbait flags
                    if !article.clickbaitFlags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(article.clickbaitFlags, id: \.self) { flag in
                                    ClickbaitFlag(text: flag)
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .contextMenu {
            Button {
                UIPasteboard.general.url = article.articleURL
            } label: {
                Label("Copier le lien", systemImage: "link")
            }
            ShareLink(item: article.articleURL) {
                Label("Partager", systemImage: "square.and.arrow.up")
            }
            Button { showSafari = true } label: {
                Label("Ouvrir dans Safari", systemImage: "safari")
            }
        }
        .fullScreenCover(isPresented: $showSafari) {
            SafariView(url: article.articleURL)
                .ignoresSafeArea()
        }
    }

    private func typeColor(_ type: SourceType) -> Color {
        switch type {
        case .newspaper:  return Color(hex: "#6366f1")
        case .journalist: return Color(hex: "#0ea5e9")
        case .website:    return Color(hex: "#8b5cf6")
        }
    }
}
