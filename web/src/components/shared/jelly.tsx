"use client";

import {
  type CSSProperties,
  type ReactNode,
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";

/** Как `JellyPressController` в Flutter: squash 0.85 → elasticOut → 1.0, ~600ms. */
export const JELLY_DURATION_MS = 600;
export const JELLY_PRESS_SCALE = 0.85;

function elasticOut(t: number): number {
  if (t === 0 || t === 1) return t;
  const p = 0.4;
  return Math.pow(2, -10 * t) * Math.sin(((t - p / 4) * (2 * Math.PI)) / p) + 1;
}

export type JellyVariant = "uniform" | "banner";

export type JellyPressOptions = {
  /** Вибрация на поддерживающих устройствах (аналог HapticFeedback). */
  haptic?: boolean;
  disabled?: boolean;
  /**
   * `uniform` — обычный scale.
   * `banner` — как ProfileHeaderBanner: scaleX + вертикальный stretch от низа + perspective.
   */
  variant?: JellyVariant;
};

function jellyStyle(scale: number, variant: JellyVariant): CSSProperties {
  if (variant === "banner") {
    const vScale = 1 + (1 - scale) * 0.5;
    return {
      transform: `perspective(1000px) scaleX(${scale}) scaleY(${vScale})`,
      transformOrigin: "bottom center",
      willChange: "transform",
    };
  }
  return {
    transform: `scale(${scale})`,
    transformOrigin: "center",
    willChange: "transform",
  };
}

/**
 * Переиспользуемый bubble-tap: `scale` + `trigger()` на клик.
 * Подставь `style` или оберни в [JellyPress].
 */
export function useJellyPress(options: JellyPressOptions = {}) {
  const { haptic = true, disabled = false, variant = "uniform" } = options;
  const [scale, setScale] = useState(1);
  const frameRef = useRef<number | null>(null);
  const startRef = useRef(0);

  const cancel = useCallback(() => {
    if (frameRef.current != null) {
      cancelAnimationFrame(frameRef.current);
      frameRef.current = null;
    }
  }, []);

  useEffect(() => () => cancel(), [cancel]);

  const trigger = useCallback(() => {
    if (disabled) return;
    cancel();
    if (haptic && typeof navigator !== "undefined" && "vibrate" in navigator) {
      navigator.vibrate?.(12);
    }
    startRef.current = performance.now();
    setScale(JELLY_PRESS_SCALE);

    const tick = (now: number) => {
      const t = Math.min(1, (now - startRef.current) / JELLY_DURATION_MS);
      const eased = elasticOut(t);
      setScale(JELLY_PRESS_SCALE + (1 - JELLY_PRESS_SCALE) * eased);
      if (t < 1) {
        frameRef.current = requestAnimationFrame(tick);
      } else {
        frameRef.current = null;
        setScale(1);
      }
    };

    frameRef.current = requestAnimationFrame(tick);
  }, [cancel, disabled, haptic]);

  return { scale, style: jellyStyle(scale, variant), trigger };
}

type JellyPressProps = JellyPressOptions & {
  children: ReactNode;
  className?: string;
  /** Вызвать jelly и затем onActivate (кнопка / ссылка). */
  onActivate?: () => void;
  as?: "div" | "span" | "button";
};

/** Обёртка: тап → bubble, потом `onActivate`. */
export function JellyPress({
  children,
  className = "",
  onActivate,
  haptic,
  disabled,
  variant,
  as: Tag = "div",
}: JellyPressProps) {
  const { style, trigger } = useJellyPress({ haptic, disabled, variant });

  return (
    <Tag
      type={Tag === "button" ? "button" : undefined}
      className={className}
      style={style}
      onPointerDown={(e) => {
        if (disabled) return;
        if (e.button !== 0) return;
        trigger();
      }}
      onClick={(e) => {
        if (disabled) return;
        onActivate?.();
        e.stopPropagation();
      }}
    >
      {children}
    </Tag>
  );
}
