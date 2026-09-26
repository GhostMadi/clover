"use client";

import { ChevronRight, X, type LucideIcon } from "lucide-react";
import Link from "next/link";
import { useId, type ReactNode } from "react";
import { AppButton } from "@/components/shared/app-button";
import { ShimmerBone } from "@/components/shared/route-shimmers";
import type { AppServiceKind } from "@/lib/service-accent";

const TILE_HOVER: Record<AppServiceKind, string> = {
  booking: "hover:border-svc-booking-ink/30 hover:bg-svc-booking/35",
  attendance: "hover:border-svc-attendance-ink/40 hover:bg-svc-attendance/35",
  resources: "hover:border-svc-resources-ink/40 hover:bg-svc-resources/35",
  bonus: "hover:border-svc-bonus-ink/40 hover:bg-svc-bonus/35",
  venue: "hover:border-svc-venue-ink/35 hover:bg-svc-venue/35",
};

const ICON_BOX: Record<AppServiceKind, string> = {
  booking: "bg-svc-booking text-svc-booking-ink",
  attendance: "bg-svc-attendance text-svc-attendance-ink",
  resources: "bg-svc-resources text-svc-resources-ink",
  bonus: "bg-svc-bonus text-svc-bonus-ink",
  venue: "bg-svc-venue text-svc-venue-ink",
};

const INFORMER: Record<AppServiceKind, Record<"info" | "next" | "warning", string>> = {
  booking: {
    info: "bg-svc-booking/45 text-ink",
    next: "bg-svc-booking text-svc-booking-ink",
    warning: "border border-line bg-surface text-ink",
  },
  attendance: {
    info: "bg-svc-attendance/40 text-ink",
    next: "bg-svc-attendance text-svc-attendance-ink",
    warning: "border border-line bg-surface text-ink",
  },
  resources: {
    info: "bg-svc-resources/40 text-ink",
    next: "bg-svc-resources text-svc-resources-ink",
    warning: "border border-line bg-surface text-ink",
  },
  bonus: {
    info: "bg-svc-bonus/40 text-ink",
    next: "bg-svc-bonus text-svc-bonus-ink",
    warning: "border border-line bg-surface text-ink",
  },
  venue: {
    info: "bg-svc-venue/35 text-ink",
    next: "bg-svc-venue text-svc-venue-ink",
    warning: "border border-line bg-surface text-ink",
  },
};

/** Одно предложение под тайтлом, если лид не в шапке shell. */
export function ServicePageLead({ children }: { children: ReactNode }) {
  return <p className="text-[13px] leading-snug text-muted">{children}</p>;
}

export function ServiceInformer({
  service,
  tone = "info",
  children,
}: {
  service: AppServiceKind;
  tone?: "info" | "next" | "warning";
  children: ReactNode;
}) {
  return (
    <p
      className={`rounded-[14px] px-3.5 py-2.5 text-[13px] font-semibold leading-snug ${INFORMER[service][tone]}`}
    >
      {children}
    </p>
  );
}

export function ServiceSection({
  label,
  title,
  action,
  children,
}: {
  label?: string;
  title?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section>
      {label || title || action ? (
        <div className="mb-3 flex items-end justify-between gap-2">
          <div className="min-w-0">
            {label ? (
              <p className="text-[12px] font-bold uppercase tracking-wide text-muted">{label}</p>
            ) : null}
            {title ? <h2 className="text-[14px] font-bold text-ink">{title}</h2> : null}
          </div>
          {action}
        </div>
      ) : null}
      {children}
    </section>
  );
}

export function ServiceTile({
  service,
  href,
  title,
  subtitle,
  icon: Icon,
  onClick,
  disabled,
}: {
  service: AppServiceKind;
  href?: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  onClick?: () => void;
  disabled?: boolean;
}) {
  const className = `group flex w-full items-start gap-3 rounded-[16px] border border-line bg-surface p-4 text-left transition disabled:opacity-60 ${TILE_HOVER[service]}`;
  const body = (
    <>
      <span
        className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-[12px] ${ICON_BOX[service]}`}
      >
        <Icon className="h-5 w-5" strokeWidth={2} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="flex items-center gap-1 text-[15px] font-bold text-ink">
          {title}
          <ChevronRight className="h-4 w-4 text-muted opacity-0 transition group-hover:opacity-100" />
        </span>
        <span className="mt-0.5 block text-[12px] leading-snug text-muted">{subtitle}</span>
      </span>
    </>
  );

  if (href) {
    return (
      <Link href={href} className={className}>
        {body}
      </Link>
    );
  }

  return (
    <button type="button" onClick={onClick} disabled={disabled} className={className}>
      {body}
    </button>
  );
}

export function ServiceListShimmer({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-2" aria-busy="true" aria-label="Загрузка">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
          <div className="flex items-center gap-3">
            <ShimmerBone className="h-10 w-10 shrink-0 rounded-[12px]" />
            <div className="min-w-0 flex-1 space-y-2">
              <ShimmerBone className="h-4 w-[55%] max-w-[12rem] rounded-md" />
              <ShimmerBone className="h-3 w-[35%] max-w-[8rem] rounded-md" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

/** Подтверждение необратимого действия: удаление, снятие с работы. */
export function ServiceConfirmDialog({
  open,
  title,
  body,
  confirmLabel,
  cancelLabel = "Оставить",
  busy = false,
  error,
  onConfirm,
  onCancel,
}: {
  open: boolean;
  title: string;
  body: ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  busy?: boolean;
  error?: string | null;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const titleId = useId();
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      onClick={() => {
        if (!busy) onCancel();
      }}
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
            onClick={onCancel}
            disabled={busy}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg disabled:opacity-50"
            aria-label="Закрыть"
          >
            <X className="h-5 w-5" strokeWidth={2} />
          </button>
        </div>
        <div className="space-y-4 px-4 py-4">
          <p className="text-[14px] leading-snug text-ink">{body}</p>
          {error ? <p className="text-[13px] text-destructive">{error}</p> : null}
          <div className="flex gap-2">
            <AppButton variant="outline" className="flex-1" disabled={busy} onClick={onCancel}>
              {cancelLabel}
            </AppButton>
            <AppButton
              variant="outline"
              className="flex-1 !border-destructive/40 !text-destructive"
              loading={busy}
              onClick={onConfirm}
            >
              {confirmLabel}
            </AppButton>
          </div>
        </div>
      </div>
    </div>
  );
}

export function ServiceEmpty({
  children,
  action,
}: {
  children: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="rounded-[14px] border border-dashed border-line bg-bg px-3.5 py-5 text-center">
      <p className="text-[13px] text-muted">{children}</p>
      {action ? <div className="mt-3 flex justify-center">{action}</div> : null}
    </div>
  );
}
