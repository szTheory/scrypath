/**
 * Use AxeBuilder's legacy frame scanner only after confirming a frame-free page.
 * The callback receives `true` only for that guarded legacy attempt; it must
 * otherwise use the normal AxeBuilder path.
 *
 * The legacy API is a documented, deprecated escape hatch. This wrapper limits
 * it to pages that have exactly their main frame and no iframe/frame elements.
 * It watches frame changes from before that check through the complete scan so
 * a result collected across a frame transition is discarded and recollected by
 * AxeBuilder's normal cross-frame path.
 * @template Result
 * @param {import("@playwright/test").Page} page
 * @param {(legacyMode: boolean) => Promise<Result>} scan
 * @returns {Promise<Result>}
 */
export async function scanWithFrameSafeLegacy(page, scan) {
  if (typeof scan !== "function") throw new TypeError("scan must be a function");

  // If this Playwright page does not expose the full frame lifecycle API, use
  // the ordinary AxeBuilder mode without trying to infer frame safety.
  if (
    !page ||
    typeof page.on !== "function" ||
    typeof page.off !== "function" ||
    typeof page.frames !== "function" ||
    typeof page.mainFrame !== "function" ||
    typeof page.locator !== "function"
  ) {
    return scan(false);
  }

  let frameChanged = false;
  const noteFrameChange = () => { frameChanged = true; };
  try {
    page.on("frameattached", noteFrameChange);
    page.on("framedetached", noteFrameChange);
  } catch {
    // Partial event support is not enough to prove the page stayed frame-free.
    page.off("frameattached", noteFrameChange);
    page.off("framedetached", noteFrameChange);
    return scan(false);
  }

  try {
    let frameFree = false;
    try {
      // The listeners are already live before either view of the frame tree is
      // inspected. The DOM check catches a present iframe before Playwright has
      // emitted its corresponding attachment event.
      const mainFrame = page.mainFrame();
      const frames = page.frames();
      const iframeCount = await page.locator("iframe, frame").count();
      frameFree =
        !frameChanged &&
        frames.length === 1 &&
        frames[0] === mainFrame &&
        iframeCount === 0;
    } catch {
      // A failed capability/preflight check selects the normal robust scanner.
      frameFree = false;
    }

    if (!frameFree) return await scan(false);

    let legacyResult;
    let legacyFailed = false;
    try {
      legacyResult = await scan(true);
    } catch (error) {
      legacyFailed = true;
      // The modern scan is the authoritative complete path. Keep the legacy
      // failure visible for diagnosis, then discard any partial caller result.
      console.warn("Axe legacy scan failed; retrying with the modern frame scanner", error);
    }

    // Any event during the legacy attempt invalidates its result. Likewise, a
    // legacy exception may be specific to that path, so rerun the full caller
    // operation once in modern mode even if no frame event was observed.
    if (legacyFailed || frameChanged) return await scan(false);
    return legacyResult;
  } finally {
    page.off("frameattached", noteFrameChange);
    page.off("framedetached", noteFrameChange);
  }
}
