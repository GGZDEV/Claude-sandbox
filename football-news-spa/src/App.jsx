import { useState } from 'react'
import { useStore } from './useStore.js'
import BottomTabBar from './components/BottomTabBar.jsx'
import FeedTab from './components/FeedTab.jsx'
import StatsTab from './components/StatsTab.jsx'
import SourcesTab from './components/SourcesTab.jsx'

export default function App() {
  const [tab, setTab] = useState('feed')
  const store = useStore()

  return (
    <div
      className="fixed inset-0 flex flex-col bg-bg overflow-hidden"
      style={{ paddingBottom: 'var(--tab-bar-h, 56px)' }}
    >
      <div className="flex-1 overflow-hidden relative">
        {/* Mount all tabs, only show active — keeps scroll position */}
        <div className={`absolute inset-0 ${tab === 'feed' ? '' : 'hidden'}`}>
          <FeedTab store={store} />
        </div>
        <div className={`absolute inset-0 ${tab === 'stats' ? '' : 'hidden'}`}>
          <StatsTab store={store} />
        </div>
        <div className={`absolute inset-0 ${tab === 'sources' ? '' : 'hidden'}`}>
          <SourcesTab store={store} />
        </div>
      </div>

      <BottomTabBar active={tab} onChange={setTab} />
    </div>
  )
}
