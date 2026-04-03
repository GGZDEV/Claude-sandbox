export default function TagChip({ text, active = false, onClick }) {
  return (
    <button
      onClick={onClick}
      className={[
        'inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium transition-all duration-150 whitespace-nowrap',
        active
          ? 'bg-blue-500/20 border border-blue-500/50 text-blue-400'
          : 'bg-white/5 border border-white/10 text-muted',
        onClick ? 'cursor-pointer active:scale-95' : 'cursor-default',
      ].join(' ')}
    >
      {text}
    </button>
  )
}
