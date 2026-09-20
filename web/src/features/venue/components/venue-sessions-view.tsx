"use client";

import { CalendarClock, Plus, X } from "lucide-react";
import { useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { VenueWorkspaceShell } from "@/features/venue/components/venue-workspace-shell";
import {
  bookablesFor,
  inventoryForOccasion,
  occasionKindLabel,
  occasionsFor,
  type MockOccasion,
  type OccasionKind,
} from "@/features/venue/lib/venue-booking-mock";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

const WEEKDAYS = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"];

function defaultKind(venueId: string): OccasionKind {
  return venueId === "cafe" ? "slot" : "session";
}

function newId() {
  return `occ_${Date.now().toString(36)}`;
}

function pad(n: number) {
  return String(n).padStart(2, "0");
}

/** «Пт 19:00» или «Пт 19:00 – 21:00» */
function buildWhenLabel(date: string, start: string, end: string, kind: OccasionKind) {
  if (!date || !start) return "";
  const d = new Date(`${date}T${start}:00`);
  if (Number.isNaN(d.getTime())) return `${date} ${start}`;
  const day = WEEKDAYS[d.getDay()] ?? "";
  if (kind === "slot" && end) return `${day} ${start} – ${end}`;
  return `${day} ${start}`;
}

function toIso(date: string, time: string) {
  if (!date || !time) return "";
  return `${date}T${time}:00+05:00`;
}

function todayIsoDate() {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function VenueSessionsView({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  const seed = useMemo(() => occasionsFor(venueId), [venueId]);
  const bookables = useMemo(() => bookablesFor(venueId), [venueId]);
  const [occasions, setOccasions] = useState<MockOccasion[]>(seed);
  const [open, setOpen] = useState(false);
  const [kind, setKind] = useState<OccasionKind>(defaultKind(venueId));
  const [title, setTitle] = useState("");
  const [date, setDate] = useState(todayIsoDate());
  const [start, setStart] = useState(kind === "slot" ? "19:00" : "20:00");
  const [end, setEnd] = useState("21:00");

  const preview = buildWhenLabel(date, start, end, kind);

  const resetForm = () => {
    const k = defaultKind(venueId);
    setKind(k);
    setTitle("");
    setDate(todayIsoDate());
    setStart(k === "slot" ? "19:00" : "20:00");
    setEnd("21:00");
  };

  const addOccasion = () => {
    if (!date || !start) return;
    const whenLabel = buildWhenLabel(date, start, end, kind);
    const next: MockOccasion = {
      id: newId(),
      kind,
      title: title.trim() || (kind === "session" ? `Сеанс ${start}` : `Слот ${start}`),
      whenLabel,
      startsAt: toIso(date, start),
      endsAt: kind === "slot" && end ? toIso(date, end) : null,
    };
    setOccasions((prev) => [...prev, next]);
    resetForm();
    setOpen(false);
  };

  return (
    <VenueWorkspaceShell venueId={venueId} title="Сеансы и слоты" venueName={name}>
      <div className="mx-auto max-w-2xl space-y-5">
        <div className="rounded-[20px] border border-line bg-surface px-4 py-3.5">
          <p className="text-[15px] font-bold text-ink">Occasion</p>
          <p className="mt-1 text-[13px] leading-relaxed text-muted">
            <span className="font-semibold text-ink">Сеанс</span> (`session`) — одно время начала.{" "}
            <span className="font-semibold text-ink">Слот</span> (`slot`) — окно «с–до».{" "}
            <span className="font-semibold text-ink">Inventory</span> (свободно / hold / занято)
            считается на пару bookable + этот occasion.
          </p>
        </div>

        <div className="flex items-center justify-between gap-3">
          <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
            Расписание · {occasions.length}
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
            <p className="text-[14px] font-bold text-ink">Новое время</p>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => {
                  setKind("session");
                  setStart("20:00");
                }}
                className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                  kind === "session"
                    ? "bg-svc-venue-ink text-on-media"
                    : "bg-surface-soft text-muted"
                }`}
              >
                Сеанс (одно время)
              </button>
              <button
                type="button"
                onClick={() => {
                  setKind("slot");
                  setStart("19:00");
                  setEnd("21:00");
                }}
                className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                  kind === "slot"
                    ? "bg-svc-venue-ink text-on-media"
                    : "bg-surface-soft text-muted"
                }`}
              >
                Слот (с–до)
              </button>
            </div>
            <label className="block space-y-1">
              <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                Название (необязательно)
              </span>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder={kind === "session" ? "Фильм · 20:00" : "Ужин"}
                className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
              />
            </label>
            <label className="block space-y-1">
              <span className="text-[11px] font-bold uppercase tracking-wide text-muted">День</span>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
              />
            </label>
            <div className={`grid gap-3 ${kind === "slot" ? "sm:grid-cols-2" : ""}`}>
              <label className="block space-y-1">
                <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                  {kind === "slot" ? "Начало" : "Время начала"}
                </span>
                <input
                  type="time"
                  value={start}
                  onChange={(e) => setStart(e.target.value)}
                  className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                />
              </label>
              {kind === "slot" ? (
                <label className="block space-y-1">
                  <span className="text-[11px] font-bold uppercase tracking-wide text-muted">
                    Конец
                  </span>
                  <input
                    type="time"
                    value={end}
                    onChange={(e) => setEnd(e.target.value)}
                    className="w-full rounded-[14px] border border-border-input bg-bg px-3 py-2.5 text-[14px] text-ink outline-none focus:border-svc-venue-ink"
                  />
                </label>
              ) : null}
            </div>
            {preview ? (
              <p className="rounded-[14px] bg-surface px-3 py-2 text-[13px] text-ink">
                Гость увидит:{" "}
                <span className="font-bold text-svc-venue-ink">{preview}</span>
              </p>
            ) : null}
            <AppButton
              type="button"
              service="venue"
              className="w-full"
              disabled={!date || !start}
              onClick={addOccasion}
            >
              Создать
            </AppButton>
          </section>
        ) : null}

        <ul className="space-y-3">
          {occasions.map((o) => {
            const inv = inventoryForOccasion(venueId, o.id);
            const free = inv.filter((r) => r.state === "free").length;
            const held = inv.filter((r) => r.state === "held").length;
            const taken = inv.filter((r) => r.state === "taken").length;
            return (
              <li
                key={o.id}
                className="rounded-[20px] border border-line bg-surface px-4 py-3.5"
              >
                <div className="flex items-start gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-venue text-svc-venue-ink">
                    <CalendarClock className="h-4 w-4" strokeWidth={2} />
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="text-[15px] font-bold text-ink">{o.title}</p>
                      <span className="rounded-full bg-surface-soft px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-muted">
                        {occasionKindLabel(o.kind)}
                      </span>
                    </div>
                    <p className="mt-1 text-[16px] font-bold text-svc-venue-ink">{o.whenLabel}</p>
                    <p className="mt-0.5 text-[12px] text-muted">
                      {o.kind === "session"
                        ? "Одно время начала · билеты/места на этот сеанс"
                        : "Окно визита · столы свободны в этом слоте"}
                    </p>
                    <div className="mt-3 flex flex-wrap gap-2 text-[12px] font-semibold">
                      <span className="rounded-full bg-success-soft px-2.5 py-1 text-ink">
                        {free} свободно
                      </span>
                      <span className="rounded-full bg-svc-venue/60 px-2.5 py-1 text-svc-venue-ink">
                        {held} на рассмотрении
                      </span>
                      <span className="rounded-full bg-surface-soft px-2.5 py-1 text-muted">
                        {taken} занято
                      </span>
                      <span className="rounded-full bg-surface-soft px-2.5 py-1 text-muted">
                        из {bookables.length}
                      </span>
                    </div>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </VenueWorkspaceShell>
  );
}
