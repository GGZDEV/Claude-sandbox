import { TrendingUp, Radio, Clock, AlertTriangle } from 'lucide-react'
import { scoreColor, scoreLabel } from './ScoreBadge.jsx'

const FLAG = (cc) => {
  if (!cc) return ''
  return [...cc.toUpperCase()].map(c =>
    String.fromCodePoint(c.codePointAt(0) + 127397)
  ).join('')
}

const BUCKETS = [
  { label: 'Très fiable',   min: 4.5, max: 6,   score: 5 },
  { label: 'Fiable',        min: 3.5, max: 4.5,  score: 4 },
  { label: 'À vérifier',    min: 2.5, max: 3.5,  score: 3 },
  { label: 'Peu fiable',    min: 1.5, max: 2.5,  score: 2 },
  { label: 'Putaclick',     min: 0,   max: 1.5,  score: 1 },
]

export default function StatsTab({ store }) {
  const { stats, sources, articles: allArticles, lastUpdate } = store

  if (!stats) {
    return (
      <div className="flex items-center justify-center h-full text-muted">
        <div className="animate-pulse text-4xl">📊</div>
      </div>
    )
  }

  // Article count per source (from local articles array)
  const countBySource = {}
  allArticles.forEach(a => {
    const sid = a.source?.id ?? a.source_id
    countBySource[sid] = (countBySource[sid] ?? 0) + 1
  })

  const topSources = [...sources]
    .filter(s => s.enabled)
    .sort((a, b) => (countBySource[b.id] ?? 0) - (countBySource[a.id] ?? 0))
    .slice(0, 8)

  const bucketCounts = BUCKETS.map(b => ({
    ...b,
    count: allArticles.filter(a => a.scores.final_score >= b.min && a.scores.final_score < b.max).length,
  }))
  const maxCount = Math.max(...bucketCounts.map(b => b.count), 1)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header
        className="flex-shrink-0 blur-bg border-b border-border"
        style={{
          background: 'rgba(15,17,23,0.88)',
          paddingTop: 'env(safe-area-inset-top, 12px)',
        }}
      >
        <div className="px-4 py-3">
          <h1 className="text-xl font-bold">Statistiques</h1>
        </div>
      </header>

      <div className="flex-1 scroll-area px-4 py-4 space-y-5">

        {/* Overview cards */}
        <div className="grid grid-cols-2 gap-2.5">
          <StatCard
            icon={<TrendingUp size={20} className="text-blue-400" />}
            label="Articles"
            value={stats.total_articles.toLocaleString('fr-FR')}
          />
          <StatCard
            icon={<Radio size={20} className="text-green-400" />}
            label="Sources actives"
            value={stats.total_sources}
          />
          <StatCard
            icon={<TrendingUp size={20} className="text-yellow-400" />}
            label="Score moyen"
            value={`${stats.avg_final_score} / 5`}
            valueColor={scoreColor(stats.avg_final_score)}
          />
          <StatCard
            icon={<AlertTriangle size={20} className="text-orange-400" />}
            label="Clickbait moy."
            value={`${Math.round(stats.avg_clickbait_score * 100)}%`}
            valueColor={stats.avg_clickbait_score > 0.3 ? '#f97316' : '#22c55e'}
          />
        </div>

        {/* Last update */}
        {lastUpdate && (
          <div className="flex items-center gap-2 text-[11px] text-faint">
            <Clock size={12} />
            Mis à jour {lastUpdate.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
          </div>
        )}

        {/* Reliability distribution */}
        <Section title="Distribution fiabilité">
          <div className="space-y-2">
            {bucketCounts.map(b => {
              const color = scoreColor(b.score)
              const pct = (b.count / maxCount) * 100
              return (
                <div key={b.label} className="flex items-center gap-2">
                  <span
                    className="w-2 h-2 rounded-full flex-shrink-0"
                    style={{ background: color }}
                  />
                  <span className="text-[12px] text-white/70 w-24 flex-shrink-0">{b.label}</span>
                  <div className="flex-1 bg-border rounded-full h-1.5 overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{ width: `${pct}%`, background: color }}
                    />
                  </div>
                  <span className="text-[12px] text-faint w-6 text-right">{b.count}</span>
                </div>
              )
            })}
          </div>
        </Section>

        {/* Top sources */}
        <Section title="Flux les plus actifs">
          <div className="space-y-2">
            {topSources.map(src => {
              const count = countBySource[src.id] ?? 0
              const maxSrc = countBySource[topSources[0]?.id] ?? 1
              return (
                <div key={src.id} className="flex items-center gap-2">
                  <span className="text-sm">{FLAG(src.country)}</span>
                  <span className="text-[12px] text-white/80 flex-1 truncate">{src.name}</span>
                  <div className="w-16 bg-border rounded-full h-1.5 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-blue-500/70"
                      style={{ width: `${(count / maxSrc) * 100}%` }}
                    />
                  </div>
                  <span className="text-[11px] text-faint w-5 text-right">{count}</span>
                </div>
              )
            })}
          </div>
        </Section>

        <div style={{ height: 'var(--tab-bar-h, 72px)' }} />
      </div>
    </div>
  )
}

function StatCard({ icon, label, value, valueColor }) {
  return (
    <div className="bg-card border border-border rounded-ios p-3.5 flex flex-col gap-2">
      {icon}
      <div>
        <p className="text-[11px] text-muted">{label}</p>
        <p
          className="text-lg font-bold tracking-tight"
          style={valueColor ? { color: valueColor } : {}}
        >
          {value}
        </p>
      </div>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div className="bg-card border border-border rounded-ios overflow-hidden">
      <div className="px-3.5 py-2.5 border-b border-border">
        <h3 className="text-[11px] font-semibold uppercase tracking-wider text-faint">{title}</h3>
      </div>
      <div className="p-3.5">{children}</div>
    </div>
  )
}
