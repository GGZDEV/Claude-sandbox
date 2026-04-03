import SwiftUI

struct SourcesView: View {
    @EnvironmentObject var manager: FeedManager

    private var grouped: [(key: SourceType, sources: [Source])] {
        let order: [SourceType] = [.newspaper, .journalist, .website]
        return order.compactMap { type in
            let srcs = manager.sources.filter { $0.type == type }
            return srcs.isEmpty ? nil : (key: type, sources: srcs)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.key) { group in
                    Section {
                        ForEach(group.sources) { source in
                            SourceRow(source: source)
                                .environmentObject(manager)
                        }
                    } header: {
                        Label(group.key.label + "s",
                              systemImage: iconName(for: group.key))
                    }
                }
            }
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func iconName(for type: SourceType) -> String {
        switch type {
        case .newspaper:  return "newspaper"
        case .journalist: return "person.crop.circle.badge.checkmark"
        case .website:    return "globe"
        }
    }
}

// MARK: - Source Row

struct SourceRow: View {
    @EnvironmentObject var manager: FeedManager
    let source: Source

    @State private var isRefreshing = false

    var body: some View {
        HStack(spacing: 12) {
            // Flag + reliability dot
            VStack(spacing: 2) {
                Text(source.flag)
                    .font(.title2)
                Circle()
                    .fill(Article.color(for: Double(source.reliability)))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 36)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.system(size: 15, weight: .semibold))

                HStack(spacing: 6) {
                    // Stars
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= source.reliability ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i <= source.reliability
                                                 ? Color(hex: "#f59e0b")
                                                 : Color(.tertiaryLabel))
                        }
                    }

                    if let city = source.city {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(city)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    if let affil = source.affiliation {
                        AffiliationBadge(text: affil)
                    }
                }

                // Tags
                if !source.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(source.tags, id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { source.isEnabled },
                set: { _ in manager.toggle(source: source.id) }
            ))
            .labelsHidden()
            .tint(.blue)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                isRefreshing = true
                Task {
                    await manager.refreshSource(source.id)
                    isRefreshing = false
                }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            .tint(.blue)
        }
    }
}
