/**
 * ScrypathOps re-skin contract: the computed-style proof (Phase 187, UI-SPEC P-01 to P-21 except
 * P-12 in `admin_path_motion.spec.ts` and P-17 in the host contract).
 *
 * Every assertion reads computed styles from a real browser and resolves the expected values from
 * the theme in the page (a probe element with `background-color: var(--token)`, scoped with
 * `data-theme` when a specific theme is wanted); no color is hard-coded here. Each check runs on
 * the six ops screens at 390 and 1280 px in light, dark and System (OS dark with no stored
 * preference). A failure lists the selector path of every offender, grouped, so it reads as a short
 * list of rules to fix.
 *
 * Economy: one `page.evaluate` per screen collects the facts for every family, cached per
 * (theme, viewport) for the whole file, so the six screens are visited once per theme and
 * viewport however many assertions read them.
 *
 * HOW TO RUN (manual server per playwright.config.ts, there is NO webServer):
 *   Boot a disposable test stack (see `make up`), then
 *     cd examples/scrypath_ecommerce
 *     PLAYWRIGHT_BASE_URL=http://127.0.0.1:<port> npx playwright test e2e/ops_reskin_contract.spec.ts --workers=1
 */
import {
  expect,
  test,
  type APIRequestContext,
  type Browser,
  type BrowserContext,
  type Page
} from "@playwright/test";

import {
  deleteSavedSearches,
  drainSearchQueue,
  saveCurrentSearch,
  seedScenario,
  waitForLiveConnected
} from "./helpers/e2e";
import { PNG } from "pngjs";

import { assertSystemDarkInvariants, THEME_MODES, themeSlug, type ThemeMode } from "./helpers/theme-grid";

// ---------------------------------------------------------------------------------------------
// Shared types and constants
// ---------------------------------------------------------------------------------------------

const VIEWPORTS_187 = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1280, height: 900 }
} as const;
type ViewportName = keyof typeof VIEWPORTS_187;
const VIEWPORT_NAMES = Object.keys(VIEWPORTS_187) as ViewportName[];

type Screen = { name: string; path: string; heading: string };

const SCREENS: Screen[] = [
  { name: "Control Room", path: "/admin/search", heading: "Control Room" },
  { name: "Search health", path: "/admin/search/health", heading: "Search health" },
  { name: "Failed sync work", path: "/admin/search/failed-sync", heading: "Failed sync work" },
  { name: "Sync and index", path: "/admin/search/sync-and-index", heading: "Sync and index" },
  { name: "Search", path: "/admin/search/search", heading: "Search" },
  { name: "Help", path: "/admin/search/help", heading: "Help" }
];

// Test-only fixture routes (mounted on the test stack only): one Search health row per status, and
// a row set with long, unbroken and non-Latin names.
const ALL_STATUSES_PATH = "/admin/search/phase173/health?scenario=all-statuses";
const LONG_NAMES_PATH = "/admin/search/phase173/health?scenario=long";

const effectiveTheme = (mode: ThemeMode): "light" | "dark" =>
  mode.kind === "explicit" ? mode.theme : mode.colorScheme;

const MODE_VIEWPORTS: Array<{ mode: ThemeMode; viewport: ViewportName; slug: string }> =
  THEME_MODES.flatMap((mode) =>
    VIEWPORT_NAMES.map((viewport) => ({ mode, viewport, slug: `${themeSlug(mode)}, ${viewport}` }))
  );

type Hit = {
  color: "plum" | "failed" | "retrying" | "clear";
  kind: string;
  path: string;
  allowed: boolean;
};

type Facts = {
  effective: string;
  tokens: Record<string, string>;
  lightPlum: string;
  fontGroups: Array<{ family: string; size: number; weight: number; transform: string; count: number; path: string }>;
  h1: { family: string; size: number; weight: number; lineHeight: number } | null;
  monoMisses: string[];
  bricolage: string[];
  statuses: Array<{
    status: string;
    word: string;
    icon: string;
    iconHeight: number;
    shape: string | null;
    ariaHidden: string | null;
    pathFill: string | null;
    path: string;
  }>;
  primaryButtons: Array<{ path: string; text: string; bg: string; color: string; inert: boolean }>;
  defaultButtons: Array<{ path: string; edges: string[]; widths: number[] }>;
  hits: Hit[];
  plumTextOnNight: string[];
  rowActions: Array<{ path: string; text: string; tuple: string; height: number }>;
  proseLinks: Array<{ path: string; decoration: string; color: string }>;
  signature: Array<{
    path: string;
    width: number;
    style: string;
    color: string;
    rect: number[];
    rectUnselected: number[] | null;
    widthUnselected: number | null;
    textColor: string;
    weight: string;
    bg: string;
  }>;
  controls: Array<{
    path: string;
    tag: string;
    named: boolean;
    // A native checkbox or radio: the browser draws its edge, so the computed border is 0.
    native: boolean;
    // The focused control shows its focus state, not its resting border.
    focused: boolean;
    plum: boolean;
    sides: Array<{ side: string; width: number; color: string; alpha: number; ratioInside: number; ratioOutside: number }>;
  }>;
  natives: Array<{ path: string; x: number; y: number; width: number; height: number; edgeRatio?: number }>;
  lockups: {
    visible: Array<{ src: string; width: number; height: number }>;
    marks: Array<{ visible: boolean; flexShrink: string }>;
  };
};

type ItemFacts = {
  path: string;
  bg: string;
  color: string;
  weight: string;
  startWidth: number;
  startStyle: string;
  startColor: string;
  suffix: string | null;
};

type OverlayFacts = {
  bg: string;
  surfaceAlpha: number;
  edges: Array<{ side: string; width: number; style: string; color: string }>;
  edgeRatio: number;
  boxShadow: string;
  pairsChecked: number;
  minRatio: number | null;
  lowPairs: Array<{ path: string; ratio: number }>;
  primaryButtons: number;
  active: ItemFacts | null;
  inactive: ItemFacts | null;
};

type P187Api = {
  collect: () => Facts;
  tokens: (scope?: string) => Record<string, string>;
  overlayFacts: (rootSelector: string, itemSelector: string, activeSelector: string) => OverlayFacts | null;
};

// ---------------------------------------------------------------------------------------------
// In-page library. Injected with `addInitScript`, so it must be self-contained.
// ---------------------------------------------------------------------------------------------

