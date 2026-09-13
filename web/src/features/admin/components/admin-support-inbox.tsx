"use client";

import { useCallback, useEffect, useState } from "react";

export type SupportItem = {
  id: string;
  created_at: string;
  contact: string;
  message: string;
  user_id: string | null;
  source: string;
  status: "new" | "in_progress" | "done" | string;
};

const STATUS_LABEL: Record<string, string> = {
  new: "Новая",
  in_progress: "В работе",
  done: "Готово",
};

export function AdminSupportInbox() {
  const [items, setItems] = useState<SupportItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/support");
      const json = (await res.json()) as { items?: SupportItem[]; error?: string };
      if (!res.ok) throw new Error(json.error || "Ошибка загрузки");
      setItems(json.items ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ошибка");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const setStatus = async (id: string, status: string) => {
    setBusyId(id);
    setError(null);
    try {
      const res = await fetch("/api/admin/support", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, status }),
      });
      const json = (await res.json()) as { item?: SupportItem; error?: string };
      if (!res.ok) throw new Error(json.error || "Ошибка обновления");
      if (json.item) {
        setItems((prev) => prev.map((row) => (row.id === id ? json.item! : row)));
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ошибка");
    } finally {
      setBusyId(null);
    }
  };

  if (loading) return <p className="text-[14px] text-muted">Загрузка…</p>;
  if (error && items.length === 0) {
    return <p className="text-[14px] text-destructive">{error}</p>;
  }

  if (items.length === 0) {
    return <p className="text-[14px] text-muted">Заявок пока нет.</p>;
  }

  return (
    <div className="flex flex-col gap-3">
      {error ? <p className="text-[14px] text-destructive">{error}</p> : null}
      {items.map((item) => (
        <article
          key={item.id}
          className="rounded-[16px] border border-line bg-surface p-4"
        >
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div>
              <p className="text-[15px] font-bold text-ink">{item.contact}</p>
              <p className="mt-0.5 text-[12px] text-muted">
                {new Date(item.created_at).toLocaleString("ru-RU")} · {item.source} ·{" "}
                {STATUS_LABEL[item.status] ?? item.status}
              </p>
            </div>
            <select
              className="rounded-[10px] border border-line bg-bg px-2 py-1.5 text-[13px] text-ink"
              value={item.status}
              disabled={busyId === item.id}
              onChange={(e) => void setStatus(item.id, e.target.value)}
            >
              <option value="new">Новая</option>
              <option value="in_progress">В работе</option>
              <option value="done">Готово</option>
            </select>
          </div>
          <p className="mt-3 whitespace-pre-wrap text-[14px] leading-relaxed text-ink">
            {item.message}
          </p>
        </article>
      ))}
    </div>
  );
}
