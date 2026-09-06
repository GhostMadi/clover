/** Форматы медиа поста. Маркер в URL / Storage: `…__ar-4x3…` — как в Flutter `PostAspectRatio`. */

export type PostAspectRatioKind = "1x1" | "4x3" | "16x9" | "9x16";

export type PostAspectRatio = {
  kind: PostAspectRatioKind;
  width: number;
  height: number;
  label: string;
  ratio: number;
};

export type PostGridSpan = { cross: number; main: number };

/** Сколько визуальных плиток в ряд: 2 (узкий) … 3 (макс в профиле). */
export type VisualCols = 2 | 3;

/** Ячеек на одну визуальную колонку (как 3 из 6 на телефоне). */
export const CELLS_PER_VISUAL = 3;

export function gridAxisCount(visualCols: VisualCols): number {
  return visualCols * CELLS_PER_VISUAL;
}

export const ASPECT_1X1: PostAspectRatio = { kind: "1x1", width: 1, height: 1, label: "1:1", ratio: 1 };
export const ASPECT_4X3: PostAspectRatio = { kind: "4x3", width: 4, height: 3, label: "4:3", ratio: 4 / 3 };
export const ASPECT_16X9: PostAspectRatio = { kind: "16x9", width: 16, height: 9, label: "16:9", ratio: 16 / 9 };
export const ASPECT_9X16: PostAspectRatio = { kind: "9x16", width: 9, height: 16, label: "9:16", ratio: 9 / 16 };

const BY_MARKER: Record<string, PostAspectRatio> = {
  "1x1": ASPECT_1X1,
  "4x3": ASPECT_4X3,
  "16x9": ASPECT_16X9,
  "9x16": ASPECT_9X16,
};

const ASPECT_RE = /__ar-(\d+)x(\d+)/i;

export function aspectFromMarker(marker?: string | null): PostAspectRatio {
  if (!marker?.trim()) return ASPECT_1X1;
  const normalized = marker.trim().toLowerCase().replace(/:/g, "x");
  return BY_MARKER[normalized] ?? ASPECT_1X1;
}

/** Читает `__ar-WxH` из пути URL обложки. */
export function aspectFromUrl(url: string): PostAspectRatio {
  if (!url.trim()) return ASPECT_1X1;
  let path = url;
  try {
    path = new URL(url).pathname;
  } catch {
    // relative / raw path
  }
  const match = ASPECT_RE.exec(path.toLowerCase());
  if (!match) return ASPECT_1X1;
  const w = Number(match[1]);
  const h = Number(match[2]);
  if (!w || !h || w <= 0 || h <= 0) return ASPECT_1X1;
  return aspectFromMarker(`${w}x${h}`);
}

function gridMainAxisCells(ratio: number, cross: number): number {
  const main = Math.round(cross / ratio);
  return Math.min(cross * 4, Math.max(1, main));
}

/**
 * Span плитки.
 * Обычные форматы — 1 визуальная колонка; 16:9 — вся ширина или 2 колонки.
 */
export function gridSpanForAspect(
  aspect: PostAspectRatio,
  visualCols: VisualCols,
  useFullRowForLandscape = false,
): PostGridSpan {
  const n = gridAxisCount(visualCols);
  const unit = CELLS_PER_VISUAL;

  if (aspect.kind === "16x9" && useFullRowForLandscape) {
    return {
      cross: n,
      main: gridMainAxisCells(aspect.ratio, n),
    };
  }

  if (aspect.kind === "16x9") {
    // минимум 2 в ряд (половина / две визуальные колонки)
    const pair = Math.min(n, unit * 2);
    return {
      cross: pair,
      main: gridMainAxisCells(aspect.ratio, pair),
    };
  }

  return {
    cross: unit,
    main: gridMainAxisCells(aspect.ratio, unit),
  };
}

/** Высота кадра в ленте/детали по ширине контейнера (как Flutter detailHeightForWidth). */
export function detailHeightForWidth(
  aspect: PostAspectRatio,
  width: number,
  viewportHeight = 800,
): number {
  const natural = width / aspect.ratio;
  if (aspect.kind === "9x16") {
    const maxHeight = viewportHeight * 0.72;
    return Math.min(maxHeight, Math.max(width * 0.9, natural));
  }
  return natural;
}
