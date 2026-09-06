"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { aspectFromUrl, detailHeightForWidth } from "@/features/post/lib/aspect-ratio";
import type { FeedPostMedia } from "@/features/post/lib/parse-feed";

type PostMediaCarouselProps = {
  media: FeedPostMedia[];
  title?: string;
  fallbackEmoji?: string;
};

function heightForUrl(url: string, width: number, vh: number): number {
  return detailHeightForWidth(aspectFromUrl(url), width, vh);
}

/**
 * Галерея поста: высота кадра lerp'ится вместе со свайпом (быстро, без ожидания snap).
 */
export function PostMediaCarousel({
  media,
  title = "",
  fallbackEmoji = "☘️",
}: PostMediaCarouselProps) {
  const rootRef = useRef<HTMLDivElement>(null);
  const scrollerRef = useRef<HTMLDivElement>(null);
  const measuredRef = useRef<{ width: number; vh: number } | null>(null);
  const dotRef = useRef(0);
  const rafRef = useRef<number | null>(null);
  const [dotIndex, setDotIndex] = useState(0);
  const [ready, setReady] = useState(false);

  const count = media.length;
  const safeDot = count === 0 ? 0 : Math.min(dotIndex, count - 1);
  const firstAspect = aspectFromUrl(media[0]?.url ?? "");

  const syncFromScroll = useCallback(() => {
    const el = scrollerRef.current;
    const root = rootRef.current;
    const measured = measuredRef.current;
    if (!el || !root || !measured || count === 0) return;

    const w = el.clientWidth;
    if (w <= 0) return;

    if (count === 1) {
      root.style.height = `${heightForUrl(media[0].url, measured.width, measured.vh)}px`;
      return;
    }

    const maxScroll = w * (count - 1);
    const x = Math.max(0, Math.min(maxScroll, el.scrollLeft));
    const progress = x / w;
    const i0 = Math.min(count - 2, Math.floor(progress));
    const i1 = i0 + 1;
    const t = Math.min(1, Math.max(0, progress - i0));

    const h0 = heightForUrl(media[i0].url, measured.width, measured.vh);
    const h1 = heightForUrl(media[i1].url, measured.width, measured.vh);
    root.style.height = `${h0 + (h1 - h0) * t}px`;

    const nextDot = Math.round(progress);
    if (nextDot !== dotRef.current) {
      dotRef.current = nextDot;
      setDotIndex(nextDot);
    }
  }, [count, media]);

  const scheduleSync = useCallback(() => {
    if (rafRef.current != null) return;
    rafRef.current = window.requestAnimationFrame(() => {
      rafRef.current = null;
      syncFromScroll();
    });
  }, [syncFromScroll]);

  useEffect(() => {
    const el = rootRef.current;
    if (!el) return;

    const updateMeasure = () => {
      const w = el.clientWidth;
      if (w <= 0) return;
      measuredRef.current = { width: w, vh: window.innerHeight };
      setReady(true);
      syncFromScroll();
    };
    updateMeasure();

    const ro = new ResizeObserver(updateMeasure);
    ro.observe(el);
    window.addEventListener("resize", updateMeasure);
    return () => {
      ro.disconnect();
      window.removeEventListener("resize", updateMeasure);
    };
  }, [syncFromScroll]);

  useEffect(() => {
    const el = scrollerRef.current;
    if (!el) return;
    el.addEventListener("scroll", scheduleSync, { passive: true });
    return () => {
      el.removeEventListener("scroll", scheduleSync);
      if (rafRef.current != null) window.cancelAnimationFrame(rafRef.current);
    };
  }, [scheduleSync]);

  const goTo = (i: number) => {
    const el = scrollerRef.current;
    if (!el || count <= 1) return;
    const clamped = Math.max(0, Math.min(count - 1, i));
    dotRef.current = clamped;
    setDotIndex(clamped);
    el.scrollTo({ left: clamped * el.clientWidth, behavior: "smooth" });
  };

  if (count === 0) {
    return (
      <div
        ref={rootRef}
        className="relative flex w-full items-center justify-center bg-surface-soft"
        style={{ aspectRatio: `${firstAspect.width} / ${firstAspect.height}` }}
      >
        <span className="text-4xl">{fallbackEmoji}</span>
      </div>
    );
  }

  return (
    <div
      ref={rootRef}
      className="group/media relative w-full overflow-hidden bg-surface-soft"
      style={
        ready
          ? undefined
          : { aspectRatio: `${firstAspect.width} / ${firstAspect.height}` }
      }
    >
      <div
        ref={scrollerRef}
        className="flex h-full w-full snap-x snap-mandatory overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        {media.map((m, i) => (
          <div key={m.id} className="relative h-full w-full shrink-0 snap-center snap-always">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={m.url}
              alt={title}
              className="absolute inset-0 h-full w-full object-cover"
              loading={i === 0 ? "eager" : "lazy"}
              draggable={false}
            />
          </div>
        ))}
      </div>

      {count > 1 ? (
        <>
          <span className="absolute right-3 top-3 rounded-md bg-ink/55 px-2 py-0.5 text-[11px] font-bold text-on-media backdrop-blur-sm">
            {safeDot + 1}/{count}
          </span>

          <button
            type="button"
            aria-label="Предыдущее фото"
            onClick={() => goTo(safeDot - 1)}
            disabled={safeDot <= 0}
            className="absolute left-2 top-1/2 hidden h-9 w-9 -translate-y-1/2 items-center justify-center rounded-full bg-ink/45 text-on-media opacity-0 backdrop-blur-sm transition hover:bg-ink/60 disabled:opacity-0 group-hover/media:opacity-100 md:flex"
          >
            <ChevronLeft className="h-5 w-5" strokeWidth={2.25} />
          </button>
          <button
            type="button"
            aria-label="Следующее фото"
            onClick={() => goTo(safeDot + 1)}
            disabled={safeDot >= count - 1}
            className="absolute right-2 top-1/2 hidden h-9 w-9 -translate-y-1/2 items-center justify-center rounded-full bg-ink/45 text-on-media opacity-0 backdrop-blur-sm transition hover:bg-ink/60 disabled:opacity-0 group-hover/media:opacity-100 md:flex"
          >
            <ChevronRight className="h-5 w-5" strokeWidth={2.25} />
          </button>

          <div className="pointer-events-none absolute inset-x-0 bottom-3 flex items-center justify-center gap-1.5">
            {media.map((m, i) => {
              const active = i === safeDot;
              return (
                <span
                  key={m.id}
                  className={`rounded-full shadow-sm transition-all duration-150 ${
                    active ? "h-2 w-2 bg-on-media" : "h-1.5 w-1.5 bg-on-media/45"
                  }`}
                />
              );
            })}
          </div>
        </>
      ) : null}
    </div>
  );
}
