import { ShimmerBone } from "@/components/shared/route-shimmers";

/** Список записей / услуг / бронирований. */
export function BookingListShimmer({ rows = 5 }: { rows?: number }) {
  return (
    <div className="space-y-2" aria-busy="true" aria-label="Загрузка">
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className="rounded-[16px] border border-line bg-surface px-3.5 py-3"
        >
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1 space-y-2">
              <ShimmerBone className="h-4 w-[70%] max-w-[14rem] rounded-md" />
              <ShimmerBone className="h-3 w-[45%] max-w-[9rem] rounded-md" />
              <ShimmerBone className="h-3 w-[55%] max-w-[11rem] rounded-md" />
            </div>
            <ShimmerBone className="h-5 w-16 shrink-0 rounded-full" />
          </div>
        </div>
      ))}
    </div>
  );
}

/** Форма / расписание / аналитика. */
export function BookingFormShimmer() {
  return (
    <div className="space-y-4" aria-busy="true" aria-label="Загрузка">
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-20 rounded-md" />
        <ShimmerBone className="h-11 w-full rounded-[14px]" />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <ShimmerBone className="h-3 w-16 rounded-md" />
          <ShimmerBone className="h-11 w-full rounded-[14px]" />
        </div>
        <div className="space-y-2">
          <ShimmerBone className="h-3 w-16 rounded-md" />
          <ShimmerBone className="h-11 w-full rounded-[14px]" />
        </div>
      </div>
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-24 rounded-md" />
        <div className="flex flex-wrap gap-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <ShimmerBone key={i} className="h-8 w-14 rounded-full" />
          ))}
        </div>
      </div>
      <ShimmerBone className="h-12 w-full rounded-[18px]" />
    </div>
  );
}

/** Карточка детали записи. */
export function BookingDetailShimmer() {
  return (
    <div className="space-y-4" aria-busy="true" aria-label="Загрузка">
      <div className="space-y-3 rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
        <ShimmerBone className="h-5 w-[75%] rounded-md" />
        <ShimmerBone className="h-3.5 w-[50%] rounded-md" />
        <ShimmerBone className="mt-2 h-4 w-[60%] rounded-md" />
        <ShimmerBone className="h-3 w-24 rounded-md" />
      </div>
      <ShimmerBone className="h-12 w-full rounded-[18px]" />
      <ShimmerBone className="h-12 w-full rounded-[18px]" />
      <ShimmerBone className="h-12 w-full rounded-[18px]" />
    </div>
  );
}

/** Слоты времени / чипы. */
export function BookingSlotsShimmer({ count = 8 }: { count?: number }) {
  return (
    <div className="flex flex-wrap gap-2" aria-busy="true" aria-label="Загрузка слотов">
      {Array.from({ length: count }).map((_, i) => (
        <ShimmerBone key={i} className="h-9 w-[4.25rem] rounded-[12px]" />
      ))}
    </div>
  );
}

/** Каталог услуг в клиентском flow. */
export function BookingCatalogShimmer() {
  return (
    <div className="space-y-5" aria-busy="true" aria-label="Загрузка">
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-16 rounded-md" />
        {Array.from({ length: 3 }).map((_, i) => (
          <div
            key={i}
            className="flex gap-3 rounded-[16px] border border-line bg-surface px-3.5 py-3"
          >
            <ShimmerBone className="h-8 w-8 shrink-0 rounded-lg" />
            <div className="min-w-0 flex-1 space-y-2">
              <ShimmerBone className="h-4 w-[65%] rounded-md" />
              <ShimmerBone className="h-3 w-[40%] rounded-md" />
            </div>
          </div>
        ))}
      </div>
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-14 rounded-md" />
        <div className="flex gap-2">
          <ShimmerBone className="h-9 w-24 rounded-full" />
          <ShimmerBone className="h-9 w-20 rounded-full" />
        </div>
      </div>
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-12 rounded-md" />
        <BookingSlotsShimmer />
      </div>
    </div>
  );
}

/** Блок аналитики. */
export function BookingAnalyticsShimmer() {
  return (
    <div className="space-y-5" aria-busy="true" aria-label="Загрузка">
      <div className="grid grid-cols-2 gap-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="rounded-[16px] border border-line bg-svc-booking/40 px-3.5 py-3"
          >
            <ShimmerBone className="h-2.5 w-14 rounded-md" />
            <ShimmerBone className="mt-2 h-5 w-20 rounded-md" />
          </div>
        ))}
      </div>
      <div className="space-y-2">
        <ShimmerBone className="h-3 w-28 rounded-md" />
        <BookingListShimmer rows={3} />
      </div>
    </div>
  );
}
