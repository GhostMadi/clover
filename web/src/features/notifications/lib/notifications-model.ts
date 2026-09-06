export type NotificationKind =
  | "like"
  | "dislike"
  | "comment"
  | "commentLike"
  | "commentDislike"
  | "followedYou"
  | "mutualFollow"
  | "bookingCreatedHost"
  | "bookingBookedClient"
  | "bookingReminderClient"
  | "bookingVisitStarted"
  | "bookingVisitNeedsClose"
  | "bookingCancelledHost"
  | "bookingCancelledClient"
  | "bookingCompletedClient"
  | "bookingNoShowClient"
  | "attendanceInvite"
  | "attendanceRulesAck"
  | "attendanceDuty"
  | "attendanceCorrection";

export type NotificationActor = {
  id: string;
  username: string;
  avatarUrl: string | null;
};

export type AppNotification = {
  id: string;
  kind: NotificationKind;
  actor: NotificationActor;
  createdAt: string;
  postId: string | null;
  commentId: string | null;
  postPreviewUrl: string | null;
  commentPreview: string | null;
  isReply: boolean;
  isUnread: boolean;
  showFollowButton: boolean;
  isFollowingActor: boolean;
  bookingId: string | null;
  bookingServiceTitle: string | null;
  bookingStartsAt: string | null;
  bonusEarnAmount: number | null;
  bookingReminderMinutesBefore: number | null;
};

export const NOTIFICATIONS_PAGE_SIZE = 24;

function parseKind(kindRaw: string, isFollowingActor: boolean): NotificationKind {
  switch (kindRaw) {
    case "post_like":
      return "like";
    case "post_dislike":
      return "dislike";
    case "post_comment":
      return "comment";
    case "comment_reply":
      return "comment";
    case "comment_like":
      return "commentLike";
    case "comment_dislike":
      return "commentDislike";
    case "user_follow":
      return isFollowingActor ? "mutualFollow" : "followedYou";
    case "booking_created_host":
      return "bookingCreatedHost";
    case "booking_booked_client":
      return "bookingBookedClient";
    case "booking_reminder_client":
      return "bookingReminderClient";
    case "booking_visit_started":
      return "bookingVisitStarted";
    case "booking_visit_needs_close":
      return "bookingVisitNeedsClose";
    case "booking_cancelled_host":
      return "bookingCancelledHost";
    case "booking_cancelled_client":
      return "bookingCancelledClient";
    case "booking_completed_client":
      return "bookingCompletedClient";
    case "booking_no_show_client":
      return "bookingNoShowClient";
    case "attendance_invite":
      return "attendanceInvite";
    case "attendance_rules_ack":
      return "attendanceRulesAck";
    case "attendance_duty":
      return "attendanceDuty";
    case "attendance_correction":
      return "attendanceCorrection";
    default:
      return "comment";
  }
}

