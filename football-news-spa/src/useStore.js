import { useState, useEffect, useCallback, useRef } from 'react'
import { fetchArticles, fetchSources, fetchStats, refreshAll, updateSource } from './api.js'

const DEFAULT_FILTER = {
  search: '', country: '', sourceType: '',
  minScore: 1, maxClickbait: 1, tag: '', sort: 'date',
}

export function useStore() {
  const [articles, setArticles]     = useState([])
  const [total, setTotal]           = useState(0)
  const [page, setPage]             = useState(1)
  const [sources, setSources]       = useState([])
  const [stats, setStats]           = useState(null)
  const [filter, setFilter]         = useState(DEFAULT_FILTER)
  const [loading, setLoading]       = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [lastUpdate, setLastUpdate] = useState(null)
  const debounceRef = useRef(null)

  // Load sources + stats once
  useEffect(() => {
    fetchSources().then(setSources).catch(console.error)
    fetchStats().then(setStats).catch(console.error)
  }, [])

  // Reload articles when filter/page changes (debounce search)
  useEffect(() => {
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => loadArticles(), filter.search ? 350 : 0)
    return () => clearTimeout(debounceRef.current)
  }, [filter, page])

  const loadArticles = useCallback(async () => {
    setLoading(true)
    try {
      const data = await fetchArticles({ ...filter, page, perPage: 40 })
      setArticles(data.articles)
      setTotal(data.total)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [filter, page])

  const refresh = useCallback(async () => {
    setRefreshing(true)
    try {
      await refreshAll()
      setLastUpdate(new Date())
      await new Promise(r => setTimeout(r, 2500))
      await Promise.all([
        fetchSources().then(setSources),
        fetchStats().then(setStats),
        loadArticles(),
      ])
    } finally {
      setRefreshing(false)
    }
  }, [loadArticles])

  const toggleSource = useCallback(async (id, enabled) => {
    setSources(prev => prev.map(s => s.id === id ? { ...s, enabled } : s))
    await updateSource(id, { enabled })
    loadArticles()
  }, [loadArticles])

  const updateFilter = useCallback((patch) => {
    setFilter(prev => ({ ...prev, ...patch }))
    setPage(1)
  }, [])

  const resetFilter = useCallback(() => {
    setFilter(DEFAULT_FILTER)
    setPage(1)
  }, [])

  const isFilterActive = Object.entries(filter).some(([k, v]) =>
    k === 'minScore' ? v > 1 : k === 'maxClickbait' ? v < 1 : Boolean(v)
  )

  const allTags = [...new Set(
    sources.filter(s => s.enabled).flatMap(s => s.tags ?? [])
  )].sort()

  return {
    articles, total, page, setPage,
    sources, stats, filter, updateFilter, resetFilter, isFilterActive,
    loading, refreshing, lastUpdate, refresh,
    toggleSource, allTags,
  }
}
