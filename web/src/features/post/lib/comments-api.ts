"use client";

import { createClient } from "@/lib/supabase/client";

export type CommentItem = {
  id: string;
  postId: string;
  userId: string;
  text: string;
  parentCommentId: string | null;
  likesCount: number;
  repliesCount: number;
  createdAt: string;
  username: string | null;
  avatarUrl: string | null;
  myLiked: boolean;
};

function parseCommentRow(raw: unknown): CommentItem | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as Record<string, unknown>;
  const comment =
    row.comment && typeof row.comment === "object"
      ? (row.comment as Record<string, unknown>)
      : row;
  const id = String(comment.id ?? "").trim();
  if (!id) return null;
  const profiles =
    comment.profiles && typeof comment.profiles === "object"
      ? (comment.profiles as Record<string, unknown>)
      : null;
  const myKind = String(row.my_kind ?? "").trim().toLowerCase();
  return {
    id,
    postId: String(comment.post_id ?? "").trim(),
    userId: String(comment.user_id ?? "").trim(),
    text: String(comment.text ?? "").trim(),
    parentCommentId: (comment.parent_comment_id as string | null)?.trim() || null,
    likesCount: Number(comment.likes_count ?? 0) || 0,
    repliesCount: Number(comment.replies_count ?? 0) || 0,
    createdAt: String(comment.created_at ?? ""),
    username: (profiles?.username as string | null)?.trim() || null,
    avatarUrl: (profiles?.avatar_url as string | null)?.trim() || null,
    myLiked: myKind === "like",
  };
}

function parseList(data: unknown): CommentItem[] {
  if (!Array.isArray(data)) return [];
  return data.map(parseCommentRow).filter((c): c is CommentItem => Boolean(c));
}

export async function listRootComments(
  postId: string,
  limit = 24,
  offset = 0,
): Promise<CommentItem[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_post_root_comments_enriched", {
    p_post_id: postId,
    p_limit: Math.min(200, Math.max(1, limit)),
    p_offset: Math.max(0, offset),
  });
  if (error) throw error;
  return parseList(data);
}

export async function listCommentReplies(
  postId: string,
  parentCommentId: string,
  limit = 50,
  offset = 0,
): Promise<CommentItem[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_comment_replies_enriched", {
    p_post_id: postId,
    p_parent_comment_id: parentCommentId,
    p_limit: Math.min(200, Math.max(1, limit)),
    p_offset: Math.max(0, offset),
  });
  if (error) throw error;
  return parseList(data);
}

export async function createComment(opts: {
  postId: string;
  text: string;
  parentCommentId?: string | null;
}): Promise<CommentItem> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const payload: Record<string, unknown> = {
    post_id: opts.postId,
    user_id: uid,
    text: opts.text.trim(),
  };
  if (opts.parentCommentId) payload.parent_comment_id = opts.parentCommentId;

  const { data, error } = await supabase.from("comments").insert(payload).select().single();
  if (error) throw error;
  const row = data as Record<string, unknown>;

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, avatar_url")
    .eq("id", uid)
    .maybeSingle();
  const p = (profile ?? {}) as Record<string, unknown>;

  return {
    id: String(row.id),
    postId: String(row.post_id),
    userId: uid,
    text: String(row.text ?? "").trim(),
    parentCommentId: (row.parent_comment_id as string | null)?.trim() || null,
    likesCount: 0,
    repliesCount: 0,
    createdAt: String(row.created_at ?? new Date().toISOString()),
    username: (p.username as string | null)?.trim() || null,
    avatarUrl: (p.avatar_url as string | null)?.trim() || null,
    myLiked: false,
  };
}

export async function setCommentLiked(commentId: string, liked: boolean) {
  const supabase = createClient();
  const { error } = await supabase.rpc("set_comment_reaction", {
    p_comment_id: commentId,
    p_kind: liked ? "like" : null,
  });
  if (error) throw error;
}
