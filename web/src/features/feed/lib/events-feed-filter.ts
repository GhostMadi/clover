import { isKnownTagKey } from "@/features/catalog/lib/marker-tags";

export type EventsContentKind = "all" | "events_only";

export type EventsFeedFilter = {
  contentKind: EventsContentKind;
  countryCode: string;
  cityCode: string;
  emoji: string | null;
  dateFrom: string | null; // YYYY-MM-DD
  dateTo: string | null;
  tagKeys: string[];
};

export const DEFAULT_EVENTS_FILTER: EventsFeedFilter = {
  contentKind: "all",
  countryCode: "kz",
  cityCode: "almaty",
  emoji: null,
  dateFrom: null,
  dateTo: null,
  tagKeys: [],
};

function parseDateOnly(raw?: string): string | null {
  const v = raw?.trim() ?? "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) return null;
  const d = new Date(`${v}T00:00:00`);
  if (Number.isNaN(d.getTime())) return null;
  return v;
}

export function parseEventsFilter(input: {
  kind?: string;
  country?: string;
  city?: string;
  emoji?: string;
  from?: string;
  to?: string;
  tags?: string;
}): EventsFeedFilter {
  const kind = input.kind === "events" || input.kind === "events_only" ? "events_only" : "all";
  const countryCode = (input.country ?? DEFAULT_EVENTS_FILTER.countryCode).trim().toLowerCase() || "kz";
  const cityCode = (input.city ?? DEFAULT_EVENTS_FILTER.cityCode).trim() || "almaty";
  const emojiRaw = (input.emoji ?? "").trim();
  const emoji =
    kind === "events_only" && emojiRaw
      ? (typeof Intl !== "undefined" && "Segmenter" in Intl
          ? [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(emojiRaw)][0]
              ?.segment ?? null
          : Array.from(emojiRaw)[0] ?? null)
      : null;
  const dateFrom = kind === "events_only" ? parseDateOnly(input.from) : null;
  const dateTo = kind === "events_only" ? parseDateOnly(input.to) : null;
  const tagKeys =
    kind === "events_only"
      ? [
          ...new Set(
            (input.tags ?? "")
              .split(",")
              .map((t) => t.trim())
              .filter((t) => t && isKnownTagKey(t)),
          ),
        ]
      : [];

  return { contentKind: kind, countryCode, cityCode, emoji, dateFrom, dateTo, tagKeys };
}

export function eventsFilterHasExtras(filter: EventsFeedFilter): boolean {
  return Boolean(filter.emoji || filter.dateFrom || filter.dateTo || filter.tagKeys.length > 0);
}
