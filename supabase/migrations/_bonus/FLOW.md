# Цепочка бонусов при записи

## Роли

| Кто | Что делает |
|-----|------------|
| **Host** | На услуге `bonus_earn_amount` и `bonus_pay_percent`; отдельного свитча программы нет |
| **Клиент** | Записывается, при необходимости включает «Оплатить бонусами» (`bookings.use_bonuses`, по умолчанию `true`) |
| **Система** | При переводе записи в `completed` двигает бонусы по журналу |

## Деньги vs бонусы

- **Денежная оплата** — вне приложения (наличные, терминал, перевод). Приложение её не проводит.
- **Бонусы** — учёт в `bonus_wallets` / `bonus_ledger`. Списание и начисление происходят **только при завершении визита** (`status → completed`).

## Шаги

### 1. Создание записи (`create_booking`)

Сохраняются снапшоты с услуги:

- `service_bonus_pay_percent` — до скольки % цены можно списать бонусами
- `service_bonus_earn_amount` — сколько начислить за визит
- `use_bonuses` — согласие клиента на списание

### 2. Визит оказан (`bookings.status → completed`)

Триггер вызывает `bonus_apply_booking_completed(booking_id)`:

1. **Списание** (`bonus_apply_booking_payment_spend`) — если `use_bonuses = true`, процент > 0:
   - лимит = `floor(price × service_bonus_pay_percent / 100)`
   - факт = `min(баланс кошелька, лимит)`
   - запись в ledger: `kind = spend`, `source = booking_payment`
   - `bookings.bonus_spent_amount` — для аудита

2. **Начисление** (`bonus_apply_booking_service_earn`) — если `service_bonus_earn_amount > 0`:
   - запись в ledger: `kind = earn`, `source = booking_service`

Порядок: **сначала списание, потом начисление** — оплата бонусами за визит, затем кэшбэк за визит.

### 3. Идемпотентность

Повторный вызов для той же записи безопасен: уникальный индекс `(wallet_id, kind, source, source_id)`.

## Источники в журнале (`bonus_ledger_source`)

| Source | Когда |
|--------|--------|
| `booking_payment` | Списание при завершении визита |
| `booking_service` | Начисление за визит |
| `manual`, `promo`, `welcome` | Будущие каналы |

## RPC для клиента

- `get_my_bonus_balance_at_host(host_id)` — баланс для экрана записи
- `list_bonus_ledger_cursor` — история с `source` / `source_id`
