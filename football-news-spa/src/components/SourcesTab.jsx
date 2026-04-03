import { useState } from 'react'
import { RefreshCw, Star, ChevronDown, ChevronUp } from 'lucide-react'
import { refreshOne } from '../api.js'
import { scoreColor } from './ScoreBadge.jsx'

const FLAG = (cc) => {
  if (!cc) return ''
  return [...cc.toUpperCase()].map(c =>
    String.fromCodePoint(c.codePointAt(0) + 127397)
  ).join('')
}

const TYPE_GROUPS = [
  { type: 'newspaper',  label: 'Journaux' },
  { type: 'journalist', label: 'Journalistes' },
  { type: 'website',    label: 'Sites web' },
]

export default function SourcesTab({ store }) {
  const { sources, toggleSource } = store
  const [refreshing, setRefreshing] = useState({})
  const [collapsed, setCollapsed] = useState({})

  const handleRefresh = async (id) => {
    setRefreshing(prev => ({ ...prev, [id]: true }))
    try { await refreshOne(id) } finally {
      setRefreshing(prev => ({ ...prev, [id]: false }))
    }
  }

  return (
    <div className="flex flex-col h-full">
      <header
        className="flex-shrink-0 blur-bg border-b border-border"
        style={{
          background: 'rgba(15,17,23,0.88)',
          paddingTop: 'env(safe-area-inset-top, 12px)',
        }}
      >
        <div className="px-4 py-3 flex items-center justify-between">
          <h1 className="text-xl font-bold">Sources</h1>
          <span className="text-[11px] text-muted">
            {sources.filter(s => s.enabled).length} / {sources.length} actives
          </span>
        </div>
      </header>

      <div className="flex-1 scroll-area px-3 py-3 space-y-3">
        {TYPE_GROUPS.map(({ type, label }) => {
          const group = sources.filter(s => s.type === type)
          if (!group.length) return null
          const isCollapsed = collapsed[type]

          return (
            <div key={type} className="bg-card border border-border rounded-ios overflow-hidden">
              {/* Group header */}
              <button
                onClick={() => setCollapsed(p => ({ ...p, [type]: !p[type] }))}
                className="w-full flex items-center justify-between px-4 py-3 border-b border-border active:bg-white/5"
              >
                <span className="text-[11px] font-semibold uppercase tracking-wider text-faint">
                  {label} ({group.length})
                </span>
                {isCollapsed
                  ? <ChevronDown size={15} className="text-faint" />
                  : <ChevronUp size={15} className="text-faint" />
                }
              </button>

              {!isCollapsed && group.map((src, i) => (
                <div
                  key={src.id}
                  className={`flex items-center gap-3 px-4 py-3 ${
                    i < group.length - 1 ? 'border-b border-border/50' : ''
                  } ${!src.enabled ? 'opacity-40' : ''} transition-opacity duration-200`}
                >
                  {/* Flag + reliability dot */}
                  <div className="flex flex-col items-center gap-1 flex-shrink-0 w-8">
                    <span className="text-xl leading-none">{FLAG(src.country)}</span>
                    <span
                      className="w-1.5 h-1.5 rounded-full"
                      style={{ background: scoreColor(src.reliability) }}
                    />
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="text-[14px] font-semibold leading-tight truncate">
                      {src.name}
                    </p>
                    <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                      {/* Stars */}
                      <div className="flex">
                        {[1,2,3,4,5].map(i => (
                          <Star
                            key={i}
                            size={10}
                            fill={i <= src.reliability ? '#f59e0b' : 'transparent'}
                            strokeWidth={1.5}
                            className={i <= src.reliability ? 'text-yellow-400' : 'text-faint'}
                          />
                        ))}
                      </div>
                      {src.city && (
                        <span className="text-[11px] text-muted">{src.city}</span>
                      )}
                      {src.affiliation && (
                        <span className="text-[10px] px-1.5 py-px rounded-full"
                          style={{
                            color: '#a5b4fc',
                            background: 'rgba(99,102,241,0.12)',
                            border: '1px solid rgba(99,102,241,0.3)',
                          }}>
                          {src.affiliation}
                        </span>
                      )}
                    </div>
                    {/* Tags */}
                    {src.tags?.length > 0 && (
                      <div className="flex gap-1 mt-1 flex-wrap">
                        {src.tags.slice(0, 3).map(t => (
                          <span
                            key={t}
                            className="text-[10px] px-1.5 py-px rounded-full bg-white/5 border border-white/10 text-faint"
                          >
                            {t}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <button
                      onClick={() => handleRefresh(src.id)}
                      disabled={refreshing[src.id]}
                      className="p-1.5 rounded-full active:bg-white/10 transition-colors"
                      title="Actualiser"
                    >
                      <RefreshCw
                        size={14}
                        className={`${refreshing[src.id] ? 'animate-spin text-accent' : 'text-faint'}`}
                      />
                    </button>

                    {/* iOS Toggle */}
                    <button
                      onClick={() => toggleSource(src.id, !src.enabled)}
                      className={[
                        'w-11 h-6 rounded-full relative transition-colors duration-200 flex-shrink-0',
                        src.enabled ? 'bg-blue-500' : 'bg-white/15',
                      ].join(' ')}
                      aria-label={src.enabled ? 'Désactiver' : 'Activer'}
                    >
                      <span
                        className="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-md transition-transform duration-200"
                        style={{ transform: `translateX(${src.enabled ? '22px' : '2px'})` }}
                      />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )
        })}

        <div style={{ height: 'var(--tab-bar-h, 72px)' }} />
      </div>
    </div>
  )
}
