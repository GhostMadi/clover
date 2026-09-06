"use client";

import { useEffect, useId, useRef, useState } from "react";
import { X } from "lucide-react";
import { AppButton } from "@/components/shared/app-button";

const fieldCls =
  "h-12 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[15px] text-ink outline-none placeholder:text-muted focus:border-svc-attendance-ink/50";

type Props = {
  open: boolean;
  title: string;
  label: string;
  placeholder?: string;
  initialValue?: string;
  submitLabel?: string;
  onClose: () => void;
  onSubmit: (value: string) => Promise<void>;
};

/** Простая модалка с одним текстовым полем (компания / папка). */
export function AttendanceNameModal({
  open,
  title,
  label,
  placeholder,
  initialValue = "",
  submitLabel = "Создать",
  onClose,
  onSubmit,
}: Props) {
  const titleId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [value, setValue] = useState(initialValue);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setValue(initialValue);
    setError(null);
    setBusy(false);
    const t = setTimeout(() => inputRef.current?.focus(), 50);
    return () => clearTimeout(t);
  }, [open, initialValue]);

  if (!open) return null;

  const submit = async () => {
    const trimmed = value.trim();
    if (!trimmed || busy) return;
    setBusy(true);
    setError(null);
    try {
      await onSubmit(trimmed);
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-2 border-b border-line px-3 py-2.5">
          <h2 id={titleId} className="min-w-0 flex-1 text-[16px] font-bold text-ink">
            {title}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
            aria-label="Закрыть"
          >
            <X className="h-5 w-5" strokeWidth={2} />
          </button>
        </div>

        <div className="space-y-4 px-4 py-4">
          <label className="block">
            <span className="mb-1.5 block text-[13px] font-semibold text-muted">
              {label}
            </span>
            <input
              ref={inputRef}
              className={fieldCls}
              value={value}
              placeholder={placeholder}
              onChange={(e) => setValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") void submit();
              }}
              disabled={busy}
            />
          </label>
          {error ? <p className="text-[13px] text-error">{error}</p> : null}
          <AppButton
            type="button"
            service="attendance"
            loading={busy}
            disabled={!value.trim()}
            onClick={() => void submit()}
          >
            {submitLabel}
          </AppButton>
        </div>
      </div>
    </div>
  );
}
