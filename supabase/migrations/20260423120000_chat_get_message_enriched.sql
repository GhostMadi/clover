-- Одна строка сообщения в том же формате, что и list_messages_enriched (json для клиента).
-- Нужна для синхронизации без полного перечитывания ленты после Realtime INSERT.

create or replace function public.get_message_enriched(p_message_id uuid)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb
)
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  conv uuid;
begin
  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null;

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  return query
  select
    to_jsonb(b.*) as message,
    jsonb_build_object('id', pr.id, 'username', pr.username, 'avatar_url', pr.avatar_url) as sender,
    (
      select jsonb_build_object(
        'id', r.id,
        'sender_id', r.sender_id,
        'text', r.text,
        'kind', r.kind::text,
        'created_at', r.created_at
      )
      from public.chat_messages r
      where r.id = b.reply_to_message_id
      limit 1
    ) as reply_preview,
    (
      select coalesce(jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.cnt) order by x.cnt desc), '[]'::jsonb)
      from (
        select emoji, count(*)::int as cnt
        from public.chat_message_reactions rr
        where rr.message_id = b.id
        group by emoji
      ) x
    ) as reactions,
    (
      select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at asc), '[]'::jsonb)
      from public.chat_message_attachments a
      where a.message_id = b.id
    ) as attachments,
    (
      select jsonb_build_object('post_id', prf.post_id, 'caption', prf.caption)
      from public.chat_message_post_refs prf
      where prf.message_id = b.id
      limit 1
    ) as post_ref
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id;
end;
$$;

revoke all on function public.get_message_enriched(uuid) from public;
grant execute on function public.get_message_enriched(uuid) to authenticated;
