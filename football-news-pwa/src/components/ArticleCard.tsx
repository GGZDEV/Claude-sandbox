import { Article } from "@/lib/types";
import { TierBadge } from "./TierBadge";
import { TagBadge } from "./TagBadge";

function timeAgo(dateStr: string): string {
  const now = Date.now();
  const then = new Date(dateStr).getTime();
  const diffMs = now - then;
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return "À l'instant";
  if (minutes < 60) return `il y a ${minutes}min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `il y a ${hours}h`;
  const days = Math.floor(hours / 24);
  return `il y a ${days}j`;
}

export function ArticleCard({ article }: { article: Article }) {
  const { source } = article;

  return (
    <a
      href={article.link}
      target="_blank"
      rel="noopener noreferrer"
      className="group block rounded-xl border border-zinc-800 bg-zinc-900 p-4 transition-colors hover:border-zinc-600 hover:bg-zinc-800/80"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          {/* Source header */}
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <span className="text-sm font-medium text-zinc-400">
              {source.countryFlag} {source.name}
            </span>
            <TierBadge tier={source.tier} />
            <span className="text-xs text-zinc-500">{timeAgo(article.pubDate)}</span>
          </div>

          {/* Title */}
          <h3 className="mb-2 text-base font-semibold leading-snug text-zinc-100 group-hover:text-white">
            {article.title}
          </h3>

          {/* Description */}
          {article.description && (
            <p className="mb-3 line-clamp-2 text-sm leading-relaxed text-zinc-400">
              {article.description}
            </p>
          )}

          {/* Tags */}
          <div className="flex flex-wrap gap-1.5">
            {source.tags.map((tag) => (
              <TagBadge key={tag} tag={tag} />
            ))}
          </div>
        </div>

        {/* Tier indicator bar */}
        <div
          className={`mt-1 h-12 w-1 flex-shrink-0 rounded-full ${
            source.tier === 1
              ? "bg-emerald-500"
              : source.tier === 2
                ? "bg-blue-500"
                : source.tier === 3
                  ? "bg-amber-500"
                  : "bg-red-500"
          }`}
        />
      </div>
    </a>
  );
}
