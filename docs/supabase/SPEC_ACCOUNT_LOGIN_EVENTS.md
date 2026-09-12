# Account login events + primary / guest

**Product:** [authentication.md](../business/authentication.md) § Сессии · [notifications.md](../business/notifications.md)  
**Migrations:**  
`20260912120000_account_login_events_notify.sql` ·  
`20260912130000_account_login_primary_guest.sql` ·  
`20260912140000_account_login_revoke_auth_session.sql`

## Model

| | |
|--|--|
| `account_login_events` | Журнал: user_id, client, platform, device_label, **role**, **status**, **session_id**, **fingerprint**, created_at |
| `role` | `primary` \| `guest` — первый вход на аккаунт = primary |
| `status` | `active` \| `confirmed` \| `revoked` |
| RLS | SELECT own; INSERT/UPDATE только через RPC |

`client`: `mobile` \| `web`  
`platform`: `ios` \| `android` \| `web` \| `unknown`

Параллельные сессии **разрешены**. Guest получает Auth-сессию; primary решает confirm / revoke.

## RPC

| RPC | Назначение |
|-----|------------|
| `report_account_login(client, platform, device_label?, session_id?)` | Пишет событие; guest + new fp → `notifications.kind = account_login` + push |
| `confirm_account_login(event_id)` | «Это я» → status `confirmed`, payload.resolved |
| `revoke_account_login(event_id)` | «Прервать» → status `revoked` + `delete auth.sessions` по `session_id` |
| `revoke_other_account_logins()` | Все гости revoked + удалить чужие `auth.sessions` (оставить JWT caller) |
| `list_my_login_events(limit)` | Список с role/status для настроек |

Анти-спам notify: primary fp / confirmed fp ≤30d / тот же fp ≤12h → без повторного алерта.

## Notification payload

```json
{
  "client": "mobile",
  "platform": "ios",
  "device_label": "iPhone",
  "login_event_id": "uuid",
  "role": "guest",
  "actions": ["confirm", "revoke", "change_password"]
}
```

После действия клиент/RPC дописывает `"resolved": "confirmed" | "revoked" | "revoked_others"`.

Тексты на клиенте. Push title/body EN keys: `new_login` / `login_from_device` (drain localize).
