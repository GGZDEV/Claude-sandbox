"use client";

import { Tier, SourceTag, TIER_LABELS } from "@/lib/types";

interface FilterBarProps {
  allTags: SourceTag[];
  selectedTags: SourceTag[];
  selectedTiers: Tier[];
  onToggleTag: (tag: SourceTag) => void;
  onToggleTier: (tier: Tier) => void;
  onClearFilters: () => void;
}

export function FilterBar({
  allTags,
  selectedTags,
  selectedTiers,
  onToggleTag,
  onToggleTier,
  onClearFilters,
}: FilterBarProps) {
  const hasFilters = selectedTags.length > 0 || selectedTiers.length > 0;

  return (
    <div className="space-y-3">
      {/* Tier filters */}
      <div>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-zinc-500">
          Fiabilité
        </h3>
        <div className="flex flex-wrap gap-2">
          {([1, 2, 3, 4] as Tier[]).map((tier) => {
            const config = TIER_LABELS[tier];
            const isActive = selectedTiers.includes(tier);
            return (
              <button
                key={tier}
                onClick={() => onToggleTier(tier)}
                className={`rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                  isActive
                    ? `${config.color} border-transparent text-white`
                    : "border-zinc-700 text-zinc-400 hover:border-zinc-500 hover:text-zinc-300"
                }`}
              >
                {config.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Tag filters */}
      <div>
        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-zinc-500">
          Type de source
        </h3>
        <div className="flex flex-wrap gap-2">
          {allTags.map((tag) => {
            const isActive = selectedTags.includes(tag);
            return (
              <button
                key={tag}
                onClick={() => onToggleTag(tag)}
                className={`rounded-md border px-2 py-1 text-xs font-medium transition-colors ${
                  isActive
                    ? "border-zinc-500 bg-zinc-700 text-white"
                    : "border-zinc-700 text-zinc-400 hover:border-zinc-500 hover:text-zinc-300"
                }`}
              >
                {tag}
              </button>
            );
          })}
        </div>
      </div>

      {/* Clear */}
      {hasFilters && (
        <button
          onClick={onClearFilters}
          className="text-xs text-zinc-500 underline hover:text-zinc-300"
        >
          Effacer les filtres
        </button>
      )}
    </div>
  );
}
