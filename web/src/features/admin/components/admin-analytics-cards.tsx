"use client";

import { useCallback, useEffect, useState } from "react";

type Stats = Record<string, number | string | null | undefined>;

const LABELS: { key: string; label: string; group: string }[] = [
  { key: "profiles_total", label: "Профилей всего", group: "Пользователи" },
  { key: "dau", label: "DAU (1д)", group: "Пользователи" },
  { key: "active_logins", label: "Активные логины", group: "Пользователи" },
  { key: "new_profiles", label: "Новые профили", group: "Пользователи" },
  { key: "tag_booking", label: "Тег booking", group: "Сервисы" },
  { key: "tag_attendance", label: "Тег attendance", group: "Сервисы" },
  { key: "tag_resources", label: "Тег resources", group: "Сервисы" },
  { key: "booking_points", label: "Точки записи", group: "Сервисы" },
  { key: "attendance_workplaces", label: "Компании посещаемости", group: "Сервисы" },
  { key: "bookings_period", label: "Записи за период", group: "Активность" },
  { key: "punches_period", label: "Отметки за период", group: "Активность" },
  { key: "posts_period", label: "Посты за период", group: "Активность" },
  { key: "support_new", label: "Support · new", group: "Ops" },
  { key: "honest_quiz_finished", label: "Honest quiz · finished", group: "Ops" },
];

export function AdminAnalyticsCards() {
  const [days, setDays] = useState<1 | 7 | 30>(7);
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async (period: 1 | 7 | 30) => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/admin/stats?days=${period}`);
      const json = (await res.json()) as { stats?: Stats; error?: string };
      if (!res.ok) throw new Error(json.error || "Ошибка загрузки");
      setStats(json.stats ?? {});
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ошибка");
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load(days);
  }, [days, load]);

  const groups = ["Пользователи", "Сервисы", "Активность", "Ops"];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap gap-2">
        {([1, 7, 30] as const).map((d) => (
          <button
            key={d}
            type="button"
            onClick={() => setDays(d)}
            className={`rounded-[12px] px-3 py-2 text-[13px] font-semibold transition ${
              days === d
                ? "bg-brand text-white"
                : "border border-line bg-surface text-ink hover:border-brand/40"
            }`}
          >
            {d}д
          </button>
        ))}
      </div>

      {loading ? <p className="text-[14px] text-muted">Загрузка…</p> : null}
      {error ? <p className="text-[14px] text-destructive">{error}</p> : null}

      {!loading && stats
        ? groups.map((group) => (
            <section key={group} className="flex flex-col gap-3">
              <h2 className="text-[13px] font-semibold uppercase tracking-wide text-muted">
                {group}
              </h2>
              <div className="grid gap-3 sm:grid-cols-2">
                {LABELS.filter((row) => row.group === group).map((row) => (
                  <div
                    key={row.key}
                    className="rounded-[16px] border border-line bg-surface p-4"
                  >
                    <p className="text-[12px] text-muted">{row.label}</p>
                    <p className="mt-1 text-[28px] font-bold tracking-tight text-ink">
                      {typeof stats[row.key] === "number" ? stats[row.key] : "—"}
                    </p>
                  </div>
                ))}
              </div>
            </section>
          ))
        : null}
    </div>
  );
}
