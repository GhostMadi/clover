# SPEC: booking staff invite (через DM)

**Продукт:** [booking-staff-plan.md](../business/booking-staff-plan.md) · [booking-tz.md](../business/booking-tz.md) (WP5b)  
**Миграции:**  
`20260908170000_booking_staff_invite_kinds.sql`  
`20260908171000_booking_staff_invite_rpc.sql`

## Что

| Объект | Назначение |
|--------|------------|
| `chat_message_kind.booking_staff_invite` | Вид сообщения-карточки в чате |
| `chat_message_booking_cards` | Payload карточки (`invite_id`, `host_id`, `host_display_name`) |
| `booking_staff_invites` | Заявка host → invitee (`pending` / `accepted` / `declined` / `cancelled`) |
| `booking_invite_staff(profile_id)` | Хозяин создаёт pending + DM-карточку |
| `booking_accept_staff_invite` | Invitee → linked `booking_staff` с `profile_id` |
| `booking_reject_staff_invite` | Invitee отклоняет |
| `booking_cancel_staff_invite` | Хозяин отменяет pending |
| `list_booking_staff_invites_pending` | Список ожидания у хозяина |
| `list_messages_enriched` / `get_message_enriched` | Колонка `booking_card` |

## Правила

- Сразу писать `booking_staff.profile_id` с клиента **нельзя** для нового linked-staff — только через Accept.
- Имя без аккаунта — по-прежнему insert в `booking_staff` без `profile_id` (нет invite).
- Тег `bookingCalendar` **не** выдаётся автоматически.

## Клиент

Flutter: invite из поиска исполнителей; Accept/Reject в `ChatBookingStaffCardBubble`.
