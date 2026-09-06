import type { BookingStatus } from "@/features/booking/lib/booking-model";

export function statusLabelRu(status: BookingStatus): string {
  switch (status) {
    case "pending":
      return "Ожидает";
    case "confirmed":
      return "Подтверждена";
    case "client_arrived":
      return "Клиент пришёл";
    case "in_progress":
      return "В работе";
    case "completed":
      return "Оказана";
    case "cancelled":
      return "Отменена";
    case "no_show":
      return "Не пришёл";
  }
}

export function formatPriceKzt(price: number): string {
  if (Number.isInteger(price)) return `${price} ₸`;
  return `${price.toFixed(0)} ₸`;
}

export function formatBookingWhen(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString("ru-RU", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatSlotTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
}

export function dateKeyLocal(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function startOfLocalDay(d = new Date()): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function addDays(d: Date, n: number): Date {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

/** Диапазон inbox хозяина: −45 … +60 дней. */
export function hostInboxRange(now = new Date()): { from: Date; to: Date } {
  const from = addDays(startOfLocalDay(now), -45);
  const to = addDays(startOfLocalDay(now), 60);
  to.setHours(23, 59, 59, 999);
  return { from, to };
}

export function myBookingsRange(now = new Date()): { from: Date; to: Date } {
  const from = addDays(startOfLocalDay(now), -90);
  const to = addDays(startOfLocalDay(now), 120);
  to.setHours(23, 59, 59, 999);
  return { from, to };
}

export function endsAt(startsAt: string, durationMinutes: number): Date {
  const d = new Date(startsAt);
  d.setMinutes(d.getMinutes() + durationMinutes);
  return d;
}

export function canClientCancel(startsAt: string, hoursBefore: number, now = new Date()): boolean {
  const start = new Date(startsAt);
  if (Number.isNaN(start.getTime())) return false;
  if (start.getTime() <= now.getTime()) return false;
  if (hoursBefore <= 0) return true;
  const deadline = start.getTime() - hoursBefore * 3600_000;
  return now.getTime() <= deadline;
}