export function parseNotificationRow(row: Record<string, unknown>): AppNotification | null {
  const id = String(row.id ?? "").trim();
  if (!id) return null;
  const kindRaw = String(row.kind ?? "").trim();
  if (!kindRaw) return null;

  const actorRaw = row.actor;
  if (!actorRaw || typeof actorRaw !== "object") return null;
  const a = actorRaw as Record<string, unknown>;
  const actorId = String(a.id ?? "").trim();
  if (!actorId) return null;
  const username = String(a.username ?? "").trim() || "noName";
  const avatarUrl = (a.avatar_url as string | null | undefined)?.trim() || null;

  const payloadRaw = row.payload;
  const payload =
    payloadRaw && typeof payloadRaw === "object"
      ? (payloadRaw as Record<string, unknown>)
      : {};

  const createdAt = String(row.created_at ?? "");
  if (!createdAt) return null;

  const isFollowingActor = row.is_following_actor === true;
  const kind = parseKind(kindRaw, isFollowingActor);
  const commentPreview = (payload.comment_preview as string | null | undefined)?.trim() || null;
  const serviceTitle = (payload.service_title as string | null | undefined)?.trim() || null;
  const bonusRaw = payload.bonus_earn_amount;
  const bonus =
    typeof bonusRaw === "number"
      ? bonusRaw
      : typeof bonusRaw === "string"
        ? Number(bonusRaw) || null
        : null;
  const reminderRaw = payload.minutes_before;
  const reminder =
    typeof reminderRaw === "number"
      ? reminderRaw
      : typeof reminderRaw === "string"
        ? Number(reminderRaw) || null
        : null;

  return {
    id,
    kind,
    actor: { id: actorId, username, avatarUrl },
    createdAt,
    postId: (row.post_id as string | null | undefined)?.trim() || null,
    commentId: (row.comment_id as string | null | undefined)?.trim() || null,
    postPreviewUrl: (row.post_preview_url as string | null | undefined)?.trim() || null,
    commentPreview,
    isReply: kindRaw === "comment_reply" || payload.is_reply === true,
    isUnread: row.read_at == null,
    showFollowButton: kindRaw === "user_follow",
    isFollowingActor,
    bookingId: (row.booking_id as string | null | undefined)?.trim() || null,
    bookingServiceTitle: serviceTitle,
    bookingStartsAt: payload.starts_at ? String(payload.starts_at) : null,
    bonusEarnAmount: bonus && bonus > 0 ? bonus : null,
    bookingReminderMinutesBefore: reminder && reminder > 0 ? reminder : null,
  };
}

export function notificationMessage(item: AppNotification): string {
  const name = `@${item.actor.username}`;
  const service = item.bookingServiceTitle?.trim() || "запись";
  switch (item.kind) {
    case "followedYou":
      return `${name} подписался(-ась) на вас`;
    case "mutualFollow":
      return `${name} подписался(-ась) на вас. Вы подписаны друг на друга`;
    case "like":
      return `${name} лайкнул(а) ваш пост`;
    case "dislike":
      return `${name} дизлайкнул(а) ваш пост`;
    case "comment":
      return item.isReply
        ? `${name} ответил(а) на ваш комментарий`
        : `${name} прокомментировал(а) ваш пост`;
    case "commentLike":
      return `${name} лайкнул(а) ваш комментарий`;
    case "commentDislike":
      return `${name} дизлайкнул(а) ваш комментарий`;
    case "bookingCreatedHost":
      return `${name} записался(-ась): ${service}`;
    case "bookingBookedClient":
      return `Вы записаны: ${service}`;
    case "bookingReminderClient":
      return `Напоминание: ${service}`;
    case "bookingVisitStarted":
      return `Сейчас визит — ${service}`;
    case "bookingVisitNeedsClose":
      return `Закройте визит — ${service}`;
    case "bookingCancelledHost":
      return `${name} отменил(а) запись: ${service}`;
    case "bookingCancelledClient":
      return `${name} отменил(а) вашу запись: ${service}`;
    case "bookingCompletedClient":
      return item.bonusEarnAmount
        ? `Визит завершён: ${service} · +${item.bonusEarnAmount} бонусов`
        : `Визит завершён: ${service}`;
    case "bookingNoShowClient":
      return `Визит отмечен как «не пришёл»: ${service}`;
    case "attendanceInvite":
      return `${name} пригласил(-а) в команду посещаемости`;
    case "attendanceRulesAck":
      return "Новые правила компании — нужно принять";
    case "attendanceDuty":
      return "Обновлён список дежурных";
    case "attendanceCorrection":
      return "Запрос на исправление отметки";
    default:
      return `${name} · уведомление`;
  }
}

export function formatRelativeTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const diff = Date.now() - d.getTime();
  const m = Math.floor(diff / 60_000);
  if (m < 1) return "сейчас";
  if (m < 60) return `${m} мин`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} ч`;
  const days = Math.floor(h / 24);
  if (days < 7) return `${days} д`;
  return d.toLocaleDateString("ru-RU", { day: "numeric", month: "short" });
}
