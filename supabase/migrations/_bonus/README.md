# Bonus migrations

| Migration | Phase | Description |
|-----------|-------|-------------|
| `20260801120000_bonus_program_status_on_profiles.sql` | 0 | `bonus_program_status` enum on `profiles` |
| `20260801130000_booking_services_bonus_pay_percent.sql` | 1 | `bonus_pay_percent` on `booking_services` |
| `20260801140000_profiles_with_sync_meta_refresh_bonus.sql` | 0 | Recreate view after `bonus_program_status` |
| `20260801150000_bonus_wallets_ledger.sql` | 2–3 | Wallets, ledger, list RPCs |
| `20260801170000_booking_use_bonuses.sql` | 4 | `use_bonuses` на записи |
| `20260801180000_bonus_booking_completed_chain.sql` | 4 | Списание + начисление при `completed` |

Подробная цепочка: [FLOW.md](./FLOW.md)

## Ledger architecture

- **`bonus_ledger_source`** enum — extensible channel: `booking_service`, `booking_payment`, `manual`, `promo`, `welcome`.
- **`bonus_post_ledger_entry`** — single write path for all sources (idempotent by `wallet + kind + source + source_id`).
- **`bonus_apply_booking_completed`** — при `completed`: сначала spend (`booking_payment`), затем earn (`booking_service`).

Planned: in-app денежная оплата (сейчас — на месте, см. FLOW.md).
