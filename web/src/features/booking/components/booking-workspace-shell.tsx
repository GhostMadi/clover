"use client";

import {
  BarChart3,
  BookOpen,
  ClipboardList,
  LayoutGrid,
  LayoutTemplate,
  MapPin,
  MessageCircle,
  Scissors,
  Settings2,
} from "lucide-react";
import { useState, useTransition, type ReactNode } from "react";
import { BookingPointChat } from "@/features/booking/components/booking-point-chat";
import { BookingPointSwitcher } from "@/features/booking/components/booking-point-switcher";
import { bookingPointBase } from "@/features/booking/lib/booking-prefs";
import { openBookingPointChat } from "@/features/booking/lib/points-api";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

function pointNav(
  pointId: string,
  chat: { busy: boolean; open: boolean; onSelect: () => void },
): ServiceWorkspaceNavItem[] {
  const base = bookingPointBase(pointId);
  return [
    {
      href: base,
      label: "Обзор",
      match: (p) => !chat.open && (p === base || p === `${base}/`),
      Icon: LayoutGrid,
      group: "main",
    },
    {
      href: `${base}/inbox`,
      label: "Записи",
      match: (p) => !chat.open && p.startsWith(`${base}/inbox`),
      Icon: ClipboardList,
      group: "main",
    },
    {
      href: `${base}/services`,
      label: "Услуги",
      match: (p) => !chat.open && p.startsWith(`${base}/services`),
      Icon: Scissors,
      group: "main",
    },
    {
      href: `${base}/visual`,
      label: "Схема",
      match: (p) => !chat.open && p.startsWith(`${base}/visual`),
      Icon: LayoutTemplate,
      group: "main",
    },
    {
      href: `${base}/analytics`,
      label: "Аналитика",
      match: (p) => !chat.open && p.startsWith(`${base}/analytics`),
      Icon: BarChart3,
      group: "main",
    },
    {
      href: `${base}/settings`,
      label: "Настройки",
      match: (p) => !chat.open && p.startsWith(`${base}/settings`),
      Icon: Settings2,
      group: "main",
    },
    {
      href: `${base}/guide`,
      label: "Гайд",
      match: (p) => !chat.open && p.startsWith(`${base}/guide`),
      Icon: BookOpen,
      group: "main",
    },
    {
      href: `${base}/chat`,
      label: chat.busy ? "Открываем чат…" : "Чат",
      match: () => chat.open,
      Icon: MessageCircle,
      group: "main",
      onSelect: chat.onSelect,
      disabled: chat.busy,
    },
    {
      href: "/app/settings/booking/points",
      label: "Точки",
      match: (p) => !chat.open && p.startsWith("/app/settings/booking/points"),
      Icon: MapPin,
      group: "main",
    },
  ];
}

type BookingWorkspaceShellProps = {
  pointId: string;
  title: string;
  lead?: string;
  children: ReactNode;
  trailing?: ReactNode;
  pointName?: string;
  /** Узкий shell без точек (клиент / calendar) — legacy. */
  hidePointChrome?: boolean;
  backHref?: string;
  hideNav?: boolean;
};

/**
 * Workspace точки записи — тот же каркас, что посещаемость / ресурсы.
 * См. docs/business/website-host-desktop.md
 */
export function BookingWorkspaceShell({
  pointId,
  title,
  lead,
  children,
  trailing,
  pointName,
  hidePointChrome = false,
  backHref,
  hideNav = false,
}: BookingWorkspaceShellProps) {
  const hubPath = bookingPointBase(pointId);
  const [chatBusy, setChatBusy] = useState(false);
  const [chatOpen, setChatOpen] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [chatError, setChatError] = useState<string | null>(null);
  const [, startTransition] = useTransition();
  const entity = hidePointChrome ? undefined : (
    <BookingPointSwitcher pointId={pointId} currentName={pointName} fullWidth />
  );

  const openChat = () => {
    if (chatBusy) return;
    if (chatOpen) {
      setChatOpen(false);
      return;
    }
    if (conversationId) {
      setChatOpen(true);
      return;
    }
    setChatBusy(true);
    setChatError(null);
    startTransition(async () => {
      try {
        const convId = await openBookingPointChat(pointId);
        setConversationId(convId);
        setChatOpen(true);
      } catch (e: unknown) {
        setChatError(e instanceof Error ? e.message : "Не удалось открыть чат");
      } finally {
        setChatBusy(false);
      }
    });
  };

  return (
    <ServiceWorkspaceShell
      service="booking"
      brandTitle="Запись"
      brandSubtitle="Рабочий стол точки"
      title={chatOpen ? "Чат" : title}
      lead={chatOpen ? "Переписка команды этой точки." : lead}
      nav={
        hideNav
          ? []
          : pointNav(pointId, { busy: chatBusy, open: chatOpen, onSelect: openChat })
      }
      hideNav={hideNav}
      hubPath={hubPath}
      hubBackHref="/app/settings/booking/points"
      backHref={backHref ?? `${hubPath}/inbox`}
      entitySlot={entity}
      navNote={chatError ?? undefined}
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {chatOpen && conversationId ? (
        <BookingPointChat
          conversationId={conversationId}
          onClose={() => setChatOpen(false)}
        />
      ) : (
        children
      )}
    </ServiceWorkspaceShell>
  );
}

/** Клиентские экраны без точки (my bookings). */
export function BookingClientShell({
  title,
  children,
  backHref = "/app/settings",
}: {
  title: string;
  children: ReactNode;
  backHref?: string;
}) {
  return (
    <ServiceWorkspaceShell
      service="booking"
      brandTitle="Запись"
      title={title}
      nav={[]}
      hideNav
      hubPath="/app/settings/booking/my"
      hubBackHref={backHref}
      backHref={backHref}
      maxWidthClassName="max-w-[720px]"
    >
      {children}
    </ServiceWorkspaceShell>
  );
}
