-- Обложки видео только в Storage (`{media_uuid}__poster.jpg`); в post_media только URL ролика.
alter table public.post_media
  drop column if exists poster_url;
