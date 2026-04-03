import Foundation
import Combine

// MARK: - Filter State

struct FeedFilter: Equatable {
    var searchText: String = ""
    var country: String = ""       // "" = all
    var sourceType: SourceType? = nil
    var minScore: Double = 1.0
    var maxClickbait: Double = 1.0
    var tag: String = ""
    var sourceId: String = ""
    var sort: SortOrder = .date

    enum SortOrder: String, CaseIterable {
        case date  = "date"
        case score = "score"
        var label: String { self == .date ? "Date" : "Fiabilité" }
    }

    var isActive: Bool {
        !searchText.isEmpty || !country.isEmpty || sourceType != nil
        || minScore > 1.0 || maxClickbait < 1.0 || !tag.isEmpty || !sourceId.isEmpty
    }
}

// MARK: - FeedManager

@MainActor
final class FeedManager: ObservableObject {

    // MARK: Published state
    @Published var sources: [Source] = []
    @Published var allArticles: [Article] = []
    @Published var filter = FeedFilter()
    @Published var isRefreshing = false
    @Published var lastRefreshDate: Date? = nil
    @Published var errorMessage: String? = nil

    // MARK: Persistence keys
    private let enabledKey  = "source_enabled"
    private let articlesKey = "cached_articles"

    // MARK: Init
    init() {
        sources = loadSourceStates()
        allArticles = loadCachedArticles()
    }

    // MARK: - Filtered articles

    var filteredArticles: [Article] {
        var result = allArticles.filter { article in
            guard let src = source(for: article.sourceId), src.isEnabled else { return false }

            if !filter.searchText.isEmpty {
                let q = filter.searchText.lowercased()
                guard article.title.lowercased().contains(q)
                   || (article.summary?.lowercased().contains(q) ?? false) else { return false }
            }
            if !filter.country.isEmpty {
                guard src.country == filter.country else { return false }
            }
            if let type = filter.sourceType {
                guard src.type == type else { return false }
            }
            if filter.minScore > 1.0 {
                guard article.finalScore >= filter.minScore else { return false }
            }
            if filter.maxClickbait < 1.0 {
                guard article.clickbaitScore <= filter.maxClickbait else { return false }
            }
            if !filter.tag.isEmpty {
                guard src.tags.contains(filter.tag) else { return false }
            }
            if !filter.sourceId.isEmpty {
                guard article.sourceId == filter.sourceId else { return false }
            }
            return true
        }

        switch filter.sort {
        case .date:
            result.sort { $0.publishedAt > $1.publishedAt }
        case .score:
            result.sort { $0.finalScore != $1.finalScore
                ? $0.finalScore > $1.finalScore
                : $0.publishedAt > $1.publishedAt }
        }
        return result
    }

    // All tags across enabled sources
    var availableTags: [String] {
        let tags = sources.filter(\.isEnabled).flatMap(\.tags)
        return Array(Set(tags)).sorted()
    }

    var availableCountries: [String] {
        Array(Set(sources.map(\.country))).sorted()
    }

    // MARK: - Source helpers

    func source(for id: String) -> Source? {
        sources.first { $0.id == id }
    }

    func toggle(source id: String) {
        guard let idx = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[idx].isEnabled.toggle()
        saveSourceStates()
    }

    // MARK: - Refresh

    func refreshAll() async {
        isRefreshing = true
        errorMessage = nil

        let enabled = sources.filter(\.isEnabled)
        await withTaskGroup(of: [Article].self) { group in
            for src in enabled {
                group.addTask { [src] in
                    await self.fetchSource(src)
                }
            }
            var fresh: [Article] = []
            for await batch in group { fresh.append(contentsOf: batch) }

            // Merge: keep existing, add new
            var existing = Dictionary(uniqueKeysWithValues: allArticles.map { ($0.id, $0) })
            for art in fresh { existing[art.id] = art }

            allArticles = Array(existing.values)
                .sorted { $0.publishedAt > $1.publishedAt }
                .prefix(500)
                .map { $0 }

            saveArticles()
            lastRefreshDate = .now
        }

        isRefreshing = false
    }

    func refreshSource(_ id: String) async {
        guard let src = source(for: id) else { return }
        let batch = await fetchSource(src)
        var existing = Dictionary(uniqueKeysWithValues: allArticles.map { ($0.id, $0) })
        for art in batch { existing[art.id] = art }
        allArticles = Array(existing.values).sorted { $0.publishedAt > $1.publishedAt }
        saveArticles()
    }

    // MARK: - Private fetch

    private func fetchSource(_ source: Source) async -> [Article] {
        guard let url = URL(string: source.feedURL) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let raw = RSSParser.parse(data: data)
            return raw.map { item in
                let (cbScore, flags) = ClickbaitDetector.detect(item.title)
                let final = ClickbaitDetector.finalScore(
                    sourceReliability: source.reliability,
                    clickbaitScore: cbScore
                )
                return Article(
                    id: "\(source.id)_\(item.id)",
                    sourceId: source.id,
                    title: item.title,
                    articleURL: item.url,
                    summary: item.summary,
                    publishedAt: item.publishedAt,
                    author: item.author,
                    imageURL: item.imageURL,
                    sourceReliability: source.reliability,
                    clickbaitScore: cbScore,
                    finalScore: final,
                    clickbaitFlags: flags
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Persistence

    private func loadSourceStates() -> [Source] {
        var srcs = Source.allSources
        guard let data = UserDefaults.standard.data(forKey: enabledKey),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else { return srcs }
        for i in srcs.indices {
            if let enabled = dict[srcs[i].id] { srcs[i].isEnabled = enabled }
        }
        return srcs
    }

    private func saveSourceStates() {
        let dict = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0.isEnabled) })
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: enabledKey)
        }
    }

    private func loadCachedArticles() -> [Article] {
        guard let data = UserDefaults.standard.data(forKey: articlesKey),
              let articles = try? JSONDecoder().decode([Article].self, from: data) else { return [] }
        return articles
    }

    private func saveArticles() {
        if let data = try? JSONEncoder().encode(allArticles) {
            UserDefaults.standard.set(data, forKey: articlesKey)
        }
    }
}
