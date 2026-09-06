"use client";

import { Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  savePunchConfig,
} from "@/features/attendance/lib/attendance-api";
import type { AttendanceCustomPunch } from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";

type DraftPunch = {
  id?: string;
  label: string;
  scheduledTime: string | null;
};

const fieldCls =
  "h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-svc-attendance-ink/50";

export function AttendancePunchTypesView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const router = useRouter();
  const back = `/app/settings/attendance/w/${workplaceId}/settings`;
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [clockInEnabled, setClockInEnabled] = useState(true);
  const [clockOutEnabled, setClockOutEnabled] = useState(true);
  const [clockInScheduled, setClockInScheduled] = useState<string | null>(null);
  const [clockOutScheduled, setClockOutScheduled] = useState<string | null>(
    null,
  );
  const [custom, setCustom] = useState<DraftPunch[]>([]);
  const [addOpen, setAddOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void getAdminWorkplace(workplaceId)
      .then((w) => {
        if (cancelled) return;
        if (!w) {
          setLoadError("Компания не найдена или нет прав admin");
          setLoading(false);
          return;
        }
        setClockInEnabled(w.clockInEnabled);
        setClockOutEnabled(w.clockOutEnabled);
        setClockInScheduled(w.clockInScheduled);
        setClockOutScheduled(w.clockOutScheduled);
        setCustom(
          w.customPunches.map((p: AttendanceCustomPunch) => ({
            id: p.id,
            label: p.label,
            scheduledTime: p.scheduledTime,
          })),
        );
        setLoading(false);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setLoadError(e instanceof Error ? e.message : "Не удалось загрузить");
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [workplaceId]);

  const canSave = clockInEnabled || clockOutEnabled;

  const save = async () => {
    if (!canSave || saving) return;
    setSaving(true);
    setError(null);
    try {
      await savePunchConfig({
        workplaceId,
        clockInEnabled,
        clockOutEnabled,
        clockInScheduled: clockInEnabled ? clockInScheduled : null,
        clockOutScheduled: clockOutEnabled ? clockOutScheduled : null,
        customPunches: custom,
      });
      router.push(back);
      router.refresh();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <SettingsShell title="Типы отметок" backHref={back} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={5} />
        </div>
      </SettingsShell>
    );
  }

  if (loadError) {
    return (
      <SettingsShell title="Типы отметок" backHref={back} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{loadError}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  return (
    <SettingsShell
      title="Типы отметок"
      backHref={back}
      service="attendance"
      trailing={
        <button
          type="button"
          title="Добавить"
          onClick={() => setAddOpen(true)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-attendance-ink hover:bg-svc-attendance"
          aria-label="Добавить свою отметку"
        >
          <Plus className="h-5 w-5" strokeWidth={2.25} />
        </button>
      }
    >
      <div className="space-y-6 px-4 py-5 pb-10">
        <p className="text-[13px] text-muted">
          У каждого типа можно задать время, когда работник должен отметиться.
        </p>

        <section className="overflow-hidden rounded-[16px] border border-line bg-surface">
          <p className="border-b border-line px-3.5 py-2.5 text-[12px] font-bold uppercase tracking-wide text-muted">
            Приход и уход
          </p>
          <SystemPunchRow
            title="Пришёл"
            enabled={clockInEnabled}
            scheduled={clockInScheduled}
            onEnabled={(v) => {
              setClockInEnabled(v);
              if (!v) setClockInScheduled(null);
            }}
            onScheduled={setClockInScheduled}
          />
          <div className="border-t border-line">
            <SystemPunchRow
              title="Ушёл"
              enabled={clockOutEnabled}
              scheduled={clockOutScheduled}
              onEnabled={(v) => {
                setClockOutEnabled(v);
                if (!v) setClockOutScheduled(null);
              }}
              onScheduled={setClockOutScheduled}
            />
          </div>
        </section>

        {!canSave ? (
          <p className="text-[13px] font-semibold text-error">
            Включите хотя бы «Пришёл» или «Ушёл»
          </p>
        ) : null}

        <section className="space-y-2">
          <p className="px-1 text-[15px] font-bold text-ink">Свои отметки</p>
          <p className="px-1 text-[12px] text-muted">
            «Обед», «Перерыв» — с опциональным временем.
          </p>
          {custom.length === 0 ? (
            <p className="px-1 py-6 text-center text-[13px] text-muted">
              Пока нет своих отметок. Нажмите + чтобы добавить.
            </p>
          ) : (
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {custom.map((p, i) => (
                <li
                  key={p.id ?? `new-${i}`}
                  className={i > 0 ? "border-t border-line" : ""}
                >
                  <div className="flex items-start gap-3 px-3.5 py-3">
                    <div className="min-w-0 flex-1 space-y-2">
                      <p className="text-[15px] font-bold text-ink">{p.label}</p>
                      <label className="block">
                        <span className="mb-1 block text-[11px] font-semibold text-muted">
                          Время (необязательно)
                        </span>
                        <input
                          type="time"
                          className={fieldCls}
                          value={p.scheduledTime ?? ""}
                          onChange={(e) => {
                            const v = e.target.value || null;
                            setCustom((prev) =>
                              prev.map((row, idx) =>
                                idx === i ? { ...row, scheduledTime: v } : row,
                              ),
                            );
                          }}
                        />
                      </label>
                    </div>
                    <button
                      type="button"
                      title="Удалить"
                      onClick={() =>
                        setCustom((prev) => prev.filter((_, idx) => idx !== i))
                      }
                      className="mt-1 flex h-9 w-9 items-center justify-center rounded-full text-error hover:bg-bg"
                    >
                      <Trash2 className="h-4 w-4" strokeWidth={2} />
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        {error ? <p className="text-[13px] text-error">{error}</p> : null}

        <AppButton
          type="button"
          service="attendance"
          loading={saving}
          disabled={!canSave}
          onClick={() => void save()}
        >
          Сохранить
        </AppButton>
      </div>

      <AttendanceNameModal
        open={addOpen}
        title="Своя отметка"
        label="Название"
        placeholder="Обед"
        onClose={() => setAddOpen(false)}
        onSubmit={async (label) => {
          setCustom((prev) => [...prev, { label, scheduledTime: null }]);
        }}
      />
    </SettingsShell>
  );
}

function SystemPunchRow({
  title,
  enabled,
  scheduled,
  onEnabled,
  onScheduled,
}: {
  title: string;
  enabled: boolean;
  scheduled: string | null;
  onEnabled: (v: boolean) => void;
  onScheduled: (v: string | null) => void;
}) {
  return (
    <div className="space-y-3 px-3.5 py-3.5">
      <div className="flex items-center justify-between gap-3">
        <p className="text-[15px] font-bold text-ink">{title}</p>
        <button
          type="button"
          role="switch"
          aria-checked={enabled}
          onClick={() => onEnabled(!enabled)}
          className={`relative h-7 w-12 shrink-0 rounded-full transition ${
            enabled ? "bg-svc-attendance-ink" : "bg-line"
          }`}
        >
          <span
            className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
              enabled ? "left-[1.35rem]" : "left-0.5"
            }`}
          />
        </button>
      </div>
      {enabled ? (
        <label className="block">
          <span className="mb-1 block text-[11px] font-semibold text-muted">
            Время (необязательно)
          </span>
          <input
            type="time"
            className={fieldCls}
            value={scheduled ?? ""}
            onChange={(e) => onScheduled(e.target.value || null)}
          />
        </label>
      ) : null}
    </div>
  );
}
