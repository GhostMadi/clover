-- Chat search hardening: full-text index on messages (text only).
-- Idempotent.

-- --------------------------------------------------------------------------- tsvector + trigger
alter table public.chat_messages
  add column if not exists search_tsv tsvector;

create or replace function public.chat_messages_update_search_tsv()
returns trigger
language plpgsql
as $$
begin
  if new.kind = 'text' and new.text is not null then
    new.search_tsv := to_tsvector('simple', new.text);
  else
    new.search_tsv := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_chat_messages_search_tsv on public.chat_messages;
create trigger trg_chat_messages_search_tsv
  before insert or update of text, kind on public.chat_messages
  for each row
  execute function public.chat_messages_update_search_tsv();

-- Backfill existing rows (best effort).
update public.chat_messages
set search_tsv = to_tsvector('simple', text)
where kind = 'text' and text is not null and (search_tsv is null);

create index if not exists chat_messages_search_tsv_gin_idx
  on public.chat_messages using gin (search_tsv);

comment on column public.chat_messages.search_tsv is 'FTS for kind=text; maintained by trigger.';

