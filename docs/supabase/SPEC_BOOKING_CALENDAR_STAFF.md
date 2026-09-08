# SPEC: bookingCalendar + staff assignee RPCs

**Продукт:** [booking-tz.md](../business/booking-tz.md) · [booking-staff-plan.md](../business/booking-staff-plan.md)  
**Миграция:** `20260908150000_booking_calendar_tag_and_staff_rpcs.sql`

## Что

| Объект | Назначение |
|--------|------------|
| `marker_tags.key = bookingCalendar` | Account-тег силы «мне дают заказы» |
| RLS `booking_staff` | `profile_id = auth.uid()` может читать свои строки staff |
| `list_my_staff_booking_hosts()` | Аккаунты-источники, где я linked staff |
| `list_my_staff_bookings_enriched(...)` | Мои визиты как исполнитель (опционально `p_host_id`) |

## Не даёт

- Писать статусы визита от имени исполнителя (v1 read-only на клиенте)
- Читать полный inbox / аналитику хозяина

## Клиент

Flutter: `lib/feature/_booking_/booking_calendar/`
