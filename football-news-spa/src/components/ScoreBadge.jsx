export function scoreColor(score) {
  if (score >= 4.5) return '#22c55e'
  if (score >= 3.5) return '#84cc16'
  if (score >= 2.5) return '#f59e0b'
  if (score >= 1.5) return '#f97316'
  return '#ef4444'
}

export function scoreLabel(score) {
  if (score >= 4.5) return 'Très fiable'
  if (score >= 3.5) return 'Fiable'
  if (score >= 2.5) return 'À vérifier'
  if (score >= 1.5) return 'Peu fiable'
  return 'Putaclick'
}

export default function ScoreBadge({ score, compact = false }) {
  const color = scoreColor(score)
  return (
    <span
      className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold border"
      style={{ color, background: `${color}18`, borderColor: `${color}44` }}
    >
      <span
        className="w-1.5 h-1.5 rounded-full flex-shrink-0"
        style={{ background: color }}
      />
      {!compact && <>{scoreLabel(score)} · </>}
      {score.toFixed(1)}
    </span>
  )
}
