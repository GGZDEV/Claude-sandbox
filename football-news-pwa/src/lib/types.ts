export type Tier = 1 | 2 | 3 | 4;

export type SourceTag =
  | "Officiel"
  | "Journal Catalan"
  | "Journal Madrilène"
  | "Pro-Real Madrid"
  | "Pro-Barça"
  | "Spécialiste Mercato"
  | "Tabloïd"
  | "Presse Sportive"
  | "Télévision"
  | "Journaliste Indépendant"
  | "Agence de Presse";

export interface Source {
  id: string;
  name: string;
  url: string;
  feedUrl: string;
  tier: Tier;
  tags: SourceTag[];
  country: string;
  countryFlag: string;
  logo?: string;
  description: string;
}

export interface Article {
  id: string;
  title: string;
  link: string;
  description: string;
  pubDate: string;
  source: Source;
  imageUrl?: string;
}

export const TIER_LABELS: Record<Tier, { label: string; color: string; description: string }> = {
  1: {
    label: "Tier 1",
    color: "bg-emerald-500",
    description: "Source officielle ou très fiable",
  },
  2: {
    label: "Tier 2",
    color: "bg-blue-500",
    description: "Source généralement fiable",
  },
  3: {
    label: "Tier 3",
    color: "bg-amber-500",
    description: "Source parfois fiable, rumeurs fréquentes",
  },
  4: {
    label: "Tier 4",
    color: "bg-red-500",
    description: "Source peu fiable, clickbait fréquent",
  },
};