function installP187(): void {
  type RGBA = [number, number, number, number];

  const TOKEN_VARS: Record<string, string> = {
    primary: "--color-primary",
    primaryContent: "--color-primary-content",
    base100: "--color-base-100",
    base200: "--color-base-200",
    base300: "--color-base-300",
    baseContent: "--color-base-content",
    controlEdge: "--ops-control-edge",
    sunken: "--ops-sunken",
    selected: "--ops-selected",
    muted: "--ops-text-muted",
    failed: "--ops-status-failed",
    retrying: "--ops-status-retrying",
    pending: "--ops-status-pending",
    clear: "--ops-status-clear"
  };

  let canvas: HTMLCanvasElement | null = null;
  let g2d: CanvasRenderingContext2D | null = null;

  const parse = (css: string): RGBA => {
    const m = css.match(/^rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:\s*[,/]\s*([\d.]+%?))?\s*\)$/);
    if (m) {
      const raw = m[4];
      const alpha = raw === undefined ? 1 : raw.endsWith("%") ? parseFloat(raw) / 100 : parseFloat(raw);
      return [Number(m[1]), Number(m[2]), Number(m[3]), alpha];
    }
    // Any other CSS color syntax (oklch, color-mix, color()) is normalized through a canvas.
    if (!canvas) {
      canvas = document.createElement("canvas");
      canvas.width = 1;
      canvas.height = 1;
      g2d = canvas.getContext("2d", { willReadFrequently: true });
    }
    const ctx = g2d as CanvasRenderingContext2D;
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = "#000000";
    ctx.fillStyle = css;
    ctx.fillRect(0, 0, 1, 1);
    const d = ctx.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2], d[3] / 255];
  };

  const canon = (css: string): string => {
    const [r, g, b, a] = parse(css);
    const rgb = `${Math.round(r)}, ${Math.round(g)}, ${Math.round(b)}`;
    return a >= 0.999 ? `rgb(${rgb})` : `rgba(${rgb}, ${a.toFixed(3)})`;
  };

  const lum = (c: number[]): number => {
    const f = (v: number): number => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]);
  };
  const ratio = (a: number[], b: number[]): number => {
    const la = lum(a);
    const lb = lum(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  };
  const over = (top: RGBA, bottom: number[]): number[] =>
    [0, 1, 2].map((i) => top[i] * top[3] + bottom[i] * (1 - top[3]));

  // The color directly behind an element: every ancestor background, composited from the first
  // opaque one downward. `includeSelf` adds the element's own fill (the inside of its border).
  const backdrop = (el: Element, includeSelf: boolean): number[] => {
    const layers: RGBA[] = [];
    let node: Element | null = includeSelf ? el : el.parentElement;
    while (node) {
      const c = parse(getComputedStyle(node).backgroundColor);
      if (c[3] > 0) layers.push(c);
      if (c[3] >= 0.999) break;
      node = node.parentElement;
    }
    let base: number[] = [255, 255, 255];
    for (let i = layers.length - 1; i >= 0; i -= 1) base = over(layers[i], base);
    return base;
  };

  const visible = (el: Element): boolean => {
    const r = el.getBoundingClientRect();
    if (r.width <= 1 && r.height <= 1) return false;
    const s = getComputedStyle(el);
    return s.visibility === "visible" && s.display !== "none";
  };

  const pathOf = (el: Element): string => {
    const parts: string[] = [];
    let node: Element | null = el;
    for (let depth = 0; node && depth < 3 && node !== document.body; depth += 1, node = node.parentElement) {
      let part = node.tagName.toLowerCase();
      if (node.id) part += `#${node.id}`;
      const testid = node.getAttribute("data-testid");
      if (testid) part += `[${testid}]`;
      const cls =
        typeof node.className === "string"
          ? node.className.trim().split(/\s+/).filter(Boolean).slice(0, 3).join(".")
          : "";
      if (cls) part += `.${cls}`;
      parts.unshift(part);
    }
    return parts.join(" > ");
  };

  const probeColor = (declaration: string, scope?: string): string => {
    const p = document.createElement("div");
    if (scope) p.setAttribute("data-theme", scope);
    p.style.cssText = `position:absolute;left:-9999px;top:0;width:1px;height:1px;${declaration}`;
    document.body.appendChild(p);
    const value = getComputedStyle(p).backgroundColor;
    p.remove();
    return canon(value);
  };

  const tokens = (scope?: string): Record<string, string> =>
    Object.fromEntries(
      Object.entries(TOKEN_VARS).map(([key, name]) => [key, probeColor(`background-color:var(${name})`, scope)])
    );

  const hasOwnText = (el: Element): boolean =>
    Array.from(el.childNodes).some((n) => n.nodeType === Node.TEXT_NODE && (n.textContent ?? "").trim() !== "");

  const firstFamily = (family: string): string => family.split(",")[0].trim().replace(/^["']|["']$/g, "");

  const SKIP_TAGS = new Set(["SCRIPT", "STYLE", "TEMPLATE", "HEAD", "META", "LINK", "TITLE", "NOSCRIPT"]);

  // Selection Signature elements (UI-SPEC Interaction Contracts) and the reserved-color lists.
  const SIGNATURE = [
    ".ops-nav-item-active",
    ".ops-nav-item[aria-current='page']",
    ".ops-saved-search-row--loaded",
    ".ops-object-item-active",
    ".ops-filter-chip--selected",
    ".ops-schema-picker__option:has(input:checked)",
    ".ops-segmented-btn[aria-pressed='true']",
    ".ops-btn[aria-pressed='true']",
    ".ops-theme-toggle__button[aria-pressed='true']",
    ".ops-theme-toggle__button[data-theme-selected='true']",
    ".ops-cmdk__item.is-active"
  ];
  const PLUM_TEXT = [
    "a.link",
    ".link-primary",
    ".ops-help-link",
    ".ops-handoff__link",
    ".ops-help-topics a",
    ".ops-help-content a:not(.ops-text-action)",
    ".ops-nav-item-active",
    ".ops-nav-item[aria-current='page']",
    ".ops-cmdk__item.is-active"
  ];
  const PLUM_FILL = [".btn-primary", "input[type=checkbox]:checked", "input[type=radio]:checked", ".toggle:checked"];
  const PROSE_LINKS = [
    "a.link",
    ".link-primary",
    ".ops-help-link",
    ".ops-handoff__link",
    ".ops-help-topics a",
    ".ops-help-content a:not(.ops-text-action)"
  ];
  const FAILED_AREAS = ["[data-sync-status='failed']", ".ops-notice-surface--error", ".text-error", ".ops-metric__value--error"];
  const RETRYING_AREAS = ["[data-sync-status='retrying']", ".ops-notice-surface--warning", ".ops-metric__value--warning"];
  const CLEAR_AREAS = ["[data-sync-status='clear']"];

  const CONTROL = "button, input:not([type=hidden]), select, textarea, .btn, summary, [role=button]";
  const CONTROL_EXEMPT = ".ops-text-action, .btn-ghost, .ops-icon-btn, [data-ops-timestamp-copy], .sr-only";
  // LD-15: the controls the UI-SPEC names must carry the opaque Control Edge.
  const CONTROL_NAMED =
    "input:not([type=hidden]), select, textarea, .btn:not(.btn-ghost):not(.btn-primary), .ops-filter-chip, .ops-command-hint, .ops-nav-trigger, .ops-nav-close, .ops-theme-toggle";

  const sideKey = ["top", "right", "bottom", "left"] as const;

  const collect = (): Facts => {
    const tk = tokens();
    const lightTokens = tokens("light");
    const effective = document.documentElement.getAttribute("data-theme-effective") ?? "";
    const els = Array.from(document.body.querySelectorAll("*")).filter(
      (e) => !SKIP_TAGS.has(e.tagName) && visible(e)
    );

    const fontGroups = new Map<string, Facts["fontGroups"][number]>();
    const monoMisses: string[] = [];
    const bricolage: string[] = [];
    const hits: Hit[] = [];
    const plumTextOnNight: string[] = [];
    const controls: Facts["controls"] = [];
    const natives: Facts["natives"] = [];
    const defaultButtons: Facts["defaultButtons"] = [];
    const primaryButtons: Facts["primaryButtons"] = [];
    const rowActions: Facts["rowActions"] = [];
    const proseLinks: Facts["proseLinks"] = [];

    const palette: Array<["plum" | "failed" | "retrying" | "clear", string]> = [
      ["plum", tk.primary],
      ["failed", tk.failed],
      ["retrying", tk.retrying],
      ["clear", tk.clear]
    ];
    const areaFor = (color: string): string[] =>
      color === "failed" ? FAILED_AREAS : color === "retrying" ? RETRYING_AREAS : CLEAR_AREAS;

    for (const el of els) {
      const cs = getComputedStyle(el);
      const path = pathOf(el);
      const own = hasOwnText(el);

      // Typography (P-02).
      if (/bricolage/i.test(cs.fontFamily)) bricolage.push(path);
      if (own) {
        const family = firstFamily(cs.fontFamily);
        const key = `${family}|${cs.fontSize}|${cs.fontWeight}|${cs.textTransform}`;
        const group = fontGroups.get(key);
        if (group) group.count += 1;
        else
          fontGroups.set(key, {
            family,
            size: parseFloat(cs.fontSize),
            weight: Number(cs.fontWeight),
            transform: cs.textTransform,
            count: 1,
            path
          });
      }
      if (
        el.matches(".ops-time__value, [data-ops-timestamp-copy], [data-ops-identity], code, kbd") &&
        firstFamily(cs.fontFamily) !== "Sometype Mono"
      ) {
        monoMisses.push(`${path} -> ${cs.fontFamily}`);
      }

      // Reserved colors (P-04, P-18).
      for (const [name, value] of palette) {
        const allowedIn = (list: string[]): boolean => el.closest(list.join(",")) !== null;
        const record = (kind: string, allowed: boolean): void => {
          hits.push({ color: name, kind, path, allowed });
        };
        if (own && canon(cs.color) === value) {
          record("text", name === "plum" ? allowedIn(PLUM_TEXT) : allowedIn(areaFor(name)));
        }
        if (canon(cs.backgroundColor) === value) {
          record("background", name === "plum" ? el.matches(PLUM_FILL.join(",")) : false);
        }
        sideKey.forEach((side, i) => {
          const width = parseFloat(
            [cs.borderTopWidth, cs.borderRightWidth, cs.borderBottomWidth, cs.borderLeftWidth][i]
          );
          const style = [cs.borderTopStyle, cs.borderRightStyle, cs.borderBottomStyle, cs.borderLeftStyle][i];
          const color = [cs.borderTopColor, cs.borderRightColor, cs.borderBottomColor, cs.borderLeftColor][i];
          if (width > 0 && style !== "none" && canon(color) === value) {
            let allowed = false;
            if (name === "plum") {
              allowed =
                el.matches(PLUM_FILL.join(",")) || (side === "left" && el.matches(SIGNATURE.join(",")));
            } else if (side === "left") {
              allowed = el.matches(areaFor(name).join(","));
            }
            record(`border-${side}`, allowed);
          }
        });
        if (cs.outlineStyle !== "none" && parseFloat(cs.outlineWidth) > 0 && canon(cs.outlineColor) === value) {
          record("outline", name === "plum" && el.matches(":focus-visible"));
        }
        if (el instanceof SVGElement && cs.fill !== "none" && canon(cs.fill) === value) {
          record("fill", allowedIn(areaFor(name)));
        }
      }
      if (effective === "dark" && own && canon(cs.color) === lightTokens.primary) {
        plumTextOnNight.push(path);
      }

      // Plum buttons and default buttons (P-04).
      if (el.matches(".btn-primary")) {
        primaryButtons.push({
          path,
          text: (el.textContent ?? "").trim(),
          bg: canon(cs.backgroundColor),
          color: canon(cs.color),
          inert: el.closest("[inert]") !== null
        });
      } else if (el.matches(".btn:not(.btn-ghost)")) {
        defaultButtons.push({
          path,
          edges: [cs.borderTopColor, cs.borderRightColor, cs.borderBottomColor, cs.borderLeftColor].map(canon),
          widths: [cs.borderTopWidth, cs.borderRightWidth, cs.borderBottomWidth, cs.borderLeftWidth].map(parseFloat)
        });
      }

      // Row actions and prose links (P-05, P-06).
      if (
        el.matches(".ops-text-action") &&
        !(el as HTMLButtonElement).disabled &&
        el.getAttribute("aria-disabled") !== "true"
      ) {
        rowActions.push({
          path,
          text: (el.textContent ?? "").trim().replace(/\s+/g, " "),
          tuple: [
            firstFamily(cs.fontFamily),
            cs.fontSize,
            cs.fontWeight,
            canon(cs.color),
            cs.textDecorationLine,
            cs.textDecorationStyle
          ].join(" | "),
          height: el.getBoundingClientRect().height
        });
      }
      if (el.matches(PROSE_LINKS.join(","))) {
        proseLinks.push({ path, decoration: cs.textDecorationLine, color: canon(cs.color) });
      }

      // Controls (P-08).
      if (el.matches(CONTROL) && !el.matches(CONTROL_EXEMPT)) {
        const inside = backdrop(el, true);
        const outside = backdrop(el, false);
        const sides: Facts["controls"][number]["sides"] = [];
        sideKey.forEach((side, i) => {
          const width = parseFloat(
            [cs.borderTopWidth, cs.borderRightWidth, cs.borderBottomWidth, cs.borderLeftWidth][i]
          );
          const style = [cs.borderTopStyle, cs.borderRightStyle, cs.borderBottomStyle, cs.borderLeftStyle][i];
          const raw = [cs.borderTopColor, cs.borderRightColor, cs.borderBottomColor, cs.borderLeftColor][i];
          if (width <= 0 || style === "none") return;
          const rgba = parse(raw);
          sides.push({
            side,
            width,
            color: canon(raw),
            alpha: rgba[3],
            ratioInside: ratio(rgba, inside),
            ratioOutside: ratio(rgba, outside)
          });
        });
        const native =
          el instanceof HTMLInputElement &&
          (el.type === "checkbox" || el.type === "radio") &&
          cs.appearance !== "none";
        controls.push({
          path,
          tag: el.tagName.toLowerCase(),
          named: el.matches(CONTROL_NAMED),
          native,
          focused: el.matches(":focus"),
          plum: el.matches(".btn-primary"),
          sides
        });
        if (native && !(el as HTMLInputElement).checked) {
          const r = el.getBoundingClientRect();
          natives.push({ path, x: r.x + window.scrollX, y: r.y + window.scrollY, width: r.width, height: r.height });
        }
      }
    }

    const h1El = document.querySelector("h1");
    const h1cs = h1El ? getComputedStyle(h1El) : null;

    // Status words and icons (P-03).
    const statuses: Facts["statuses"] = Array.from(document.querySelectorAll("[data-sync-status]"))
      .filter(visible)
      .map((el) => {
        const word = el.querySelector(".ops-sync-status__word");
        const svg = el.querySelector("svg");
        const pathEl = svg?.querySelector("path") ?? null;
        return {
          status: el.getAttribute("data-sync-status") ?? "",
          word: word ? canon(getComputedStyle(word).color) : "",
          icon: svg ? canon(getComputedStyle(svg).color) : "",
          iconHeight: svg ? svg.getBoundingClientRect().height : 0,
          shape: svg?.getAttribute("data-shape") ?? null,
          ariaHidden: svg?.getAttribute("aria-hidden") ?? null,
          pathFill: pathEl?.getAttribute("fill") ?? svg?.getAttribute("fill") ?? null,
          path: pathOf(el)
        };
      });

    // Selection Signature (P-07): the line, and the layout with the selection removed.
    const signature: Facts["signature"] = [];
    const unselect = (el: Element): (() => void) => {
      const saved = new Map<string, string | null>();
      for (const attr of ["class", "aria-pressed", "data-theme-selected", "aria-current"]) {
        saved.set(attr, el.getAttribute(attr));
      }
      const classes = (el.getAttribute("class") ?? "")
        .split(/\s+/)
        .filter(
          (c) =>
            ![
              "ops-nav-item-active",
              "ops-saved-search-row--loaded",
              "ops-object-item-active",
              "ops-filter-chip--selected",
              "is-active"
            ].includes(c)
        );
      el.setAttribute("class", classes.join(" "));
      if (el.hasAttribute("aria-pressed")) el.setAttribute("aria-pressed", "false");
      el.removeAttribute("data-theme-selected");
      el.removeAttribute("aria-current");
      return () => {
        saved.forEach((value, attr) => {
          if (value === null) el.removeAttribute(attr);
          else el.setAttribute(attr, value);
        });
      };
    };
    const rectOf = (el: Element): number[] => {
      const r = el.getBoundingClientRect();
      return [r.x, r.y, r.width, r.height].map((v) => Math.round(v * 100) / 100);
    };
    for (const el of Array.from(document.querySelectorAll(SIGNATURE.join(","))).filter(visible)) {
      const cs = getComputedStyle(el);
      const rect = rectOf(el);
      let rectUnselected: number[] | null = null;
      let widthUnselected: number | null = null;
      // A checked schema option cannot be unselected without changing the form, so only its line is read.
      if (!el.matches(".ops-schema-picker__option")) {
        const restore = unselect(el);
        rectUnselected = rectOf(el);
        widthUnselected = parseFloat(getComputedStyle(el).borderInlineStartWidth);
        restore();
      }
      signature.push({
        path: pathOf(el),
        width: parseFloat(cs.borderInlineStartWidth),
        style: cs.borderInlineStartStyle,
        color: canon(cs.borderInlineStartColor),
        rect,
        rectUnselected,
        widthUnselected,
        textColor: canon(cs.color),
        weight: cs.fontWeight,
        bg: canon(cs.backgroundColor)
      });
    }

    // Lockups (P-11).
    const lockups: Facts["lockups"] = { visible: [], marks: [] };
    for (const mark of Array.from(document.querySelectorAll(".ops-wordmark"))) {
      const rect = mark.getBoundingClientRect();
      lockups.marks.push({
        visible: rect.width > 0 && getComputedStyle(mark).display !== "none",
        flexShrink: getComputedStyle(mark).flexShrink
      });
    }
    for (const img of Array.from(document.querySelectorAll(".ops-wordmark img"))) {
      const rect = img.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0 && getComputedStyle(img).display !== "none") {
        lockups.visible.push({ src: img.getAttribute("src") ?? "", width: rect.width, height: rect.height });
      }
    }

    return {
      effective,
      tokens: tk,
      lightPlum: lightTokens.primary,
      fontGroups: Array.from(fontGroups.values()),
      h1: h1cs
        ? {
            family: h1cs.fontFamily,
            size: parseFloat(h1cs.fontSize),
            weight: Number(h1cs.fontWeight),
            lineHeight: parseFloat(h1cs.lineHeight)
          }
        : null,
      monoMisses,
      bricolage,
      statuses,
      primaryButtons,
      defaultButtons,
      hits,
      plumTextOnNight,
      rowActions,
      proseLinks,
      signature,
      controls,
      natives,
      lockups
    };
  };

  // An open overlay (palette, drawer, sheet or modal): its surface, its text pairs, its Plum
  // buttons, and its active item beside an inactive sibling (P-07, P-16).
  const describeItem = (el: Element): ItemFacts => {
    const cs = getComputedStyle(el);
    const name = el.querySelector(".ops-saved-search-row__name");
    return {
      path: pathOf(el),
      bg: canon(cs.backgroundColor),
      color: canon(cs.color),
      weight: cs.fontWeight,
      startWidth: parseFloat(cs.borderInlineStartWidth),
      startStyle: cs.borderInlineStartStyle,
      startColor: canon(cs.borderInlineStartColor),
      suffix: name ? getComputedStyle(name, "::after").content : null
    };
  };

  const overlayFacts = (rootSelector: string, itemSelector: string, activeSelector: string): OverlayFacts | null => {
    const root = document.querySelector(rootSelector);
    if (!root || !visible(root)) return null;
    const cs = getComputedStyle(root);
    const edges = sideKey.map((side, i) => ({
      side,
      width: parseFloat([cs.borderTopWidth, cs.borderRightWidth, cs.borderBottomWidth, cs.borderLeftWidth][i]),
      style: [cs.borderTopStyle, cs.borderRightStyle, cs.borderBottomStyle, cs.borderLeftStyle][i],
      color: canon([cs.borderTopColor, cs.borderRightColor, cs.borderBottomColor, cs.borderLeftColor][i])
    }));
    const surface = parse(cs.backgroundColor);
    const surfaceRgb = backdrop(root, true);
    const pairs: OverlayFacts["lowPairs"] = [];
    let minRatio = Infinity;
    let checked = 0;
    for (const el of Array.from(root.querySelectorAll("*")).filter(visible)) {
      if (!hasOwnText(el)) continue;
      if (el.closest(":disabled, [aria-disabled='true']")) continue;
      const fg = parse(getComputedStyle(el).color);
      const behind = backdrop(el, true);
      const r = ratio(over(fg, behind), behind);
      checked += 1;
      minRatio = Math.min(minRatio, r);
      if (r < 4.5) pairs.push({ path: pathOf(el), ratio: r });
    }
    const controlEdge = tokens().controlEdge;
    const edgeRgba = parse(controlEdge);
    const active = root.querySelector(activeSelector);
    const inactive = Array.from(root.querySelectorAll(itemSelector)).find((e) => !e.matches(activeSelector) && visible(e));
    return {
      bg: canon(cs.backgroundColor),
      surfaceAlpha: surface[3],
      edges,
      edgeRatio: ratio(edgeRgba, surfaceRgb),
      boxShadow: cs.boxShadow,
      pairsChecked: checked,
      minRatio: Number.isFinite(minRatio) ? minRatio : null,
      lowPairs: pairs,
      primaryButtons: Array.from(root.querySelectorAll(".btn-primary")).filter(visible).length,
      active: active && visible(active) ? describeItem(active) : null,
      inactive: inactive ? describeItem(inactive) : null
    };
  };

  (window as unknown as { __p187: P187Api }).__p187 = { collect, tokens, overlayFacts };
}

// Let every finite transition and animation finish first, so a color read mid-transition (the
// 80 ms selection fade after load) is never mistaken for a resting value. Looping animations are
// not awaited: P-12 proves there are none.
const settle = (page: Page): Promise<void> =>
  page.evaluate(async () => {
    await Promise.all(
      document
        .getAnimations()
        .filter((animation) => animation.effect?.getComputedTiming().iterations !== Infinity)
        .map((animation) => animation.finished.catch(() => undefined))
    );
  });

async function collectFacts(page: Page): Promise<Facts> {
  await settle(page);
  return page.evaluate(() => (window as unknown as { __p187: P187Api }).__p187.collect());
}

// A native checkbox or radio has no computed border: the browser draws its edge. Read the drawn
// edge from pixels, as the strongest contrast between the background beside the box and the
// pixels across the middle row of its left edge.
async function measureNatives(page: Page, facts: Facts): Promise<void> {
  const luminance = (r: number, g: number, b: number): number => {
    const f = (v: number): number => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  for (const n of facts.natives) {
    const clip = { x: Math.max(0, n.x - 3), y: Math.max(0, n.y - 3), width: n.width + 6, height: n.height + 6 };
    const png = PNG.sync.read(await page.screenshot({ clip, fullPage: true }));
    const row = Math.floor(png.height / 2);
    const at = (x: number): number => {
      const i = (row * png.width + x) * 4;
      return luminance(png.data[i], png.data[i + 1], png.data[i + 2]);
    };
    const background = at(0);
    let best = 1;
    for (let x = 1; x < Math.min(png.width, 9); x += 1) {
      const l = at(x);
      best = Math.max(best, (Math.max(l, background) + 0.05) / (Math.min(l, background) + 0.05));
    }
    n.edgeRatio = best;
  }
}

// ---------------------------------------------------------------------------------------------
// Page and snapshot helpers
// ---------------------------------------------------------------------------------------------

type ContextOptions = { forcedColors?: "active"; viewport?: { width: number; height: number } };

async function newThemedPage(
  browser: Browser,
  mode: ThemeMode,
  viewport: ViewportName | { width: number; height: number },
  options: ContextOptions = {}
): Promise<{ page: Page; context: BrowserContext; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: typeof viewport === "string" ? VIEWPORTS_187[viewport] : viewport,
    colorScheme: mode.kind === "system" ? mode.colorScheme : "light",
    ...(options.forcedColors ? { forcedColors: options.forcedColors } : {})
  });
  if (mode.kind === "explicit") {
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        try {
          window.localStorage.setItem(key, value);
        } catch {
          // about:blank has no storage; the app's own document does.
        }
      },
      ["phx:theme", mode.theme]
    );
  }
  await context.addInitScript(installP187);
  const page = await context.newPage();
  return { page, context, close: () => context.close() };
}

