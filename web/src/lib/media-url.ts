/** Public CDN for R2 Custom Domain (bytes). */
export const MEDIA_CDN_ORIGIN = "https://media.clover.com.kz";

/**
 * URL для `<img>` на вебе: same-origin `/media/...` → rewrite на CDN.
 *
 * Натив (мобилка) ходит на media.clover.com.kz напрямую и часто видит картинки,
 * а в браузере DNS / Brave Shields / фильтры режут этот хост → пустые превью.
 * Прокси через clover.com.kz снимает эту разницу.
 */
export function toWebMediaSrc(url: string | null | undefined): string {
  const raw = (url ?? "").trim();
  if (!raw) return "";
  try {
    const u = new URL(raw);
    if (u.hostname === "media.clover.com.kz") {
      return `/media${u.pathname}${u.search}${u.hash}`;
    }
  } catch {
    /* relative / invalid — as is */
  }
  return raw;
}
