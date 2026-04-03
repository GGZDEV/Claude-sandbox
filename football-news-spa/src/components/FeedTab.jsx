import { useState, useRef, useCallback } from 'react'
import { RefreshCw, SlidersHorizontal, ChevronLeft, ChevronRight } from 'lucide-react'
import ArticleCard from './ArticleCard.jsx'
import FilterSheet from './FilterSheet.jsx'
import TagChip from './TagChip.jsx'

export default function FeedTab({ store }) {
  const {
    articles, total, page, setPage,
    filter, updateFilter, resetFilter, isFilterActive,
    loading, refreshing, refresh, allTags,
    sources,
  } = store

  const [filterOpen, setFilterOpen] = useState(false)
  const scrollRef = useRef(null)
  const totalPages = Math.ceil(total / 40)

  const sourceMap = Object.fromEntries(sources.map(s => [s.id, s]))

  const handleTagClick = useCallback((tag) => {
    updateFilter({ tag: filter.tag === tag ? '' : tag })
  }, [filter.tag, updateFilter])

  const goPage = (p) => {
    setPage(p)
    scrollRef.current?.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header
        className="flex-shrink-0 blur-bg border-b border-border z-30"
        style={{
          background: 'rgba(15,17,23,0.88)',
          paddingTop: 'env(safe-area-inset-top, 12px)',
        }}
      >
        <div className="flex items-center justify-between px-4 py-3">
          <h1 className="text-xl font-bold tracking-tight">
            ⚽ <span className="text-white">FootNews</span>
          </h1>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setFilterOpen(true)}
              className="p-2 rounded-full transition-colors active:bg-white/10"
              title="Filtres"
            >
              <SlidersHorizontal
                size={20}
                className="transition-colors"
                style={{ color: isFilterActive ? '#3b82f6' : '#7a8299' }}
                strokeWidth={isFilterActive ? 2.2 : 1.8}
              />
            </button>
            <button
              onClick={refresh}
              disabled={refreshing}
              className="p-2 rounded-full transition-colors active:bg-white/10"
              title="Rafraîchir"
            >
              <RefreshCw
                size={20}
                className={`transition-all ${refreshing ? 'animate-spin text-accent' : 'text-muted'}`}
                strokeWidth={1.8}
              />
            </button>
          </div>
        </div>

        {/* Tag scroll bar */}
        {allTags.length > 0 && (
          <div className="overflow-x-auto no-scrollbar px-4 pb-3">
            <div className="flex gap-1.5 w-max">
              <TagChip
                text="Tous"
                active={!filter.tag}
                onClick={() => updateFilter({ tag: '' })}
              />
              {allTags.map(t => (
                <TagChip
                  key={t}
                  text={t}
                  active={filter.tag === t}
                  onClick={() => updateFilter({ tag: filter.tag === t ? '' : t })}
                />
              ))}
            </div>
          </div>
        )}
      </header>

      {/* Feed */}
      <div ref={scrollRef} className="flex-1 scroll-area px-3 py-3 space-y-3">
        {loading && articles.length === 0 ? (
          <Skeleton />
        ) : articles.length === 0 ? (
          <EmptyState isFiltered={isFilterActive} onReset={resetFilter} />
        ) : (
          <>
            {articles.map(a => (
              <ArticleCard
                key={a.id}
                article={a}
                source={sourceMap[a.source?.id ?? a.source_id]}
                onTagClick={handleTagClick}
              />
            ))}

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-center gap-2 py-4">
                <button
                  onClick={() => goPage(page - 1)}
                  disabled={page === 1}
                  className="p-2 rounded-full bg-card border border-border disabled:opacity-30"
                >
                  <ChevronLeft size={18} className="text-muted" />
                </button>
                <span className="text-sm text-muted px-2">
                  {page} / {totalPages}
                </span>
                <button
                  onClick={() => goPage(page + 1)}
                  disabled={page === totalPages}
                  className="p-2 rounded-full bg-card border border-border disabled:opacity-30"
                >
                  <ChevronRight size={18} className="text-muted" />
                </button>
              </div>
            )}
          </>
        )}
        <div style={{ height: 'var(--tab-bar-h, 72px)' }} />
      </div>

      <FilterSheet
        open={filterOpen}
        onClose={() => setFilterOpen(false)}
        filter={filter}
        onChange={updateFilter}
        onReset={() => { resetFilter(); setFilterOpen(false) }}
        allTags={allTags}
        isActive={isFilterActive}
      />
    </div>
  )
}

function Skeleton() {
  return (
    <div className="space-y-3">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="bg-card rounded-ios border border-border overflow-hidden animate-pulse">
          <div className="h-36 bg-border/40" />
          <div className="p-3.5 space-y-2.5">
            <div className="h-3 bg-border rounded w-1/3" />
            <div className="h-4 bg-border rounded w-full" />
            <div className="h-4 bg-border rounded w-4/5" />
            <div className="h-3 bg-border rounded w-2/3" />
          </div>
        </div>
      ))}
    </div>
  )
}

function EmptyState({ isFiltered, onReset }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center gap-4">
      <span className="text-5xl">📭</span>
      <div>
        <p className="text-base font-semibold text-white/80">Aucun article</p>
        <p className="text-sm text-muted mt-1">
          {isFiltered ? 'Modifiez vos filtres.' : 'Rafraîchissez les flux.'}
        </p>
      </div>
      {isFiltered && (
        <button
          onClick={onReset}
          className="px-4 py-2 bg-accent/20 border border-accent/40 text-accent rounded-ios-sm text-sm font-medium"
        >
          Réinitialiser les filtres
        </button>
      )}
    </div>
  )
}
