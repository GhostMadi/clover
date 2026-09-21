"use client";

import { useEffect, useState } from "react";
import { BookingAnalyticsShimmer } from "@/features/booking/components/booking-shimmers";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  analyticsPeriodDefaults,
  emptyAnalytics,
  getBookingAnalytics,
} from "@/features/booking/lib/analytics-api";
import {
  readBookingAnalyticsCache,
  writeBookingAnalyticsCache,
} from "@/features/booking/lib/booking-prefs";
import type { BookingAnalytics, BookingStaff } from "@/features/booking/lib/booking-model";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";
import { listMyStaff } from "@/features/booking/lib/staff-api";
import { createClient } from "@/lib/supabase/client";

function fmt(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function weekPreset(now = new Date()): { from: string; to: string } {
  const day = now.getDay();
  const mondayOffset = day === 0 ? -6 : 1 - day;
  const from = new Date(now.getFullYear(), now.getMonth(), now.getDate() + mondayOffset);
  const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + 6);
  return { from: fmt(from), to: fmt(to) };
}

function monthPreset(now = new Date()): { from: string; to: string } {
  const from = new Date(now.getFullYear(), now.getMonth(), 1);
  const to = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  return { from: fmt(from), to: fmt(to) };
}

export function BookingAnalyticsView({ pointId }: { pointId: string }) {
  const defaults = analyticsPeriodDefaults();
  const [from, setFrom] = useState(defaults.from);
  const [to, setTo] = useState(defaults.to);
  const [staffId, setStaffId] = useState("");
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [data, setData] = useState<BookingAnalytics>(emptyAnalytics());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void listMyStaff(true)
      .then((list) => {
        if (!cancelled) setStaff(list);
      })
      .catch(() => {
        if (!cancelled) setStaff([]);
      });
    return () => {
      cancelled = true;
    };
  }, [pointId]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;
      const uid = session?.user.id ?? null;
      const sid = staffId || undefined;
      const cached = readBookingAnalyticsCache(uid, from, to, pointId, sid);
      if (cached) {
        setData(cached);
        setLoading(false);
      } else {
        setLoading(true);
      }

      try {
        const res = await getBookingAnalytics({ from, to, pointId, staffId: sid });
        if (cancelled) return;
        setData(res);
        setError(null);
        writeBookingAnalyticsCache(uid, from, to, res, pointId, sid);
      } catch (e: unknown) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Ошибка");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [from, to, pointId, staffId]);

  return (
    <BookingWorkspaceShell pointId={pointId} title="Аналитика">
      <div className="space-y-5">
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            className="rounded-[12px] border border-line bg-surface px-3 py-1.5 text-[12px] font-bold text-ink hover:bg-svc-booking/40"
            onClick={() => {
              const p = weekPreset();
              setFrom(p.from);
              setTo(p.to);
            }}
          >
            Неделя
          </button>
          <button
            type="button"
            className="rounded-[12px] border border-line bg-surface px-3 py-1.5 text-[12px] font-bold text-ink hover:bg-svc-booking/40"
            onClick={() => {
              const p = monthPreset();
              setFrom(p.from);
              setTo(p.to);
            }}
          >
            Месяц
          </button>
        </div>

        <div className="grid max-w-md grid-cols-2 gap-3">
          <label className="block">
            <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">С</span>
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink"
            />
          </label>
          <label className="block">
            <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">По</span>
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink"
            />
          </label>
        </div>

        {staff.length > 1 ? (
          <label className="block max-w-md">
            <span className="mb-1.5 block text-[12px] font-bold uppercase text-muted">
              Мастер
            </span>
            <select
              value={staffId}
              onChange={(e) => setStaffId(e.target.value)}
              className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink"
            >
              <option value="">Все</option>
              {staff.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.displayName}
                </option>
              ))}
            </select>
          </label>
        ) : null}

        {error ? <p className="text-sm text-destructive">{error}</p> : null}
        {loading ? (
          <BookingAnalyticsShimmer />
        ) : data.totalBookings === 0 ? (
          <p className="rounded-[14px] border border-dashed border-line bg-surface px-4 py-8 text-center text-sm text-muted">
            За период записей нет
          </p>
        ) : (
          <>
            <div className="grid grid-cols-2 gap-2 md:grid-cols-3 lg:grid-cols-7">
              <Stat label="Всего" value={String(data.totalBookings)} />
              <Stat label="Ждут" value={String(data.pendingBookings)} />
              <Stat label="Выручка" value={formatPriceKzt(data.revenue)} />
              <Stat label="Подтверждено" value={String(data.confirmedBookings)} />
              <Stat label="Оказано" value={String(data.completedBookings)} />
              <Stat label="Отменено" value={String(data.cancelledBookings)} />
              <Stat label="Средний чек" value={formatPriceKzt(data.avgCheck)} />
            </div>

            {data.popularServices.length ? (
              <section>
                <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                  Популярные услуги
                </p>
                <ul className="space-y-1.5">
                  {data.popularServices.map((s) => (
                    <li
                      key={s.serviceId}
                      className="rounded-[12px] border border-line bg-surface px-3 py-2 text-[14px]"
                    >
                      {s.emojiText} {s.title} · {s.bookingCount}
                    </li>
                  ))}
                </ul>
              </section>
            ) : null}

            {data.topStaff.length ? (
              <section>
                <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                  Топ мастеров
                </p>
                <ul className="space-y-1.5">
                  {data.topStaff.map((s) => (
                    <li
                      key={s.staffId}
                      className="rounded-[12px] border border-line bg-surface px-3 py-2 text-[14px]"
                    >
                      {s.displayName} · {s.bookingCount} · {formatPriceKzt(s.revenue)}
                    </li>
                  ))}
                </ul>
              </section>
            ) : null}
          </>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[16px] border border-line bg-svc-booking/40 px-3.5 py-3">
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-1 text-[18px] font-extrabold text-ink">{value}</p>
    </div>
  );
}
