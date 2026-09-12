"use client";

import { Building2, Check, ChevronDown } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  readBookingPointsCache,
  swapBookingPointPath,
  writeLastBookingPointId,
  type BookingPointCacheItem,
} from "@/features/booking/lib/booking-prefs";
import { listBookingPoints } from "@/features/booking/lib/points-api";
import { createClient } from "@/lib/supabase/client";

type Props = {
  pointId: string;
  currentName?: string;
  /** В rail слева — на всю ширину. */
  fullWidth?: boolean;
};

export function BookingPointSwitcher({
  pointId,
  currentName,
  fullWidth = false,
}: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [userId, setUserId] = useState<string | null>(null);
  const [items, setItems] = useState<BookingPointCacheItem[]>([]);
  const rootRef = useRef<HTMLDivElement>(null);

  const hydrate = useCallback(async () => {
    const {
      data: { session },
    } = await createClient().auth.getSession();
    const uid = session?.user.id ?? null;
    setUserId(uid);
    const cached = readBookingPointsCache(uid);
    if (cached?.length) setItems(cached);
    try {
      const list = await listBookingPoints();
      setItems(list.map((p) => ({ id: p.id, name: p.name })));
    } catch {
      /* keep cache */
    }
  }, []);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  useEffect(() => {
    writeLastBookingPointId(userId, pointId);
  }, [userId, pointId]);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  const label =
    currentName?.trim() ||
    items.find((p) => p.id === pointId)?.name ||
    "Точка";

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={`inline-flex items-center gap-1.5 rounded-[12px] border border-line bg-surface px-2.5 py-1.5 text-left transition hover:bg-svc-booking/40 ${
          fullWidth ? "w-full max-w-none" : "max-w-[220px]"
        }`}
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        <Building2 className="h-4 w-4 shrink-0 text-svc-booking-ink" strokeWidth={2} />
        <span className="min-w-0 truncate text-[13px] font-bold text-ink">{label}</span>
        <ChevronDown className="h-4 w-4 shrink-0 text-muted" strokeWidth={2} />
      </button>

      {open ? (
        <div
          role="listbox"
          className="absolute right-0 z-30 mt-1.5 w-[min(100vw-2rem,280px)] overflow-hidden rounded-[14px] border border-line bg-surface shadow-elevate-md"
        >
          <ul className="max-h-64 overflow-y-auto py-1">
            {items.map((p) => {
              const active = p.id === pointId;
              return (
                <li key={p.id}>
                  <button
                    type="button"
                    role="option"
                    aria-selected={active}
                    onClick={() => {
                      setOpen(false);
                      if (p.id === pointId) return;
                      writeLastBookingPointId(userId, p.id);
                      router.push(swapBookingPointPath(pathname, p.id));
                    }}
                    className={`flex w-full items-center gap-2 px-3 py-2.5 text-left text-[13px] transition hover:bg-svc-booking/40 ${
                      active ? "font-bold text-svc-booking-ink" : "font-semibold text-ink"
                    }`}
                  >
                    <span className="min-w-0 flex-1 truncate">{p.name}</span>
                    {active ? <Check className="h-4 w-4 shrink-0" strokeWidth={2.5} /> : null}
                  </button>
                </li>
              );
            })}
          </ul>
          <div className="border-t border-line px-2 py-2">
            <Link
              href="/app/settings/booking/points"
              onClick={() => setOpen(false)}
              className="block rounded-[10px] px-2 py-2 text-[12px] font-bold text-svc-booking-ink hover:bg-svc-booking/40"
            >
              Все точки…
            </Link>
          </div>
        </div>
      ) : null}
    </div>
  );
}