async function gotoPath(page: Page, path: string, heading: string): Promise<void> {
  await page.goto(path);
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: heading, exact: true })).toBeVisible();
}

async function seedIncident(request: APIRequestContext): Promise<void> {
  const seed = await seedScenario(request, "incident");
  if (seed.tenant_id) {
    // The incident seed leaves the catalog synced; draining keeps the queue facts stable.
    await drainSearchQueue(request).catch(() => undefined);
  }
}

type ScreenFacts = { screen: string; facts: Facts };

const snapshotCache = new Map<string, Promise<ScreenFacts[]>>();

// Visit the six screens once for a (theme, viewport) and cache the collected facts for the file.
function screenFacts(browser: Browser, mode: ThemeMode, viewport: ViewportName): Promise<ScreenFacts[]> {
  const key = `${themeSlug(mode)}|${viewport}`;
  const cached = snapshotCache.get(key);
  if (cached) return cached;
  const run = (async (): Promise<ScreenFacts[]> => {
    const { page, close } = await newThemedPage(browser, mode, viewport);
    try {
      const out: ScreenFacts[] = [];
      for (const screen of SCREENS) {
        await gotoPath(page, screen.path, screen.heading);
        if (mode.kind === "system") await assertSystemDarkInvariants(page);
        const facts = await collectFacts(page);
        await measureNatives(page, facts);
        out.push({ screen: screen.name, facts });
      }
      await page.goto(ALL_STATUSES_PATH);
      await waitForLiveConnected(page);
      await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
      const fixtureFacts = await collectFacts(page);
      await measureNatives(page, fixtureFacts);
      out.push({ screen: "Search health (all statuses)", facts: fixtureFacts });
      return out;
    } finally {
      await close();
    }
  })();
  snapshotCache.set(key, run);
  return run;
}

