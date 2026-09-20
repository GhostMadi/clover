"use client";

import { MessageSquare } from "lucide-react";
import { AppButton } from "@/components/shared/app-button";
import { VenueWorkspaceShell } from "@/features/venue/components/venue-workspace-shell";
import { reservationsFor } from "@/features/venue/lib/venue-booking-mock";

const NAMES: Record<string, string> = {
  cafe: "Кафе Clover",
  cinema: "Кино Star",
  poetry: "Вечер поэзии",
};

function statusLabel(s: string): string {
  if (s === "confirmed") return "Подтверждён";
  if (s === "declined") return "Отклонён";
  return "Запрос";
}

function statusClass(s: string): string {
  if (s === "confirmed") return "bg-success-soft text-ink";
  if (s === "declined") return "bg-surface-soft text-muted";
  return "bg-svc-venue text-svc-venue-ink";
}

export function VenueInboxView({ venueId }: { venueId: string }) {
  const name = NAMES[venueId] ?? "Заведение";
  const items = reservationsFor(venueId);

  return (
    <VenueWorkspaceShell venueId={venueId} title="Inbox" venueName={name}>
      <div className="mx-auto max-w-2xl space-y-5">
        <div className="rounded-[20px] border border-line bg-surface px-4 py-3.5">
          <p className="text-[15px] font-bold text-ink">Запросы на бронь</p>
          <p className="mt-1 text-[13px] leading-relaxed text-muted">
            Клиент выбрал место + время → soft-hold → ты подтверждаешь или отклоняешь. Деньги пока
            вне Clover.
          </p>
        </div>

        <ul className="space-y-3">
          {items.map((r) => (
            <li key={r.id} className="rounded-[20px] border border-line bg-surface p-4">
              <div className="flex items-start gap-3">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-venue text-svc-venue-ink">
                  <MessageSquare className="h-4 w-4" strokeWidth={2} />
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-[15px] font-bold text-ink">{r.guestName}</p>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ${statusClass(r.status)}`}
                    >
                      {statusLabel(r.status)}
                    </span>
                  </div>
                  <p className="mt-1 text-[13px] font-semibold text-ink">
                    {r.bookableLabel} · {r.occasionLabel}
                  </p>
                  <p className="text-[12px] text-muted">
                    {r.guests} гостя
                    {r.comment ? ` · «${r.comment}»` : ""}
                  </p>
                  {r.status === "requested" ? (
                    <div className="mt-3 flex flex-wrap gap-2">
                      <AppButton type="button" service="venue" size="row" className="!w-auto px-3">
                        Подтвердить
                      </AppButton>
                      <AppButton
                        type="button"
                        service="venue"
                        variant="outline"
                        size="row"
                        className="!w-auto px-3"
                      >
                        Отклонить
                      </AppButton>
                    </div>
                  ) : null}
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </VenueWorkspaceShell>
  );
}
