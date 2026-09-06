/** Базовая «кость» шиммера. */
export function ShimmerBone({ className = "" }: { className?: string }) {
  return <div className={`shimmer-bone ${className}`} aria-hidden />;
}

/** Лента: шапка-фильтр + карточки. */
export function FeedRouteShimmer() {
  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[480px] sm:max-w-[520px]">
        <div className="flex h-12 items-center justify-between border-b border-line px-4">
          <ShimmerBone className="h-8 w-8 rounded-full" />
          <ShimmerBone className="h-4 w-28 rounded-md" />
          <ShimmerBone className="h-8 w-8 rounded-full" />
        </div>
        {[0, 1].map((i) => (
          <div key={i} className="border-b border-line">
            <div className="flex items-center gap-3 px-4 py-3">
              <ShimmerBone className="h-9 w-9 rounded-full" />
              <div className="flex-1 space-y-2">
                <ShimmerBone className="h-3 w-28 rounded-md" />
                <ShimmerBone className="h-2.5 w-16 rounded-md" />
              </div>
              <ShimmerBone className="h-8 w-20 rounded-[12px]" />
            </div>
            <ShimmerBone className="aspect-[4/5] w-full rounded-none" />
            <div className="space-y-2 px-4 py-3">
              <ShimmerBone className="h-3 w-64 max-w-[75%] rounded-md" />
              <ShimmerBone className="h-3 w-40 max-w-[50%] rounded-md" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/** Карта: mint-плоскость + контролы. */
export function MapRouteShimmer() {
  return (
    <div className="relative h-[calc(100dvh-3rem-4.25rem)] w-full overflow-hidden bg-mint md:h-dvh">
      <div className="absolute inset-0 opacity-70">
        <div className="absolute left-[12%] top-[18%] h-24 w-24 rounded-full bg-mint" />
        <div className="absolute right-[18%] top-[36%] h-32 w-40 rounded-[40%] bg-line/50" />
        <div className="absolute bottom-[28%] left-[28%] h-20 w-28 rounded-[30%] bg-mint" />
      </div>
      <span className="absolute left-[40%] top-[42%] h-3 w-3 rounded-full bg-brand/50" />
      <span className="absolute left-[55%] top-[48%] h-3 w-3 rounded-full bg-brand/40" />
      <span className="absolute left-[35%] top-[55%] h-3 w-3 rounded-full bg-brand/35" />
      <span className="absolute left-[62%] top-[38%] h-3 w-3 rounded-full bg-brand/45" />
      <ShimmerBone className="absolute bottom-20 right-4 h-12 w-12 rounded-full md:bottom-6" />
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2">
        <ShimmerBone className="h-8 w-28 rounded-full" />
      </div>
    </div>
  );
}

/** Уведомления: список строк. */
export function NotificationsRouteShimmer() {
  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[520px]">
        <div className="flex h-12 items-center gap-2 border-b border-line px-4">
          <ShimmerBone className="h-5 w-5 rounded-md" />
          <ShimmerBone className="h-4 w-32 rounded-md" />
        </div>
        <ul className="divide-y divide-line">
          {Array.from({ length: 8 }).map((_, i) => (
            <li key={i} className="flex gap-3 px-4 py-3">
              <ShimmerBone className="h-11 w-11 shrink-0 rounded-full" />
              <div className="min-w-0 flex-1 space-y-2 py-0.5">
                <ShimmerBone className="h-3.5 w-[88%] rounded-md" />
                <ShimmerBone className="h-3 w-[62%] rounded-md" />
                <ShimmerBone className="h-2.5 w-14 rounded-md" />
              </div>
              {i % 3 === 0 ? (
                <ShimmerBone className="h-12 w-12 shrink-0 self-center rounded-lg" />
              ) : i % 3 === 1 ? (
                <ShimmerBone className="h-9 w-24 shrink-0 self-center rounded-[12px]" />
              ) : null}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

/** Чаты: список диалогов. */
export function ChatRouteShimmer() {
  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[640px]">
        <div className="border-b border-line px-4 pb-3 pt-3">
          <ShimmerBone className="h-6 w-36 rounded-md" />
          <ShimmerBone className="mt-3 h-11 w-full rounded-[14px]" />
        </div>
        <ul>
          {Array.from({ length: 7 }).map((_, i) => (
            <li key={i} className="flex gap-3 px-4 py-3">
              <ShimmerBone className="h-[52px] w-[52px] shrink-0 rounded-full" />
              <div className="min-w-0 flex-1 space-y-2 py-1">
                <div className="flex justify-between gap-2">
                  <ShimmerBone className="h-3.5 w-28 rounded-md" />
                  <ShimmerBone className="h-3 w-10 rounded-md" />
                </div>
                <ShimmerBone className="h-3 w-[70%] rounded-md" />
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

/** Тред чата: шапка + пузыри + композер. */
export function ChatThreadShimmer() {
  return (
    <div className="flex h-[calc(100dvh-3rem-4.25rem)] flex-col bg-bg md:h-dvh">
      <div className="flex h-12 shrink-0 items-center gap-2 border-b border-line bg-surface px-2">
        <ShimmerBone className="h-10 w-10 rounded-full" />
        <ShimmerBone className="h-8 w-8 rounded-full" />
        <ShimmerBone className="h-4 w-28 rounded-md" />
      </div>
      <div className="min-h-0 flex-1 space-y-3 px-4 py-4">
        <div className="flex justify-start">
          <ShimmerBone className="h-14 w-[55%] rounded-[20px] rounded-bl-lg" />
        </div>
        <div className="flex justify-end">
          <ShimmerBone className="h-12 w-[48%] rounded-[20px] rounded-br-lg" />
        </div>
        <div className="flex justify-start">
          <ShimmerBone className="h-20 w-[62%] rounded-[20px] rounded-bl-lg" />
        </div>
        <div className="flex justify-end">
          <ShimmerBone className="h-10 w-[40%] rounded-[20px] rounded-br-lg" />
        </div>
      </div>
      <div className="flex shrink-0 items-center gap-2 border-t border-line bg-surface px-3 py-2">
        <ShimmerBone className="h-11 flex-1 rounded-[18px]" />
        <ShimmerBone className="h-11 w-11 rounded-full" />
      </div>
    </div>
  );
}

/** Профиль: баннер + аватар + сетка. */
export function ProfileRouteShimmer() {
  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto max-w-2xl lg:max-w-3xl xl:max-w-4xl">
        <ShimmerBone className="aspect-[3/1] w-full rounded-none sm:aspect-[3.5/1]" />
        <div className="px-4 pt-3 sm:px-5 sm:pt-4 lg:px-6">
          <div className="flex items-center gap-3 sm:gap-5">
            <ShimmerBone className="-mt-10 h-20 w-20 rounded-full border-4 border-surface sm:-mt-12 sm:h-24 sm:w-24 lg:h-28 lg:w-28" />
            <div className="flex flex-1 justify-around gap-2 pt-2">
              {[0, 1, 2].map((i) => (
                <div key={i} className="flex flex-col items-center gap-1.5">
                  <ShimmerBone className="h-5 w-8 rounded-md" />
                  <ShimmerBone className="h-2.5 w-12 rounded-md" />
                </div>
              ))}
            </div>
          </div>
          <div className="mt-4 space-y-2">
            <ShimmerBone className="h-4 w-40 rounded-md" />
            <ShimmerBone className="h-3 w-24 rounded-md" />
            <ShimmerBone className="h-3 w-72 max-w-[85%] rounded-md" />
          </div>
          <div className="mt-4 flex gap-2">
            <ShimmerBone className="h-9 flex-1 rounded-[12px]" />
            <ShimmerBone className="h-9 w-9 rounded-[12px]" />
          </div>
        </div>
        <div className="mt-6 grid grid-cols-3 gap-[3px] px-0 sm:gap-2 sm:px-5 lg:px-6">
          {Array.from({ length: 9 }).map((_, i) => (
            <ShimmerBone key={i} className="aspect-square w-full rounded-sm" />
          ))}
        </div>
      </div>
    </div>
  );
}

/** Деталь поста: шапка + одна карточка. */
export function PostRouteShimmer() {
  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="sticky top-0 z-10 border-b border-line bg-surface/95 backdrop-blur-md">
        <div className="mx-auto flex h-12 max-w-[480px] items-center gap-2 px-3 sm:max-w-[520px]">
          <ShimmerBone className="h-10 w-10 rounded-full" />
          <ShimmerBone className="h-4 w-20 rounded-md" />
        </div>
      </div>
      <div className="mx-auto w-full max-w-[480px] sm:max-w-[520px]">
        <div className="flex items-center gap-3 px-4 py-3">
          <ShimmerBone className="h-9 w-9 rounded-full" />
          <ShimmerBone className="h-3 w-28 rounded-md" />
        </div>
        <ShimmerBone className="aspect-[4/5] w-full" />
        <div className="space-y-2 px-4 py-3">
          <ShimmerBone className="h-3 w-full rounded-md" />
          <ShimmerBone className="h-3 w-[66%] rounded-md" />
          <ShimmerBone className="h-3 w-[33%] rounded-md" />
        </div>
      </div>
    </div>
  );
}
