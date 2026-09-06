import { ShimmerBone } from "@/components/shared/route-shimmers";

export default function NewPostLoading() {
  return (
    <div className="flex min-h-[calc(100dvh-3rem-4.25rem)] flex-col bg-surface md:min-h-dvh">
      <div className="mx-auto flex w-full max-w-[640px] flex-1 flex-col">
        <div className="flex h-12 items-center gap-2 border-b border-line px-2">
          <ShimmerBone className="h-10 w-10 rounded-full" />
          <ShimmerBone className="h-4 w-40 rounded-md" />
        </div>
        <div className="flex flex-1 flex-col items-center justify-center gap-4 px-6 py-16">
          <ShimmerBone className="h-40 w-full max-w-sm rounded-[20px]" />
          <ShimmerBone className="h-4 w-48 rounded-md" />
        </div>
      </div>
    </div>
  );
}
