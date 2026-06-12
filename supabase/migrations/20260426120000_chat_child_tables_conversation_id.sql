-- Денормализация conversation_id под фильтры Realtime postgres_changes:
-- одна подписка на тред — только события этого диалога (не весь стол).

alter table public.chat_message_reactions
  add column if not exists conversation_id uuid references public.chat_conversations(id) on delete cascade;

alter table public.chat_message_attachments
  add column if not exists conversation_id uuid references public.chat_conversations(id) on delete cascade;

alter table public.chat_message_post_refs
  add column if not exists conversation_id uuid references public.chat_conversations(id) on delete cascade;

update public.chat_message_reactions r
set conversation_id = m.conversation_id
from public.chat_messages m
where m.id = r.message_id
  and (r.conversation_id is null or r.conversation_id <> m.conversation_id);

update public.chat_message_attachments a
set conversation_id = m.conversation_id
from public.chat_messages m
where m.id = a.message_id
  and (a.conversation_id is null or a.conversation_id <> m.conversation_id);

update public.chat_message_post_refs p
set conversation_id = m.conversation_id
from public.chat_messages m
where m.id = p.message_id
  and (p.conversation_id is null or p.conversation_id <> m.conversation_id);

alter table public.chat_message_reactions alter column conversation_id set not null;
alter table public.chat_message_attachments alter column conversation_id set not null;
alter table public.chat_message_post_refs alter column conversation_id set not null;

create index if not exists chat_message_reactions_conversation_idx
  on public.chat_message_reactions (conversation_id);

create index if not exists chat_message_attachments_conversation_idx
  on public.chat_message_attachments (conversation_id);

create index if not exists chat_message_post_refs_conversation_idx
  on public.chat_message_post_refs (conversation_id);

create or replace function public.chat_sync_child_row_conversation_id()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  cid uuid;
begin
  select m.conversation_id into cid
  from public.chat_messages m
  where m.id = new.message_id;

  if cid is null then
    raise exception 'chat_sync_child_row_conversation_id: message_not_found';
  end if;

  new.conversation_id := cid;
  return new;
end;
$$;

drop trigger if exists trg_chat_message_reactions_conv on public.chat_message_reactions;
create trigger trg_chat_message_reactions_conv
  before insert or update of message_id on public.chat_message_reactions
  for each row execute function public.chat_sync_child_row_conversation_id();

drop trigger if exists trg_chat_message_attachments_conv on public.chat_message_attachments;
create trigger trg_chat_message_attachments_conv
  before insert or update of message_id on public.chat_message_attachments
  for each row execute function public.chat_sync_child_row_conversation_id();

drop trigger if exists trg_chat_message_post_refs_conv on public.chat_message_post_refs;
create trigger trg_chat_message_post_refs_conv
  before insert or update of message_id on public.chat_message_post_refs
  for each row execute function public.chat_sync_child_row_conversation_id();
