# SPEC: Relations & hiring — REMOVED

**Status:** **REMOVED** from live DB (2026-07-26).  
**Drop migration:** `20260726150000_drop_relations_system.sql`  
**Historical add:** `20260504054611_add_relations_system.sql`

Do **not** implement clients against this SPEC. Attendance / booking staff invites cover team flows instead.

---

## Historical overview (archive)

Professional relations between two accounts lived in **`public.relations`**. One row per unordered pair: **`from_account_id < to_account_id`**. Intent: `hire` | `join`. Status: `pending` → `active` | `rejected`; `active` → `terminated`.

RPCs (gone): `request_relation`, `update_relation_status`, `withdraw_relation`, `list_my_relations_enriched`, `get_my_relation_with`.

Profile flags `hiring_enabled` / `open_for_memberships` were dropped with the system.

See `MIGRATIONS_INDEX.md` → Relations (historical).
