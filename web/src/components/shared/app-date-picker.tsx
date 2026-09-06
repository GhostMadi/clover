"use client";

import { Calendar, ChevronDown, X } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";

const MONTHS_RU = [
  "января",
  "февраля",
  "марта",
  "апреля",
  "мая",
  "июня",
  "июля",
  "августа",
  "сентября",
  "октября",
  "ноября",
  "декабря",
] as const;

function pad2(n: number) {
  return String(n).padStart(2, "0");
}

export function formatAppDateTime(value: Date): string {
  const d = value.getDate();
  const month = MONTHS_RU[value.getMonth()] ?? "";
  return `${d} ${month} · ${pad2(value.getHours())}:${pad2(value.getMinutes())}`;
}

export function formatAppDate(value: Date): string {
  const d = value.getDate();
  const month = MONTHS_RU[value.getMonth()] ?? "";
  return `${d} ${month}`;
}

function toDateInputValue(d: Date): string {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function combineLocal(dateStr: string, hour: number, minute: number): Date {
  const [y, m, day] = dateStr.split("-").map(Number);
  return new Date(y!, (m ?? 1) - 1, day ?? 1, hour, minute, 0, 0);
}

type AppPickerFieldProps = {
  label?: string;
  hint: string;
  displayText?: string | null;
  onClick?: () => void;
  disabled?: boolean;
  className?: string;
};

/** Оболочка поля как `AppPickerFieldShell` в мобилке. */
export function AppPickerField({
  label,
  hint,
  displayText,
  onClick,
  disabled = false,
  className = "",
}: AppPickerFieldProps) {
  const hasValue = Boolean(displayText?.trim());
  return (
    <div className={`block ${className}`}>
      {label ? (
        <span className="mb-1.5 block pl-1 text-[13px] font-semibold text-ink">{label}</span>
      ) : null}
      <button
        type="button"
        disabled={disabled}
        onClick={onClick}
        className="flex w-full items-center gap-3 rounded-[16px] border border-line bg-bg px-4 py-[18px] text-left shadow-elevate-sm transition hover:border-brand/40 disabled:opacity-50"
      >
        <Calendar className="h-[22px] w-[22px] shrink-0 text-brand" strokeWidth={1.75} />
        <span
          className={`min-w-0 flex-1 truncate text-[15px] font-semibold ${
            hasValue ? "text-ink" : "text-muted"
          }`}
        >
          {hasValue ? displayText : hint}
        </span>
        <ChevronDown className="h-6 w-6 shrink-0 text-ink/55" strokeWidth={1.75} />
      </button>
    </div>
  );
}

type AppDateTimePickerProps = {
  label?: string;
  hint?: string;
  value: Date | null;
  onChange: (value: Date | null) => void;
  disabled?: boolean;
  clearable?: boolean;
  className?: string;
};

/**
 * Дата + время: поле → шторка (как AppTimePicker / AppDatePicker).
 * Всегда используй вместо raw `datetime-local`.
 */
export function AppDateTimePicker({
  label = "Дата и время",
  hint = "Выберите дату и время",
  value,
  onChange,
  disabled = false,
  clearable = true,
  className = "",
}: AppDateTimePickerProps) {
  const [open, setOpen] = useState(false);
  const initial = value ?? new Date();
  const [dateStr, setDateStr] = useState(toDateInputValue(initial));
  const [hour, setHour] = useState(initial.getHours());
  const [minute, setMinute] = useState(initial.getMinutes());

  useEffect(() => {
    if (!open) return;
    const base = value ?? new Date();
    setDateStr(toDateInputValue(base));
    setHour(base.getHours());
    setMinute(base.getMinutes());
  }, [open, value]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  const hours = useMemo(() => Array.from({ length: 24 }, (_, i) => i), []);
  const minutes = useMemo(
    () => Array.from({ length: 60 }, (_, i) => i).filter((m) => m % 5 === 0 || m === minute),
    [minute],
  );

  const confirm = () => {
    onChange(combineLocal(dateStr, hour, minute));
    setOpen(false);
  };

  return (
    <div className={className}>
      <AppPickerField
        label={label}
        hint={hint}
        displayText={value ? formatAppDateTime(value) : null}
        disabled={disabled}
        onClick={() => setOpen(true)}
      />
      {clearable && value && !disabled ? (
        <button
          type="button"
          onClick={() => onChange(null)}
          className="mt-1.5 text-[12px] font-semibold text-muted hover:text-ink"
        >
          Сбросить
        </button>
      ) : null}

      {open ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setOpen(false)}
          />
          <div className="relative z-10 flex max-h-[85dvh] w-full max-w-md flex-col rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="flex items-center gap-2 border-b border-line px-3 py-3">
              <h2 className="min-w-0 flex-1 text-[16px] font-bold text-ink">{label}</h2>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-bg"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5 text-ink" strokeWidth={2} />
              </button>
            </div>

            <div className="space-y-4 overflow-y-auto px-4 py-4">
              <label className="block">
                <span className="mb-1.5 block text-[13px] font-semibold text-ink">Дата</span>
                <input
                  type="date"
                  value={dateStr}
                  onChange={(e) => setDateStr(e.target.value)}
                  className="h-12 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] font-semibold text-ink outline-none focus:border-brand"
                />
              </label>

              <div>
                <span className="mb-1.5 block text-[13px] font-semibold text-ink">Время</span>
                <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-2">
                  <select
                    value={hour}
                    onChange={(e) => setHour(Number(e.target.value))}
                    className="h-12 rounded-[14px] border border-brand/30 bg-mint/50 px-3 text-center text-[18px] font-bold text-ink outline-none focus:border-brand"
                  >
                    {hours.map((h) => (
                      <option key={h} value={h}>
                        {pad2(h)}
                      </option>
                    ))}
                  </select>
                  <span className="text-[28px] font-bold text-brand">:</span>
                  <select
                    value={minute}
                    onChange={(e) => setMinute(Number(e.target.value))}
                    className="h-12 rounded-[14px] border border-brand/30 bg-mint/50 px-3 text-center text-[18px] font-bold text-ink outline-none focus:border-brand"
                  >
                    {minutes.map((m) => (
                      <option key={m} value={m}>
                        {pad2(m)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <div className="border-t border-line px-4 py-3">
              <AppButton type="button" onClick={confirm}>
                Готово
              </AppButton>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}

type AppDatePickerProps = {
  label?: string;
  hint?: string;
  value: Date | null;
  onChange: (value: Date | null) => void;
  disabled?: boolean;
  clearable?: boolean;
  className?: string;
};

/** Только дата (без времени), тот же паттерн поля + шторка. */
export function AppDatePicker({
  label = "Дата",
  hint = "Выберите дату",
  value,
  onChange,
  disabled = false,
  clearable = true,
  className = "",
}: AppDatePickerProps) {
  const [open, setOpen] = useState(false);
  const [dateStr, setDateStr] = useState(toDateInputValue(value ?? new Date()));

  useEffect(() => {
    if (!open) return;
    setDateStr(toDateInputValue(value ?? new Date()));
  }, [open, value]);

  return (
    <div className={className}>
      <AppPickerField
        label={label}
        hint={hint}
        displayText={value ? formatAppDate(value) : null}
        disabled={disabled}
        onClick={() => setOpen(true)}
      />
      {clearable && value && !disabled ? (
        <button
          type="button"
          onClick={() => onChange(null)}
          className="mt-1.5 text-[12px] font-semibold text-muted hover:text-ink"
        >
          Сбросить
        </button>
      ) : null}

      {open ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setOpen(false)}
          />
          <div className="relative z-10 w-full max-w-md rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="flex items-center gap-2 border-b border-line px-3 py-3">
              <h2 className="min-w-0 flex-1 text-[16px] font-bold text-ink">{label}</h2>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-bg"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5 text-ink" strokeWidth={2} />
              </button>
            </div>
            <div className="px-4 py-4">
              <input
                type="date"
                value={dateStr}
                onChange={(e) => setDateStr(e.target.value)}
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] font-semibold text-ink outline-none focus:border-brand"
              />
            </div>
            <div className="border-t border-line px-4 py-3">
              <AppButton
                type="button"
                onClick={() => {
                  const [y, m, d] = dateStr.split("-").map(Number);
                  onChange(new Date(y!, (m ?? 1) - 1, d ?? 1));
                  setOpen(false);
                }}
              >
                Готово
              </AppButton>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
