"use client";

import { Building2, ChevronRight, Plus } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/shared/app-button";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import {
  bookingPointBase,
  readBookingPointsCache,
  writeLastBookingPointId,
} from "@/features/booking/lib/booking-prefs";
import {
  createBookingPoint,
  listBookingPoints,
  type BookingPoint,
} from "@/features/booking/lib/points-api";
import {
  ServiceEmpty,
  ServiceInformer,
} from "@/features/shared/components/service-page";
import { ServiceWorkspaceShell } from "@/features/shared/components/service-workspace-shell";
import { getSessionUserId } from "@/lib/run-service-swr";
import { serviceTileIcon } from "@/lib/service-accent";
import { LayoutGrid } from "lucide-react";

export function BookingPointsView() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [points, setPoints] = useState<BookingPoint[]>([]);
  const [userId, setUserId] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      setUserId(uid);
      setPoints(await listBookingPoints());
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const uid = await getSessionUserId();
      if (cancelled) return;
      setUserId(uid);
      const cached = readBookingPointsCache(uid);
      if (cached && cached.length > 0) {
        setPoints(
          cached.map((p) => ({
            id: p.id,
            name: p.name,
            hostId: uid ?? "",
            createdAt: "",
          })),
        );
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [reload]);

  const openPoint = (id: string) => {
    writeLastBookingPointId(userId, id);
    router.push(`${bookingPointBase(id)}/inbox`);
  };

  return (
    <ServiceWorkspaceShell
      service="booking"
      brandTitle="Запись"
      title="Точки"
      lead="Каждая точка — свои записи, услуги и часы."
      hubPath="/app/settings/booking/points"
      hubBackHref="/app/settings"
      nav={[
        {
          href: "/app/settings/booking/points",
          label: "Точки",
          match: (p) => p.startsWith("/app/settings/booking/points"),
          Icon: LayoutGrid,
        },
      ]}
      trailing={
        <button
          type="button"
          title="Новая точка"
          onClick={() => setCreating(true)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-booking-ink hover:bg-svc-booking"
          aria-label="Новая точка"
        >
          <Plus className="h-5 w-5" strokeWidth={2.25} />
        </button>
      }
    >
      <div className="space-y-4">
        {error ? (
          <ServiceInformer service="booking" tone="warning">
            {error}
          </ServiceInformer>
        ) : null}
        {loading ? (
          <BookingListShimmer rows={4} />
        ) : points.length === 0 ? (
          <ServiceEmpty>Точек пока нет. Создайте первую — с неё начнётся запись.</ServiceEmpty>
        ) : (
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {points.map((p, i) => (
              <li key={p.id} className={i > 0 ? "border-t border-line" : ""}>
                <button
                  type="button"
                  onClick={() => openPoint(p.id)}
                  className="flex w-full items-center gap-3 px-3.5 py-3.5 text-left transition hover:bg-svc-booking/40"
                >
                  <span className={serviceTileIcon("booking")}>
                    <Building2 className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span className="min-w-0 flex-1 truncate text-[15px] font-bold text-ink">
                    {p.name}
                  </span>
                  <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
                </button>
              </li>
            ))}
          </ul>
        )}

        {creating ? (
          <div className="space-y-3 rounded-[16px] border border-line bg-surface p-4">
            <p className="text-[14px] font-bold text-ink">Новая точка</p>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Например, Салон на Абая"
              className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] outline-none focus:border-svc-booking-ink/50"
            />
            <div className="flex gap-2">
              <AppButton
                service="booking"
                disabled={!name.trim()}
                onClick={() => {
                  void (async () => {
                    try {
                      const p = await createBookingPoint(name);
                      writeLastBookingPointId(userId, p.id);
                      router.push(`${bookingPointBase(p.id)}/inbox`);
                    } catch (e: unknown) {
                      setError(e instanceof Error ? e.message : "Ошибка");
                    }
                  })();
                }}
              >
                Создать
              </AppButton>
              <AppButton variant="outline" onClick={() => setCreating(false)}>
                Отмена
              </AppButton>
            </div>
          </div>
        ) : null}
      </div>
    </ServiceWorkspaceShell>
  );
}
