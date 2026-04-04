"use client";

import { useState, useMemo } from "react";
import { Article, Tier, SourceTag } from "@/lib/types";
import { ArticleCard } from "./ArticleCard";
import { FilterBar } from "./FilterBar";

export function ArticleList({ articles }: { articles: Article[] }) {
  const [selectedTiers, setSelectedTiers] = useState<Tier[]>([]);
  const [selectedTags, setSelectedTags] = useState<SourceTag[]>([]);
  const [showFilters, setShowFilters] = useState(false);

  const allTags = useMemo(() => {
    const tags = new Set<SourceTag>();
    articles.forEach((a) => a.source.tags.forEach((t) => tags.add(t)));
    return Array.from(tags).sort();
  }, [articles]);

  const filtered = useMemo(() => {
    return articles.filter((article) => {
      if (selectedTiers.length > 0 && !selectedTiers.includes(article.source.tier)) {
        return false;
      }
      if (
        selectedTags.length > 0 &&
        !article.source.tags.some((t) => selectedTags.includes(t))
      ) {
        return false;
      }
      return true;
    });
  }, [articles, selectedTiers, selectedTags]);

  return (
    <div>
      {/* Filter toggle */}
      <div className="mb-4 flex items-center justify-between">
        <p className="text-sm text-zinc-500">
          {filtered.length} article{filtered.length !== 1 ? "s" : ""}
          {selectedTiers.length > 0 || selectedTags.length > 0
            ? ` (filtré${filtered.length !== 1 ? "s" : ""})`
            : ""}
        </p>
        <button
          onClick={() => setShowFilters(!showFilters)}
          className="flex items-center gap-1.5 rounded-lg border border-zinc-700 px-3 py-1.5 text-xs font-medium text-zinc-400 transition-colors hover:border-zinc-500 hover:text-zinc-300"
        >
          <svg
            className="h-3.5 w-3.5"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25 2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0 1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0 0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z"
            />
          </svg>
          Filtres
          {(selectedTiers.length > 0 || selectedTags.length > 0) && (
            <span className="rounded-full bg-zinc-600 px-1.5 text-xs text-white">
              {selectedTiers.length + selectedTags.length}
            </span>
          )}
        </button>
      </div>

      {/* Filters panel */}
      {showFilters && (
        <div className="mb-6 rounded-xl border border-zinc-800 bg-zinc-900/50 p-4">
          <FilterBar
            allTags={allTags}
            selectedTags={selectedTags}
            selectedTiers={selectedTiers}
            onToggleTag={(tag) =>
              setSelectedTags((prev) =>
                prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
              )
            }
            onToggleTier={(tier) =>
              setSelectedTiers((prev) =>
                prev.includes(tier) ? prev.filter((t) => t !== tier) : [...prev, tier]
              )
            }
            onClearFilters={() => {
              setSelectedTags([]);
              setSelectedTiers([]);
            }}
          />
        </div>
      )}

      {/* Legend */}
      <div className="mb-4 flex flex-wrap items-center gap-3 text-xs text-zinc-500">
        <span className="flex items-center gap-1">
          <span className="inline-block h-2 w-2 rounded-full bg-emerald-500" /> Tier 1 — Officiel
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-block h-2 w-2 rounded-full bg-blue-500" /> Tier 2 — Fiable
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-block h-2 w-2 rounded-full bg-amber-500" /> Tier 3 — Rumeurs
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-block h-2 w-2 rounded-full bg-red-500" /> Tier 4 — Clickbait
        </span>
      </div>

      {/* Articles */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-8 text-center text-zinc-500">
            Aucun article ne correspond aux filtres sélectionnés.
          </div>
        ) : (
          filtered.map((article) => <ArticleCard key={article.id} article={article} />)
        )}
      </div>
    </div>
  );
}
