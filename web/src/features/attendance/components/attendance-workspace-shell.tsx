"use client";

import {
  BarChart3,
  BookOpen,
  Building2,
  CalendarClock,
  ClipboardList,
  LayoutGrid,
  MessageCircle,
  Settings2,
  Users,
  Wallet,
} from "lucide-react";
import { useEffect, useState, useTransition, type ReactNode } from "react";
import { AttendanceCompanyChat } from "@/features/attendance/components/attendance-company-chat";
import { AttendanceCompanySwitcher } from "@/features/attendance/components/attendance-company-switcher";
import { getAdminWorkplace } from "@/features/attendance/lib/attendance-api";
import {
  ServiceWorkspaceShell,
  type ServiceWorkspaceNavItem,
} from "@/features/shared/components/service-workspace-shell";

function workplaceNav(
  workplaceId: string,
  chat: { busy: boolean; open: boolean; onSelect: () => void },
): ServiceWorkspaceNavItem[] {
  const base = `/app/settings/attendance/w/${workplaceId}`;
  return [
    {
      href: base,
      label: "Сегодня",
      match: (p) => !chat.open && (p === base || p === `${base}/`),
      Icon: LayoutGrid,
      group: "main",
    },
    {
      href: `${base}/members`,
      label: "Люди",
      match: (p) => !chat.open && p.startsWith(`${base}/members`),
      Icon: Users,
      group: "main",
    },
    {
      href: `${base}/duty`,
      label: "Дежурства",
      match: (p) => !chat.open && p.startsWith(`${base}/duty`),
      Icon: CalendarClock,
      group: "main",
    },
    {
      href: `${base}/timesheet`,
      label: "Табель",
      match: (p) => !chat.open && p.startsWith(`${base}/timesheet`),
      Icon: ClipboardList,
      group: "main",
    },
    {
      href: `${base}/payroll`,
      label: "Зарплата",
      match: (p) => !chat.open && p.startsWith(`${base}/payroll`),
      Icon: Wallet,
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
      href: "/app/settings/attendance/companies",
      label: "Компании",
      match: (p) =>
        !chat.open &&
        (p === "/app/settings/attendance/companies" ||
          p.startsWith("/app/settings/attendance/companies/")),
      Icon: Building2,
      group: "main",
    },
  ];
}

type AttendanceWorkspaceShellProps = {
  workplaceId: string;
  title: string;
  lead?: string;
  children: ReactNode;
  trailing?: ReactNode;
  brandSubtitle?: string;
  /** Имя компании для селектора (если title — другой экран). */
  companyName?: string;
};

/**
 * Workspace компании — тот же каркас, что Запись / Ресурсы.
 * См. docs/business/website-host-desktop.md
 */
export function AttendanceWorkspaceShell({
  workplaceId,
  title,
  lead,
  children,
  trailing,
  brandSubtitle = "Рабочий стол компании",
  companyName,
}: AttendanceWorkspaceShellProps) {
  const hubPath = `/app/settings/attendance/w/${workplaceId}`;
  const [chatBusy, setChatBusy] = useState(false);
  const [chatOpen, setChatOpen] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [chatError, setChatError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  useEffect(() => {
    setChatOpen(false);
    setConversationId(null);
    setChatError(null);
  }, [workplaceId]);

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
        const workplace = await getAdminWorkplace(workplaceId);
        const convId = workplace?.groupConversationId ?? null;
        if (!convId) {
          setChatError("Чата компании пока нет");
          return;
        }
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
      service="attendance"
      brandTitle="Посещаемость"
      brandSubtitle={brandSubtitle}
      title={chatOpen ? "Чат" : title}
      lead={chatOpen ? "Переписка команды этой компании." : lead}
      nav={workplaceNav(workplaceId, {
        busy: chatBusy,
        open: chatOpen,
        onSelect: openChat,
      })}
      hubPath={hubPath}
      hubBackHref="/app/settings/attendance/companies"
      backHref={hubPath}
      entitySlot={
        <AttendanceCompanySwitcher
          workplaceId={workplaceId}
          currentName={companyName}
          fullWidth
        />
      }
      navNote={chatError ?? undefined}
      trailing={trailing}
      maxWidthClassName="max-w-[1400px]"
    >
      {chatOpen && conversationId ? (
        <AttendanceCompanyChat
          conversationId={conversationId}
          onClose={() => setChatOpen(false)}
        />
      ) : (
        children
      )}
    </ServiceWorkspaceShell>
  );
}
