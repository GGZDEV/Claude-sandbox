import { SourceTag } from "@/lib/types";

const TAG_STYLES: Record<string, string> = {
  Officiel: "bg-emerald-900/50 text-emerald-300 border-emerald-700",
  "Journal Catalan": "bg-red-900/50 text-red-300 border-red-700",
  "Journal Madrilène": "bg-purple-900/50 text-purple-300 border-purple-700",
  "Pro-Real Madrid": "bg-purple-900/50 text-purple-300 border-purple-700",
  "Pro-Barça": "bg-red-900/50 text-red-300 border-red-700",
  "Spécialiste Mercato": "bg-cyan-900/50 text-cyan-300 border-cyan-700",
  Tabloïd: "bg-orange-900/50 text-orange-300 border-orange-700",
  "Presse Sportive": "bg-zinc-700/50 text-zinc-300 border-zinc-600",
  Télévision: "bg-indigo-900/50 text-indigo-300 border-indigo-700",
  "Journaliste Indépendant": "bg-teal-900/50 text-teal-300 border-teal-700",
  "Agence de Presse": "bg-slate-700/50 text-slate-300 border-slate-600",
};

export function TagBadge({ tag }: { tag: SourceTag }) {
  const style = TAG_STYLES[tag] || "bg-zinc-700/50 text-zinc-300 border-zinc-600";
  return (
    <span
      className={`${style} inline-flex items-center rounded-md border px-1.5 py-0.5 text-xs font-medium`}
    >
      {tag}
    </span>
  );
}
