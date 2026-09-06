"use client";

import { Heart, Send, User, X } from "lucide-react";
import Link from "next/link";
import { useEffect, useState, useTransition } from "react";
import {
  createComment,
  listCommentReplies,
  listRootComments,
  setCommentLiked,
  type CommentItem,
} from "@/features/post/lib/comments-api";

function timeAgo(iso: string): string {
  const t = Date.parse(iso);
  if (!Number.isFinite(t)) return "";
  const sec = Math.max(0, Math.floor((Date.now() - t) / 1000));
  if (sec < 60) return "сейчас";
  if (sec < 3600) return `${Math.floor(sec / 60)} мин`;
  if (sec < 86400) return `${Math.floor(sec / 3600)} ч`;
  return `${Math.floor(sec / 86400)} д`;
}

type CommentsSheetProps = {
  postId: string;
  open: boolean;
  onClose: () => void;
  onCountDelta?: (delta: number) => void;
};

/** Шторка комментариев: корни + ответы + лайк. */
export function CommentsSheet({
  postId,
  open,
  onClose,
  onCountDelta,
}: CommentsSheetProps) {
  const [roots, setRoots] = useState<CommentItem[]>([]);
  const [replies, setReplies] = useState<Record<string, CommentItem[]>>({});
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [text, setText] = useState("");
  const [replyTo, setReplyTo] = useState<CommentItem | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  useEffect(() => {
    if (!open) return;
    setLoading(true);
    setError(null);
    void listRootComments(postId)
      .then(setRoots)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Не удалось загрузить"),
      )
      .finally(() => setLoading(false));
  }, [open, postId]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  const toggleReplies = (c: CommentItem) => {
    if (expanded.has(c.id)) {
      setExpanded((prev) => {
        const next = new Set(prev);
        next.delete(c.id);
        return next;
      });
      return;
    }
    setExpanded((prev) => new Set(prev).add(c.id));
    if (!replies[c.id]) {
      void listCommentReplies(postId, c.id)
        .then((list) => setReplies((prev) => ({ ...prev, [c.id]: list })))
        .catch(() => setReplies((prev) => ({ ...prev, [c.id]: [] })));
    }
  };

  const toggleLike = (c: CommentItem, isReply: boolean, parentId?: string) => {
    const nextLiked = !c.myLiked;
    const patch = (item: CommentItem): CommentItem =>
      item.id === c.id
        ? {
            ...item,
            myLiked: nextLiked,
            likesCount: Math.max(0, item.likesCount + (nextLiked ? 1 : -1)),
          }
        : item;

    if (isReply && parentId) {
      setReplies((prev) => ({
        ...prev,
        [parentId]: (prev[parentId] ?? []).map(patch),
      }));
    } else {
      setRoots((prev) => prev.map(patch));
    }
    startTransition(async () => {
      try {
        await setCommentLiked(c.id, nextLiked);
      } catch {
        if (isReply && parentId) {
          setReplies((prev) => ({
            ...prev,
            [parentId]: (prev[parentId] ?? []).map((item) =>
              item.id === c.id ? c : item,
            ),
          }));
        } else {
          setRoots((prev) => prev.map((item) => (item.id === c.id ? c : item)));
        }
      }
    });
  };

  const send = () => {
    const body = text.trim();
    if (!body) return;
    setText("");
    const parent = replyTo;
    setReplyTo(null);
    startTransition(async () => {
      try {
        const created = await createComment({
          postId,
          text: body,
          parentCommentId: parent?.id ?? null,
        });
        if (parent) {
          setReplies((prev) => ({
            ...prev,
            [parent.id]: [...(prev[parent.id] ?? []), created],
          }));
          setRoots((prev) =>
            prev.map((r) =>
              r.id === parent.id ? { ...r, repliesCount: r.repliesCount + 1 } : r,
            ),
          );
          setExpanded((prev) => new Set(prev).add(parent.id));
        } else {
          setRoots((prev) => [created, ...prev]);
        }
        onCountDelta?.(1);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не отправилось");
        setText(body);
      }
    });
  };

  const renderItem = (c: CommentItem, isReply: boolean, parentId?: string) => {
    const name = c.username?.trim() || "noName";
    return (
      <li key={c.id} className={`flex gap-2.5 ${isReply ? "pl-10" : ""}`}>
        <Link
          href={`/app/u/${c.userId}`}
          className="mt-0.5 h-8 w-8 shrink-0 overflow-hidden rounded-full bg-bg"
        >
          {c.avatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={c.avatarUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="flex h-full w-full items-center justify-center">
              <User className="h-4 w-4 text-muted" />
            </span>
          )}
        </Link>
        <div className="min-w-0 flex-1">
          <p className="text-[13px] text-ink">
            <Link href={`/app/u/${c.userId}`} className="font-bold">
              {name}
            </Link>{" "}
            <span className="whitespace-pre-wrap">{c.text}</span>
          </p>
          <div className="mt-1 flex flex-wrap items-center gap-3 text-[11px] font-semibold text-muted">
            <span>{timeAgo(c.createdAt)}</span>
            {!isReply ? (
              <button type="button" onClick={() => setReplyTo(c)} className="hover:text-ink">
                Ответить
              </button>
            ) : null}
            {!isReply && c.repliesCount > 0 ? (
              <button type="button" onClick={() => toggleReplies(c)} className="hover:text-ink">
                {expanded.has(c.id)
                  ? "Скрыть ответы"
                  : `Показать ответы (${c.repliesCount})`}
              </button>
            ) : null}
          </div>
        </div>
        <button
          type="button"
          onClick={() => toggleLike(c, isReply, parentId)}
          className={`flex flex-col items-center gap-0.5 ${
            c.myLiked ? "text-destructive" : "text-muted"
          }`}
        >
          <Heart className={`h-4 w-4 ${c.myLiked ? "fill-current" : ""}`} strokeWidth={2} />
          {c.likesCount > 0 ? (
            <span className="text-[10px] font-bold">{c.likesCount}</span>
          ) : null}
        </button>
      </li>
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      <button
        type="button"
        className="absolute inset-0 bg-ink/40"
        aria-label="Закрыть"
        onClick={onClose}
      />
      <div className="relative z-10 flex h-[70dvh] w-full max-w-lg flex-col rounded-t-[20px] bg-surface shadow-xl sm:h-[min(70dvh,640px)] sm:rounded-[20px]">
        <div className="flex items-center gap-2 border-b border-line px-3 py-3">
          <h2 className="min-w-0 flex-1 text-center text-[15px] font-bold text-ink">
            Комментарии
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="absolute right-2 top-2 flex h-9 w-9 items-center justify-center rounded-full hover:bg-bg"
            aria-label="Закрыть"
          >
            <X className="h-5 w-5" strokeWidth={2} />
          </button>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-4 py-3">
          {loading ? (
            <p className="py-8 text-center text-sm text-muted">Загрузка…</p>
          ) : null}
          {error ? (
            <p className="mb-3 rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
              {error}
            </p>
          ) : null}
          {!loading && roots.length === 0 ? (
            <p className="py-10 text-center text-sm text-muted">Пока нет комментариев</p>
          ) : null}
          <ul className="space-y-4">
            {roots.map((c) => (
              <div key={c.id} className="space-y-3">
                {renderItem(c, false)}
                {expanded.has(c.id)
                  ? (replies[c.id] ?? []).map((r) => renderItem(r, true, c.id))
                  : null}
              </div>
            ))}
          </ul>
        </div>

        <div className="border-t border-line px-3 py-2.5">
          {replyTo ? (
            <div className="mb-2 flex items-center gap-2 text-[12px] text-muted">
              <span className="min-w-0 flex-1 truncate">
                Ответ @{replyTo.username?.trim() || "user"}
              </span>
              <button type="button" onClick={() => setReplyTo(null)} className="font-semibold">
                Отмена
              </button>
            </div>
          ) : null}
          <div className="flex items-center gap-2">
            <input
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  send();
                }
              }}
              placeholder="Комментарий…"
              className="h-11 min-w-0 flex-1 rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink outline-none focus:border-brand"
            />
            <button
              type="button"
              onClick={send}
              disabled={!text.trim()}
              className="flex h-11 w-11 items-center justify-center rounded-[14px] bg-brand text-on-brand disabled:opacity-40"
              aria-label="Отправить"
            >
              <Send className="h-4 w-4" strokeWidth={2} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
