"use client";

import { Check } from "lucide-react";
import { type ReactNode } from "react";

type AppCheckboxProps = {
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  className?: string;
  "aria-label"?: string;
};

/**
 * Чекбокс Clover: скруглённый квадрат, primary fill + textInverse галочка.
 */
export function AppCheckbox({
  checked,
  onChange,
  disabled = false,
  className = "",
  "aria-label": ariaLabel,
}: AppCheckboxProps) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      aria-label={ariaLabel}
      disabled={disabled}
      onClick={(e) => {
        e.stopPropagation();
        onChange(!checked);
      }}
      className={`flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-[7px] border-2 transition ${
        checked
          ? "border-brand bg-brand text-on-brand shadow-elevate-brand-sm"
          : "border-line bg-surface text-transparent hover:border-brand/50"
      } disabled:opacity-45 ${className}`}
    >
      <Check
        className={`h-3.5 w-3.5 ${checked ? "opacity-100" : "opacity-0"}`}
        strokeWidth={3}
      />
    </button>
  );
}

type AppCheckboxRowProps = {
  title: string;
  subtitle?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  className?: string;
  children?: ReactNode;
};

/** Строка как `AppSwitchRow`: заголовок слева, чекбокс справа. */
export function AppCheckboxRow({
  title,
  subtitle,
  checked,
  onChange,
  disabled = false,
  className = "",
  children,
}: AppCheckboxRowProps) {
  return (
    <div
      className={`rounded-[14px] border border-line/80 bg-surface px-3.5 py-3 ${className}`}
    >
      <div className="flex items-start justify-between gap-3">
        <button
          type="button"
          disabled={disabled}
          onClick={() => onChange(!checked)}
          className="min-w-0 flex-1 text-left disabled:opacity-50"
        >
          <span className="block text-[15px] font-bold leading-snug text-ink">{title}</span>
          {subtitle ? (
            <span className="mt-0.5 block text-[12px] leading-snug text-muted">{subtitle}</span>
          ) : null}
        </button>
        <AppCheckbox
          checked={checked}
          onChange={onChange}
          disabled={disabled}
          aria-label={title}
        />
      </div>
      {children}
    </div>
  );
}
