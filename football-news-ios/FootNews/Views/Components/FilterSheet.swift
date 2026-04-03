import SwiftUI

struct FilterSheet: View {
    @EnvironmentObject var manager: FeedManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {

                // MARK: Search
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Joueur, club, transfert…", text: $manager.filter.searchText)
                            .autocorrectionDisabled()
                    }
                } header: { Text("Recherche") }

                // MARK: Sort
                Section {
                    Picker("Trier par", selection: $manager.filter.sort) {
                        ForEach(FeedFilter.SortOrder.allCases, id: \.self) { order in
                            Text(order.label).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Tri") }

                // MARK: Score
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Score minimum")
                            Spacer()
                            ScoreBadge(score: manager.filter.minScore)
                        }
                        Slider(value: $manager.filter.minScore, in: 1...5, step: 0.5)
                            .tint(Article.color(for: manager.filter.minScore))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Anti-putaclick max.")
                            Spacer()
                            Text(manager.filter.maxClickbait < 1.0
                                 ? "\(Int(manager.filter.maxClickbait * 100))%"
                                 : "Désactivé")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(manager.filter.maxClickbait < 0.4
                                                 ? Color(hex: "#22c55e")
                                                 : .secondary)
                        }
                        Slider(value: $manager.filter.maxClickbait, in: 0...1, step: 0.1)
                            .tint(Color(hex: "#f97316"))
                        Text("Glissez vers la gauche pour masquer le clickbait.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } header: { Text("Fiabilité") }

                // MARK: Country
                Section {
                    Picker("Pays", selection: $manager.filter.country) {
                        Text("Tous").tag("")
                        ForEach(countryOptions, id: \.code) { c in
                            Text("\(c.flag) \(c.name)").tag(c.code)
                        }
                    }
                } header: { Text("Pays") }

                // MARK: Source type
                Section {
                    Picker("Type", selection: $manager.filter.sourceType) {
                        Text("Tous").tag(Optional<SourceType>.none)
                        ForEach(SourceType.allCases, id: \.self) { type in
                            Text(type.label).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Type de source") }

                // MARK: Tags
                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(manager.availableTags, id: \.self) { tag in
                            TagChip(text: tag,
                                    isActive: manager.filter.tag == tag) {
                                manager.filter.tag = manager.filter.tag == tag ? "" : tag
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Tags") }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Réinitialiser") {
                        manager.filter = FeedFilter()
                    }
                    .foregroundStyle(manager.filter.isActive ? .red : .secondary)
                    .disabled(!manager.filter.isActive)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    struct CountryOption {
        let code: String
        let name: String
        var flag: String {
            let base: UInt32 = 127397
            return code.unicodeScalars.compactMap {
                Unicode.Scalar(base + $0.value).map { String($0) }
            }.joined()
        }
    }

    private let countryOptions: [CountryOption] = [
        .init(code: "FR", name: "France"),
        .init(code: "ES", name: "Espagne"),
        .init(code: "IT", name: "Italie"),
        .init(code: "DE", name: "Allemagne"),
        .init(code: "GB", name: "Angleterre"),
        .init(code: "TR", name: "Turquie"),
        .init(code: "PT", name: "Portugal"),
    ]
}

// MARK: - FlowLayout for tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map(\.size.height).max() ?? 0 }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            let rowHeight = row.map(\.size.height).max() ?? 0
            for item in row {
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct Item {
        let subview: LayoutSubview
        let size: CGSize
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Item]] {
        let maxWidth = proposal.width ?? 300
        var rows: [[Item]] = [[]]
        var x: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(proposal)
            if x + size.width > maxWidth, !rows.last!.isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(Item(subview: sv, size: size))
            x += size.width + spacing
        }
        return rows.filter { !$0.isEmpty }
    }
}
