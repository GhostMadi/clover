# SPEC: Relations & hiring (canonical graph)

## Overview

Professional relations between two accounts live in **`public.relations`**. One row per unordered pair: **`from_account_id < to_account_id`** (canonical order). **`initiator_id`** is always one of the two endpoints and records who created the current request.

## Columns (conceptual)

| Column | Meaning |
|--------|---------|
| `relation_type` | **`hire`** — initiator acts as employer hiring the peer. **`join`** — initiator asks to join the peer’s team. |
| `status` | `pending` → `active` \| `rejected`; `active` → `terminated`. |
| `initiator_id` | Who sent the request (`from_account_id` or `to_account_id`). |

## Intent rules (`request_relation`)

| `p_action` | Who is checked | Rule |
|------------|----------------|------|
| **`hire`** | Caller (`auth.uid()`) | Caller must have **`profiles.hiring_enabled = true`**. |
| **`join`** | Target (`p_target_id`) | Target must have **`profiles.open_for_memberships = true`**. |

Self-requests are forbidden. Unknown profile rows surface as `user_not_found` where applicable.

## Upsert / reopen

- **Insert** a new `pending` row when the pair does not exist.
- **On conflict** (pair already exists): **`UPDATE`** to new `pending` intent **only if** current `status` is **`rejected`** or **`terminated`**.
- If the pair exists in **`pending`** or **`active`**, the command does **not** update and raises **`relation_already_active_or_pending`** (`ROW_COUNT = 0` after upsert).

## State machine (`update_relation_status`)

**Receiver** for a pending row: the participant who is **not** `initiator_id`.

| Current | `p_new_status` | Who may call | Result |
|---------|----------------|--------------|--------|
| `pending` | `active` | Receiver only | `active` |
| `pending` | `rejected` | Receiver only | `rejected` |
| `active` | `terminated` | Either endpoint | `terminated` |

Any other transition raises an exception (e.g. `can_only_accept_pending`, `can_only_terminate_active`, `only_receiver_can_accept`).

There is **no** transition from `rejected` or `terminated` except a **new** `request_relation`, which reopens to `pending`.

## Client access

| Operation | Mechanism |
|-----------|-----------|
| Read edges for the current user | **`SELECT`** on `relations` under RLS (row visible if `auth.uid()` is one of the two accounts). |
| Create / reopen request | RPC **`request_relation(p_target_id, p_action)`**. |
| Accept / reject / terminate | RPC **`update_relation_status(p_relation_id, p_new_status)`**. |
| One row with a given peer | RPC **`get_my_relation_with(p_other)`** (canonical pair resolved server-side). |

Direct **`INSERT` / `UPDATE` / `DELETE`** on `relations` by `authenticated` is revoked; mutating paths are RPC-only (`security definer`).

## Flutter naming

- **`hire`** on profile UI: “I hire this person” (requires my `hiring_enabled`).
- **`join`**: “I want to join this person’s team” (requires their `open_for_memberships`).
