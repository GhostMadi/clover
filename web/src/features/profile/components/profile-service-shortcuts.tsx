"use client";

import { CalendarDays, CalendarRange } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { AppButtonLink } from "@/components/shared/app-button";
import type { AppServiceKind } from "@/lib/service-accent";

type ShortcutSpec = {
  key: string;
  href: string;
  label: string;
  Icon: LucideIcon;
  service: AppServiceKind;
  variant: "primary" | "outline";
};

function ShortcutLine({ items }: { items: ShortcutSpec[] }) {
  if (items.length === 0) return null;
  const iconOnly = items.length >= 3;

  return (
    <div className="flex gap-2">
      {items.map((item) => {
        const Icon = item.Icon;
        if (iconOnly) {
          return (
            <AppButtonLink
              key={item.key}
              href={item.href}
              size="icon"
              variant={item.variant}
              service={item.service}
              title={item.label}
              aria-label={item.label}
            >
              <Icon strokeWidth={2.25} />
            </AppButtonLink>
          );
        }
        return (
          <AppButtonLink
            key={item.key}
            href={item.href}
            size="row"
            variant={item.variant}
            service={item.service}
            title={item.label}
            className="min-w-0 flex-1 gap-2"
          >
            <Icon className="h-4 w-4 shrink-0" strokeWidth={2.25} />
            <span className="truncate">{item.label}</span>
          </AppButtonLink>
        );
      })}
    </div>
  );
}

type Props = {
  tagKeys: string[];
};

/**
 * Две линии быстрых входов на своём профиле:
 * верх — worker (`bookingCalendar`), низ — admin (`booking`).
 * ≤2 в линии → иконка+текст; ≥3 → только иконка + title.
 */
export function ProfileServiceShortcuts({ tagKeys }: Props) {
  const keys = new Set(tagKeys);

  const worker: ShortcutSpec[] = [];
  if (keys.has("bookingCalendar")) {
    worker.push({
      key: "bookingCalendar",
      href: "/app/settings/booking/calendar",
      label: "Календарь",
      Icon: CalendarRange,
      service: "booking",
      variant: "outline",
    });
  }

  const admin: ShortcutSpec[] = [];
  if (keys.has("booking")) {
    admin.push({
      key: "booking",
      href: "/app/settings/booking",
      label: "Запись",
      Icon: CalendarDays,
      service: "booking",
      variant: "primary",
    });
  }

  if (worker.length === 0 && admin.length === 0) return null;

  return (
    <div className="mt-3 flex max-w-xl flex-col gap-2 sm:mt-4">
      <ShortcutLine items={worker} />
      <ShortcutLine items={admin} />
    </div>
  );
}
