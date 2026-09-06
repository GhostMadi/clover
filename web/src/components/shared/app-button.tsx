"use client";

import Link from "next/link";
import {
  type ButtonHTMLAttributes,
  type CSSProperties,
  type ReactNode,
} from "react";
import { useJellyPress } from "@/components/shared/jelly";
import { serviceCtaClasses, type AppServiceKind } from "@/lib/service-accent";

type Variant = "primary" | "outline" | "ghost" | "google";
type Size = "default" | "icon" | "row";

const variants: Record<Variant, string> = {
  primary:
    "bg-brand text-on-brand hover:opacity-90 disabled:opacity-50 shadow-elevate-brand",
  outline:
    "border border-line bg-surface text-ink hover:bg-surface-soft disabled:opacity-50",
  ghost: "border border-line/40 bg-surface-soft/40 text-ink hover:bg-surface-soft disabled:opacity-50",
  google: "border border-line bg-surface text-ink hover:bg-surface-soft disabled:opacity-50",
};

const sizes: Record<Size, string> = {
  default: "h-[52px] w-full rounded-[18px] px-4 text-[15px] font-semibold",
  row: "h-11 rounded-[14px] px-4 text-sm font-semibold sm:h-12",
  icon: "h-11 w-11 shrink-0 rounded-[14px] px-0 sm:h-12 sm:w-12 [&_svg]:h-[22px] [&_svg]:w-[22px]",
};

type AppButtonBase = {
  children: ReactNode;
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  jelly?: boolean;
  className?: string;
  service?: AppServiceKind;
};

type AppButtonProps = AppButtonBase &
  ButtonHTMLAttributes<HTMLButtonElement> & {
    href?: undefined;
  };

type AppButtonLinkProps = AppButtonBase & {
  href: string;
  title?: string;
  "aria-label"?: string;
};

function classes(
  variant: Variant,
  size: Size,
  className: string,
  service?: AppServiceKind,
) {
  const baseVariant =
    service && variant === "primary"
      ? serviceCtaClasses(service)
      : variants[variant];
  const iconOnCta =
    size === "icon" && variant === "primary"
      ? service === "booking"
        ? "!text-svc-booking-ink [&_svg]:!text-svc-booking-ink [&_svg]:!stroke-svc-booking-ink"
        : service
          ? "!text-on-media [&_svg]:!text-on-media [&_svg]:!stroke-on-media"
          : "!text-on-brand [&_svg]:!text-on-brand [&_svg]:!stroke-on-brand"
      : "";
  return `inline-flex items-center justify-center transition-colors ${baseVariant} ${sizes[size]} ${iconOnCta} ${className}`;
}

  /** Stroke/цвет иконки на CTA. */
function brandIconStyle(
  variant: Variant,
  size: Size,
  service: AppServiceKind | undefined,
  extra?: CSSProperties,
): CSSProperties | undefined {
  const force = size === "icon" && variant === "primary";
  if (!force && !extra) return extra;
  const onBooking = force && service === "booking";
  return {
    ...(force
      ? {
          color: onBooking
            ? "var(--svc-booking-ink)"
            : service
              ? "var(--on-media)"
              : "var(--on-brand)",
        }
      : null),
    ...extra,
  };
}

/** CTA как `AppButton` в Flutter: primary / outline / icon (+ service). */
export function AppButton({
  children,
  variant = "primary",
  size = "default",
  className = "",
  loading,
  jelly = true,
  service,
  onClick,
  ...props
}: AppButtonProps) {
  const disabled = Boolean(loading || props.disabled);
  const { style, trigger } = useJellyPress({ disabled: disabled || !jelly });

  return (
    <button
      type="button"
      className={classes(variant, size, className, service)}
      disabled={disabled}
      {...props}
      style={
        jelly
          ? brandIconStyle(variant, size, service, {
              ...style,
              ...(typeof props.style === "object" && props.style ? props.style : {}),
            })
          : brandIconStyle(
              variant,
              size,
              service,
              typeof props.style === "object" && props.style ? props.style : undefined,
            )
      }
      onPointerDown={(e) => {
        props.onPointerDown?.(e);
        if (disabled || !jelly || e.button !== 0 || e.defaultPrevented) return;
        trigger();
      }}
      onClick={onClick}
    >
      {loading ? (
        <span className="h-5 w-5 animate-spin rounded-full border-2 border-current border-r-transparent" />
      ) : (
        children
      )}
    </button>
  );
}

/** Та же кнопка-ссылка (профиль «+», «Редактировать»). */
export function AppButtonLink({
  children,
  href,
  variant = "primary",
  size = "default",
  className = "",
  jelly = true,
  service,
  title,
  "aria-label": ariaLabel,
}: AppButtonLinkProps) {
  const { style, trigger } = useJellyPress({ disabled: !jelly });

  return (
    <Link
      href={href}
      title={title}
      aria-label={ariaLabel}
      className={classes(variant, size, className, service)}
      style={brandIconStyle(variant, size, service, jelly ? style : undefined)}
      onPointerDown={(e) => {
        if (!jelly || e.button !== 0) return;
        trigger();
      }}
    >
      {children}
    </Link>
  );
}
