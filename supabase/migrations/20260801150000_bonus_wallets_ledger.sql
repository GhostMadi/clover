-- Bonus phase 2+3: wallets, append-only ledger, list RPCs (no N+1).

do $$ begin
  create type public.bonus_ledger_kind as enum ('earn', 'spend', 'adjust', 'expire');
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- bonus_wallets
create table if not exists public.bonus_wallets (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles (id) on delete cascade,
  host_id uuid not null references public.profiles (id) on delete cascade,
  balance bigint not null default 0 constraint bonus_wallets_balance_nonneg check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bonus_wallets_client_host_unique unique (client_id, host_id),
  constraint bonus_wallets_not_self check (client_id <> host_id)
);

comment on table public.bonus_wallets is
  'Баланс бонусов клиента у конкретного host-аккаунта.';

create index if not exists bonus_wallets_client_balance_idx
  on public.bonus_wallets (client_id, balance desc, updated_at desc)
  where balance > 0;

create index if not exists bonus_wallets_host_idx
  on public.bonus_wallets (host_id);

-- --------------------------------------------------------------------------- bonus_ledger (append-only)
create table if not exists public.bonus_ledger (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.bonus_wallets (id) on delete cascade,
  kind public.bonus_ledger_kind not null,
  amount bigint not null constraint bonus_ledger_amount_positive check (amount > 0),
  balance_after bigint not null constraint bonus_ledger_balance_after_nonneg check (balance_after >= 0),
  title text not null constraint bonus_ledger_title_not_blank check (char_length(trim(title)) > 0),
  subtitle text,
  ref_type text,
  ref_id uuid,
  created_at timestamptz not null default now()
);

comment on table public.bonus_ledger is
  'Журнал операций по бонусному кошельку. balance_after — снимок после операции.';

create index if not exists bonus_ledger_wallet_created_idx
  on public.bonus_ledger (wallet_id, created_at desc, id desc);

-- --------------------------------------------------------------------------- wallet balance sync on ledger insert
create or replace function public.bonus_ledger_before_insert_sync_wallet()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_delta bigint;
  v_balance bigint;
begin
  v_delta := case new.kind
    when 'earn' then new.amount
    when 'adjust' then new.amount
    when 'spend' then -new.amount
    when 'expire' then -new.amount
    else 0
  end;

  select w.balance
  into v_balance
  from public.bonus_wallets w
  where w.id = new.wallet_id
  for update;

  if not found then
    raise exception 'bonus wallet not found';
  end if;

  v_balance := v_balance + v_delta;
  if v_balance < 0 then
    raise exception 'insufficient bonus balance';
  end if;

  new.balance_after := v_balance;

  update public.bonus_wallets
  set balance = v_balance, updated_at = now()
  where id = new.wallet_id;

  return new;
end;
$$;

drop trigger if exists trg_bonus_ledger_before_insert_sync_wallet on public.bonus_ledger;
create trigger trg_bonus_ledger_before_insert_sync_wallet
  before insert on public.bonus_ledger
  for each row
  execute function public.bonus_ledger_before_insert_sync_wallet();

-- --------------------------------------------------------------------------- RLS
alter table public.bonus_wallets enable row level security;
alter table public.bonus_ledger enable row level security;

drop policy if exists bonus_wallets_select_own on public.bonus_wallets;
create policy bonus_wallets_select_own
  on public.bonus_wallets
  for select
  to authenticated
  using (client_id = auth.uid());

drop policy if exists bonus_ledger_select_own on public.bonus_ledger;
create policy bonus_ledger_select_own
  on public.bonus_ledger
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.bonus_wallets w
      where w.id = wallet_id
        and w.client_id = auth.uid()
    )
  );

revoke all on table public.bonus_wallets from anon;
revoke all on table public.bonus_ledger from anon;
grant select on table public.bonus_wallets to authenticated;
grant select on table public.bonus_ledger to authenticated;

-- --------------------------------------------------------------------------- host mini json for bonus lists
create or replace function public.bonus_host_mini_json(p_host_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'id', pr.id,
    'full_name', coalesce(nullif(trim(pr.full_name), ''), nullif(trim(pr.username), ''), 'Аккаунт'),
    'username', pr.username,
    'avatar_url', pr.avatar_url
  )
  from public.profiles pr
  where pr.id = p_host_id;
$$;

comment on function public.bonus_host_mini_json(uuid) is
  'Host profile snippet for bonus wallet lists.';

grant execute on function public.bonus_host_mini_json(uuid) to authenticated;

-- --------------------------------------------------------------------------- list_my_bonus_accounts
create or replace function public.list_my_bonus_accounts(p_limit int default 50)
returns table (
  host_id uuid,
  balance bigint,
  host jsonb
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    w.host_id,
    w.balance,
    public.bonus_host_mini_json(w.host_id) as host
  from public.bonus_wallets w
  where w.client_id = auth.uid()
    and w.balance > 0
  order by w.updated_at desc, w.host_id
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

comment on function public.list_my_bonus_accounts(int) is
  'Bonus wallets for current client with balance > 0 and embedded host profile.';

grant execute on function public.list_my_bonus_accounts(int) to authenticated;

-- --------------------------------------------------------------------------- list_bonus_ledger_cursor
create or replace function public.list_bonus_ledger_cursor(
  p_host_id uuid,
  p_limit int default 50,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_wallet_id uuid;
  v_balance bigint := 0;
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_items jsonb;
  v_count int;
begin
  select w.id, w.balance
  into v_wallet_id, v_balance
  from public.bonus_wallets w
  where w.client_id = auth.uid()
    and w.host_id = p_host_id;

  if v_wallet_id is null then
    return jsonb_build_object(
      'balance', 0,
      'items', '[]'::jsonb,
      'has_more', false
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(e)::jsonb order by e.created_at desc, e.id desc), '[]'::jsonb)
  into v_items
  from (
    select
      l.id,
      l.kind::text as kind,
      l.amount,
      l.balance_after,
      l.title,
      l.subtitle,
      l.created_at
    from public.bonus_ledger l
    where l.wallet_id = v_wallet_id
      and (
        p_cursor_id is null
        or (l.created_at, l.id) < (p_cursor_created_at, p_cursor_id)
      )
    order by l.created_at desc, l.id desc
    limit v_limit + 1
  ) e;

  v_count := jsonb_array_length(v_items);

  if v_count > v_limit then
    v_items := (
      select coalesce(jsonb_agg(elem), '[]'::jsonb)
      from (
        select elem
        from jsonb_array_elements(v_items) with ordinality as t(elem, ord)
        where ord <= v_limit
      ) s
    );
    return jsonb_build_object(
      'balance', v_balance,
      'items', v_items,
      'has_more', true
    );
  end if;

  return jsonb_build_object(
    'balance', v_balance,
    'items', v_items,
    'has_more', false
  );
end;
$$;

comment on function public.list_bonus_ledger_cursor(uuid, int, timestamptz, uuid) is
  'Bonus history for current client at host: balance + ledger entries (cursor).';

grant execute on function public.list_bonus_ledger_cursor(uuid, int, timestamptz, uuid) to authenticated;

notify pgrst, 'reload schema';
