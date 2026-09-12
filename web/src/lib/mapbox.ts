/** Public Mapbox token + Standard style (lightPreset day/night). */

export const MAPBOX_STYLE_STANDARD = "mapbox://styles/mapbox/standard";

export function getMapboxToken(): string {
  return process.env.NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN?.trim() ?? "";
}

export function isWebDarkTheme(): boolean {
  if (typeof document === "undefined") return false;
  return document.documentElement.getAttribute("data-theme") === "dark";
}

export function mapboxLightPreset(dark = isWebDarkTheme()): "day" | "night" {
  return dark ? "night" : "day";
}

/** Config for Mapbox Standard — color theme always `default`, light by app theme. */
export function mapboxBasemapConfig(dark = isWebDarkTheme()) {
  return {
    basemap: {
      lightPreset: mapboxLightPreset(dark),
      theme: "default",
    },
  };
}

export function applyMapboxLightPreset(map: { setConfigProperty: (importId: string, name: string, value: unknown) => void }, dark: boolean) {
  map.setConfigProperty("basemap", "lightPreset", mapboxLightPreset(dark));
  map.setConfigProperty("basemap", "theme", "default");
}

/** Следит за `html[data-theme]` (как ThemeToggle / prefs). */
export function subscribeWebTheme(onChange: (dark: boolean) => void): () => void {
  if (typeof document === "undefined") return () => {};
  const el = document.documentElement;
  let last = isWebDarkTheme();
  const notify = () => {
    const next = isWebDarkTheme();
    if (next === last) return;
    last = next;
    onChange(next);
  };
  const obs = new MutationObserver(notify);
  obs.observe(el, { attributes: true, attributeFilter: ["data-theme"] });
  return () => obs.disconnect();
}
