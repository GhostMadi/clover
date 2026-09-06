import { ShimmerBone } from "@/components/shared/route-shimmers";

export function AttendanceListShimmer({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-2" aria-busy="true" aria-label="Загрузка">
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5"
        >
          <div className="flex items-center gap-3">
            <ShimmerBone className="h-10 w-10 shrink-0 rounded-[12px]" />
            <div className="min-w-0 flex-1 space-y-2">
              <ShimmerBone className="h-4 w-[55%] max-w-[12rem] rounded-md" />
              <ShimmerBone className="h-3 w-[35%] max-w-[8rem] rounded-md" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
