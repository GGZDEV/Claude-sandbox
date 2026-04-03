import { Newspaper, BarChart2, ListChecks } from 'lucide-react'

const TABS = [
  { id: 'feed',    label: 'Fil',      Icon: Newspaper   },
  { id: 'stats',   label: 'Stats',    Icon: BarChart2   },
  { id: 'sources', label: 'Sources',  Icon: ListChecks  },
]

export default function BottomTabBar({ active, onChange }) {
  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 blur-bg border-t border-border"
      style={{
        background: 'rgba(15,17,23,0.85)',
        paddingBottom: 'env(safe-area-inset-bottom, 0px)',
      }}
    >
      <div className="flex">
        {TABS.map(({ id, label, Icon }) => {
          const isActive = active === id
          return (
            <button
              key={id}
              onClick={() => onChange(id)}
              className="flex-1 flex flex-col items-center justify-center gap-0.5 py-2 transition-all duration-150 active:scale-95"
            >
              <Icon
                size={24}
                strokeWidth={isActive ? 2.2 : 1.6}
                className="transition-colors duration-150"
                style={{ color: isActive ? '#3b82f6' : '#7a8299' }}
              />
              <span
                className="text-[10px] font-medium transition-colors duration-150"
                style={{ color: isActive ? '#3b82f6' : '#7a8299' }}
              >
                {label}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
