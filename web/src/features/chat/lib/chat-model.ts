export const CHATS_PAGE_SIZE = 40;
export const MESSAGES_PAGE_SIZE = 50;

export type ChatPeer = {
  id: string;
  username: string;
  avatarUrl: string | null;
};

export type ChatConversation = {
  id: string;
  type: "dm" | "group";
  title: string;
  isGroup: boolean;
  peer: ChatPeer | null;
  lastMessageText: string;
  lastMessageAt: string;
  isLastMessageMine: boolean;
  isRead: boolean;
  unreadCount: number;
  avatarUrl: string | null;
};

export type ChatAttachment = {
  id: string;
  bucket: string;
  path: string;
  mime: string | null;
  sizeBytes: number | null;
  url: string | null;
};

export type ChatPostRef = {
  postId: string;
  caption: string | null;
  title: string | null;
  coverUrl: string | null;
};

export type ChatBookingStaffCard = {
  inviteId: string;
  hostId: string;
  hostDisplayName: string;
};

export type ChatAttendanceCard = {
  card: "attendance_invite" | "attendance_rules";
  workplaceId: string;
  workplaceName: string;
  membershipId: string | null;
  configVersion: number | null;
};

export type ChatMessage = {
  id: string;
  clientMessageId: string | null;
  conversationId: string | null;
  kind: string;
  text: string;
  sentAt: string;
  isMine: boolean;
  isRead: boolean;
  isPending?: boolean;
  sendFailed?: boolean;
  postRef: ChatPostRef | null;
  bookingStaffCard: ChatBookingStaffCard | null;
  attendanceCard: ChatAttendanceCard | null;
  attachments: ChatAttachment[];
  editedAt: string | null;
};

function asMap(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object") return null;
  return value as Record<string, unknown>;
}

function asInt(value: unknown): number {
  if (typeof value === "number") return Math.trunc(value);
  return Number.parseInt(String(value ?? ""), 10) || 0;
}

function previewText(message: Record<string, unknown> | null): string {
  if (!message) return "Нет сообщений";
  const kind = String(message.kind ?? "text");
  const text = String(message.text ?? "").trim();
  switch (kind) {
    case "media":
    case "file":
      return text || "Вложение";
    case "post_ref":
      return "Пост";
    case "attendance_invite":
      return text || "Приглашение в команду";
    case "attendance_rules":
      return text || "Правила посещаемости";
    case "booking_staff_invite":
      return text || "Приглашение в запись";
    case "system":
      return text || "Системное сообщение";
    default:
      return text || "Сообщение";
  }
}

function displayMessageText(
  message: Record<string, unknown>,
  opts: {
    kind: string;
    postRef: ChatPostRef | null;
    bookingStaffCard: ChatBookingStaffCard | null;
    attendanceCard: ChatAttendanceCard | null;
    attachmentCount: number;
  },
): string {
  const text = String(message.text ?? "").trim();
  if (opts.kind === "post_ref" || opts.postRef) {
    return opts.postRef?.caption ?? text;
  }
  if (opts.attendanceCard) {
    return opts.attendanceCard.card === "attendance_invite"
      ? `Приглашение · ${opts.attendanceCard.workplaceName}`
      : `Правила · ${opts.attendanceCard.workplaceName}`;
  }
  if (opts.bookingStaffCard) {
    return (
      text ||
      `Приглашение в запись · ${opts.bookingStaffCard.hostDisplayName}`
    );
  }
  if (opts.kind === "booking_staff_invite") {
    return text || "Приглашение в запись";
  }
  if (opts.kind === "attendance_invite") return text || "Приглашение в команду";
  if (opts.kind === "attendance_rules") return text || "Правила посещаемости";
  if (opts.kind === "text") return text;
  if (text) return text;
  if (opts.kind === "media" || opts.kind === "file") {
    return opts.attachmentCount > 0 ? "Вложение" : "";
  }
  if (opts.kind === "system") return "Системное сообщение";
  return text;
}

function parseBookingStaffCard(
  raw: unknown,
): ChatBookingStaffCard | null {
  const map = asMap(raw);
  if (!map) return null;
  if (String(map.card ?? "") !== "booking_staff_invite") return null;
  const inviteId = String(map.invite_id ?? "").trim();
  const hostId = String(map.host_id ?? "").trim();
  if (!inviteId || !hostId) return null;
  const hostDisplayName =
    String(map.host_display_name ?? "").trim() || "аккаунт";
  return { inviteId, hostId, hostDisplayName };
}

function parseAttendanceCard(raw: unknown): ChatAttendanceCard | null {
  const map = asMap(raw);
  if (!map) return null;
  const card = String(map.card ?? "").trim();
  if (card !== "attendance_invite" && card !== "attendance_rules") return null;
  const workplaceId = String(map.workplace_id ?? "").trim();
  if (!workplaceId) return null;
  return {
    card,
    workplaceId,
    workplaceName: String(map.workplace_name ?? "").trim() || "компания",
    membershipId: String(map.membership_id ?? "").trim() || null,
    configVersion:
      typeof map.config_version === "number"
        ? Math.trunc(map.config_version)
        : Number.parseInt(String(map.config_version ?? ""), 10) || null,
  };
}