// Two saved searches, created through the Save modal (a product path, not a fixture edit), so the
// Manage sheet has a loaded row and an inactive sibling, and P-19 can compare a CJK name's row
// with a Latin one. The Latin name is saved first so the CJK one is the loaded row.
const LATIN_NAME = "Reskin latin 187";
const CJK_NAME = "検索テスト";

async function runSearchOnPage(page: Page, query: string): Promise<void> {
  await gotoPath(page, "/admin/search/search", "Search");
  const input = page.getByLabel("Search text");
  await input.fill(query);
  await input.press("Enter");
  await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
}

async function overlayFactsOf(page: Page, root: string, item: string, active: string): Promise<OverlayFacts | null> {
  await settle(page);
  return page.evaluate(
    ([r, i, a]) => (window as unknown as { __p187: P187Api }).__p187.overlayFacts(r, i, a),
    [root, item, active] as const
  );
}

type StateFacts = { name: string; facts: Facts; overlay: OverlayFacts };

async function captureState(
  page: Page,
  name: string,
  root: string,
  item: string,
  active: string
): Promise<StateFacts> {
  const overlay = await overlayFactsOf(page, root, item, active);
  if (!overlay) throw new Error(`${name}: the overlay ${root} is not visible`);
  return { name, facts: await collectFacts(page), overlay };
}

