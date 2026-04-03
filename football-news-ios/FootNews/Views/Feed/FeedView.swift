import SwiftUI

struct FeedView: View {
    @EnvironmentObject var manager: FeedManager
    @State private var showFilters = false
    @State private var selectedTag: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {

                    // Quick tag bar
                    if !manager.availableTags.isEmpty {
                        tagBar
                    }

                    // Empty state
                    if manager.filteredArticles.isEmpty {
                        emptyState
                    } else {
                        // Article cards
                        ForEach(manager.filteredArticles) { article in
                            ArticleCardView(
                                article: article,
                                source: manager.source(for: article.sourceId)
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FootNews ⚽")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .refreshable {
                await manager.refreshAll()
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet()
                    .environmentObject(manager)
            }
            .task {
                if manager.allArticles.isEmpty {
                    await manager.refreshAll()
                }
            }
        }
    }

    // MARK: - Subviews

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Tous" reset chip
                TagChip(text: "Tous", isActive: manager.filter.tag.isEmpty) {
                    manager.filter.tag = ""
                    manager.filter.sourceId = ""
                }

                ForEach(manager.availableTags, id: \.self) { tag in
                    TagChip(text: tag, isActive: manager.filter.tag == tag) {
                        manager.filter.tag = manager.filter.tag == tag ? "" : tag
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var filterButton: some View {
        Button {
            showFilters = true
        } label: {
            Label("Filtres", systemImage: "line.3.horizontal.decrease.circle\(manager.filter.isActive ? ".fill" : "")")
                .labelStyle(.iconOnly)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(manager.filter.isActive ? Color.accentColor : .primary)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await manager.refreshAll() }
        } label: {
            if manager.isRefreshing {
                ProgressView().tint(.primary)
            } else {
                Label("Rafraîchir", systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
        }
        .disabled(manager.isRefreshing)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 52))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("Aucun article")
                .font(.title3.weight(.semibold))
            Text("Modifiez vos filtres ou rafraîchissez les flux.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if manager.filter.isActive {
                Button("Réinitialiser les filtres") {
                    manager.filter = FeedFilter()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
