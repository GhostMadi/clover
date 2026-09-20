"use client";

import { Link2, Plus, Ticket, X } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { VenueWorkspaceShell } from "@/features/venue/components/venue-workspace-shell";
import {
  bookablesFor,
  kindLabel,
  type BookableKind,
  type MockBookable,
} from "@/features/venue/lib/venue-booking-mock";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

function defaultKind(venueId: string): BookableKind {
  if (venueId === "poetry") return "ticket";
  if (venueId === "cinema") return "seat";
  return "seat";
}

function newId() {
  return `bk_${Date.now().toString(36)}`;
}

export function VenueBookablesView({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  const seed = useMemo(() => bookablesFor(venueId), [venueId]);
  const [items, setItems] = useState<MockBookable[]>(seed);
  const [open, setOpen] = useState(false);
  const [label, setLabel] = useState("");
  const [kind, setKind] = useState<BookableKind>(defaultKind(venueId));
  const [capacity, setCapacity] = useState(venueId === "cafe" ? "4" : "1");
  const [price, setPrice] = useState("");
  const base = `/app/settings/venue/v/${venueId}`;

  const resetForm = () => {
    setLabel("");
    setKind(defaultKind(venueId));
    setCapacity(venueId === "cafe" ? "4" : "1");
    setPrice("");
  };

  const addItem = () => {
    const trimmed = label.trim();
    if (!trimmed) return;
    const cap = Math.max(1, Number.parseInt(capacity, 10) || 1);
    const next: MockBookable = {
      id: newId(),
      kind,
      label: trimmed,
      capacity: cap,
      priceHint: price.trim() || "от 0 ₸",
      planNodeId: null,
      selection: kind === "ticket" || venueId === "cinema" ? "multi" : "single",
    };
    setItems((prev) => [...prev, next]);
    resetForm();
    setOpen(false);
  };

  return (
    <VenueWorkspaceShell venueId={venueId} title="Объекты брони" venueName={name}>
      <div className="mx-auto max-w-2xl space-y-5">
        <div className="rounded-[20px] border border-line bg-surface px-4 py-3.5">
          <p className="text-[15px] font-bold text-ink">Bookable</p>
          <p className="mt-1 text-[13px] leading-relaxed text-muted">
            Объект брони — то, что гость выбирает: билет, стол, зона. Подпись пишешь сам. Привязка к
            фигуре — в{" "}
            <Link
              href={`${base}/plan`}
              className="font-semibold text-svc-venue-ink underline-offset-2 hover:underline"
            >
              Плане
            </Link>
            .
          </p>
        </div>

        <div className="flex items-center justify-between gap-3">
          <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
            Каталог · {items.length}
          </p>
          <AppButton
            type="button"
            service="venue"
            size="row"
            className="!w-auto px-3"
            onClick={() => {
              resetForm();
              setOpen((v) => !v);
            }}
          >
            {open ? <X className="mr-1 h-3.5 w-3.5" /> : <Plus className="mr-1 h-3.5 w-3.5" />}
            {open ? "Закрыть" : "Добавить"}
          </AppButton>
        </div>

        {open ? (
          <section className="space-y-3 rounded-[20px] border-2 border-svc-venue-ink/30 bg-svc-venue/25 px-4 py-4">
            <p className="text-[14px] font-bold text-ink">Новое место / билет</p>
            <label className="block space-y-1">
              <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                Название
              </span>
              <input
                value={label}
                onChange={(e) => setLabel(e.target.value)}
                placeholder="Например: Стол у окна"
                className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                autoFocus
              />
            </label>
            <div className="grid gap-3 sm:grid-cols-2">
              <label className="block space-y-1">
                <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                  Тип
                </span>
                <select
                  value={kind}
                  onChange={(e) => setKind(e.target.value as BookableKind)}
                  className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                >
                  <option value="seat">Место (стол / кресло)</option>
                  <option value="ticket">Билет (тариф)</option>
                  <option value="zone">Зона</option>
                </select>
              </label>
              <label className="block space-y-1">
                <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                  Сколько человек
                </span>
                <input
                  type="number"
                  min={1}
                  value={capacity}
                  onChange={(e) => setCapacity(e.target.value)}
                  className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                />
              </label>
            </div>
            <label className="block space-y-1">
              <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                Цена (подсказка)
              </span>
              <input
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="от 0 ₸ или 2 500 ₸"
                className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
              />
            </label>
            <AppButton
              type="button"
              service="venue"
              className="w-full"
              disabled={!label.trim()}
              onClick={addItem}
            >
              Создать
            </AppButton>
          </section>
        ) : null}

        <ul className="overflow-hidden rounded-[20px] border border-line bg-surface">
          {items.map((b, i) => (
            <li
              key={b.id}
              className={`flex items-start gap-3 px-4 py-3.5 ${
                i > 0 ? "border-t border-line" : ""
              }`}
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-venue text-svc-venue-ink">
                <Ticket className="h-4 w-4" strokeWidth={2} />
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <p className="text-[15px] font-bold text-ink">{b.label}</p>
                  <span className="rounded-full bg-surface-soft px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-muted">
                    {kindLabel(b.kind)}
                  </span>
                </div>
                <p className="mt-0.5 text-[12px] text-muted">
                  {b.capacity} мест · {b.priceHint} ·{" "}
                  {b.selection === "multi" ? "несколько" : "одно"}
                </p>
                <p className="mt-1 flex items-center gap-1 text-[11px] text-muted">
                  <Link2 className="h-3 w-3" />
                  {b.planNodeId ? (
                    <span>
                      на схеме: <span className="font-semibold text-ink">{b.planNodeId}</span>
                    </span>
                  ) : (
                    <span>без схемы — продаётся списком</span>
                  )}
                </p>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </VenueWorkspaceShell>
  );
}
