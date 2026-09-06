"use client";

import { useJellyPress } from "@/components/shared/jelly";

type ProfileBannerProps = {
  imageUrl: string;
  /** Нет баннера — мягкий mint-плейсхолдер под большой экран. */
  empty?: boolean;
};

/**
 * Баннер профиля: та же jelly-физика, что `ProfileHeaderBanner` в Flutter
 * (squash по X + растяг по Y от низа). На вебе выше и шире.
 */
export function ProfileBanner({ imageUrl, empty }: ProfileBannerProps) {
  const { style, trigger } = useJellyPress({ variant: "banner" });

  return (
    <div className="px-3 pt-3 sm:px-4 sm:pt-4 lg:px-5 lg:pt-5">
      <button
        type="button"
        aria-label="Баннер профиля"
        onPointerDown={(e) => {
          if (e.button !== 0) return;
          trigger();
        }}
        className="block w-full cursor-pointer border-0 bg-transparent p-0 text-left outline-none focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:ring-offset-2"
        style={style}
      >
        <div className="overflow-hidden rounded-[24px] shadow-elevate-xl lg:rounded-[28px]">
          {empty || !imageUrl ? (
            <div className="h-[150px] w-full bg-gradient-to-br from-mint via-surface to-brand-soft/40 sm:h-[200px] lg:h-[260px]" />
          ) : (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={imageUrl}
              alt=""
              className="h-[150px] w-full object-cover sm:h-[200px] lg:h-[260px]"
              draggable={false}
            />
          )}
        </div>
      </button>
    </div>
  );
}
