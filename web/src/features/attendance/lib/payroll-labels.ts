/** Payroll preview keys from RPC → RU on client. See attendance_payroll_preview. */

const MONTH_RU = [
  "Январь",
  "Февраль",
  "Март",
  "Апрель",
  "Май",
  "Июнь",
  "Июль",
  "Август",
  "Сентябрь",
  "Октябрь",
  "Ноябрь",
  "Декабрь",
] as const;

const LINE_LABEL_RU: Record<string, string> = {
  late: "Опоздания",
  missed_shift: "Пропуск смены",
  absence_recorded: "Отсутствие оформлено",
  partial_day: "Неполный день",
  overtime_approved: "Переработка (утверждено)",
};

const ABSENCE_KIND_RU: Record<string, string> = {
  day_off: "Выходной",
  vacation: "Отпуск",
  sick: "Больничный",
};

/** `YYYY-MM` or legacy RU string → display. */
export function payrollPeriodLabelRu(periodKey: string): string {
  const m = /^(\d{4})-(\d{2})$/.exec(periodKey.trim());
  if (!m) return periodKey;
  const month = Number(m[2]);
  if (month < 1 || month > 12) return periodKey;
  return `${MONTH_RU[month - 1]} ${m[1]}`;
}

export function payrollLineLabelRu(code: string): string {
  return LINE_LABEL_RU[code] ?? code;
}

export function payrollLineDetailRu(code: string, detail: string): string {
  const parts = detail.split("|");
  switch (code) {
    case "late":
      if (parts.length >= 3) {
        return `${parts[0]} ₸ × ${parts[1]} мин · ${parts[2]} дн.`;
      }
      break;
    case "missed_shift":
      if (parts.length >= 2) {
        return `${parts[0]} ₸ × ${parts[1]} дн.`;
      }
      break;
    case "absence_recorded": {
      const kinds = detail
        .split(",")
        .map((k) => ABSENCE_KIND_RU[k.trim()] ?? k.trim())
        .filter(Boolean)
        .join(", ");
      return kinds ? `${kinds} — не штраф за пропуск` : detail;
    }
    case "partial_day":
      if (parts.length >= 2) {
        return `${parts[0]}% от дневной ставки · ${parts[1]}`;
      }
      break;
    case "overtime_approved":
      if (parts.length >= 2) {
        return `${parts[0]} ₸ × ${parts[1]} ч`;
      }
      break;
    default:
      break;
  }
  return detail;
}
