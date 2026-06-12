-- Markers: add is_archived flag (archiving event should archive marker, not post).

alter table public.markers
  add column if not exists is_archived boolean not null default false;

comment on column public.markers.is_archived is
  'Архивирование события (маркера). Для постов с marker_id архивируем маркер, а не posts.is_archived.';

notify pgrst, 'reload schema';

