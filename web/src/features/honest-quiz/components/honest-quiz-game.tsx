"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  fileToCompressedDataUrl,
  upsertHonestQuiz,
  type HonestAnswers,
} from "@/features/honest-quiz/lib/honest-quiz-api";

type Step = "q1" | "q2" | "q3" | "q3_upload" | "final";

function GrowingYes({
  children,
  onClick,
  grow,
  disabled,
  className = "",
}: {
  children: React.ReactNode;
  onClick: () => void;
  grow: number;
  disabled?: boolean;
  className?: string;
}) {
  const scale = Math.min(1 + grow * 0.16, 2.4);
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={`rounded-full bg-ink/90 px-6 py-2.5 text-[16px] font-medium text-bg transition hover:bg-ink disabled:opacity-50 ${className}`}
      style={{
        transform: `scale(${scale})`,
        transformOrigin: "center center",
        fontSize: 16 + Math.min(grow * 1.5, 11),
        paddingInline: 24 + grow * 5,
        paddingBlock: 10 + grow * 1.5,
      }}
    >
      {children}
    </button>
  );
}

/** Q1: «нет» телепортируется по экрану */
function NoTeleport({ onMiss, growBump }: { onMiss: (n: number) => void; growBump: () => void }) {
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const attempts = useRef(0);

  return (
    <button
      type="button"
      onPointerDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
        growBump();
        attempts.current += 1;
        onMiss(attempts.current);
        const r = 90 + attempts.current * 12;
        let x = (Math.random() * 2 - 1) * r;
        let y = (Math.random() * 2 - 1) * r * 0.7;
        if (x < -30) x = 40 + Math.random() * 50;
        setPos({ x, y });
      }}
      className="absolute z-10 touch-none rounded-full border border-line/80 bg-surface/90 px-4 py-2 text-[15px] text-muted shadow-sm transition-transform duration-150 select-none"
      style={{
        left: "70%",
        top: "50%",
        transform: `translate(calc(-50% + ${pos.x}px), calc(-50% + ${pos.y}px))`,
      }}
    >
      нет
    </button>
  );
}

/** Q2: «нет» сжимается и уезжает вниз, потом всплывает в другом месте */
function NoShrinkHop({ onMiss, growBump }: { onMiss: (n: number) => void; growBump: () => void }) {
  const [pos, setPos] = useState({ x: 40, y: 0 });
  const [phase, setPhase] = useState<"idle" | "out" | "in">("idle");
  const attempts = useRef(0);
  const busy = useRef(false);

  const tap = () => {
    if (busy.current) return;
    busy.current = true;
    growBump();
    attempts.current += 1;
    onMiss(attempts.current);
    setPhase("out");
    window.setTimeout(() => {
      setPos({
        x: 20 + Math.random() * 90,
        y: -40 + Math.random() * 90,
      });
      setPhase("in");
      window.setTimeout(() => {
        setPhase("idle");
        busy.current = false;
      }, 220);
    }, 180);
  };

  return (
    <button
      type="button"
      onPointerDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
        tap();
      }}
      className="absolute z-10 touch-none px-3 py-2 text-[16px] font-medium italic text-muted/90 select-none"
      style={{
        right: "8%",
        top: "42%",
        transform: `translate(${pos.x}px, ${pos.y}px) scale(${phase === "out" ? 0.15 : phase === "in" ? 1.08 : 1}) rotate(${phase === "out" ? 18 : 0}deg)`,
        opacity: phase === "out" ? 0.15 : 1,
        transition: "transform 180ms ease, opacity 180ms ease",
      }}
    >
      сомневаюсь…
    </button>
  );
}

/** Q3: «нет» мигает и появляется в случайном углу; после нескольких попыток почти невидимо */
function NoBlinkCorners({ onMiss, growBump }: { onMiss: (n: number) => void; growBump: () => void }) {
  const corners = [
    { left: "12%", top: "18%" },
    { left: "78%", top: "22%" },
    { left: "18%", top: "72%" },
    { left: "74%", top: "68%" },
    { left: "48%", top: "12%" },
    { left: "55%", top: "78%" },
  ];
  const [idx, setIdx] = useState(3);
  const [flash, setFlash] = useState(false);
  const attempts = useRef(0);

  return (
    <button
      type="button"
      onPointerDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
        growBump();
        attempts.current += 1;
        onMiss(attempts.current);
        setFlash(true);
        window.setTimeout(() => {
          setIdx((i) => {
            let n = Math.floor(Math.random() * corners.length);
            if (n === i) n = (n + 1) % corners.length;
            return n;
          });
          setFlash(false);
        }, 120);
      }}
      className="absolute z-10 touch-none rounded-2xl px-3 py-2 text-[14px] font-medium select-none"
      style={{
        left: corners[idx].left,
        top: corners[idx].top,
        transform: "translate(-50%, -50%)",
        opacity: flash ? 0 : Math.max(0.28, 1 - attempts.current * 0.12),
        background: "color-mix(in srgb, var(--surface) 70%, transparent)",
        color: "var(--muted)",
        border: "1px dashed color-mix(in srgb, var(--line) 80%, transparent)",
        transition: "left 200ms ease, top 200ms ease, opacity 120ms ease",
      }}
    >
      потом
    </button>
  );
}

