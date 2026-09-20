-- Shared emoji wallpaper per conversation (all participants see the same).
-- Product: docs/business/chat-emoji-wallpaper.md

alter table public.chat_conversations
  add column if not exists wallpaper_emojis text[] not null default '{}'::text[];

alter table public.chat_conversations
  drop constraint if exists chat_conversations_wallpaper_emojis_len_chk;

alter table public.chat_conversations
  add constraint chat_conversations_wallpaper_emojis_len_chk
  check (cardinality(wallpaper_emojis) <= 8);

comment on column public.chat_conversations.wallpaper_emojis is
  'Shared emoji wallpaper (max 8 unique graphemes); empty = no wallpaper.';

-- --------------------------------------------------------------------------- normalize helper
create or replace function public.chat_normalize_wallpaper_emojis(p_emojis text[])
returns text[]
language plpgsql
immutable
set search_path = public
as $$
declare
  v_out text[] := '{}'::text[];
  v_item text;
  v_trim text;
begin
  if p_emojis is null then
    return '{}'::text[];
  end if;

  foreach v_item in array p_emojis loop
    v_trim := btrim(coalesce(v_item, ''));
    if v_trim = '' then
      continue;
    end if;
    -- Sanity: reject huge blobs posing as one "emoji"
    if char_length(v_trim) > 16 then
      continue;
    end if;
    if v_trim = any (v_out) then
      continue;
    end if;
    v_out := array_append(v_out, v_trim);
    exit when cardinality(v_out) >= 8;
  end loop;

  return v_out;
end;
$$;

revoke all on function public.chat_normalize_wallpaper_emojis(text[]) from public;

-- --------------------------------------------------------------------------- get
create or replace function public.get_conversation_wallpaper(p_conversation_id uuid)
returns text[]
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  perform public.chat_assert_participant(p_conversation_id);
  return coalesce(
    (
      select c.wallpaper_emojis
      from public.chat_conversations c
      where c.id = p_conversation_id
    ),
    '{}'::text[]
  );
end;
$$;

revoke all on function public.get_conversation_wallpaper(uuid) from public;
grant execute on function public.get_conversation_wallpaper(uuid) to authenticated;

-- --------------------------------------------------------------------------- set + broadcast
create or replace function public.set_conversation_wallpaper(
  p_conversation_id uuid,
  p_emojis text[] default '{}'::text[]
)
returns text[]
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_emojis text[];
begin
  perform public.chat_assert_participant(p_conversation_id);
  v_emojis := public.chat_normalize_wallpaper_emojis(p_emojis);

  update public.chat_conversations
  set wallpaper_emojis = v_emojis
  where id = p_conversation_id;

  perform realtime.send(
    jsonb_build_object(
      'conversation_id', p_conversation_id::text,
      'wallpaper_emojis', to_jsonb(v_emojis),
      'updated_by', auth.uid()::text
    ),
    'wallpaper_changed',
    'chat_thread_' || p_conversation_id::text,
    false
  );

  return v_emojis;
end;
$$;

revoke all on function public.set_conversation_wallpaper(uuid, text[]) from public;
grant execute on function public.set_conversation_wallpaper(uuid, text[]) to authenticated;
