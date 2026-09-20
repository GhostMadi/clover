"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Eye } from "lucide-react";
import { VenueWorkspaceShell } from "@/features/venue/components/venue-workspace-shell";
import {
  bookablesFor,
  inventoryForOccasion,
  kindLabel,
  occasionsFor,
  stateLabel,
  type BookableInventoryState,
} from "@/features/venue/lib/venue-booking-mock";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

function chipFor(state: BookableInventoryState): string {
  if (state === "held") return "bg-svc-venue/70 text-svc-venue-ink ring-1 ring-svc-venue-ink/20";
  if (state === "taken") return "bg-surface-soft text-muted line-through opacity-70";
  return "bg-success-soft text-ink ring-1 ring-svc-venue-ink/10";
}

export function VenueShowcaseView({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  const occasions = occasionsFor(venueId);
  const bookables = bookablesFor(venueId);
  const [occasionId, setOccasionId] = useState(occasions[0]?.id ?? "");
  const base = `/app/settings/venue/v/${venueId}`;

  const rows = useMemo(() => {
    const inv = inventoryForOccasion(venueId, occasionId);
    const byId = new Map(inv.map((r) => [r.bookableId, r.state]));
    return bookables.map((b) => ({
      bookable: b,
      state: byId.get(b.id) ?? ("free" as const),
    }));
  }, [venueId, occasionId, bookables]);

  const free = rows.filter((r) => r.state === "free").length;

  return (
    <VenueWorkspaceShell venueId={venueId} title="Витрина" venueName={name}>
      <div className="mx-auto max-w-2xl space-y-5">
        <div className="rounded-[20px] border border-line bg-surface px-4 py-3.5">
          <p className="flex items-center gap-2 text-[15px] font-bold text-ink">
            <Eye className="h-4 w-4 text-svc-venue-ink" />
            Как видит гость
          </p>
          <p className="mt-1 text-[13px] leading-relaxed text-muted">
            Сначала <span className="font-semibold text-ink">occasion</span> (сеанс/слот), потом{" "}
            <span className="font-semibold text-ink">bookable</span>. Цвет ={" "}
            <span className="font-semibold text-ink">inventory</span> на этот occasion, не «навсегда»
            в рисунке.
          </p>
        </div>

        <div>
          <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
            1. Occasion
          </p>
          <div className="flex flex-wrap gap-2">
            {occasions.map((o) => {
              const active = o.id === occasionId;
              return (
                <button
                  key={o.id}
                  type="button"
                  onClick={() => setOccasionId(o.id)}
                  className={`rounded-[14px] px-3.5 py-2 text-left text-[13px] font-semibold transition ${
                    active
                      ? "bg-svc-venue text-svc-venue-ink shadow-elevate-sm"
                      : "border border-line bg-surface text-ink hover:bg-svc-venue/40"
                  }`}
                >
                  <span className="block">{o.whenLabel}</span>
                  <span className="block text-[11px] font-medium opacity-70">{o.title}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <div className="mb-2 flex items-end justify-between gap-2">
            <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
              2. Bookable на этот occasion
            </p>
            <p className="text-[12px] font-semibold text-svc-venue-ink">{free} свободно</p>
          </div>
          <ul className="grid gap-2 sm:grid-cols-2">
            {rows.map(({ bookable: b, state }) => (
              <li key={b.id}>
                <button
                  type="button"
                  disabled={state !== "free"}
                  className={`flex w-full items-center justify-between gap-2 rounded-[16px] px-3.5 py-3 text-left transition ${chipFor(state)} ${
                    state === "free" ? "hover:shadow-elevate-sm" : "cursor-not-allowed"
                  }`}
                >
                  <span>
                    <span className="block text-[14px] font-bold">{b.label}</span>
                    <span className="block text-[11px] opacity-80">
                      {kindLabel(b.kind)} · {b.capacity} · {b.priceHint}
                    </span>
                  </span>
                  <span className="shrink-0 text-[11px] font-bold uppercase tracking-wide">
                    {stateLabel(state)}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>

        <p className="text-[12px] leading-relaxed text-muted">
          На полной схеме те же id красятся поверх плана.{" "}
          <Link
            href={`${base}/plan`}
            className="font-semibold text-svc-venue-ink underline-offset-2 hover:underline"
          >
            Редактор плана
          </Link>
          {" · "}
          <Link
            href={`${base}/inbox`}
            className="font-semibold text-svc-venue-ink underline-offset-2 hover:underline"
          >
            Inbox запросов
          </Link>
        </p>
      </div>
    </VenueWorkspaceShell>
  );
}
