/* ============================================================
   FootNews — Frontend App
   ============================================================ */

const API = "";  // same origin; change to "http://localhost:8000" for dev

// ---- State ----
const state = {
  page: 1,
  perPage: 30,
  sort: "date",
  filters: {
    search: "",
    country: "",
    type: "",
    minScore: 1,
    maxClickbait: 1,
    tag: "",
    sourceId: "",
  },
  sources: [],
  loading: false,
};

// ---- Utils ----
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

const COUNTRY_FLAGS = { FR:"🇫🇷", ES:"🇪🇸", IT:"🇮🇹", DE:"🇩🇪", GB:"🏴󠁧󠁢󠁥󠁮󠁧󠁿", TR:"🇹🇷", PT:"🇵🇹", NL:"🇳🇱" };
const TYPE_LABELS = { newspaper: "Journal", journalist: "Journaliste", website: "Site web" };

function scoreClass(score) {
  if (score >= 4.5) return "score-5";
  if (score >= 3.5) return "score-4";
  if (score >= 2.5) return "score-3";
  if (score >= 1.5) return "score-2";
  return "score-1";
}

function scoreLabel(score) {
  if (score >= 4.5) return "Très fiable";
  if (score >= 3.5) return "Fiable";
  if (score >= 2.5) return "À vérifier";
  if (score >= 1.5) return "Peu fiable";
  return "Putaclick";
}

function starsHtml(n) {
  return [1,2,3,4,5].map(i =>
    `<span class="${i <= n ? "star-on" : ""}">★</span>`
  ).join("");
}

