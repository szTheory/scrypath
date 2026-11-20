// WCAG 2.x contrast math for the website checks.
//
// toLinear, relativeLuminance and contrastRatioRaw are COPIED, not imported (D-32), from
// examples/scrypath_ecommerce/contrast-checker.mjs lines 60 to 80, so website/ keeps no dependency on
// another directory. The static contract asserts that these functions reproduce every ratio that
// brand/brand.json publishes for the pairs the site uses, so the copy cannot drift silently from the
// brand's numbers. The original file is not edited.

// sRGB channel (0 to 1) to linear (IEC 61966-2-1)
function toLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

// Hex color to relative luminance (WCAG 2.x)
export function relativeLuminance(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

// WCAG contrast ratio at full precision (no rounding): thresholds are compared on this value.
export function contrastRatioRaw(fg, bg) {
  const L1 = relativeLuminance(fg);
  const L2 = relativeLuminance(bg);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}

// The ratio rounded to two decimals, the form brand.json publishes. Display and published-value
// comparison only; never compare a threshold against this.
export function roundRatio(ratio) {
  return Math.round(ratio * 100) / 100;
}

// ---------------------------------------------------------------------------
// Computed-color parsing (D-05). Chromium serializes a computed color as rgb()/rgba() or, for
// color-mix() and other non-legacy results, as color(srgb r g b / a). Both are parsed here; any other
// form throws so a surprise serialization fails loudly instead of resolving to a wrong ratio.
// Channels are returned as 0 to 255 floats and alpha as 0 to 1.
// ---------------------------------------------------------------------------

function channelValue(token, scale) {
  const text = token.trim();
  const value = text.endsWith('%') ? (Number.parseFloat(text) / 100) * scale : Number.parseFloat(text);
  if (!Number.isFinite(value)) {
    throw new Error(`Cannot parse color channel "${token}"`);
  }
  return value;
}

function alphaValue(token) {
  if (token === undefined) {
    return 1;
  }
  const text = token.trim();
  const value = text.endsWith('%') ? Number.parseFloat(text) / 100 : Number.parseFloat(text);
  if (!Number.isFinite(value)) {
    throw new Error(`Cannot parse alpha "${token}"`);
  }
  return Math.min(1, Math.max(0, value));
}

export function parseCssColor(input) {
  const text = String(input).trim();
  const legacy = /^rgba?\(\s*([^)]*)\)$/i.exec(text);
  if (legacy) {
    const [channels, alpha] = legacy[1].split('/').map(part => part.trim());
    const parts = channels.includes(',') ? channels.split(',').map(part => part.trim()) : channels.split(/\s+/);
    const alphaPart = alpha ?? (parts.length === 4 ? parts[3] : undefined);
    if (parts.length < 3 || parts.length > 4 || (alpha !== undefined && parts.length !== 3)) {
      throw new Error(`Cannot parse color "${input}"`);
    }
    return {
      r: channelValue(parts[0], 255),
      g: channelValue(parts[1], 255),
      b: channelValue(parts[2], 255),
      a: alphaValue(alphaPart)
    };
  }
  const srgb = /^color\(\s*srgb\s+([^)]*)\)$/i.exec(text);
  if (srgb) {
    const [channels, alpha] = srgb[1].split('/').map(part => part.trim());
    const parts = channels.split(/\s+/);
    if (parts.length !== 3) {
      throw new Error(`Cannot parse color "${input}"`);
    }
    return {
      r: channelValue(parts[0], 1) * 255,
      g: channelValue(parts[1], 1) * 255,
      b: channelValue(parts[2], 1) * 255,
      a: alphaValue(alpha)
    };
  }
  throw new Error(`Unsupported computed color form "${input}" (expected rgb(), rgba() or color(srgb ...))`);
}

// "#RRGGBB" to a parsed color.
export function hexToColor(hex) {
  if (!/^#[0-9A-Fa-f]{6}$/.test(hex)) {
    throw new Error(`Not a six-digit hex color: ${hex}`);
  }
  return {
    r: parseInt(hex.slice(1, 3), 16),
    g: parseInt(hex.slice(3, 5), 16),
    b: parseInt(hex.slice(5, 7), 16),
    a: 1
  };
}

// What a screen paints: each channel rounded to 8 bits.
function quantize(color) {
  return {
    r: Math.min(255, Math.max(0, Math.round(color.r))),
    g: Math.min(255, Math.max(0, Math.round(color.g))),
    b: Math.min(255, Math.max(0, Math.round(color.b))),
    a: color.a
  };
}

// Composite a (possibly translucent) foreground over an opaque background. Result is opaque and
// rounded to 8 bits per channel, as the browser paints it.
export function compositeOver(fg, bg) {
  if (bg.a !== 1) {
    throw new Error('compositeOver needs an opaque background');
  }
  const a = fg.a;
  return quantize({
    r: fg.r * a + bg.r * (1 - a),
    g: fg.g * a + bg.g * (1 - a),
    b: fg.b * a + bg.b * (1 - a),
    a: 1
  });
}

export function toHex(color) {
  const { r, g, b } = quantize(color);
  return `#${[r, g, b].map(channel => channel.toString(16).padStart(2, '0')).join('').toUpperCase()}`;
}

// Raw contrast ratio of a parsed foreground, composited over an opaque parsed background first.
export function contrastRatio(fg, bg) {
  const surface = quantize(bg);
  return contrastRatioRaw(toHex(compositeOver(fg, surface)), toHex(surface));
}
