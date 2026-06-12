-- Chat schema: conversations, participants, messages, reactions, attachments, shared posts.
-- Designed for Supabase Auth + RLS. Client data access is via RPC (no direct table DML).
-- This migration is idempotent (safe to re-apply).

-- --------------------------------------------------------------------------- enums
do $$
begin
  create type public.chat_conversation_type as enum ('dm', 'group');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.chat_participant_role as enum ('member', 'admin');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.chat_message_kind as enum ('text', 'media', 'file', 'post_ref', 'system');
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- chat_conversations
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  type public.chat_conversation_type not null,
  title text null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists chat_conversations_created_at_desc_idx
  on public.chat_conversations (created_at desc);

comment on table public.chat_conversations is 'Chat dialog or group. Membership is in chat_participants.';

-- --------------------------------------------------------------------------- chat_participants
create table if not exists public.chat_participants (
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.chat_participant_role not null default 'member',
  joined_at timestamptz not null default now(),
  left_at timestamptz null,
  last_read_at timestamptz null,
  last_read_message_id uuid null,
  primary key (conversation_id, user_id)
);

create index if not exists chat_participants_user_idx
  on public.chat_participants (user_id, conversation_id);

create index if not exists chat_participants_conversation_idx
  on public.chat_participants (conversation_id, joined_at desc);

comment on column public.chat_participants.left_at is 'If set, user left conversation (soft leave).';
comment on column public.chat_participants.last_read_at is 'Client read marker; updated via RPC mark_conversation_read.';
comment on column public.chat_participants.last_read_message_id is 'Optional stable marker for precise unread counts.';

-- --------------------------------------------------------------------------- chat_messages
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  kind public.chat_message_kind not null default 'text',
  text text null,
  reply_to_message_id uuid null references public.chat_messages(id) on delete set null,
  forwarded_from_message_id uuid null references public.chat_messages(id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz null,
  deleted_at timestamptz null,
  constraint chat_messages_text_len check (text is null or char_length(text) <= 4000),
  constraint chat_messages_text_not_blank_for_text
    check (kind <> 'text' or (text is not null and char_length(trim(text)) > 0))
);

create index if not exists chat_messages_conversation_created_desc_idx
  on public.chat_messages (conversation_id, created_at desc, id);

create index if not exists chat_messages_sender_idx
  on public.chat_messages (sender_id, created_at desc);

comment on table public.chat_messages is 'Chat messages with soft delete. Attachments and post refs are separate tables.';

-- --------------------------------------------------------------------------- reactions
create table if not exists public.chat_message_reactions (
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null constraint chat_message_reactions_emoji_len check (char_length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, emoji)
);

create index if not exists chat_message_reactions_message_idx
  on public.chat_message_reactions (message_id, created_at desc);

comment on table public.chat_message_reactions is 'Per-user reactions (emoji) to messages; unique by (message_id, user_id, emoji).';

-- --------------------------------------------------------------------------- attachments metadata
create table if not exists public.chat_message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  bucket text not null,
  path text not null,
  mime text null,
  size_bytes bigint null,
  width int null,
  height int null,
  duration_ms int null,
  preview_path text null,
  created_at timestamptz not null default now(),
  constraint chat_message_attachments_path_not_blank check (char_length(trim(path)) > 0)
);

create index if not exists chat_message_attachments_message_idx
  on public.chat_message_attachments (message_id);

comment on table public.chat_message_attachments is 'Attachment metadata; actual bytes live in Supabase Storage.';

-- --------------------------------------------------------------------------- shared posts
create table if not exists public.chat_message_post_refs (
  message_id uuid primary key references public.chat_messages(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  caption text null,
  created_at timestamptz not null default now()
);

create index if not exists chat_message_post_refs_post_idx
  on public.chat_message_post_refs (post_id);

comment on table public.chat_message_post_refs is 'Message -> referenced post (share into chat).';

-- --------------------------------------------------------------------------- RLS: enabled, but no direct client DML
alter table public.chat_conversations enable row level security;
alter table public.chat_participants enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_message_reactions enable row level security;
alter table public.chat_message_attachments enable row level security;
alter table public.chat_message_post_refs enable row level security;

revoke all on table public.chat_conversations from anon;
revoke all on table public.chat_conversations from authenticated;
revoke all on table public.chat_participants from anon;
revoke all on table public.chat_participants from authenticated;
revoke all on table public.chat_messages from anon;
revoke all on table public.chat_messages from authenticated;
revoke all on table public.chat_message_reactions from anon;
revoke all on table public.chat_message_reactions from authenticated;
revoke all on table public.chat_message_attachments from anon;
revoke all on table public.chat_message_attachments from authenticated;
revoke all on table public.chat_message_post_refs from anon;
revoke all on table public.chat_message_post_refs from authenticated;

-- Idempotent: повторный push на БД, где политики уже созданы ранее (MCP / ручной запуск).
drop policy if exists chat_conversations_select_participant on public.chat_conversations;
drop policy if exists chat_participants_select_participant on public.chat_participants;
drop policy if exists chat_messages_select_participant on public.chat_messages;
drop policy if exists chat_message_reactions_select_participant on public.chat_message_reactions;
drop policy if exists chat_message_attachments_select_participant on public.chat_message_attachments;
drop policy if exists chat_message_post_refs_select_participant on public.chat_message_post_refs;

-- Minimal SELECT policies for server-side (security definer RPC with row_security off).
-- (We still add invoker policies for future flexibility / Admin UI.)
create policy chat_conversations_select_participant
  on public.chat_conversations for select
  using (
    exists (
      select 1
      from public.chat_participants p
      where p.conversation_id = chat_conversations.id
        and p.user_id = auth.uid()
        and p.left_at is null
    )
  );

create policy chat_participants_select_participant
  on public.chat_participants for select
  using (
    exists (
      select 1
      from public.chat_participants p
      where p.conversation_id = chat_participants.conversation_id
        and p.user_id = auth.uid()
        and p.left_at is null
    )
  );

create policy chat_messages_select_participant
  on public.chat_messages for select
  using (
    deleted_at is null
    and exists (
      select 1
      from public.chat_participants p
      where p.conversation_id = chat_messages.conversation_id
        and p.user_id = auth.uid()
        and p.left_at is null
    )
  );

create policy chat_message_reactions_select_participant
  on public.chat_message_reactions for select
  using (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_participants p
        on p.conversation_id = m.conversation_id
       and p.user_id = auth.uid()
       and p.left_at is null
      where m.id = chat_message_reactions.message_id
    )
  );

create policy chat_message_attachments_select_participant
  on public.chat_message_attachments for select
  using (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_participants p
        on p.conversation_id = m.conversation_id
       and p.user_id = auth.uid()
       and p.left_at is null
      where m.id = chat_message_attachments.message_id
        and m.deleted_at is null
    )
  );

create policy chat_message_post_refs_select_participant
  on public.chat_message_post_refs for select
  using (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_participants p
        on p.conversation_id = m.conversation_id
       and p.user_id = auth.uid()
       and p.left_at is null
      where m.id = chat_message_post_refs.message_id
        and m.deleted_at is null
    )
  );

