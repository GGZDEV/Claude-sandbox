const BASE = '/api'

async function get(path) {
  const res = await fetch(BASE + path)
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
  return res.json()
}

async function post(path) {
  const res = await fetch(BASE + path, { method: 'POST' })
  if (!res.ok) throw new Error(`${res.status}`)
  return res.json()
}

async function patch(path, body) {
  const res = await fetch(BASE + path, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  return res.json()
}

export function fetchArticles(params = {}) {
  const q = new URLSearchParams()
  q.set('page', params.page ?? 1)
  q.set('per_page', params.perPage ?? 40)
  q.set('sort', params.sort ?? 'date')
  if (params.search)        q.set('search', params.search)
  if (params.country)       q.set('country', params.country)
  if (params.minScore > 1)  q.set('min_score', params.minScore)
  if (params.maxClickbait < 1) q.set('max_clickbait', params.maxClickbait)
  if (params.tag)           q.set('tag', params.tag)
  if (params.sourceId)      q.set('source_id', params.sourceId)
  return get(`/articles?${q}`)
}

export const fetchSources = () => get('/sources')
export const fetchStats   = () => get('/stats')
export const refreshAll   = () => post('/refresh')
export const refreshOne   = (id) => post(`/refresh/${id}`)
export const updateSource = (id, body) => patch(`/sources/${id}`, body)
