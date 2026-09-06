/** Цветовые матрицы как в Flutter `AppImageEditColorMatrices` / `AppImageEffect`. */

export type ColorMatrix = readonly [
  number, number, number, number, number,
  number, number, number, number, number,
  number, number, number, number, number,
  number, number, number, number, number,
];

export type ImageEditToolId =
  | "brightness"
  | "contrast"
  | "saturation"
  | "warmth"
  | "fade";

export type ImageEditSettings = {
  effectId: string;
  brightness: number;
  contrast: number;
  saturation: number;
  warmth: number;
  fade: number;
};

export const DEFAULT_IMAGE_EDIT: ImageEditSettings = {
  effectId: "original",
  brightness: 0,
  contrast: 0,
  saturation: 0,
  warmth: 0,
  fade: 0,
};

export const IMAGE_EDIT_TOOLS: {
  id: ImageEditToolId;
  label: string;
}[] = [
  { id: "brightness", label: "Яркость" },
  { id: "contrast", label: "Контраст" },
  { id: "saturation", label: "Насыщ." },
  { id: "warmth", label: "Теплота" },
  { id: "fade", label: "Затухание" },
];

const IDENTITY: ColorMatrix = [
  1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
];

export type ImageEffectPreset = {
  id: string;
  name: string;
  matrix: ColorMatrix;
};

export const IMAGE_EFFECT_PRESETS: ImageEffectPreset[] = [
  { id: "original", name: "Оригинал", matrix: IDENTITY },
  {
    id: "luminar",
    name: "Люмина",
    matrix: [1.08, 0.02, 0, 0, 8, 0, 1.04, 0, 0, 6, 0, 0, 0.96, 0, 0, 0, 0, 0, 1, 0],
  },
  {
    id: "cool",
    name: "Холод",
    matrix: [0.95, 0, 0, 0, 0, 0, 1.02, 0, 0, 0, 0, 0, 1.12, 0, 10, 0, 0, 0, 1, 0],
  },
  {
    id: "maya",
    name: "Майя",
    matrix: [
      0.93, 0.05, 0.02, 0, 18, 0.03, 0.92, 0.05, 0, 18, 0.02, 0.05, 0.88, 0, 18, 0, 0, 0, 1, 0,
    ],
  },
  {
    id: "ray",
    name: "Рей",
    matrix: [
      1.25, -0.05, -0.05, 0, -10, -0.05, 1.25, -0.05, 0, -10, -0.05, -0.05, 1.25, 0, -10, 0, 0, 0,
      1, 0,
    ],
  },
  {
    id: "paris",
    name: "Пари",
    matrix: [1.05, 0.08, 0, 0, 12, 0.02, 1.0, 0, 0, 8, 0, 0.02, 0.92, 0, 0, 0, 0, 0, 1, 0],
  },
  {
    id: "mono",
    name: "Моно",
    matrix: [
      0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0,
    ],
  },
  {
    id: "vivid",
    name: "Яркий",
    matrix: [
      1.18, -0.05, -0.05, 0, 0, -0.05, 1.18, -0.05, 0, 0, -0.05, -0.05, 1.18, 0, 0, 0, 0, 0, 1, 0,
    ],
  },
];

function effectById(id: string): ImageEffectPreset {
  return IMAGE_EFFECT_PRESETS.find((e) => e.id === id) ?? IMAGE_EFFECT_PRESETS[0]!;
}

function brightnessMatrix(value: number): ColorMatrix {
  const offset = value * 36;
  return [1, 0, 0, 0, offset, 0, 1, 0, 0, offset, 0, 0, 1, 0, offset, 0, 0, 0, 1, 0];
}

function contrastMatrix(value: number): ColorMatrix {
  const scale = 1 + value;
  const offset = (1 - scale) * 128;
  return [scale, 0, 0, 0, offset, 0, scale, 0, 0, offset, 0, 0, scale, 0, offset, 0, 0, 0, 1, 0];
}

function saturationMatrix(value: number): ColorMatrix {
  const s = 1 + value;
  const r = 0.2126;
  const g = 0.7152;
  const b = 0.0722;
  const ir = (1 - s) * r;
  const ig = (1 - s) * g;
  const ib = (1 - s) * b;
  return [ir + s, ig, ib, 0, 0, ir, ig + s, ib, 0, 0, ir, ig, ib + s, 0, 0, 0, 0, 0, 1, 0];
}