const stateCache = new Map<string, Promise<StateFacts[]>>();

// The overlays a person can open: the command palette, the mobile navigation drawer (390 px
// only), the Save search modal and the Manage saved searches sheet with a loaded row.
function overlayStates(browser: Browser, mode: ThemeMode, viewport: ViewportName): Promise<StateFacts[]> {
  const key = `${themeSlug(mode)}|${viewport}`;
  const cached = stateCache.get(key);
  if (cached) return cached;
  const run = (async (): Promise<StateFacts[]> => {
    const { page, close } = await newThemedPage(browser, mode, viewport);
    try {
      const out: StateFacts[] = [];

      await gotoPath(page, SCREENS[0].path, SCREENS[0].heading);
      await page.locator(".ops-header .ops-command-hint").click();
      await expect(page.locator("#ops-cmdk")).toBeVisible();
      out.push(await captureState(page, "palette", "#ops-cmdk .ops-cmdk__panel", ".ops-cmdk__item", ".ops-cmdk__item.is-active"));
      await page.keyboard.press("Escape");
      await expect(page.locator("#ops-cmdk")).toBeHidden();

      if (viewport === "mobile") {
        await page.locator("[data-ops-nav-open]").click();
        await expect(page.locator("#ops-mobile-nav")).toBeVisible();
        out.push(
          await captureState(page, "drawer", ".ops-mobile-nav__panel", ".ops-nav-item", ".ops-nav-item[aria-current='page']")
        );
        await page.locator("[data-ops-nav-close]").last().click();
        await expect(page.locator("#ops-mobile-nav")).toBeHidden();
      }

      // A query no saved search holds, so the toolbar offers Save search.
      await runSearchOnPage(page, "contract probe");
      await page.locator("#search-save-new, #search-save-as").first().click();
      const dialog = page.getByRole("dialog", { name: /^Save (search|as)$/ });
      await expect(dialog).toBeVisible();
      out.push(await captureState(page, "save modal", ".modal-box", "button", ".never-active"));
      await dialog.getByRole("button", { name: "Cancel", exact: true }).click();
      await expect(dialog).toBeHidden();

      await page.locator("#saved-search-picker-button").click();
      await page
        .locator("#saved-search-menu .ops-saved-search-menu__item", { hasText: CJK_NAME })
        .first()
        .click();
      await expect(page.locator("#saved-search-status")).toContainText(`Loaded “${CJK_NAME}”`);
      await page.locator("#saved-search-manage-open").click();
      const sheet = page.getByRole("dialog", { name: "Manage saved searches" });
      await expect(sheet).toBeVisible();
      out.push(
        await captureState(page, "manage sheet", ".ops-sheet__panel", ".ops-saved-search-row", ".ops-saved-search-row--loaded")
      );
      return out;
    } finally {
      await close();
    }
  })();
  stateCache.set(key, run);
  return run;
}

// Every collected page: the six screens, the all-statuses fixture and the four overlay states.
async function allFacts(browser: Browser, mode: ThemeMode, viewport: ViewportName): Promise<ScreenFacts[]> {
  const screens = await screenFacts(browser, mode, viewport);
  const states = await overlayStates(browser, mode, viewport);
  return [...screens, ...states.map((state) => ({ screen: `state: ${state.name}`, facts: state.facts }))];
}

// Group a list of strings (selector paths and the like) into "text (xN)" lines for failure output.
function grouped(lines: string[]): string[] {
  const counts = new Map<string, number>();
  for (const line of lines) counts.set(line, (counts.get(line) ?? 0) + 1);
  return Array.from(counts, ([line, n]) => (n > 1 ? `${line} (x${n})` : line));
}

const approx = (a: number, b: number, tolerance = 0.5): boolean => Math.abs(a - b) <= tolerance;

// ---------------------------------------------------------------------------------------------
// The contract
// ---------------------------------------------------------------------------------------------

