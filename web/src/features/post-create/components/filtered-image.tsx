"use client";

import { useId, type CSSProperties, type DragEventHandler } from "react";
import {
  composedColorMatrix,
  effectOnlyMatrix,
  matrixToSvgValues,
  type ColorMatrix,
  type ImageEditSettings,
} from "@/features/post-create/lib/image-edit-matrix";

type FilteredImageProps = {
  src: string;
  alt?: string;
  className?: string;
  style?: CSSProperties;
  settings?: ImageEditSettings;
  effectIdOnly?: string;
  draggable?: boolean;
  onDragStart?: DragEventHandler<HTMLImageElement>;
};

function useMatrixFilter(matrix: ColorMatrix) {
  const rawId = useId().replace(/:/g, "");
  const filterId = `img-edit-${rawId}`;
  const values = matrixToSvgValues(matrix);
  return { filterId, values };
}

/** Превью с feColorMatrix (как ColorFiltered в мобилке). */
export function FilteredImage({
  src,
  alt = "",
  className = "",
  style,
  settings,
  effectIdOnly,
  draggable = false,
  onDragStart,
}: FilteredImageProps) {
  const matrix = settings
    ? composedColorMatrix(settings)
    : effectOnlyMatrix(effectIdOnly ?? "original");
  const { filterId, values } = useMatrixFilter(matrix);

  return (
    <>
      <svg width={0} height={0} className="absolute" aria-hidden>
        <filter id={filterId} colorInterpolationFilters="sRGB">
          <feColorMatrix type="matrix" values={values} />
        </filter>
      </svg>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt={alt}
        draggable={draggable}
        onDragStart={onDragStart}
        className={className}
        style={{ ...style, filter: `url(#${filterId})` }}
      />
    </>
  );
}
