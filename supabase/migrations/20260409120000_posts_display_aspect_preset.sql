-- Posts: fixed display aspect preset (no runtime image ratio detection).
-- Presets: ratio_4_5, ratio_1_1, ratio_2_3, ratio_9_16

do $$
begin
  create type public.post_display_aspect_preset as enum (
    'ratio_4_5',
    'ratio_1_1',
    'ratio_2_3',
    'ratio_9_16'
  );
exception
  when duplicate_object then null;
end $$;

alter table public.posts
  add column if not exists display_aspect_preset public.post_display_aspect_preset not null default 'ratio_4_5';

comment on column public.posts.display_aspect_preset is
  'UI display aspect preset for post media (e.g. ratio_4_5). Used for stable layout without reading image dimensions.';

-- Ensure updated_at changes when preset changes too.
drop trigger if exists trg_posts_set_updated_at on public.posts;
create trigger trg_posts_set_updated_at
  before update of title, subtitle, description, cluster_id, is_archived, deleted_at, display_aspect_preset on public.posts
  for each row
  execute function public.posts_set_updated_at();

