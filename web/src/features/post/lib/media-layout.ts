import {
  type PostAspectRatio,
  type PostGridSpan,
  type VisualCols,
  CELLS_PER_VISUAL,
  gridAxisCount,
  gridSpanForAspect,
} from "@/features/post/lib/aspect-ratio";

export type PostGridPlacement = PostGridSpan & {
  /** 0-based column start */
  col: number;
  /** 0-based row start */
  row: number;
};

/**
 * Раскладка сетки: до `visualCols` плиток в ряд (макс 3).
 * 16:9 — на всю ширину (1) или на 2 колонки.
 */
export function computeGridPlacements(
  aspects: PostAspectRatio[],
  visualCols: VisualCols = 3,
): PostGridPlacement[] {
  const n = gridAxisCount(visualCols);
  const colTop = Array.from({ length: n }, () => 0);
  const out: PostGridPlacement[] = [];
  const pairCross = Math.min(n, CELLS_PER_VISUAL * 2);

  function placementTop(startCol: number, cross: number): number {
    let top = colTop[startCol]!;
    for (let i = startCol + 1; i < startCol + cross; i++) {
      if (colTop[i]! > top) top = colTop[i]!;
    }
    return top;
  }

  function leftmostColForSpan(cross: number): number {
    let bestCol = 0;
    let bestTop = Number.POSITIVE_INFINITY;
    for (let c = 0; c <= n - cross; c++) {
      const top = placementTop(c, cross);
      if (top < bestTop) {
        bestTop = top;
        bestCol = c;
      }
    }
    return bestCol;
  }

  function occupySpan(span: PostGridSpan, startCol: number) {
    const row = placementTop(startCol, span.cross);
    out.push({ ...span, col: startCol, row });
    const newTop = row + span.main;
    for (let c = startCol; c < startCol + span.cross; c++) {
      colTop[c] = newTop;
    }
  }

  for (const aspect of aspects) {
    if (aspect.kind === "16x9") {
      const fullSpan = gridSpanForAspect(aspect, visualCols, true);
      const pairSpan = gridSpanForAspect(aspect, visualCols, false);
      const fullTop = placementTop(0, n);
      const pairCol = leftmostColForSpan(pairCross);
      const pairTop = placementTop(pairCol, pairCross);

      if (fullTop <= pairTop) {
        occupySpan(fullSpan, 0);
      } else {
        occupySpan(pairSpan, pairCol);
      }
      continue;
    }

    const span = gridSpanForAspect(aspect, visualCols, false);
    const col = leftmostColForSpan(span.cross);
    occupySpan(span, col);
  }

  return out;
}