function relTime(isoStr) {
  const diff = Date.now() - new Date(isoStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "à l'instant";
  if (mins < 60) return `il y a ${mins} min`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `il y a ${hrs}h`;
  const days = Math.floor(hrs / 24);
  return `il y a ${days}j`;
}

function showToast(msg, duration = 3000) {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.remove("hidden");
  setTimeout(() => t.classList.add("hidden"), duration);
}

function setLoading(on) {
  state.loading = on;
  $("#loading").classList.toggle("hidden", !on);
}

// ---- API calls ----
async function apiFetch(path) {
  const res = await fetch(API + path);
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json();
}

async function apiPost(path) {
  const res = await fetch(API + path, { method: "POST" });
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json();
}

async function apiPatch(path, body) {
  const res = await fetch(API + path, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return res.json();
}

// ---- Build query string ----
function buildQuery() {
  const p = new URLSearchParams();
  p.set("page", state.page);
  p.set("per_page", state.perPage);
  p.set("sort", state.sort);
  if (state.filters.search)      p.set("search", state.filters.search);
  if (state.filters.country)     p.set("country", state.filters.country);
  if (state.filters.minScore > 1) p.set("min_score", state.filters.minScore);
  if (state.filters.maxClickbait < 1) p.set("max_clickbait", state.filters.maxClickbait);
  if (state.filters.tag)         p.set("tag", state.filters.tag);
  if (state.filters.sourceId)    p.set("source_id", state.filters.sourceId);
  return p.toString();
}

// ---- Render articles ----
function renderArticleCard(a) {
  const src = a.source;
  const sc = a.scores;
  const cls = scoreClass(sc.final_score);
  const flag = COUNTRY_FLAGS[src.country] || "";
  const typeLabel = TYPE_LABELS[src.type] || src.type;
  const hasImage = !!a.image_url;

  const tagsHtml = (src.tags || []).map(t =>
    `<span class="tag" data-tag="${t}">${t}</span>`
  ).join("");

  const flagsHtml = (sc.clickbait_flags || []).map(f =>
    `<span class="flag" title="Signal de clickbait">${f}</span>`
  ).join("");

  const affiliationHtml = src.affiliation
    ? `<span class="affiliation-badge">${src.affiliation}</span>`
    : "";

  const imageHtml = hasImage
    ? `<img class="card-image" src="${escHtml(a.image_url)}" alt="" loading="lazy" onerror="this.remove()" />`
    : "";

  return `
    <article class="card">
      ${imageHtml}
      <div class="card-body">
        <div class="card-meta">
          <div class="source-badge">
            <span class="source-type-dot ${src.type}"></span>
            <span class="source-name" title="${escHtml(src.name)}">
              ${flag} ${escHtml(src.name)}
              ${src.city ? `<span style="opacity:.5"> · ${escHtml(src.city)}</span>` : ""}
            </span>
          </div>
          <span class="card-date">${relTime(a.published_at)}</span>
        </div>

        <div class="card-title">
          <a href="${escHtml(a.url)}" target="_blank" rel="noopener noreferrer">
            ${escHtml(a.title)}
          </a>
        </div>

        ${a.summary ? `<p class="card-summary">${escHtml(a.summary)}</p>` : ""}

        <div class="card-footer">
          <div style="display:flex;flex-wrap:wrap;gap:4px;align-items:center">
            <span class="score-badge ${cls}" title="Score de fiabilité : source ${sc.source_reliability}/5, clickbait ${(sc.clickbait_score*100).toFixed(0)}%">
              ${scoreLabel(sc.final_score)} · ${sc.final_score.toFixed(1)}
            </span>
            ${affiliationHtml}
          </div>
          <div style="display:flex;flex-wrap:wrap;gap:4px">
            ${tagsHtml}
          </div>
        </div>

        ${flagsHtml ? `<div class="clickbait-flags">${flagsHtml}</div>` : ""}
      </div>
    </article>
  `;
}

function escHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ---- Render pagination ----
function renderPagination(total) {
  const totalPages = Math.ceil(total / state.perPage);
  if (totalPages <= 1) { $("#pagination").innerHTML = ""; return; }

  const pages = [];
  pages.push(`<button class="page-btn" ${state.page === 1 ? "disabled" : ""} data-page="${state.page - 1}">← Précédent</button>`);

  for (let i = 1; i <= totalPages; i++) {
    if (i === 1 || i === totalPages || (i >= state.page - 2 && i <= state.page + 2)) {
      pages.push(`<button class="page-btn ${i === state.page ? "active" : ""}" data-page="${i}">${i}</button>`);
    } else if (i === state.page - 3 || i === state.page + 3) {
      pages.push(`<span style="color:var(--text-faint);padding:0 4px">…</span>`);
    }
  }

  pages.push(`<button class="page-btn" ${state.page === totalPages ? "disabled" : ""} data-page="${state.page + 1}">Suivant →</button>`);
  $("#pagination").innerHTML = pages.join("");
}

// ---- Main fetch & render ----
async function loadArticles() {
  setLoading(true);
  try {
    const data = await apiFetch(`/api/articles?${buildQuery()}`);
    const feed = $("#feed");

    if (!data.articles.length) {
      feed.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">📭</div>
          <h3>Aucun article trouvé</h3>
          <p>Essayez de modifier vos filtres ou de rafraîchir les flux.</p>
        </div>`;
      $("#pagination").innerHTML = "";
      return;
    }

    feed.innerHTML = data.articles.map(renderArticleCard).join("");
    renderPagination(data.total);

    // Tag click → filter
    $$(".tag", feed).forEach(t => {
      t.addEventListener("click", e => {
        e.preventDefault();
        e.stopPropagation();
        setTagFilter(t.dataset.tag);
      });
    });
  } catch (err) {
    console.error(err);
    showToast("Erreur lors du chargement des articles");
  } finally {
    setLoading(false);
  }
}

// ---- Stats ----
async function loadStats() {
  try {
    const s = await apiFetch("/api/stats");
    $("#stats-bar").innerHTML = `
      <span class="stat-item"><strong>${s.total_articles.toLocaleString("fr-FR")}</strong> articles</span>
      <span class="stat-item"><strong>${s.total_sources}</strong> sources actives</span>
      <span class="stat-item">Score moyen : <strong>${s.avg_final_score}/5</strong></span>
      <span class="stat-item">Clickbait moyen : <strong>${(s.avg_clickbait_score * 100).toFixed(0)}%</strong></span>
    `;
  } catch {}
}

// ---- Sources panel ----
async function loadSources() {
  try {
    state.sources = await apiFetch("/api/sources");
    renderSourcesPanel();
  } catch (err) {
    console.error(err);
  }
}

function renderSourcesPanel() {
  const list = $("#sources-list");
  const grouped = {};
  for (const s of state.sources) {
    const group = s.type;
    if (!grouped[group]) grouped[group] = [];
    grouped[group].push(s);
  }

  const typeOrder = ["newspaper", "journalist", "website"];
  const typeNames = { newspaper: "Journaux", journalist: "Journalistes", website: "Sites web" };

  let html = "";
  for (const type of typeOrder) {
    const sources = grouped[type];
    if (!sources) continue;
    html += `<div class="sources-group-header" style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--text-faint);padding:8px 4px 4px;font-weight:600">${typeNames[type]}</div>`;
    for (const s of sources) {
      const flag = COUNTRY_FLAGS[s.country] || "";
      const starsStr = starsHtml(s.reliability);
      const lastFetched = s.last_fetched ? relTime(s.last_fetched) : "jamais";
      const errorBadge = s.error_count > 2 ? `<span style="color:var(--score-1);font-size:10px">⚠ ${s.error_count} erreurs</span>` : "";
      html += `
        <div class="source-row ${s.enabled ? "" : "disabled"}" data-id="${s.id}">
          <div class="source-row-info">
            <div class="source-row-name">${flag} ${escHtml(s.name)}</div>
            <div class="source-row-meta">
              <span class="reliability-stars">${starsStr}</span>
              ${s.city ? `<span>${escHtml(s.city)}</span>` : ""}
              ${s.affiliation ? `<span class="affiliation-badge">${escHtml(s.affiliation)}</span>` : ""}
              <span style="color:var(--text-faint)">maj ${lastFetched}</span>
              ${errorBadge}
            </div>
            <div style="margin-top:4px;display:flex;gap:4px;flex-wrap:wrap">
              ${(s.tags || []).map(t => `<span class="tag" style="font-size:10px">${t}</span>`).join("")}
            </div>
          </div>
          <label class="toggle" title="${s.enabled ? "Désactiver" : "Activer"}">
            <input type="checkbox" data-source-id="${s.id}" ${s.enabled ? "checked" : ""} />
            <span class="toggle-slider"></span>
          </label>
        </div>
      `;
    }
  }
  list.innerHTML = html;

  // Toggle handlers
  $$("input[data-source-id]", list).forEach(cb => {
    cb.addEventListener("change", async () => {
      const id = cb.dataset.sourceId;
      await apiPatch(`/api/sources/${id}`, { enabled: cb.checked });
      const src = state.sources.find(s => s.id === id);
      if (src) src.enabled = cb.checked;
      cb.closest(".source-row").classList.toggle("disabled", !cb.checked);
      showToast(cb.checked ? "Source activée" : "Source désactivée");
      loadArticles();
      loadStats();
    });
  });
}

// ---- Tag filter ----
function setTagFilter(tag) {
  state.filters.tag = tag;
  state.page = 1;
  renderActiveTagFilters();
  loadArticles();
}

function renderActiveTagFilters() {
  const container = $("#active-tags");
  if (!state.filters.tag) { container.innerHTML = ""; return; }
  container.innerHTML = `
    <span class="tag active removable" data-tag="${state.filters.tag}">
      Tag : ${escHtml(state.filters.tag)}
    </span>
  `;
  container.querySelector(".tag").addEventListener("click", () => {
    state.filters.tag = "";
    renderActiveTagFilters();
    loadArticles();
  });
}

// ---- Event wiring ----
let searchTimer = null;

function wireFilters() {
  const searchInput = $("#filter-search");
  searchInput.addEventListener("input", () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      state.filters.search = searchInput.value;
      state.page = 1;
      loadArticles();
    }, 400);
  });

  const scoreRange = $("#filter-score");
  const scoreVal = $("#filter-score-val");
  scoreRange.addEventListener("input", () => {
    state.filters.minScore = parseFloat(scoreRange.value);
    scoreVal.textContent = scoreRange.value;
  });
  scoreRange.addEventListener("change", () => { state.page = 1; loadArticles(); });

  const cbRange = $("#filter-clickbait");
  const cbVal = $("#filter-clickbait-val");
  cbRange.addEventListener("input", () => {
    const v = parseFloat(cbRange.value);
    state.filters.maxClickbait = v;
    cbVal.textContent = v === 1 ? "max" : `${(v * 100).toFixed(0)}%`;
  });
  cbRange.addEventListener("change", () => { state.page = 1; loadArticles(); });

  $("#filter-country").addEventListener("change", e => {
    state.filters.country = e.target.value;
    state.page = 1;
    loadArticles();
  });

  $("#filter-type").addEventListener("change", e => {
    state.filters.type = e.target.value;
    state.page = 1;
    loadArticles();
  });

  $("#filter-sort").addEventListener("change", e => {
    state.sort = e.target.value;
    state.page = 1;
    loadArticles();
  });

  $("#btn-reset-filters").addEventListener("click", () => {
    state.filters = { search: "", country: "", type: "", minScore: 1, maxClickbait: 1, tag: "", sourceId: "" };
    state.sort = "date";
    state.page = 1;
    $("#filter-search").value = "";
    $("#filter-score").value = 1;
    $("#filter-score-val").textContent = "1";
    $("#filter-clickbait").value = 1;
    $("#filter-clickbait-val").textContent = "max";
    $("#filter-country").value = "";
    $("#filter-type").value = "";
    $("#filter-sort").value = "date";
    renderActiveTagFilters();
    loadArticles();
  });

  // Pagination
  $("#pagination").addEventListener("click", e => {
    const btn = e.target.closest(".page-btn");
    if (!btn || btn.disabled) return;
    state.page = parseInt(btn.dataset.page, 10);
    window.scrollTo({ top: 0, behavior: "smooth" });
    loadArticles();
  });

  // Refresh button
  $("#btn-refresh").addEventListener("click", async () => {
    const btn = $("#btn-refresh");
    btn.disabled = true;
    btn.querySelector("span").textContent = "En cours…";
    try {
      await apiPost("/api/refresh");
      showToast("Rafraîchissement des flux lancé…");
      setTimeout(() => { loadArticles(); loadStats(); }, 3000);
    } catch {
      showToast("Erreur lors du rafraîchissement");
    } finally {
      btn.disabled = false;
      btn.querySelector("span").textContent = "Rafraîchir";
    }
  });

  // Sources panel
  $("#btn-sources").addEventListener("click", () => {
    loadSources();
    $("#sources-panel").classList.remove("hidden");
    $("#sources-overlay").classList.remove("hidden");
  });

  const closePanel = () => {
    $("#sources-panel").classList.add("hidden");
    $("#sources-overlay").classList.add("hidden");
  };
  $("#btn-close-sources").addEventListener("click", closePanel);
  $("#sources-overlay").addEventListener("click", closePanel);
}

// ---- Init ----
async function init() {
  wireFilters();
  await Promise.all([loadArticles(), loadStats()]);
}

document.addEventListener("DOMContentLoaded", init);
