import { ExternalLink, Share2 } from 'lucide-react'
import ScoreBadge from './ScoreBadge.jsx'
import TagChip from './TagChip.jsx'

const TYPE_DOT = {
  newspaper:  '#6366f1',
  journalist: '#0ea5e9',
  website:    '#8b5cf6',
}

const FLAG = (cc) => {
  if (!cc) return ''
  const offset = 127397
  return [...cc.toUpperCase()].map(c => String.fromCodePoint(c.codePointAt(0) + offset)).join('')
}

function relTime(iso) {
  const diff = Date.now() - new Date(iso).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1)  return 'à l\'instant'
  if (m < 60) return `${m} min`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h`
  return `${Math.floor(h / 24)}j`
}

export default function ArticleCard({ article, source, onTagClick }) {
  const { title, url, summary, published_at, image_url, scores } = article
  const dotColor = TYPE_DOT[source?.type] ?? '#7a8299'

  return (
    <article className="bg-card rounded-ios border border-border overflow-hidden transition-all duration-150 active:scale-[0.99] press-active">
      {/* Hero image */}
      {image_url && (
        <img
          src={image_url}
          alt=""
          loading="lazy"
          className="w-full object-cover"
          style={{ height: 160 }}
          onError={e => e.target.closest('.img-wrap')?.remove()}
        />
      )}

      <div className="p-3.5 flex flex-col gap-2.5">
        {/* Source row */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-1.5 min-w-0">
            <span
              className="w-2 h-2 rounded-full flex-shrink-0"
              style={{ background: dotColor }}
            />
            <span className="text-[11px] font-semibold text-muted truncate">
              {FLAG(source?.country)} {source?.name}
              {source?.city && (
                <span className="text-faint font-normal"> · {source.city}</span>
              )}
            </span>
          </div>
          <span className="text-[11px] text-faint flex-shrink-0">
            {relTime(published_at)}
          </span>
        </div>

        {/* Title */}
        <a
          href={url}
          target="_blank"
          rel="noopener noreferrer"
          className="text-[15px] font-semibold leading-snug text-white/90 hover:text-blue-400 transition-colors line-clamp-3"
        >
          {title}
        </a>

        {/* Summary */}
        {summary && (
          <p className="text-[12px] text-muted leading-relaxed line-clamp-2">
            {summary}
          </p>
        )}

        {/* Score + affiliation */}
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-1.5 flex-wrap">
            <ScoreBadge score={scores.final_score} />
            {source?.affiliation && (
              <span className="text-[10px] px-2 py-0.5 rounded-full border"
                style={{
                  color: '#a5b4fc',
                  background: 'rgba(99,102,241,0.1)',
                  borderColor: 'rgba(99,102,241,0.35)',
                }}>
                {source.affiliation}
              </span>
            )}
          </div>
          {/* Top 2 tags */}
          <div className="flex gap-1 flex-wrap">
            {(source?.tags ?? []).slice(0, 2).map(t => (
              <TagChip key={t} text={t} onClick={() => onTagClick?.(t)} />
            ))}
          </div>
        </div>

        {/* Clickbait flags */}
        {scores.clickbait_flags?.length > 0 && (
          <div className="flex gap-1 flex-wrap">
            {scores.clickbait_flags.map(f => (
              <span
                key={f}
                className="text-[10px] px-1.5 py-0.5 rounded"
                style={{
                  color: '#f87171',
                  background: '#2d1a1a',
                  border: '1px solid #5c2e2e',
                }}
              >
                {f}
              </span>
            ))}
          </div>
        )}

        {/* Action row */}
        <div className="flex items-center justify-end gap-3 pt-0.5 border-t border-border/50">
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 text-[11px] text-muted hover:text-accent transition-colors"
          >
            <ExternalLink size={12} /> Lire
          </a>
          <button
            onClick={() => navigator.share?.({ title, url }) ?? navigator.clipboard?.writeText(url)}
            className="flex items-center gap-1 text-[11px] text-muted hover:text-accent transition-colors"
          >
            <Share2 size={12} /> Partager
          </button>
        </div>
      </div>
    </article>
  )
}