export function publicStorageUrl(bucket: string, path: string): string | null {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
  if (!base || !bucket || !path) return null;
  if (bucket === "r2") return null;
  return `${base}/storage/v1/object/public/${bucket}/${path}`;
}

export function parseConversationRow(
  row: Record<string, unknown>,
  currentUserId: string,
): ChatConversation | null {
  const id = String(row.conversation_id ?? "").trim();
  if (!id) return null;
  const typeRaw = String(row.type ?? "dm");
  const isGroup = typeRaw === "group";
  const title = String(row.title ?? "").trim();
  const other = asMap(row.other_user);
  const peer: ChatPeer | null = other
    ? {
        id: String(other.id ?? "").trim(),
        username: String(other.username ?? "").trim() || "чат",
        avatarUrl: (other.avatar_url as string | null | undefined)?.trim() || null,
      }
    : null;
  const last = asMap(row.last_message);
  const unreadCount = asInt(row.unread_count);
  const senderId = last ? String(last.sender_id ?? "").trim() : "";
  const isLastMessageMine = Boolean(senderId && senderId === currentUserId);
  const lastMessageAt =
    (last && String(last.created_at ?? "")) ||
    String(row.created_at ?? "") ||
    new Date().toISOString();
  const displayName = isGroup
    ? title || "Групповой чат"
    : peer?.username || "Чат";
  const isRead = isLastMessageMine
    ? last?.read_by_peer === true
    : unreadCount <= 0;

  return {
    id,
    type: isGroup ? "group" : "dm",
    title: displayName,
    isGroup,
    peer: peer?.id ? peer : null,
    lastMessageText: previewText(last),
    lastMessageAt,
    isLastMessageMine,
    isRead,
    unreadCount,
    avatarUrl: peer?.avatarUrl ?? null,
  };
}

export function parseMessageRow(
  row: Record<string, unknown>,
  currentUserId: string,
): ChatMessage | null {
  const message = asMap(row.message);
  if (!message) return null;
  const id = String(message.id ?? "").trim();
  if (!id) return null;
  const senderId = String(message.sender_id ?? "").trim();
  const kind = String(message.kind ?? "text");
  const postRaw = asMap(row.post_ref);
  const postRef: ChatPostRef | null = postRaw
    ? {
        postId: String(postRaw.post_id ?? "").trim(),
        caption: (postRaw.caption as string | null | undefined)?.trim() || null,
        title: (postRaw.title as string | null | undefined)?.trim() || null,
        coverUrl: (postRaw.cover_url as string | null | undefined)?.trim() || null,
      }
    : null;
  if (postRef && !postRef.postId) {
    // invalid
  }
  const validPost =
    postRef && postRef.postId
      ? postRef
      : null;

  const bookingStaffCard = parseBookingStaffCard(row.booking_card);
  const attendanceCard = parseAttendanceCard(row.attendance_card);

  const attachmentsRaw = Array.isArray(row.attachments) ? row.attachments : [];
  const attachments: ChatAttachment[] = [];
  for (const raw of attachmentsRaw) {
    const a = asMap(raw);
    if (!a) continue;
    const path = String(a.path ?? "").trim();
    if (!path) continue;
    const bucket = String(a.bucket ?? "chat_media").trim() || "chat_media";
    const publicUrl = String(a.public_url ?? a.url ?? "").trim();
    attachments.push({
      id: String(a.id ?? "").trim(),
      bucket,
      path,
      mime: (a.mime as string | null | undefined)?.trim() || null,
      sizeBytes: typeof a.size_bytes === "number" ? a.size_bytes : Number(a.size_bytes) || null,
      url: publicUrl || publicStorageUrl(bucket, path),
    });
  }

  return {
    id,
    clientMessageId: (message.client_message_id as string | null | undefined)?.trim() || null,
    conversationId: (message.conversation_id as string | null | undefined)?.trim() || null,
    kind,
    text: displayMessageText(message, {
      kind,
      postRef: validPost,
      bookingStaffCard,
      attendanceCard,
      attachmentCount: attachments.length,
    }),
    sentAt: String(message.created_at ?? new Date().toISOString()),
    isMine: senderId === currentUserId,
    isRead: senderId === currentUserId && message.read_by_peer === true,
    postRef: validPost,
    bookingStaffCard,
    attendanceCard,
    attachments,
    editedAt: (message.edited_at as string | null | undefined)?.trim() || null,
  };
}

export function formatChatListTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diffDays = Math.floor((today.getTime() - day.getTime()) / 86_400_000);
  if (diffDays === 0) {
    return d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
  }
  if (diffDays === 1) return "Вчера";
  if (diffDays < 7) {
    const weekdays = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"];
    return weekdays[d.getDay()] ?? "";
  }
  return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit" });
}

export function formatMessageTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
}

export function formatMessageDayLabel(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diffDays = Math.floor((today.getTime() - day.getTime()) / 86_400_000);
  if (diffDays === 0) return "Сегодня";
  if (diffDays === 1) return "Вчера";
  return d.toLocaleDateString("ru-RU", {
    day: "numeric",
    month: "long",
    year: d.getFullYear() !== now.getFullYear() ? "numeric" : undefined,
  });
}
