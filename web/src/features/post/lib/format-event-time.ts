/** Формат даты ивента как AppTimePicker.formatEventStart. */

const MONTHS = [
  "января",
  "февраля",
  "марта",
  "апреля",
  "мая",
  "июня",
  "июля",
  "августа",
  "сентября",
  "октября",
  "ноября",
  "декабря",
];

const WEEKDAYS = [
  "понедельник",
  "вторник",
  "среда",
  "четверг",
  "пятница",
  "суббота",
  "воскресенье",
];

function pad2(n: number) {
  return n.toString().padStart(2, "0");
}

function formatDaysRemaining(days: number): string {
  const mod10 = days % 10;
  const mod100 = days % 100;
  if (mod10 === 1 && mod100 !== 11) return `${days} день`;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return `${days} дня`;
  return `${days} дней`;
}

function formatHms(totalSeconds: number): string {
  const clamped = Math.max(0, Math.min(totalSeconds, 99 * 3600 + 59 * 60 + 59));
  const h = Math.floor(clamped / 3600);
  const m = Math.floor((clamped % 3600) / 60);
  const s = clamped % 60;
  return `${pad2(h)}:${pad2(m)}:${pad2(s)}`;
}

/** «15 июня, суббота · 14:30» */
export function formatEventStart(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const weekday = WEEKDAYS[(d.getDay() + 6) % 7]; // Mon=0
  const time = `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
  return `${d.getDate()} ${MONTHS[d.getMonth()]}, ${weekday} · ${time}`;
}

export type CountdownPhase = "beforeDays" | "beforeHours" | "live" | "finished";

export function countdownPhase(isoStart: string, isoEnd: string | null | undefined, now = new Date()): CountdownPhase {
  const start = new Date(isoStart);
  if (Number.isNaN(start.getTime())) return "finished";
  const end = isoEnd ? new Date(isoEnd) : null;

  if (now < start) {
    const ms = start.getTime() - now.getTime();
    return ms >= 86_400_000 ? "beforeDays" : "beforeHours";
  }
  if (end && !Number.isNaN(end.getTime()) && now < end) return "live";
  return "finished";
}

/** Текст бейджа как у `_PostMarkerCountdown`. */
export function formatCountdownBadge(
  isoStart: string,
  isoEnd: string | null | undefined,
  now = new Date(),
): { text: string; live: boolean } {
  const start = new Date(isoStart);
  const end = isoEnd ? new Date(isoEnd) : null;
  const phase = countdownPhase(isoStart, isoEnd, now);

  switch (phase) {
    case "beforeDays": {
      const days = Math.floor((start.getTime() - now.getTime()) / 86_400_000);
      return { text: `через ${formatDaysRemaining(days)}`, live: false };
    }
    case "beforeHours":
      return {
        text: formatHms(Math.floor((start.getTime() - now.getTime()) / 1000)),
        live: false,
      };
    case "live":
      if (!end || Number.isNaN(end.getTime())) return { text: "LIVE", live: true };
      return {
        text: formatHms(Math.floor((end.getTime() - now.getTime()) / 1000)),
        live: true,
      };
    case "finished":
      return { text: "Завершено", live: false };
  }
}
