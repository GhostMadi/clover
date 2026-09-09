"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { aspectFromUrl, gridAxisCount, type VisualCols } from "@/features/post/lib/aspect-ratio";
import type { GridPost } from "@/features/post/lib/grid-post";
import { computeGridPlacements, type PostGridPlacement } from "@/features/post/lib/media-layout";

function visualColsForWidth(width: number): VisualCols {
  if (width < 520) return 2;
  return 3;
}

/** Staggered-сетка постов: span из `__ar-WxH` в URL. Макс 3 в ряд. Тап → деталь. */
export function PostsGrid({ posts }: { posts: GridPost[] }) {
  const [visualCols, setVisualCols] = useState<VisualCols>(3);

  useEffect(() => {
    const update = () => setVisualCols(visualColsForWidth(window.innerWidth));
    update();
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  }, []);

  if (posts.length === 0) {
    return (
      <div className="py-12 text-center sm:py-16">
        <p className="text-sm font-semibold text-ink">Пока пусто</p>
        <p className="mt-1 text-sm text-muted">Попробуй другой город или режим «Все»</p>
      </div>
    );
  }

  const axis = gridAxisCount(visualCols);
  const aspects = posts.map((p) => aspectFromUrl(p.coverUrl ?? ""));
  const placements: PostGridPlacement[] = computeGridPlacements(aspects, visualCols);

  return (
    <div className="profile-posts-grid" style={{ ["--post-grid-cols" as string]: axis }}>
      {posts.map((post, i) => {
        const place = placements[i];
        if (!place) return null;
        return (
          <Link
            key={post.id}
            href={`/app/posts/${post.id}`}
            className="group relative overflow-hidden rounded-[7px] bg-mint sm:rounded-[12px]"
            title={post.title ?? undefined}
            style={{
              gridColumn: `${place.col + 1} / span ${place.cross}`,
              gridRow: `${place.row + 1} / span ${place.main}`,
            }}
          >
            {post.coverUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={post.coverUrl}
                alt={post.title ?? ""}
                referrerPolicy="no-referrer"
                className="absolute inset-0 h-full w-full object-cover transition duration-300 group-hover:scale-[1.03]"
                loading="lazy"
              />
            ) : (
              <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-mint to-brand-soft/50">
                <span className="text-2xl sm:text-3xl">{post.textEmoji || "☘️"}</span>
              </div>
            )}

            {post.mediaCount > 1 ? (
              <span className="absolute right-1.5 top-1.5 rounded-md bg-ink/55 px-1.5 py-0.5 text-[10px] font-bold text-on-media backdrop-blur-sm sm:text-[11px]">
                {post.mediaCount}
              </span>
            ) : null}

            {post.isEvent && post.textEmoji ? (
              <span className="absolute bottom-1.5 left-1.5 flex h-7 w-7 items-center justify-center rounded-full bg-surface/90 text-sm shadow-sm sm:h-8 sm:w-8 sm:text-base">
                {post.textEmoji}
              </span>
            ) : null}
          </Link>
        );
      })}
    </div>
  );
}
