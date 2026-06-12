-- Комментарии: актуализация под клиент (Flutter) и индекс под ленту корневых комментариев.
--
-- Контракт (см. CommentsRepositoryImpl):
--   SELECT ... FROM comments
--   WHERE post_id = :id AND parent_comment_id IS NULL AND is_deleted = false
--   ORDER BY created_at DESC
--   RANGE offset..offset+limit-1
--   + embed автора: profiles!comments_user_id_fkey(username, avatar_url)
--
-- Поля строки, ожидаемые CommentModel.fromApi:
--   id, post_id, user_id, text, parent_comment_id, likes_count, created_at, edited_at, is_deleted, profiles

-- Индекс под «корни поста, новые сверху», без мёртвых веток в фильтре
create index if not exists comments_post_root_created_desc_idx
  on public.comments (post_id, created_at desc)
  where parent_comment_id is null
    and not is_deleted;

comment on index public.comments_post_root_created_desc_idx is
  'Лента корневых комментариев поста (как fetchRootComments в приложении).';

comment on table public.comments is
  'Комментарии к посту; дерево через parent_comment_id. Корневая лента в приложении: parent is null, is_deleted = false, order created_at desc. Текст 1..2000 символов; likes_count денормализован из comment_likes.';

comment on column public.comments.user_id is
  'Автор; FK → profiles.id. PostgREST embed в клиенте: profiles!comments_user_id_fkey(username, avatar_url).';

comment on column public.comments.parent_comment_id is
  'null — корневой комментарий (показывается в шторке поста); иначе ответ в ветке.';

comment on column public.comments.is_deleted is
  'Мягкое удаление; корневые с is_deleted не попадают в posts.comments_count (триггер).';
