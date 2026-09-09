/**
 * Chat candy accents = AppPalette.light softs (жвачка / мультик).
 * Не следуют dark svc-токенам — иначе тусклый «космос».
 */

export type ChatAccentClasses = {
  fill: string;
  ink: string;
  onFill: string;
  meta: string;
  border: string;
};

const SLOTS: ChatAccentClasses[] = [
  {
    fill: "bg-[color:var(--chat-candy-blue)]",
    ink: "text-[color:var(--chat-candy-blue-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-border-blue)]",
  },
  {
    fill: "bg-[color:var(--chat-candy-orange)]",
    ink: "text-[color:var(--chat-candy-orange-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-orange-ink)]/25",
  },
  {
    fill: "bg-[color:var(--chat-candy-lilac)]",
    ink: "text-[color:var(--chat-candy-lilac-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-lilac-ink)]/30",
  },
  {
    fill: "bg-[color:var(--chat-candy-yellow)]",
    ink: "text-[color:var(--chat-candy-yellow-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-yellow-ink)]/30",
  },
  {
    fill: "bg-[color:var(--chat-candy-rose)]",
    ink: "text-[color:var(--chat-candy-rose-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-rose-ink)]/30",
  },
  {
    fill: "bg-[color:var(--chat-candy-cyan)]",
    ink: "text-[color:var(--chat-candy-cyan-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-border-blue)]",
  },
  {
    fill: "bg-[color:var(--chat-candy-mint)]",
    ink: "text-[color:var(--chat-candy-mint-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-border-green)]",
  },
  {
    fill: "bg-[color:var(--chat-candy-lime)]",
    ink: "text-[color:var(--chat-candy-mint-ink)]",
    onFill: "text-[color:var(--chat-candy-on)]",
    meta: "text-[color:var(--chat-candy-meta)]",
    border: "border-[color:var(--chat-candy-border-green)]",
  },
];

export const CHAT_MINE_ACCENT: ChatAccentClasses = {
  fill: "bg-[color:var(--chat-candy-mine)]",
  ink: "text-[color:var(--chat-candy-mint-ink)]",
  onFill: "text-[color:var(--chat-candy-on)]",
  meta: "text-[color:var(--chat-candy-meta)]",
  border: "border-[color:var(--chat-candy-border-green)]",
};

function stableIndex(seed: string): number {
  const raw = seed.trim();
  if (!raw) return 0;
  let hash = 0;
  for (let i = 0; i < raw.length; i++) {
    hash = 0x1fffffff & (hash + raw.charCodeAt(i));
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

export function chatAccentForSeed(seed: string): ChatAccentClasses {
  return SLOTS[stableIndex(seed) % SLOTS.length]!;
}
