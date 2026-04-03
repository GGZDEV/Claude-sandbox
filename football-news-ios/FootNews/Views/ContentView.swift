import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: FeedManager

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Fil", systemImage: "newspaper.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SourcesView()
                .tabItem {
                    Label("Sources", systemImage: "list.bullet.rectangle.fill")
                }
        }
        .tint(.blue)
    }
}

// MARK: - Stats View

struct StatsView: View {
    @EnvironmentObject var manager: FeedManager

    var body: some View {
        NavigationStack {
            List {
                // Overview
                Section {
                    StatRow(label: "Articles total",
                            value: "\(manager.allArticles.count)",
                            icon: "doc.text.fill", color: .blue)
                    StatRow(label: "Sources actives",
                            value: "\(manager.sources.filter(\.isEnabled).count)",
                            icon: "antenna.radiowaves.left.and.right", color: .green)
                    if let date = manager.lastRefreshDate {
                        StatRow(label: "Dernière MAJ",
                                value: date.formatted(date: .omitted, time: .shortened),
                                icon: "clock.fill", color: .orange)
                    }
                } header: { Text("Vue d'ensemble") }

                // Reliability distribution
                Section {
                    ForEach(reliabilityBuckets, id: \.label) { bucket in
                        HStack {
                            Circle().fill(bucket.color).frame(width: 10, height: 10)
                            Text(bucket.label)
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(bucket.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            // Mini bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(bucket.color.opacity(0.8))
                                .frame(
                                    width: CGFloat(bucket.count) / CGFloat(max(1, manager.allArticles.count)) * 80,
                                    height: 8
                                )
                        }
                    }
                } header: { Text("Distribution fiabilité") }

                // Top sources by article count
                Section {
                    ForEach(topSources.prefix(8), id: \.id) { src in
                        HStack {
                            Text(src.flag)
                            Text(src.name)
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Spacer()
                            Text("\(articleCount(for: src.id))")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: { Text("Flux les plus actifs") }
            }
            .navigationTitle("Statistiques")
        }
    }

    private var reliabilityBuckets: [(label: String, color: Color, count: Int)] {
        let articles = manager.allArticles
        return [
            ("Très fiable (4.5–5)", Article.color(for: 5), articles.filter { $0.finalScore >= 4.5 }.count),
            ("Fiable (3.5–4.5)",    Article.color(for: 4), articles.filter { $0.finalScore >= 3.5 && $0.finalScore < 4.5 }.count),
            ("À vérifier (2.5–3.5)", Article.color(for: 3), articles.filter { $0.finalScore >= 2.5 && $0.finalScore < 3.5 }.count),
            ("Peu fiable (1.5–2.5)", Article.color(for: 2), articles.filter { $0.finalScore >= 1.5 && $0.finalScore < 2.5 }.count),
            ("Putaclick (<1.5)",    Article.color(for: 1), articles.filter { $0.finalScore < 1.5 }.count),
        ]
    }

    private var topSources: [Source] {
        manager.sources
            .filter(\.isEnabled)
            .sorted { articleCount(for: $0.id) > articleCount(for: $1.id) }
    }

    private func articleCount(for sourceId: String) -> Int {
        manager.allArticles.filter { $0.sourceId == sourceId }.count
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(label)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
