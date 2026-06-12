## Comments

Миграции (не переносить из корня):

- `../20260402140000_posts_post_media_engagement.sql` — таблица `comments` (дерево `parent_comment_id`), `likes_count`, RLS и гранты; изначально были `comment_likes` (заменены позже на реакции).
- `../20260412100000_comments_contract_and_root_index.sql` — частичный индекс под корневую ленту комментариев, комментарии к контракту колонок и embed `profiles` для PostgREST.
- `../20260413100000_comments_replies_count.sql` — колонка `replies_count`, бэкфилл, триггеры на вставку/удаление/soft-delete ответов.
- `../20260413120000_comment_reactions_like_post.sql` — таблица `comment_reactions` (как `post_reactions`: `like` | `dislike`, одна строка на пару comment×user), колонка `comments.dislikes_count`, триггеры счётчиков, RPC `set_comment_reaction` и `get_my_comment_reactions`, удаление `comment_likes`.
- `../20260413130000_list_comments_enriched_rpc.sql` — `list_post_root_comments_enriched` и `list_comment_replies_enriched`: комментарий в JSON + `my_kind` за один вызов (аналог `get_post_enriched` по смыслу).

### Сохранения постов

Отдельно от комментариев: сохранённые посты (`post_saves`), enriched saved feed и RPC — см. `_posts/README.md` и соответствующие миграции с `saved` / `post_saves` в имени.

### Пост как объект в чате

Таблица **`chat_message_post_refs`** и виды сообщений с `kind = post_ref` — в домене чата: см. **`../_chat/README.md`**.
