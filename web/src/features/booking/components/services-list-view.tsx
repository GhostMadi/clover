"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { AppButton, AppButtonLink } from "@/components/shared/app-button";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { AddStaffModal } from "@/features/booking/components/add-staff-modal";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { listMyServices } from "@/features/booking/lib/services-api";
import { listMyStaff } from "@/features/booking/lib/staff-api";
import type { BookingService, BookingStaff } from "@/features/booking/lib/booking-model";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";

export function ServicesListView() {
  const [services, setServices] = useState<BookingService[]>([]);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [addOpen, setAddOpen] = useState(false);

  const reload = () => {
    setLoading(true);
    void Promise.all([listMyServices(), listMyStaff(false)])
      .then(([s, st]) => {
        setServices(s);
        setStaff(st);
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : "Ошибка"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    reload();
  }, []);

  return (
    <SettingsShell
      title="Услуги"
      backHref="/app/settings/booking"
      service="booking"
      trailing={
        <AppButtonLink
          href="/app/settings/booking/services/new"
          size="icon"
          service="booking"
          title="Новая услуга"
          aria-label="Новая услуга"
        >
          <Plus strokeWidth={2.5} />
        </AppButtonLink>
      }
    >
      <div className="space-y-6 px-4 py-5">
        {error ? <p className="text-sm text-destructive">{error}</p> : null}

        <section>
          <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
            Каталог
          </p>
          {loading ? (
            <BookingListShimmer rows={4} />
          ) : services.length === 0 ? (
            <p className="text-sm text-muted">Пока нет услуг. Создайте первую.</p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {services.map((s, i) => (
                <li key={s.id} className={i > 0 ? "border-t border-line" : ""}>
                  <Link
                    href={`/app/settings/booking/services/${s.id}`}
                    className="flex items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-booking/40"
                  >
                    <span className="text-xl">{s.emojiText}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[15px] font-bold text-ink">
                        {s.title}
                        {!s.isActive ? (
                          <span className="ml-2 text-[11px] font-semibold text-muted">
                            неактивна
                          </span>
                        ) : null}
                      </span>
                      <span className="block text-[12px] text-muted">
                        {s.durationMinutes} мин · {formatPriceKzt(s.price)} · мастеров{" "}
                        {s.executorIds.length}
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section>
          <div className="mb-2 flex items-center justify-between gap-2 px-0.5">
            <p className="text-[12px] font-bold uppercase tracking-wide text-muted">Мастера</p>
            <AppButton size="row" service="booking" onClick={() => setAddOpen(true)}>
              <span className="inline-flex items-center gap-1.5">
                <Plus className="h-4 w-4" strokeWidth={2.5} />
                Добавить
              </span>
            </AppButton>
          </div>
          {staff.length === 0 ? (
            <p className="rounded-[14px] border border-dashed border-line bg-bg px-3.5 py-4 text-sm text-muted">
              Пока нет мастеров. Добавьте первого.
            </p>
          ) : (
            <ul className="space-y-1.5">
              {staff.map((s) => (
                <li
                  key={s.id}
                  className="rounded-[12px] border border-line bg-bg px-3 py-2.5 text-[14px] font-semibold text-ink"
                >
                  {s.displayName}
                  {!s.isActive ? (
                    <span className="ml-2 text-[11px] font-medium text-muted">выкл</span>
                  ) : null}
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      <AddStaffModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onCreated={() => {
          setError(null);
          reload();
        }}
      />
    </SettingsShell>
  );
}
