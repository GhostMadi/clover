"use client";

import { useCallback, useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  payrollPreview,
  updatePayrollSettings,
  type PayrollPreview,
} from "@/features/attendance/lib/attendance-api";
import {
  monthPeriodToToday,
  type AttendancePayrollRules,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import { SettingsShell } from "@/features/settings/components/settings-shell";

function money(n: number): string {
  return `${Math.round(n).toLocaleString("ru-RU")} ₸`;
}

export function AttendancePayrollView({ workplaceId }: { workplaceId: string }) {
  const back = `/app/settings/attendance/w/${workplaceId}`;
  const period = monthPeriodToToday();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [rules, setRules] = useState<AttendancePayrollRules | null>(null);
  const [preview, setPreview] = useState<PayrollPreview | null>(null);
  const [saving, setSaving] = useState(false);
  const [previewBusy, setPreviewBusy] = useState(false);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const w = await getAdminWorkplace(workplaceId);
      if (!w) {
        setError("Компания не найдена или нет прав admin");
        return;
      }
      setWorkplace(w);
      setRules(w.payrollRules);
      const p = await payrollPreview({
        workplaceId,
        start: period.start,
        end: period.end,
        rules: w.payrollRules,
      });
      setPreview(p);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId, period.start, period.end]);

  useEffect(() => {
    void reload();
  }, [reload]);

  if (loading || !rules) {
    return (
      <SettingsShell title="Зарплата" backHref={back} service="attendance">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </SettingsShell>
    );
  }

  if (error || !workplace) {
    return (
      <SettingsShell title="Зарплата" backHref={back} service="attendance">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error ?? "Нет данных"}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </SettingsShell>
    );
  }

  const refreshPreview = async (next: AttendancePayrollRules) => {
    setPreviewBusy(true);
    try {
      setPreview(
        await payrollPreview({
          workplaceId,
          start: period.start,
          end: period.end,
          rules: next,
        }),
      );
    } catch {
      /* keep old */
    } finally {
      setPreviewBusy(false);
    }
  };

  return (
    <SettingsShell title="Зарплата" backHref={back} service="attendance">
      <div className="space-y-6 px-4 py-5 pb-10">
        {preview ? (
          <section className="space-y-3">
            <p className="text-[16px] font-bold text-ink">
              {preview.periodLabel || period.label}
            </p>
            <div className="grid grid-cols-2 gap-2">
              <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
                <p className="text-[11px] font-semibold text-muted">База</p>
                <p className="mt-1 text-[16px] font-bold text-ink">
                  {money(preview.team.baseTotal)}
                </p>
              </div>
              <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3">
                <p className="text-[11px] font-semibold text-muted">К выплате</p>
                <p className="mt-1 text-[16px] font-bold text-svc-attendance-ink">
                  {money(preview.team.netTotal)}
                </p>
              </div>
            </div>
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {preview.workers.map((w, i) => (
                <li
                  key={w.workerId}
                  className={`px-3.5 py-3 ${i > 0 ? "border-t border-line" : ""}`}
                >
                  <div className="flex items-center justify-between gap-3">
                    <p className="truncate text-[14px] font-bold text-ink">
                      {w.displayName || w.username || w.workerId.slice(0, 8)}
                    </p>
                    <p className="shrink-0 text-[14px] font-bold text-ink">
                      {money(w.netPay)}
                    </p>
                  </div>
                  <p className="text-[11px] text-muted">
                    база {money(w.baseSalary)}
                  </p>
                </li>
              ))}
            </ul>
            {previewBusy ? (
              <p className="text-[12px] text-muted">Обновляем превью…</p>
            ) : null}
          </section>
        ) : null}

        <section className="space-y-3">
          <p className="text-[15px] font-bold text-ink">Правила</p>
          <div className="overflow-hidden rounded-[16px] border border-line bg-surface">
            <ToggleRow
              title="Опоздания списывают"
              value={rules.lateDeductsPay}
              onChange={(v) => {
                const next = { ...rules, lateDeductsPay: v };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <ToggleRow
              title="Переработка добавляет"
              value={rules.overtimeAddsPay}
              onChange={(v) => {
                const next = { ...rules, overtimeAddsPay: v };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <ToggleRow
              title="Пропуски списывают"
              value={rules.absenceDeductsPay}
              onChange={(v) => {
                const next = { ...rules, absenceDeductsPay: v };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <ToggleRow
              title="Неполный день списывает"
              value={rules.partialDayDeductsPay}
              onChange={(v) => {
                const next = { ...rules, partialDayDeductsPay: v };
                setRules(next);
                void refreshPreview(next);
              }}
              last
            />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <NumField
              label="− ₸ / мин опоздания"
              value={rules.lateDeductPerMinute}
              onChange={(n) => {
                const next = { ...rules, lateDeductPerMinute: n };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <NumField
              label="+ ₸ / час OT"
              value={rules.overtimeBonusPerHour}
              onChange={(n) => {
                const next = { ...rules, overtimeBonusPerHour: n };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <NumField
              label="− ₸ / день пропуска"
              value={rules.absenceDeductPerDay}
              onChange={(n) => {
                const next = { ...rules, absenceDeductPerDay: n };
                setRules(next);
                void refreshPreview(next);
              }}
            />
            <NumField
              label="− % неполный день"
              value={rules.partialDayDeductPercent}
              onChange={(n) => {
                const next = { ...rules, partialDayDeductPercent: n };
                setRules(next);
                void refreshPreview(next);
              }}
            />
          </div>

          <AppButton
            type="button"
            service="attendance"
            loading={saving}
            onClick={() => {
              setSaving(true);
              void updatePayrollSettings({ workplaceId, rules })
                .then(() => reload())
                .finally(() => setSaving(false));
            }}
          >
            Сохранить правила
          </AppButton>
        </section>

        {workplace.groupConversationId ? (
          <AppButtonLink
            href={`/app/chat/${workplace.groupConversationId}`}
            service="attendance"
          >
            Чат компании
          </AppButtonLink>
        ) : (
          <p className="text-[12px] text-muted">
            Групповой чат создаётся при создании компании; если его нет —
            обновите bootstrap с телефона.
          </p>
        )}
      </div>
    </SettingsShell>
  );
}

function ToggleRow({
  title,
  value,
  onChange,
  last,
}: {
  title: string;
  value: boolean;
  onChange: (v: boolean) => void;
  last?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between gap-3 px-3.5 py-3 ${
        last ? "" : "border-b border-line"
      }`}
    >
      <p className="text-[14px] font-semibold text-ink">{title}</p>
      <button
        type="button"
        role="switch"
        aria-checked={value}
        onClick={() => onChange(!value)}
        className={`relative h-7 w-12 shrink-0 rounded-full transition ${
          value ? "bg-svc-attendance-ink" : "bg-line"
        }`}
      >
        <span
          className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
            value ? "left-[1.35rem]" : "left-0.5"
          }`}
        />
      </button>
    </div>
  );
}

function NumField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (n: number) => void;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[11px] font-semibold text-muted">
        {label}
      </span>
      <input
        type="number"
        min={0}
        value={value}
        onChange={(e) => onChange(Math.max(0, Number(e.target.value) || 0))}
        className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-svc-attendance-ink/50"
      />
    </label>
  );
}
