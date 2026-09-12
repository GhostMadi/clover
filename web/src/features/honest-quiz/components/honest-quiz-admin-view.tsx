"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

type RunRow = {
  id: string;
  created_at: string;
  updated_at: string;
  finished: boolean;
  answers: Record<string, unknown>;
  has_photo: boolean;
  user_agent: string | null;
};

type RunDetail = RunRow & {
  photo_data_url: string | null;
};

export function HonestQuizAdminView() {
  const [runs, setRuns] = useState<RunRow[]>([]);
  const [detail, setDetail] = useState<RunDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/honest-quiz");
      const json = (await res.json()) as { runs?: RunRow[]; error?: string };
      if (!res.ok) throw new Error(json.error || "Ошибка загрузки");
      setRuns(json.runs ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ошибка");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const openRun = async (id: string) => {
    setError(null);
    try {
      const res = await fetch(`/api/admin/honest-quiz?id=${encodeURIComponent(id)}`);
      const json = (await res.json()) as { run?: RunDetail; error?: string };
      if (!res.ok) throw new Error(json.error || "Ошибка");
      setDetail(json.run ?? null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ошибка");
    }
  };

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col gap-6 px-5 py-10">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-[13px] font-semibold text-brand">Временно</p>
          <h1 className="mt-1 text-[24px] font-bold text-ink">Честный тест — ответы</h1>
          <p className="mt-1 text-[13px] text-muted">
            Игра:{" "}
            <Link href="/honest" className="text-brand underline">
              /honest
            </Link>
          </p>
        </div>
        <Link
          href="/admin/home"
          className="rounded-[12px] border border-line px-3 py-2 text-[13px] font-semibold text-ink"
        >
          ← Админка
        </Link>
      </header>

      {error ? <p className="text-[14px] text-destructive">{error}</p> : null}
      {loading ? <p className="text-[14px] text-muted">Загрузка…</p> : null}

      {!loading && runs.length === 0 ? (
        <p className="text-[14px] text-muted">Пока нет прохождений</p>
      ) : null}

      <ul className="divide-y divide-line rounded-[16px] border border-line bg-surface">
        {runs.map((r) => (
          <li key={r.id}>
            <button
              type="button"
              onClick={() => void openRun(r.id)}
              className="flex w-full flex-col gap-1 px-4 py-3 text-left hover:bg-mint/40"
            >
              <span className="text-[14px] font-semibold text-ink">
                {new Date(r.created_at).toLocaleString("ru-RU")}
                {r.finished ? " · финиш" : " · в процессе"}
                {r.has_photo ? " · 📸" : ""}
              </span>
              <span className="text-[12px] text-muted">
                q1={String(r.answers?.q1 ?? "—")} · q2={String(r.answers?.q2 ?? "—")} · q3=
                {String(r.answers?.q3 ?? "—")} · no-clicks:{" "}
                {String(r.answers?.q1_no_attempts ?? 0)}/
                {String(r.answers?.q2_no_attempts ?? 0)}/
                {String(r.answers?.q3_no_attempts ?? 0)}
              </span>
            </button>
          </li>
        ))}
      </ul>

      {detail ? (
        <section className="rounded-[16px] border border-line bg-surface p-4">
          <div className="flex items-start justify-between gap-2">
            <h2 className="text-[16px] font-bold text-ink">Прохождение</h2>
            <button
              type="button"
              className="text-[13px] font-semibold text-muted"
              onClick={() => setDetail(null)}
            >
              Закрыть
            </button>
          </div>
          <pre className="mt-3 overflow-x-auto rounded-[12px] bg-bg p-3 text-[12px] text-ink">
            {JSON.stringify(detail.answers, null, 2)}
          </pre>
          {detail.photo_data_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={detail.photo_data_url}
              alt="Фото из теста"
              className="mt-4 max-h-[480px] w-full rounded-[14px] object-contain"
            />
          ) : (
            <p className="mt-3 text-[13px] text-muted">Фото ещё нет</p>
          )}
        </section>
      ) : null}
    </main>
  );
}
