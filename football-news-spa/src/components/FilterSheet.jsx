import { useEffect, useRef } from 'react'
import { X, RotateCcw } from 'lucide-react'
import TagChip from './TagChip.jsx'
import { scoreColor, scoreLabel } from './ScoreBadge.jsx'

const COUNTRIES = [
  { code: '', name: 'Tous' },
  { code: 'FR', name: '🇫🇷 France' },
  { code: 'ES', name: '🇪🇸 Espagne' },
  { code: 'IT', name: '🇮🇹 Italie' },
  { code: 'DE', name: '🇩🇪 Allemagne' },
  { code: 'GB', name: '🏴󠁧󠁢󠁥󠁮󠁧󠁿 Angleterre' },
  { code: 'TR', name: '🇹🇷 Turquie' },
]

const SOURCE_TYPES = [
  { value: '', label: 'Tous' },
  { value: 'newspaper', label: 'Journaux' },
  { value: 'journalist', label: 'Journalistes' },
  { value: 'website', label: 'Sites' },
]

const SORTS = [
  { value: 'date', label: 'Date' },
  { value: 'score', label: 'Fiabilité' },
]

export default function FilterSheet({ open, onClose, filter, onChange, onReset, allTags, isActive }) {
  const sheetRef = useRef(null)

  // Close on backdrop click
  useEffect(() => {
    if (!open) return
    const onKey = (e) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  if (!open) return null

  const sc = scoreColor(filter.minScore)
  const cbPct = Math.round(filter.maxClickbait * 100)

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      {/* Sheet */}
      <div
        ref={sheetRef}
        className="fixed inset-x-0 bottom-0 z-50 flex flex-col rounded-t-[20px] bg-panel border-t border-border spring-in"
        style={{ maxHeight: '90dvh', paddingBottom: 'env(safe-area-inset-bottom, 16px)' }}
      >
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 rounded-full bg-border" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border">
          <button
            onClick={onReset}
            className={`text-sm font-medium transition-colors ${isActive ? 'text-red-400' : 'text-faint cursor-default'}`}
            disabled={!isActive}
          >
            <span className="flex items-center gap-1.5"><RotateCcw size={14} /> Réinitialiser</span>
          </button>
          <h2 className="text-base font-semibold">Filtres</h2>
          <button onClick={onClose} className="text-muted hover:text-white transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Content */}
        <div className="overflow-y-auto flex-1 px-4 py-4 space-y-5">

          {/* Search */}
          <Section label="Recherche">
            <input
              type="search"
              placeholder="Joueur, club, transfert…"
              value={filter.search}
              onChange={e => onChange({ search: e.target.value })}
              className="w-full bg-card border border-border rounded-ios-sm px-3 py-2 text-sm text-white placeholder:text-faint outline-none focus:border-accent transition-colors"
            />
          </Section>

          {/* Sort */}
          <Section label="Trier par">
            <SegmentedControl
              options={SORTS}
              value={filter.sort}
              onChange={v => onChange({ sort: v })}
            />
          </Section>

          {/* Score */}
          <Section label={
            <span className="flex items-center gap-2">
              Score minimum
              <span className="text-[11px] font-bold px-1.5 py-0.5 rounded-full"
                style={{ color: sc, background: `${sc}22` }}>
                {filter.minScore.toFixed(1)} — {scoreLabel(filter.minScore)}
              </span>
            </span>
          }>
            <input
              type="range" min="1" max="5" step="0.5"
              value={filter.minScore}
              onChange={e => onChange({ minScore: parseFloat(e.target.value) })}
              className="w-full"
              style={{ accentColor: sc }}
            />
          </Section>

          {/* Anti-clickbait */}
          <Section label={
            <span className="flex items-center gap-2">
              Anti-putaclick
              <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                filter.maxClickbait < 1
                  ? 'text-orange-400 bg-orange-400/15'
                  : 'text-faint bg-white/5'
              }`}>
                {filter.maxClickbait < 1 ? `≤ ${cbPct}% clickbait` : 'Désactivé'}
              </span>
            </span>
          }>
            <input
              type="range" min="0" max="1" step="0.1"
              value={filter.maxClickbait}
              onChange={e => onChange({ maxClickbait: parseFloat(e.target.value) })}
              className="w-full"
              style={{ accentColor: '#f97316' }}
            />
            <p className="text-[11px] text-faint mt-1">
              Glissez vers la gauche pour masquer les articles clickbait.
            </p>
          </Section>

          {/* Country */}
          <Section label="Pays">
            <SegmentedControl
              options={COUNTRIES}
              value={filter.country}
              onChange={v => onChange({ country: v })}
              wrap
            />
          </Section>

          {/* Type */}
          <Section label="Type de source">
            <SegmentedControl
              options={SOURCE_TYPES}
              value={filter.sourceType}
              onChange={v => onChange({ sourceType: v })}
            />
          </Section>

          {/* Tags */}
          {allTags.length > 0 && (
            <Section label="Tags">
              <div className="flex flex-wrap gap-1.5">
                {allTags.map(t => (
                  <TagChip
                    key={t}
                    text={t}
                    active={filter.tag === t}
                    onClick={() => onChange({ tag: filter.tag === t ? '' : t })}
                  />
                ))}
              </div>
            </Section>
          )}
        </div>
      </div>
    </>
  )
}

function Section({ label, children }) {
  return (
    <div className="space-y-2">
      <label className="text-[11px] font-semibold uppercase tracking-wider text-faint">
        {label}
      </label>
      {children}
    </div>
  )
}

function SegmentedControl({ options, value, onChange, wrap = false }) {
  return (
    <div className={`flex gap-1 ${wrap ? 'flex-wrap' : ''}`}>
      {options.map(opt => (
        <button
          key={opt.value ?? opt.code}
          onClick={() => onChange(opt.value ?? opt.code)}
          className={[
            'flex-1 min-w-0 px-2.5 py-1.5 rounded-ios-sm text-[12px] font-medium transition-all duration-150 whitespace-nowrap',
            (opt.value ?? opt.code) === value
              ? 'bg-blue-500/20 border border-blue-500/50 text-blue-400'
              : 'bg-white/5 border border-white/8 text-muted hover:text-white',
          ].join(' ')}
        >
          {opt.label ?? opt.name}
        </button>
      ))}
    </div>
  )
}