function warmthMatrix(value: number): ColorMatrix {
  const shift = value * 28;
  return [1, 0, 0, 0, shift, 0, 1, 0, 0, 0, 0, 0, 1, 0, -shift, 0, 0, 0, 1, 0];
}

function fadeMatrix(value: number): ColorMatrix {
  const lift = value * 24;
  const scale = 1 - value * 0.18;
  const offset = lift + (1 - scale) * 128;
  return [scale, 0, 0, 0, offset, 0, scale, 0, 0, offset, 0, 0, scale, 0, offset, 0, 0, 0, 1, 0];
}

/** a × b (как Flutter multiply). */
export function multiplyMatrices(a: ColorMatrix, b: ColorMatrix): ColorMatrix {
  const out = new Array<number>(20).fill(0);
  for (let row = 0; row < 4; row++) {
    for (let col = 0; col < 5; col++) {
      if (col === 4) {
        out[row * 5 + 4] =
          a[row * 5 + 4]! +
          b[4]! * a[row * 5 + 0]! +
          b[9]! * a[row * 5 + 1]! +
          b[14]! * a[row * 5 + 2]! +
          b[19]! * a[row * 5 + 3]!;
        continue;
      }
      out[row * 5 + col] =
        a[row * 5 + 0]! * b[col + 0]! +
        a[row * 5 + 1]! * b[col + 5]! +
        a[row * 5 + 2]! * b[col + 10]! +
        a[row * 5 + 3]! * b[col + 15]!;
    }
  }
  return out as unknown as ColorMatrix;
}

export function composeMatrices(matrices: ColorMatrix[]): ColorMatrix {
  return matrices.reduce<ColorMatrix>((acc, m) => multiplyMatrices(acc, m), IDENTITY);
}

export function composedColorMatrix(settings: ImageEditSettings): ColorMatrix {
  return composeMatrices([
    effectById(settings.effectId).matrix,
    brightnessMatrix(settings.brightness),
    contrastMatrix(settings.contrast),
    saturationMatrix(settings.saturation),
    warmthMatrix(settings.warmth),
    fadeMatrix(settings.fade),
  ]);
}

export function effectOnlyMatrix(effectId: string): ColorMatrix {
  return effectById(effectId).matrix;
}

export function isIdentityEdit(settings: ImageEditSettings): boolean {
  return (
    settings.effectId === "original" &&
    settings.brightness === 0 &&
    settings.contrast === 0 &&
    settings.saturation === 0 &&
    settings.warmth === 0 &&
    settings.fade === 0
  );
}

/** SVG feColorMatrix values (offsets 0–1). */
export function matrixToSvgValues(m: ColorMatrix): string {
  const rows: string[] = [];
  for (let r = 0; r < 4; r++) {
    const i = r * 5;
    rows.push(
      `${m[i]} ${m[i + 1]} ${m[i + 2]} ${m[i + 3]} ${m[i + 4]! / 255}`,
    );
  }
  return rows.join(" ");
}

/** Применить матрицу к ImageData (RGB 0–255, как Flutter exporter). */
export function applyColorMatrixToImageData(data: ImageData, m: ColorMatrix): void {
  const px = data.data;
  for (let i = 0; i < px.length; i += 4) {
    const r = px[i]!;
    const g = px[i + 1]!;
    const b = px[i + 2]!;
    const a = px[i + 3]!;
    px[i] = clampByte(m[0]! * r + m[1]! * g + m[2]! * b + m[3]! * a + m[4]!);
    px[i + 1] = clampByte(m[5]! * r + m[6]! * g + m[7]! * b + m[8]! * a + m[9]!);
    px[i + 2] = clampByte(m[10]! * r + m[11]! * g + m[12]! * b + m[13]! * a + m[14]!);
    px[i + 3] = clampByte(m[15]! * r + m[16]! * g + m[17]! * b + m[18]! * a + m[19]!);
  }
}

function clampByte(n: number): number {
  return Math.max(0, Math.min(255, Math.round(n)));
}

export function formatSliderPercent(value: number): string {
  const percent = Math.round(value * 100);
  if (percent > 0) return `+${percent}`;
  return `${percent}`;
}
