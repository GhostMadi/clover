export type GridPost = {
  id: string;
  coverUrl: string | null;
  title: string | null;
  textEmoji: string | null;
  isEvent: boolean;
  mediaCount: number;
};

export function toGridPosts(
  posts: Array<{
    id: string;
    coverUrl: string | null;
    title: string | null;
    textEmoji: string | null;
    isEvent: boolean;
    media: { length: number };
  }>,
): GridPost[] {
  return posts.map((p) => ({
    id: p.id,
    coverUrl: p.coverUrl,
    title: p.title,
    textEmoji: p.textEmoji,
    isEvent: p.isEvent,
    mediaCount: p.media.length,
  }));
}
