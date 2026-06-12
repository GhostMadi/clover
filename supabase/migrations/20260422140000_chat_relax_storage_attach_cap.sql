-- Relax chat uploads: MIME/file caps enforced on the client; Storage accepts broader types.
-- Attachment count ceiling raised (still bounded for abuse resistance).

set search_path = public;

update storage.buckets
set
  allowed_mime_types = null,
  file_size_limit = null
where id = 'chat_media';

create or replace function public.send_message_with_attachments(
  p_conversation_id uuid,
  p_kind text,
  p_text text default null,
  p_reply_to uuid default null,
  p_attachments jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  mk public.chat_message_kind;
  mid uuid;
  elem jsonb;
  att_count int;
  pth text;
  bkt text;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  perform public.chat_assert_participant(p_conversation_id);

  att_count := coalesce(jsonb_array_length(coalesce(p_attachments, '[]'::jsonb)), 0);
  if att_count < 1 then
    raise exception 'attachments_required' using errcode = 'P0013';
  end if;
  if att_count > 100 then
    raise exception 'too_many_attachments' using errcode = 'P0014';
  end if;

  mk := coalesce(nullif(trim(coalesce(p_kind, '')), ''), 'media')::public.chat_message_kind;
  if mk not in ('media'::public.chat_message_kind, 'file'::public.chat_message_kind) then
    raise exception 'invalid_kind_for_attachments' using errcode = 'P0015';
  end if;

  insert into public.chat_messages (
    conversation_id, sender_id, kind, text, reply_to_message_id, forwarded_from_message_id
  )
  values (
    p_conversation_id,
    uid,
    mk,
    nullif(trim(coalesce(p_text, '')), ''),
    p_reply_to,
    null
  )
  returning id into mid;

  for elem in select value from jsonb_array_elements(coalesce(p_attachments, '[]'::jsonb)) as x(value)
  loop
    bkt := nullif(trim(coalesce(elem->>'bucket', '')), '');
    pth := nullif(trim(coalesce(elem->>'path', '')), '');
    if bkt is null or bkt = '' or pth is null or pth = '' then
      raise exception 'attachment_missing_bucket_or_path' using errcode = 'P0016';
    end if;
    if bkt <> 'chat_media' then
      raise exception 'invalid_attachment_bucket' using errcode = 'P0017';
    end if;
    if pth not like (uid::text || '/%') then
      raise exception 'attachment_path_not_owned' using errcode = 'P0018';
    end if;

    insert into public.chat_message_attachments (
      message_id,
      bucket,
      path,
      mime,
      size_bytes,
      width,
      height,
      duration_ms,
      preview_path
    )
    values (
      mid,
      bkt,
      pth,
      nullif(trim(elem->>'mime'), ''),
      case when elem ? 'size_bytes' and nullif(trim(elem->>'size_bytes'), '') is not null
        then (elem->>'size_bytes')::bigint else null end,
      case when elem ? 'width' and nullif(trim(elem->>'width'), '') is not null
        then (elem->>'width')::int else null end,
      case when elem ? 'height' and nullif(trim(elem->>'height'), '') is not null
        then (elem->>'height')::int else null end,
      case when elem ? 'duration_ms' and nullif(trim(elem->>'duration_ms'), '') is not null
        then (elem->>'duration_ms')::int else null end,
      nullif(trim(elem->>'preview_path'), '')
    );
  end loop;

  return mid;
end;
$$;
