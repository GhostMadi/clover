/** Shared emoji wallpaper helpers. См. docs/business/chat-emoji-wallpaper.md */

const MAX_CHAT_WALLPAPER_EMOJIS = 8;

export function normalizeWallpaperEmojis(raw: string, max = MAX_CHAT_WALLPAPER_EMOJIS): string[] {
  const out: string[] = [];
  for (const ch of [...raw]) {
    if (!ch.trim()) continue;
    if (out.includes(ch)) continue;
    out.push(ch);
    if (out.length >= max) break;
  }
  return out;
}

export function parseWallpaperEmojis(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is string => typeof x === "string" && x.trim().length > 0)
    .map((x) => x.trim())
    .slice(0, MAX_CHAT_WALLPAPER_EMOJIS);
}

type ScatterItem = {
  emoji: string;
  left: number;
  top: number;
  size: number;
  rotate: number;
};

function hashSeed(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = 0x1fffffff & (h + s.charCodeAt(i));
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
  h ^= h >> 11;
  return 0x1fffffff & (h + ((0x00003fff & h) << 15));
}

function mulberry32(seed: number) {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

export function buildEmojiScatter(emojis: string[], seed: string, count = 28): ScatterItem[] {
  if (emojis.length === 0) return [];
  const rnd = mulberry32(hashSeed(seed + emojis.join("")));
  const items: ScatterItem[] = [];
  for (let i = 0; i < count; i++) {
    items.push({
      emoji: emojis[i % emojis.length]!,
      left: rnd() * 92 + 2,
      top: rnd() * 92 + 2,
      size: 18 + rnd() * 22,
      rotate: rnd() * 60 - 30,
    });
  }
  return items;
}