export function HonestQuizGame() {
  const [step, setStep] = useState<Step>("q1");
  const [answers, setAnswers] = useState<HonestAnswers>({});
  const [aside, setAside] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [grow1, setGrow1] = useState(0);
  const [grow2, setGrow2] = useState(0);
  const [grow3, setGrow3] = useState(0);
  const fileRef = useRef<HTMLInputElement>(null);

  const persist = useCallback(async (next: HonestAnswers, finished = false, photo?: string) => {
    setAnswers(next);
    await upsertHonestQuiz({
      answers: next,
      finished,
      photoDataUrl: photo ?? null,
    });
  }, []);

  const bump = (key: "q1_no_attempts" | "q2_no_attempts" | "q3_no_attempts", n: number) => {
    void persist({ ...answers, [key]: n });
  };

  useEffect(() => {
    setAside(null);
  }, [step]);

  const onYes1 = async () => {
    await persist({ ...answers, q1: "yes" });
    setStep("q2");
  };

  const onYes2 = async () => {
    await persist({ ...answers, q2: "yes" });
    setStep("q3");
  };

  const onSend = async () => {
    await persist({ ...answers, q3: "send" });
    setStep("q3_upload");
  };

  const onPhoto = async (file: File | null) => {
    if (!file) return;
    setError(null);
    setUploading(true);
    try {
      const dataUrl = await fileToCompressedDataUrl(file);
      await persist(answers, true, dataUrl);
      setStep("final");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Не получилось — попробуй ещё раз");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="relative min-h-dvh overflow-hidden">
      {/* soft base */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 transition-colors duration-700"
        style={{
          background:
            step === "q1"
              ? "radial-gradient(ellipse 100% 80% at 30% 20%, #eef6e8 0%, var(--bg) 55%)"
              : step === "q2"
                ? "radial-gradient(ellipse 90% 70% at 70% 10%, #f3eef8 0%, var(--bg) 58%)"
                : step === "q3" || step === "q3_upload"
                  ? "radial-gradient(ellipse 85% 75% at 50% 0%, #f7f0e8 0%, var(--bg) 60%)"
                  : "radial-gradient(ellipse 80% 60% at 50% 30%, color-mix(in srgb, var(--mint) 70%, white) 0%, var(--bg) 70%)",
        }}
      />

      <div className="relative mx-auto flex min-h-dvh w-full max-w-[26rem] flex-col justify-center px-6 py-16">
        {/* ——— 1 ——— */}
        {step === "q1" && (
          <div className="anim-rise">
            <p className="text-[13px] tracking-wide text-muted">один вопрос</p>
            <h1 className="font-display mt-4 text-[clamp(1.85rem,6.5vw,2.35rem)] font-semibold leading-[1.15] tracking-tight text-ink">
              Если бы мы сейчас стояли рядом —
              <span className="mt-2 block text-ink/80">ты бы улыбнулась?</span>
            </h1>
            {aside ? (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">{aside}</p>
            ) : (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">
                Честно. Без «ну типа».
              </p>
            )}
            <div className="relative mt-14 min-h-[10rem]">
              <div className="absolute left-[22%] top-1/2 z-20 -translate-x-1/2 -translate-y-1/2">
                <GrowingYes grow={grow1} onClick={() => void onYes1()}>
                  да
                </GrowingYes>
              </div>
              <NoTeleport
                growBump={() => setGrow1((g) => g + 1)}
                onMiss={(n) => {
                  bump("q1_no_attempts", n);
                  if (n === 1) setAside("Ок, попробуй ещё раз…");
                  if (n >= 2) setAside("Кажется, «нет» сегодня на другой волне.");
                }}
              />
            </div>
          </div>
        )}

        {/* ——— 2 ——— */}
        {step === "q2" && (
          <div className="anim-rise">
            <p className="text-[13px] tracking-wide text-muted">ещё один</p>
            <h1 className="font-display mt-4 text-[clamp(1.85rem,6.5vw,2.35rem)] font-semibold leading-[1.15] tracking-tight text-ink">
              А если серьёзно —
              <span className="mt-2 block">я у тебя в голове бываю?</span>
            </h1>
            {aside ? (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">{aside}</p>
            ) : (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">
                Не обязательно каждый день. Просто… бываю?
              </p>
            )}
            <div className="relative mt-14 min-h-[11rem] overflow-visible">
              <div className="absolute left-[24%] top-[48%] z-20 -translate-x-1/2 -translate-y-1/2">
                <GrowingYes
                  grow={grow2}
                  onClick={() => void onYes2()}
                  className="!bg-[#2a2438] hover:!bg-[#1c1826]"
                >
                  бываешь
                </GrowingYes>
              </div>
              <NoShrinkHop
                growBump={() => setGrow2((g) => g + 1)}
                onMiss={(n) => {
                  bump("q2_no_attempts", n);
                  if (n === 1) setAside("Сомнения тоже имеют право на побег.");
                  if (n === 2) setAside("Ладно, я почти понял.");
                  if (n >= 3) {
                    setAside("Хватит прятаться. Дальше — проще.");
                    window.setTimeout(() => setStep("q3"), 1400);
                  }
                }}
              />
            </div>
          </div>
        )}

        {/* ——— 3 ——— */}
        {step === "q3" && (
          <div className="anim-rise">
            <p className="text-[13px] tracking-wide text-muted">последнее</p>
            <h1 className="font-display mt-4 text-[clamp(1.85rem,6.5vw,2.35rem)] font-semibold leading-[1.15] tracking-tight text-ink">
              Покажи, как ты выглядишь
              <span className="mt-2 block text-[0.92em] font-medium text-ink/75">
                прямо сейчас
              </span>
            </h1>
            {aside ? (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">{aside}</p>
            ) : (
              <p className="mt-5 text-[15px] leading-relaxed text-muted">
                Не идеальную. Живую. Одну фотку.
              </p>
            )}
            <div className="relative mt-12 min-h-[12rem]">
              <div className="absolute left-1/2 top-[42%] z-20 -translate-x-1/2 -translate-y-1/2">
                <GrowingYes
                  grow={grow3}
                  onClick={() => void onSend()}
                  className="!bg-[#3d3428] hover:!bg-[#2a231c]"
                >
                  хорошо
                </GrowingYes>
              </div>
              <NoBlinkCorners
                growBump={() => setGrow3((g) => g + 1)}
                onMiss={(n) => {
                  bump("q3_no_attempts", n);
                  if (n === 1) setAside("«Потом» тоже убегает, да?");
                  if (n >= 3) setAside("Она почти исчезла. Осталась только одна кнопка.");
                }}
              />
            </div>
          </div>
        )}

        {step === "q3_upload" && (
          <div className="anim-rise">
            <p className="font-display text-[15px] leading-relaxed text-muted">Хорошо.</p>
            <h1 className="font-display mt-4 text-[clamp(1.65rem,5.5vw,2.05rem)] font-semibold leading-snug tracking-tight text-ink">
              Выбери фото — и всё
            </h1>
            <p className="mt-4 text-[15px] leading-relaxed text-muted">
              Больше ничего не спрошу.
            </p>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              capture="user"
              className="hidden"
              onChange={(e) => void onPhoto(e.target.files?.[0] ?? null)}
            />
            <div className="mt-10">
              <GrowingYes grow={0} disabled={uploading} onClick={() => fileRef.current?.click()}>
                {uploading ? "секунду…" : "выбрать фото"}
              </GrowingYes>
            </div>
            {error ? <p className="mt-4 text-[14px] text-destructive">{error}</p> : null}
          </div>
        )}

        {step === "final" && (
          <div className="anim-rise">
            <h1 className="font-display text-[clamp(2rem,7vw,2.55rem)] font-semibold tracking-tight text-ink">
              Спасибо
            </h1>
            <p className="mt-5 text-[17px] leading-relaxed text-ink/90">
              Всё. Можешь уходить.
            </p>
            <p className="mt-12 text-[14px] leading-relaxed text-muted">
              P.S. Я именно ради этого всё и сделал.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
