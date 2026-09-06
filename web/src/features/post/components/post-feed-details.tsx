"use client";

import { useEffect, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import {
  countdownPhase,
  formatCountdownBadge,
  formatEventStart,
} from "@/features/post/lib/format-event-time";
import {
  regionLine,
  type FeedBookingService,
  type FeedMarker,
  type FeedPost,
  type FeedProfileFilter,
  type FeedTag,
} from "@/features/post/lib/parse-feed";

function LeftBorder({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-l-[3px] border-brand pl-3 py-0.5">
      {children}
    </div>
  );
}

function TagChips({ tags }: { tags: FeedTag[] }) {
  if (tags.length === 0) return null;
  return (
    <div className="flex flex-wrap gap-1.5">
      {tags.map((tag) => (
        <span
          key={tag.id}
          className="rounded-lg px-2.5 py-[5px] text-[11px] font-bold text-brand"
          style={{ background: "color-mix(in srgb, var(--brand) 6%, transparent)" }}
        >
          #{tag.label.toLowerCase()}
        </span>
      ))}
    </div>
  );
}

function ProfileFilterChips({ filters }: { filters: FeedProfileFilter[] }) {
  if (filters.length === 0) return null;
  return (
    <div className="flex flex-wrap gap-1.5">
      {filters.map((f, i) => (
        <span
          key={`${f.categoryId}-${f.label}-${i}`}
          className="rounded-[10px] border px-[9px] py-1 text-[11px] font-semibold leading-tight text-ink"
          style={{
            background: "color-mix(in srgb, var(--success-soft) 55%, transparent)",
            borderColor: "color-mix(in srgb, var(--brand) 18%, transparent)",
          }}
        >
          {f.label}
        </span>
      ))}
    </div>
  );
}

function MarkerCountdown({ eventTime, endTime }: { eventTime: string; endTime: string | null }) {
  const [now, setNow] = useState(() => new Date());
  const phase = countdownPhase(eventTime, endTime, now);

  useEffect(() => {
    if (phase === "finished") return;
    const intervalMs = phase === "beforeDays" ? 60_000 : 1_000;
    const id = window.setInterval(() => setNow(new Date()), intervalMs);
    return () => window.clearInterval(id);
  }, [eventTime, endTime, phase]);

  const { text, live } = formatCountdownBadge(eventTime, endTime, now);
  return (
    <span
      className={`shrink-0 rounded-[10px] px-2.5 py-[5px] text-[10px] font-extrabold uppercase tracking-[0.03em] ${
        live ? "bg-brand text-on-brand" : "text-muted"
      }`}
      style={live ? undefined : { background: "color-mix(in srgb, var(--ink) 5%, transparent)" }}
    >
      {text}
    </span>
  );
}

function EmojiCityRow({
  emoji,
  countryCode,
  cityCode,
}: {
  emoji: string;
  countryCode: string | null;
  cityCode: string | null;
}) {
  const region = regionLine(countryCode, cityCode);
  if (!emoji && !region) return null;
  return (
    <div className="flex items-center gap-2.5">
      {emoji ? (
        <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-surface shadow-elevate-sm text-base leading-none">
          {emoji}
        </span>
      ) : null}
      {region ? <p className="min-w-0 flex-1 truncate text-[12px] font-semibold text-muted">{region}</p> : null}
    </div>
  );
}

function AddressBlock({ primary, secondary }: { primary: string; secondary: string | null }) {
  return (
    <LeftBorder>
      <p className="text-[10px] font-bold tracking-[0.05em] text-muted">АДРЕС И ОРИЕНТИР</p>
      <p className="mt-1 text-[16px] font-extrabold leading-[1.3] text-ink">{primary}</p>
      {secondary ? <p className="mt-0.5 text-[13px] font-normal text-muted">{secondary}</p> : null}
    </LeftBorder>
  );
}

function MarkerDetails({ marker }: { marker: FeedMarker }) {
  const emoji = marker.textEmoji.trim();
  const primary = marker.addressPrimary?.trim() || null;
  const secondaryRaw = marker.addressCyrillic?.trim() || null;
  const secondary =
    secondaryRaw && secondaryRaw !== primary ? secondaryRaw : null;
  const start = marker.eventTime;

  return (
    <div className="flex flex-col gap-5">
      <EmojiCityRow emoji={emoji} countryCode={marker.countryCode} cityCode={marker.cityCode} />
      {primary ? <AddressBlock primary={primary} secondary={secondary} /> : null}
      {start ? (
        <LeftBorder>
          <div className="flex items-center gap-3">
            <div className="min-w-0 flex-1">
              <p className="text-[10px] font-bold tracking-[0.05em] text-muted">ДАТА И ВРЕМЯ</p>
              <p className="mt-1 text-[14px] font-bold text-ink">{formatEventStart(start)}</p>
            </div>
            <MarkerCountdown eventTime={start} endTime={marker.endTime} />
          </div>
        </LeftBorder>
      ) : null}
      <TagChips tags={marker.tags} />
    </div>
  );
}

function PublicationDetails({ post }: { post: FeedPost }) {
  const emoji = post.textEmoji?.trim() ?? "";
  const primary = post.addressPrimary?.trim() || null;
  const secondaryRaw = post.addressCyrillic?.trim() || null;
  const secondary =
    secondaryRaw && secondaryRaw !== primary ? secondaryRaw : null;
  const has =
    Boolean(emoji) || post.tags.length > 0 || Boolean(primary);
  if (!has) return null;

  return (
    <div className="flex flex-col gap-5">
      <EmojiCityRow emoji={emoji} countryCode={post.countryCode} cityCode={post.cityCode} />
      {primary ? <AddressBlock primary={primary} secondary={secondary} /> : null}
      <TagChips tags={post.tags} />
    </div>
  );
}

function bookingSubtitle(service: FeedBookingService): string {
  const price =
    service.price === Math.round(service.price)
      ? `${Math.round(service.price)} ₸`
      : `${service.price.toFixed(0)} ₸`;
  return `${service.emojiText} ${service.title} · ${service.durationMinutes} мин · ${price}`;
}

function BookingSection({
  service,
  authorId,
  currentUserId,
}: {
  service: FeedBookingService | null;
  authorId: string;
  currentUserId: string | null;
}) {
  if (!service || !service.isActive) return null;
  const isOwn = Boolean(currentUserId && currentUserId === authorId);
  return (
    <div className="mx-5 mb-4 rounded-2xl border border-svc-booking-ink/30 bg-svc-booking/50 p-4">
      <p className="text-[13px] font-bold text-muted">Запись на услугу</p>
      <p className="mt-1.5 text-[15px] font-bold text-ink">{bookingSubtitle(service)}</p>
      {!isOwn ? (
        <AppButtonLink
          href={`/app/u/${authorId}/book?service=${encodeURIComponent(service.id)}`}
          size="row"
          service="booking"
          className="mt-3 w-full"
        >
          Записаться на эту услугу
        </AppButtonLink>
      ) : null}
    </div>
  );
}

/**
 * Блок под реакциями: caption + маркер (адрес/время/теги) + фильтры + услуга.
 * Как PostFeedCardDetails / PostMarkerInfoSection.
 */
export function PostFeedDetails({
  post,
  currentUserId = null,
}: {
  post: FeedPost;
  currentUserId?: string | null;
}) {
  const authorName = post.authorUsername?.trim() || "noName";
  const title = post.title?.trim() ?? "";
  const description = post.description?.trim() ?? "";
  const likesLabel = post.likesCount > 0 ? `нравится ${post.likesCount}` : null;
  const dislikesLabel = post.dislikesCount > 0 ? `не нравится ${post.dislikesCount}` : null;
  const hasCaption =
    Boolean(authorName) ||
    Boolean(likesLabel) ||
    Boolean(dislikesLabel) ||
    Boolean(title) ||
    Boolean(description) ||
    post.profileFilters.length > 0;

  const marker = post.marker;
  const showPublicationFallback = !marker && (
    Boolean(post.textEmoji?.trim()) ||
    post.tags.length > 0 ||
    Boolean(post.addressPrimary?.trim())
  );

  return (
    <>
      <div className="px-5 py-4">
        {hasCaption ? (
          <div>
            <p className="text-[14px] leading-snug tracking-[-0.02em] text-ink">
              <span className="font-extrabold">{authorName} </span>
              {likesLabel ? <span className="font-normal">{likesLabel}</span> : null}
              {likesLabel && dislikesLabel ? <span className="font-normal text-muted"> · </span> : null}
              {dislikesLabel ? <span className="font-normal">{dislikesLabel}</span> : null}
            </p>

            {post.profileFilters.length > 0 ? (
              <div className="mt-2">
                <ProfileFilterChips filters={post.profileFilters} />
              </div>
            ) : null}

            {title ? (
              <p className="mt-1.5 text-[20px] font-bold leading-[1.25] tracking-[-0.02em] text-ink">
                {title}
              </p>
            ) : null}

            {description ? (
              <p className="mt-2 whitespace-pre-wrap text-[15px] font-normal leading-[1.45] text-muted">
                {description}
              </p>
            ) : null}
          </div>
        ) : null}

        {marker ? (
          <div className={hasCaption ? "mt-6" : ""}>
            <MarkerDetails marker={marker} />
          </div>
        ) : showPublicationFallback ? (
          <div className={hasCaption ? "mt-6" : ""}>
            <PublicationDetails post={post} />
          </div>
        ) : null}
      </div>

      <BookingSection
        service={post.bookingService}
        authorId={post.userId}
        currentUserId={currentUserId}
      />
    </>
  );
}