test.describe("ops re-skin contract", () => {
  test.describe.configure({ timeout: 300_000 });

  test.beforeAll(async ({ request, browser }) => {
    test.setTimeout(240_000);
    await seedIncident(request);
    await deleteSavedSearches(request, { names: [LATIN_NAME, CJK_NAME] });
    // Create both saved searches through the Save modal (the CJK one last, so it is the loaded row).
    const { page, close } = await newThemedPage(browser, { kind: "explicit", theme: "light" }, "desktop");
    try {
      // A fresh page per save: after a save the toolbar offers no Save button until the inputs change.
      await runSearchOnPage(page, "quantum");
      await saveCurrentSearch(page, LATIN_NAME);
      await runSearchOnPage(page, "cyberphone");
      await saveCurrentSearch(page, CJK_NAME);
    } finally {
      await close();
    }
  });

  test.afterAll(async ({ request }) => {
    await deleteSavedSearches(request, { names: [LATIN_NAME, CJK_NAME] });
  });

  // P-01 -----------------------------------------------------------------------------------
  for (const viewport of VIEWPORT_NAMES) {
    test(`[P-01] the six settled OS and preference combinations resolve to the effective theme (${viewport})`, async ({
      browser
    }) => {
      const problems: string[] = [];
      const seenPrimary = new Map<string, string>();
      for (const os of ["light", "dark"] as const) {
        for (const stored of ["light", "dark", "system"] as const) {
          const label = `OS ${os}, stored ${stored}`;
          const expected = stored === "system" ? os : stored;
          const context = await browser.newContext({
            viewport: VIEWPORTS_187[viewport],
            colorScheme: os
          });
          if (stored !== "system") {
            await context.addInitScript(
              ([key, value]: [string, string]) => {
                try {
                  window.localStorage.setItem(key, value);
                } catch {
                  // about:blank has no storage; the app's own document does.
                }
              },
              ["phx:theme", stored]
            );
          }
          await context.addInitScript(installP187);
          const page = await context.newPage();
          try {
            await gotoPath(page, SCREENS[0].path, SCREENS[0].heading);
            const result = await page.evaluate(() => {
              const w = window as unknown as { __p187: P187Api };
              const html = document.documentElement;
              const main = document.querySelector("#ops-main") as HTMLElement;
              const probe = document.createElement("div");
              probe.style.cssText = "position:absolute;left:-9999px;color:var(--color-base-content)";
              document.body.appendChild(probe);
              const ink = getComputedStyle(probe).color;
              probe.remove();
              return {
                attr: html.getAttribute("data-theme"),
                effective: html.getAttribute("data-theme-effective"),
                page: w.__p187.tokens(),
                light: w.__p187.tokens("light"),
                dark: w.__p187.tokens("dark"),
                bodyBg: getComputedStyle(document.body).backgroundColor,
                mainColor: getComputedStyle(main).color,
                ink
              };
            });
            const want = expected === "light" ? result.light : result.dark;
            const canonOf = async (css: string): Promise<string> =>
              page.evaluate((c) => {
                const p = document.createElement("div");
                p.style.cssText = `position:absolute;left:-9999px;background-color:${c}`;
                document.body.appendChild(p);
                const v = getComputedStyle(p).backgroundColor;
                p.remove();
                return v;
              }, css);
            if (result.effective !== expected) problems.push(`${label}: data-theme-effective is ${result.effective}, want ${expected}`);
            if (stored === "system" ? result.attr !== null : result.attr !== stored)
              problems.push(`${label}: data-theme is ${result.attr}, want ${stored === "system" ? "absent" : stored}`);
            for (const key of ["primary", "base200", "baseContent"] as const) {
              if (result.page[key] !== want[key])
                problems.push(`${label}: ${key} is ${result.page[key]}, want ${want[key]} (the ${expected} theme)`);
            }
            if ((await canonOf(result.bodyBg)) !== (await canonOf(want.base200)))
              problems.push(`${label}: page color is ${result.bodyBg}, want ${want.base200}`);
            if ((await canonOf(result.mainColor)) !== (await canonOf(want.baseContent)))
              problems.push(`${label}: text color is ${result.mainColor}, want ${want.baseContent}`);
            seenPrimary.set(expected, want.primary);
            // The two themes must differ, or the comparison above proves nothing.
            if (result.light.primary === result.dark.primary) problems.push(`${label}: light and dark primary are identical`);
          } finally {
            await context.close();
          }
        }
      }
      expect(problems, "theme roles").toEqual([]);
      expect(seenPrimary.size, "both themes were observed as the effective theme").toBe(2);
    });
  }

  // P-02 -----------------------------------------------------------------------------------
  test("[P-02] type: Hanken h1, mono identities, 12 px floor, allowed weights, no capitals", async ({ browser }) => {
    const problems: string[] = [];
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        const where = `${screen} (${slug})`;
        if (facts.fontGroups.length === 0) problems.push(`${where}: no text was collected`);
        const h1 = facts.h1;
        if (!h1) {
          problems.push(`${where}: no h1`);
        } else {
          if (!h1.family.trimStart().startsWith('"Hanken Grotesk"')) problems.push(`${where}: h1 family is ${h1.family}`);
          if (h1.size !== 28) problems.push(`${where}: h1 size is ${h1.size}`);
          if (h1.weight !== 700) problems.push(`${where}: h1 weight is ${h1.weight}`);
          if (!approx(h1.lineHeight, 33.6, 0.05)) problems.push(`${where}: h1 line height is ${h1.lineHeight}`);
        }
        for (const path of facts.bricolage) problems.push(`${where}: Bricolage on ${path}`);
        for (const miss of facts.monoMisses) problems.push(`${where}: not Sometype Mono: ${miss}`);
        for (const g of facts.fontGroups) {
          const label = `${where}: ${g.path} (${g.family} ${g.size}px ${g.weight}${g.count > 1 ? `, x${g.count}` : ""})`;
          if (g.size < 12) problems.push(`${label} is under the 12px floor`);
          if (g.transform === "uppercase") problems.push(`${label} computes text-transform uppercase`);
          if (g.family === "Hanken Grotesk" && ![400, 600, 700].includes(g.weight))
            problems.push(`${label} has a Hanken weight outside 400, 600, 700`);
          if (g.family === "Sometype Mono" && ![400, 500].includes(g.weight))
            problems.push(`${label} has a mono weight outside 400, 500`);
        }
      }
    }
    expect(grouped(problems), "computed type").toEqual([]);
  });

  // P-03 -----------------------------------------------------------------------------------
  test("[P-03] status words and icons take the resolved status color; icons are 16px tall", async ({ browser }) => {
    const problems: string[] = [];
    const seen = new Set<string>();
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        for (const s of facts.statuses) {
          seen.add(s.status);
          const expected = facts.tokens[s.status];
          const where = `${screen} (${slug}): ${s.path} [${s.status}]`;
          if (!expected) problems.push(`${where}: unknown status`);
          if (s.word !== expected) problems.push(`${where}: word is ${s.word}, want ${expected}`);
          if (s.icon !== expected) problems.push(`${where}: icon is ${s.icon}, want ${expected}`);
          if (!approx(s.iconHeight, 16, 0.01)) problems.push(`${where}: icon height is ${s.iconHeight}`);
        }
      }
    }
    expect(grouped(problems), "status colors").toEqual([]);
    expect(Array.from(seen).sort(), "all four statuses were rendered and checked").toEqual([
      "clear",
      "failed",
      "pending",
      "retrying"
    ]);
  });

  // P-04 and P-18 --------------------------------------------------------------------------
  test("[P-04] [P-18] Plum is a button fill, one per scope, and only on the reserved list", async ({ browser }) => {
    const problems: string[] = [];
    let primaryButtonsSeen = 0;
    let defaultButtonsSeen = 0;
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        const where = `${screen} (${slug})`;
        const live = facts.primaryButtons.filter((b) => !b.inert);
        primaryButtonsSeen += live.length;
        if (live.length > 1) problems.push(`${where}: ${live.length} Plum buttons (${live.map((b) => b.text).join(", ")})`);
        for (const b of facts.primaryButtons) {
          if (b.bg !== facts.tokens.primary) problems.push(`${where}: ${b.path} fill is ${b.bg}, want ${facts.tokens.primary}`);
          if (b.color !== facts.tokens.primaryContent)
            problems.push(`${where}: ${b.path} label is ${b.color}, want ${facts.tokens.primaryContent}`);
        }
        for (const b of facts.defaultButtons) {
          defaultButtonsSeen += 1;
          b.widths.forEach((width, i) => {
            if (width > 0 && b.edges[i] !== facts.tokens.controlEdge)
              problems.push(`${where}: ${b.path} border ${["top", "right", "bottom", "left"][i]} is ${b.edges[i]}, want ${facts.tokens.controlEdge}`);
          });
        }
        for (const hit of facts.hits) {
          if (!hit.allowed) problems.push(`${where}: ${hit.color} ${hit.kind} on ${hit.path} is not on the reserved list`);
        }
        for (const path of facts.plumTextOnNight) problems.push(`${where}: Plum text on Night: ${path}`);
      }
    }
    expect(grouped(problems), "Plum scope and reserved colors").toEqual([]);
    expect(primaryButtonsSeen, "Plum buttons were rendered and checked").toBeGreaterThan(0);
    expect(defaultButtonsSeen, "default buttons were rendered and checked").toBeGreaterThan(0);
  });

  test("[P-04] each open overlay is its own Plum scope: the Save modal has exactly one, the others none", async ({
    browser
  }) => {
    const problems: string[] = [];
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const state of await overlayStates(browser, mode, viewport)) {
        const want = state.name === "save modal" ? 1 : 0;
        if (state.overlay.primaryButtons !== want)
          problems.push(`${state.name} (${slug}): ${state.overlay.primaryButtons} Plum buttons inside, want ${want}`);
      }
    }
    expect(problems, "Plum buttons per overlay").toEqual([]);
  });

  for (const viewport of VIEWPORT_NAMES) {
    for (const mode of THEME_MODES.slice(0, 2)) {
      test(`[P-04] the Plum button underlines its label on hover and keeps its fill (${themeSlug(mode)}, ${viewport})`, async ({
        browser
      }) => {
        const { page, close } = await newThemedPage(browser, mode, viewport);
        try {
          await gotoPath(page, SCREENS[0].path, SCREENS[0].heading);
          const button = page.locator(".btn-primary:visible").first();
          await expect(button).toBeVisible();
          const read = (): Promise<{ bg: string; decoration: string }> =>
            button.evaluate((el) => {
              const cs = getComputedStyle(el);
              return { bg: cs.backgroundColor, decoration: cs.textDecorationLine };
            });
          await page.mouse.move(0, 0);
          const rest = await read();
          await button.hover();
          await expect.poll(async () => (await read()).decoration).toContain("underline");
          const hover = await read();
          expect(hover.bg, "hover keeps the fill").toBe(rest.bg);
        } finally {
          await close();
        }
      });
    }
  }

  // P-05 and P-06 --------------------------------------------------------------------------
  test("[P-05] [P-06] row actions share one tuple; prose links are underlined Plum", async ({ browser }) => {
    const problems: string[] = [];
    let actions = 0;
    let links = 0;
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      const tuples = new Map<string, string[]>();
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        const where = `${screen} (${slug})`;
        for (const a of facts.rowActions) {
          actions += 1;
          tuples.set(a.tuple, [...(tuples.get(a.tuple) ?? []), `${screen}: ${a.text}`]);
          if (a.height < 24) problems.push(`${where}: ${a.path} is ${a.height}px tall, under 24px`);
          if (!a.tuple.includes("underline")) problems.push(`${where}: ${a.path} is not underlined at rest`);
        }
        for (const l of facts.proseLinks) {
          links += 1;
          if (!l.decoration.includes("underline")) problems.push(`${where}: link ${l.path} is not underlined at rest`);
          if (l.color !== facts.tokens.primary) problems.push(`${where}: link ${l.path} is ${l.color}, want ${facts.tokens.primary}`);
        }
      }
      if (tuples.size > 1) {
        problems.push(
          `${slug}: ${tuples.size} different row-action tuples: ${Array.from(tuples, ([t, who]) => `[${t}] ${who.slice(0, 3).join("; ")}`).join(" || ")}`
        );
      }
    }
    expect(grouped(problems), "row actions and links").toEqual([]);
    expect(actions, "row actions were rendered and checked").toBeGreaterThan(0);
    expect(links, "prose links were rendered and checked").toBeGreaterThan(0);
  });

  // P-07 -----------------------------------------------------------------------------------
  test("[P-07] the Selection Signature is a 2px solid primary start line that never moves layout", async ({
    browser
  }) => {
    const problems: string[] = [];
    const kinds = new Set<string>();
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        const where = `${screen} (${slug})`;
        for (const el of facts.signature) {
          kinds.add(el.path.split(" > ").pop()?.split(".")[1] ?? el.path);
          if (el.width !== 2) problems.push(`${where}: ${el.path} start border is ${el.width}px`);
          if (el.style !== "solid") problems.push(`${where}: ${el.path} start border is ${el.style}`);
          if (el.color !== facts.tokens.primary)
            problems.push(`${where}: ${el.path} start border is ${el.color}, want ${facts.tokens.primary}`);
          if (el.rectUnselected && !el.rect.every((v, i) => approx(v, el.rectUnselected![i], 0.5)))
            problems.push(`${where}: ${el.path} moves when selected: ${el.rectUnselected} -> ${el.rect}`);
          if (el.widthUnselected !== null && el.widthUnselected !== 2)
            problems.push(`${where}: ${el.path} does not reserve the 2px start edge at rest (${el.widthUnselected}px)`);
        }
        // The header's theme toggle always has one pressed button.
        if (!screen.startsWith("state:") && !facts.signature.some((e) => e.path.includes("ops-theme-toggle__button")))
          problems.push(`${where}: no selected theme toggle button was found`);
        // The sidebar shows the current page from 1280 px up.
        if (viewport === "desktop" && !screen.startsWith("state:") && !screen.includes("all statuses")) {
          if (!facts.signature.some((e) => e.path.includes("ops-nav-item")))
            problems.push(`${where}: no current nav item was found`);
        }
      }
    }
    expect(grouped(problems), "Selection Signature").toEqual([]);
    expect(kinds.size, "several kinds of selected element were rendered and checked").toBeGreaterThan(2);
  });

  test("[P-07] on an overlay the active item differs from the surface and from an inactive sibling", async ({
    browser
  }) => {
    const problems: string[] = [];
    const seen = new Set<string>();
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const state of await overlayStates(browser, mode, viewport)) {
        if (!["palette", "drawer", "manage sheet"].includes(state.name)) continue;
        seen.add(state.name);
        const where = `${state.name} (${slug})`;
        const { overlay } = state;
        const { active, inactive } = overlay;
        if (!active) {
          problems.push(`${where}: no active item`);
          continue;
        }
        if (!inactive) {
          problems.push(`${where}: no inactive sibling to compare with`);
          continue;
        }
        if (active.startWidth !== 2 || active.startStyle !== "solid" || active.startColor !== state.facts.tokens.primary)
          problems.push(`${where}: active line is ${active.startWidth}px ${active.startStyle} ${active.startColor}`);
        if (active.bg === overlay.bg) problems.push(`${where}: active fill ${active.bg} equals the overlay surface`);
        if (active.bg === inactive.bg) problems.push(`${where}: active fill equals the inactive sibling's`);
        // The palette and the drawer change the text; the sheet's loaded row keeps Ink (LD-14) and
        // is told apart by its fill and its "loaded" marker.
        const textDiffers =
          active.color !== inactive.color || active.weight !== inactive.weight || active.suffix !== inactive.suffix;
        if (!textDiffers) problems.push(`${where}: active and inactive items have the same text color, weight and marker`);
        if (state.name !== "manage sheet" && active.color === inactive.color && active.weight === inactive.weight)
          problems.push(`${where}: the active ${state.name} item keeps the inactive item's text color and weight`);
      }
    }
    expect(grouped(problems), "overlay selection").toEqual([]);
    expect(Array.from(seen).sort(), "palette, drawer and sheet were all opened and checked").toEqual([
      "drawer",
      "manage sheet",
      "palette"
    ]);
  });

  // P-08 -----------------------------------------------------------------------------------
  test("[P-08] every visible control's resting border has 3:1 against its backdrop and is opaque", async ({
    browser
  }) => {
    const problems: string[] = [];
    let controls = 0;
    let named = 0;
    let nativeEdges = 0;
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await allFacts(browser, mode, viewport)) {
        const where = `${screen} (${slug})`;
        for (const n of facts.natives) {
          if (n.edgeRatio === undefined) continue; // overlay states are not pixel-measured
          nativeEdges += 1;
          if (n.edgeRatio < 3) problems.push(`${where}: ${n.path} native edge is ${n.edgeRatio.toFixed(2)}:1`);
        }
        for (const c of facts.controls) {
          controls += 1;
          if (c.focused || c.native) continue; // a focused control shows focus; native edges are read from pixels
          for (const side of c.sides) {
            if (side.alpha === 0) continue; // a transparent side is not drawn (a reserved start edge)
            if (side.alpha < 0.999) problems.push(`${where}: ${c.path} ${side.side} border is translucent (${side.color})`);
            // The Plum button's border sits on its own Plum fill; its edge is read against the page.
            if (!c.plum && side.ratioInside < 3)
              problems.push(`${where}: ${c.path} ${side.side} border ${side.color} is ${side.ratioInside.toFixed(2)}:1 inside`);
            if (side.ratioOutside < 3)
              problems.push(`${where}: ${c.path} ${side.side} border ${side.color} is ${side.ratioOutside.toFixed(2)}:1 outside`);
          }
          if (c.named) {
            named += 1;
            const drawn = c.sides.filter((side) => side.alpha > 0);
            if (drawn.length === 0) problems.push(`${where}: ${c.path} is a named control with no drawn border`);
            for (const side of drawn) {
              const isEdge = side.color === facts.tokens.controlEdge;
              const isSelection = side.side === "left" && side.color === facts.tokens.primary;
              const isPlumButton = side.color === facts.tokens.primary && c.path.includes("btn-primary");
              if (!isEdge && !isSelection && !isPlumButton)
                problems.push(`${where}: ${c.path} ${side.side} border is ${side.color}, want Control Edge ${facts.tokens.controlEdge}`);
            }
          }
        }
      }
    }
    expect(grouped(problems), "control edges").toEqual([]);
    expect(controls, "controls were rendered and checked").toBeGreaterThan(20);
    expect(named, "named controls were rendered and checked").toBeGreaterThan(10);
    expect(nativeEdges, "unchecked native checkboxes and radios were rendered and measured").toBeGreaterThan(0);
  });

  // P-11 -----------------------------------------------------------------------------------
  const lockupProblems = (where: string, theme: "light" | "dark", facts: Facts, problems: string[]): void => {
    const want = theme === "dark" ? "scrypath-wordmark-inverse.svg" : "scrypath-wordmark.svg";
    const { visible, marks } = facts.lockups;
    if (visible.length !== 1) {
      problems.push(`${where}: ${visible.length} lockups display, want exactly 1 (${visible.map((v) => v.src).join(", ")})`);
      return;
    }
    const [lockup] = visible;
    if (!lockup.src.endsWith(`/images/${want}`)) problems.push(`${where}: lockup src is ${lockup.src}, want ...${want}`);
    if (lockup.width < 136 - 0.01) problems.push(`${where}: lockup is ${lockup.width}px wide, under 136`);
    if (lockup.height < 28.8 - 0.05) problems.push(`${where}: lockup is ${lockup.height}px tall, under 28.8`);
    if (lockup.width < 112 || lockup.height < 24) problems.push(`${where}: lockup is under the book's 112 x 24 floor`);
    for (const mark of marks.filter((m) => m.visible)) {
      if (mark.flexShrink !== "0") problems.push(`${where}: a visible lockup has flex-shrink ${mark.flexShrink}`);
    }
  };

  test("[P-11] exactly one lockup per theme, the matching file, at least 136 x 28.8 and never shrunk", async ({
    browser
  }) => {
    const problems: string[] = [];
    for (const { mode, viewport, slug } of MODE_VIEWPORTS) {
      for (const { screen, facts } of await screenFacts(browser, mode, viewport)) {
        lockupProblems(`${screen} (${slug})`, effectiveTheme(mode), facts, problems);
      }
    }
    for (const theme of ["light", "dark"] as const) {
      for (const width of [320, 390, 768, 1280]) {
        const { page, close } = await newThemedPage(browser, { kind: "explicit", theme }, { width, height: 800 });
        try {
          await gotoPath(page, SCREENS[0].path, SCREENS[0].heading);
          lockupProblems(`Control Room (${theme}, ${width}px)`, theme, await collectFacts(page), problems);
        } finally {
          await close();
        }
      }
    }
    expect(grouped(problems), "lockup").toEqual([]);
  });

  // P-13 -----------------------------------------------------------------------------------
  test("[P-13] under forced colors the selection line, the focus outline and the status icons stay visible", async ({
    browser
  }) => {
    const { page, close } = await newThemedPage(
      browser,
      { kind: "explicit", theme: "light" },
      "desktop",
      { forcedColors: "active" }
    );
    try {
      await page.goto(ALL_STATUSES_PATH);
      await waitForLiveConnected(page);
      await expect(page.getByRole("heading", { name: "Search health", exact: true })).toBeVisible();
      expect(await page.evaluate(() => matchMedia("(forced-colors: active)").matches), "forced colors are active").toBe(true);

      const result = await page.evaluate(() => {
        const rgbaAlpha = (css: string): number => {
          if (css === "transparent") return 0;
          const comma = css.match(/^rgba\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*,\s*([\d.]+)\s*\)$/);
          if (comma) return Number(comma[1]);
          const slash = css.match(/\/\s*([\d.]+%?)\s*\)$/);
          if (slash) return slash[1].endsWith("%") ? parseFloat(slash[1]) / 100 : Number(slash[1]);
          return 1;
        };
        const selected = Array.from(
          document.querySelectorAll(
            ".ops-nav-item[aria-current='page'], .ops-theme-toggle__button[aria-pressed='true']"
          )
        )
          .filter((el) => el.getBoundingClientRect().width > 0)
          .map((el) => {
            const cs = getComputedStyle(el);
            return {
              name: `${el.tagName.toLowerCase()}.${el.className}`.slice(0, 80),
              width: parseFloat(cs.borderInlineStartWidth),
              style: cs.borderInlineStartStyle,
              alpha: rgbaAlpha(cs.borderInlineStartColor)
            };
          });

        const target = document.querySelector<HTMLElement>("#ops-main a[href], #ops-main button");
        target?.focus({ focusVisible: true } as FocusOptions);
        const fcs = target ? getComputedStyle(target) : null;
        const focus = fcs
          ? {
              name: `${target?.tagName.toLowerCase()}.${target?.className}`.slice(0, 80),
              style: fcs.outlineStyle,
              width: parseFloat(fcs.outlineWidth),
              alpha: rgbaAlpha(fcs.outlineColor)
            }
          : null;

        const icons = Array.from(document.querySelectorAll("[data-sync-status] svg[data-shape]")).map((svg) => {
          const path = svg.querySelector("path");
          const svgColor = getComputedStyle(svg).color;
          return {
            shape: svg.getAttribute("data-shape"),
            attr: path?.getAttribute("fill") ?? svg.getAttribute("fill"),
            computedFill: path ? getComputedStyle(path).fill : "",
            svgColor
          };
        });
        return { selected, focus, icons };
      });

      expect(result.selected.length, "selected elements were found").toBeGreaterThanOrEqual(2);
      for (const el of result.selected) {
        expect(el.width, `${el.name} keeps its 2px start line`).toBe(2);
        expect(el.style, `${el.name} keeps a solid start line`).toBe("solid");
        expect(el.alpha, `${el.name} start line is not transparent`).toBeGreaterThan(0);
      }
      expect(result.focus, "an element took focus").not.toBeNull();
      expect(result.focus?.style, "focus outline style").not.toBe("none");
      expect(result.focus?.width, "focus outline width").toBeGreaterThanOrEqual(2);
      expect(result.focus?.alpha, "focus outline is not transparent").toBeGreaterThan(0);

      expect(new Set(result.icons.map((i) => i.shape)), "all four status shapes render").toEqual(
        new Set(["filled", "hollow", "bottom-filled", "notched"])
      );
      for (const icon of result.icons) {
        expect(icon.attr, `${icon.shape} icon paints with currentColor`).toBe("currentColor");
        expect(icon.computedFill, `${icon.shape} icon fill follows the text color`).toBe(icon.svgColor);
      }
    } finally {
      await close();
    }
  });
});
