"use client";

import {
  Bookmark,
  Building2,
  CalendarDays,
  ChevronRight,
  Folder,
  Info,
  Layers,
  UserRound,
} from "lucide-react";
import Link from "next/link";
import { serviceTileIcon, type AppServiceKind } from "@/lib/service-accent";
import { SettingsShell } from "@/features/settings/components/settings-shell";

type HubItem = {
  href: string;
  label: string;
  subtitle: string;
  icon: typeof Bookmark;
  service?: AppServiceKind;
};

function buildSections(
  hasBookingTag: boolean,
  hasAttendanceTag: boolean,
  hasResourcesTag: boolean,
): {
  title: string;
  items: HubItem[];
}[] {
  const serviceItems: HubItem[] = [];
  if (hasBookingTag) {
    serviceItems.push({
      href: "/app/settings/booking",
      label: "Запись",
      subtitle: "Услуги, inbox и расписание хозяина",
      icon: CalendarDays,
      service: "booking",
    });
  }
  if (hasAttendanceTag) {
    serviceItems.push({
      href: "/app/settings/attendance",
      label: "Посещаемость",
      subtitle: "Компании, геозона и работники",
      icon: Building2,
      service: "attendance",
    });
  }
  if (hasResourcesTag) {
    serviceItems.push({
      href: "/app/settings/resources",
      label: "Ресурсы",
      subtitle: "Местоположения и фильтры витрины",
      icon: Layers,
      service: "resources",
    });
  }
  serviceItems.push({
    href: "/app/settings/guide",
    label: "Гайд",
    subtitle: "Запись, посещаемость и ресурсы",
    icon: Info,
  });
  serviceItems.push({
    href: "/app/settings/booking/my",
    label: "Мои бронирования",
    subtitle: "Где вы клиент — без тега хозяина",
    icon: CalendarDays,
    service: "booking",
  });

  return [
    { title: "Сервисы", items: serviceItems },
    {
      title: "Архивы",
      items: [
        {
          href: "/app/settings/saved",
          label: "Сохранённые посты",
          subtitle: "Посты, которые вы сохранили",
          icon: Bookmark,
        },
        {
          href: "/app/settings/archives/clusters",
          label: "Кластеры",
          subtitle: "Архивные коллекции профиля",
          icon: Folder,
        },
      ],
    },
    {
      title: "Аккаунт",
      items: [
        {
          href: "/app/settings/account",
          label: "Аккаунт",
          subtitle: "Тема, язык, выход",
          icon: UserRound,
        },
      ],
    },
    {
      title: "О приложении",
      items: [
        {
          href: "/app/settings/about",
          label: "О приложении",
          subtitle: "Clover и версия сайта",
          icon: Info,
        },
      ],
    },
  ];
}

type Props = {
  hasBookingTag?: boolean;
  hasAttendanceTag?: boolean;
  hasResourcesTag?: boolean;
};

export function SettingsHubView({
  hasBookingTag = false,
  hasAttendanceTag = false,
  hasResourcesTag = false,
}: Props) {
  const sections = buildSections(hasBookingTag, hasAttendanceTag, hasResourcesTag);

  return (
    <SettingsShell title="Настройки" backHref="/app/profile">
      <div className="space-y-6 px-4 py-5">
        {sections.map((section) => (
          <section key={section.title}>
            <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
              {section.title}
            </p>
            <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
              {section.items.map((item) => {
                const Icon = item.icon;
                const hover =
                  item.service === "resources"
                    ? "hover:bg-svc-resources/40"
                    : item.service === "booking"
                      ? "hover:bg-svc-booking/40"
                      : item.service === "attendance"
                        ? "hover:bg-svc-attendance/40"
                        : "hover:bg-bg";
                return (
                  <li key={`${item.href}:${item.label}`} className="border-b border-line last:border-0">
                    <Link
                      href={item.href}
                      className={`flex items-center gap-3 px-3.5 py-3.5 transition ${hover}`}
                    >
                      <span
                        className={
                          item.service
                            ? serviceTileIcon(item.service)
                            : "flex h-10 w-10 items-center justify-center rounded-[12px] bg-mint text-brand"
                        }
                      >
                        <Icon className="h-5 w-5" strokeWidth={2} />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block text-[15px] font-bold text-ink">{item.label}</span>
                        <span className="block text-[12px] text-muted">{item.subtitle}</span>
                      </span>
                      <ChevronRight className="h-5 w-5 text-muted" strokeWidth={2} />
                    </Link>
                  </li>
                );
              })}
            </ul>
          </section>
        ))}
      </div>
    </SettingsShell>
  );
}
