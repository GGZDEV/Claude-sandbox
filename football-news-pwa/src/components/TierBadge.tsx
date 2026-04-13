import { Tier, TIER_LABELS } from "@/lib/types";

export function TierBadge({ tier }: { tier: Tier }) {
  const config = TIER_LABELS[tier];
  return (
    <span
      title={config.description}
      className={`${config.color} inline-flex items-center rounded-full px-2 py-0.5 text-xs font-bold text-white`}
    >
      {config.label}
    </span>
  );
}
