-- Revert: remove display_aspect_preset from posts (store aspect in media file name instead).

-- Restore updated_at trigger definition (without display_aspect_preset).
drop trigger if exists trg_posts_set_updated_at on public.posts;
create trigger trg_posts_set_updated_at
  before update of title, subtitle, description, cluster_id, is_archived, deleted_at on public.posts
  for each row
  execute function public.posts_set_updated_at();

alter table public.posts
  drop column if exists display_aspect_preset;

drop type if exists public.post_display_aspect_preset;

