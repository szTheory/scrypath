import { expect, type Browser, type BrowserContext, type Locator, type Page, type TestInfo } from "@playwright/test";
import { createHash } from "node:crypto";
import { createRequire } from "node:module";
import { appendFile, mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import {
  deleteSavedSearches,
  putSavedSearch,
  seedScenario,
  waitForLiveConnected
} from "./e2e";

export const STATE_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6"] as const;
export const ACTION_ELEMENTS = ["E8", "E9", "E10"] as const;
export const STATE_CATEGORIES = ["empty", "loading", "error", "populated", "partial", "zero-one-many"] as const;
export const CONTENT_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10"] as const;
export const OVERFLOW_ELEMENTS = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E10"] as const;
export const THEMES = ["light", "dark", "system-dark"] as const;
export const REQUIRED_WIDTHS = [1440, 768, 390] as const;

type ElementId = typeof CONTENT_ELEMENTS[number];
type Category = typeof STATE_CATEGORIES[number] | "overflow" | "long-text";
type Assertion = { name: string; status: "passed"; actual: string };
type Transport = { operation: string; outcome: string };
type ImageReceipt = { path: string; sha256: string; viewport: { width: number; height: number }; capture: string };

const digest = (value: string | Buffer) => createHash("sha256").update(value).digest("hex");
const safe = (value: string) => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const targetUrl = process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002";
const artifactRoot = process.env.E2E_ARTIFACT_DIR || "";
const evidencePath = process.env.PHASE105_EVIDENCE_PATH || "";
const fixturePath = "/phase185-fixture/clock.txt";
const fonts = Object.freeze({ method: "retained-cdp-fixed-font-v1", fixed_font_family: "Liberation Mono", applied: "before-first-navigation", lifetime: "page-context" });
const packageRequire = createRequire(path.join(process.cwd(), "package.json"));
const playwrightPackageVersion = packageRequire("@playwright/test/package.json").version as string;

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).sort(([left], [right]) => left.localeCompare(right)).map(([key, item]) => [key, canonicalize(item)]));
  }
  return value;
}
export async function launchPreservationBrowser(chromium: { launch: (options: { timeout: number; args: string[] }) => Promise<Browser> }): Promise<Browser> {
  const { launchDisposableBrowser } = await import("../ui-review.mjs");
  return (await launchDisposableBrowser(chromium)).browser;
}

function routeFor(element: ElementId): string {
  switch (element) {
    case "E1": return "/";
    case "E2": return "/admin/search";
    case "E3": return "/admin/search/phase173/health?scenario=healthy";
    case "E4": return "/admin/search/failed-sync";
    case "E5": return "/admin/search/search?saved=manage";
    case "E6": return "/admin/search/sync-and-index";
    case "E7": return "/admin/search/phase173/health?scenario=long";
    case "E8": return "/admin/search/help";
    case "E9": return "/admin/search/search";
    case "E10": return "/admin/search/search?saved=manage";
  }
}

function scenarioFor(element: ElementId, category: Category): "all_green" | "degraded" | "incident" | "empty" | "e2e_search_catalog" | null {
  if (element === "E1") return category === "empty" ? "empty" : "e2e_search_catalog";
  if (element === "E2") return category === "zero-one-many" ? null : category === "empty" ? "empty" : category === "partial" || category === "error" ? "incident" : "all_green";
  if (element === "E3" || element === "E7") return null;
  if (element === "E4") return category === "zero-one-many" ? null : category === "empty" ? "empty" : category === "populated" || category === "error" ? "incident" : "all_green";
  if (element === "E5" || element === "E10") return category === "empty" ? "empty" : "all_green";
  if (element === "E6") return category === "empty" ? "empty" : category === "partial" || category === "error" ? "degraded" : "all_green";
  if (element === "E9") return "all_green";
  return null;
}

async function setTheme(context: BrowserContext, theme: typeof THEMES[number]): Promise<void> {
  await context.addInitScript((value) => {
    if (value === "system-dark") localStorage.removeItem("phx:theme");
    else localStorage.setItem("phx:theme", value);
  }, theme);
}

async function fixedClock(): Promise<{ instant: string; sha256: string }> {
  const bytes = await readFile(fixturePath);
  if (bytes.length === 0 || bytes.toString("utf8").trim() !== bytes.toString("utf8")) throw new Error("Phase185 clock fixture must be a non-empty single-line UTC instant without surrounding whitespace.");
  const instant = bytes.toString("utf8");
  if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(instant) || Number.isNaN(Date.parse(instant))) throw new Error("Phase185 clock fixture is not the pinned millisecond UTC format.");
  return { instant, sha256: `sha256:${digest(bytes)}` };
}

async function verifyFixedDateLeavesTimersRunning(page: Page, instant: string): Promise<{ fired: boolean; elapsed_ms: number; observed_date: string }> {
  const observation = await page.evaluate(async () => {
    const started = performance.now();
    const timer = await new Promise<{ elapsed_ms: number; observed_date: string }>((resolve) => {
      setTimeout(() => resolve({ elapsed_ms: performance.now() - started, observed_date: new Date().toISOString() }), 40);
    });
    return timer;
  });
  if (observation.elapsed_ms < 20 || observation.observed_date !== instant) {
    throw new Error(`Browser fixed Date/timer profile is not active: ${JSON.stringify(observation)} (expected Date ${instant} and a real timer callback).`);
  }
  return { fired: true, ...observation };
}

function themeFor(element: ElementId, category: Category): typeof THEMES[number] {
  const number = Number(element.slice(1));
  const categoryIndex = Math.max(0, STATE_CATEGORIES.indexOf(category as typeof STATE_CATEGORIES[number]));
  return THEMES[(number + categoryIndex) % THEMES.length];
}

async function assertObserved(name: string, actual: string | number | boolean, predicate: (value: string | number | boolean) => boolean): Promise<Assertion> {
  expect(predicate(actual), name).toBe(true);
  return { name, status: "passed", actual: String(actual) };
}

async function initializeData(element: ElementId, category: Category, request: Parameters<typeof seedScenario>[0]): Promise<string> {
  const scenario = scenarioFor(element, category);
  let identity = `phase185:${element}:${category}`;
  if (scenario) {
    const seed = await seedScenario(request, scenario);
    identity += `:${scenario}:${seed.tenant_id ?? "none"}:${Object.keys(seed.products).sort().join(",")}`;
  }
  if (element === "E5" || element === "E10") {
    await deleteSavedSearches(request, { prefix: "phase185-heldout-" });
    const name = `phase185-heldout-${element.toLowerCase()}-${category}`;
    const count = category === "empty" ? 0 : category === "zero-one-many" ? 3 : 1;
    for (let index = 0; index < count; index += 1) {
      await putSavedSearch(request, `${name}-${index + 1}`, { mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: index === 1 ? "quantum" : "scanner", opts: { page: { size: 10 } } });
    }
    identity += `:saved-searches:${count}:${name}`;
  }
  if (element === "E2" && category === "zero-one-many") identity += ":scenario-sequence=all_green,degraded,incident;final=incident";
  if (element === "E3" && category === "zero-one-many") identity += ":scenario-sequence=empty,healthy,partial;final=partial";
  if (element === "E4" && category === "zero-one-many") identity += ":scenario-sequence=incident;filtered-cause;unavailable-schema;final=zero-rows";
  if (element === "E6" && category === "zero-one-many") identity += ":selection-sequence=zero-selected,Product-selected,two-allowlisted";
  return identity;
}

async function assertServerClock(page: Page, instant: string, assertions: Assertion[], transport: Transport[]): Promise<void> {
  await page.clock.setFixedTime(new Date(instant));
  const response = await page.goto("/admin/search/phase173/health?scenario=healthy");
  if (!response?.ok()) throw new Error(`Clock probe navigation failed with ${response?.status() ?? "no HTTP response"}.`);
  await waitForLiveConnected(page);
  const stamp = page.locator("[data-ops-timestamp-copy]").first();
  await expect(stamp).toBeVisible();
  const serverValue = await stamp.getAttribute("data-ops-timestamp-copy");
  if (!serverValue || new Date(serverValue).toISOString() !== instant) throw new Error(`Server Clock did not render the mounted fixed instant: expected ${instant}, got ${serverValue ?? "missing"}.`);
  assertions.push({ name: "fixed server Clock matches read-only fixture", status: "passed", actual: serverValue });
  transport.push({ operation: "server-clock-liveview-refresh", outcome: `connected; status=${response.status()}; timestamp=${serverValue}` });
}

async function primaryHeading(page: Page, element: ElementId): Promise<Locator> {
  const names: Record<ElementId, RegExp> = {
    E1: /Tenant-scoped catalog search/,
    E2: /^Control Room$/,
    E3: /^Search health$/,
    E4: /^Failed sync work$/,
    E5: /^Search$/,
    E6: /^Sync and index$/,
    E7: /^Search health$/,
    E8: /^Help$/,
    E9: /^Search$/,
    E10: /^Search$/
  };
  const heading = page.getByRole("heading", { level: 1, name: names[element] });
  await expect(heading).toBeVisible();
  return heading;
}

async function enterPage(page: Page, element: ElementId, assertions: Assertion[], transport: Transport[]): Promise<Locator> {
  const response = await page.goto(routeFor(element));
  if (!response?.ok()) throw new Error(`${element} product route returned ${response?.status() ?? "no HTTP response"}.`);
  await waitForLiveConnected(page);
  transport.push({ operation: "product-route-liveview", outcome: `connected; status=${response.status()}` });
  const heading = await primaryHeading(page, element);
  const headingText = (await heading.innerText()).trim();
  assertions.push(await assertObserved(`${element} actual product heading is visible`, headingText, (value) => typeof value === "string" && value.length > 0));
  return heading;
}

async function prepareSavedManager(page: Page, element: ElementId): Promise<void> {
  if (element !== "E5" && element !== "E10") return;
  await expect(page.getByRole("dialog", { name: "Manage saved searches" })).toBeVisible();
}

async function assertEmpty(page: Page, element: ElementId, assertions: Assertion[]): Promise<Locator> {
  let locator: Locator;
  if (element === "E1") {
    await page.getByLabel("Search products").fill("phase185-no-matching-product");
    await waitForLiveConnected(page);
    locator = page.locator("[data-testid='storefront-results']");
    const text = await locator.innerText();
    assertions.push(await assertObserved("storefront keeps the real no-match next step", text, (value) => String(value).includes("No matching results yet") && String(value).includes("Adjust the query or filters")));
  } else if (element === "E2") {
    locator = page.locator("main");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Control Room empty seed retains the bounded claim and next routes", text, (value) => String(value).includes("No sync failures found") && String(value).includes("Document visibility is checked separately") && String(value).includes("View search health")));
  } else if (element === "E3") {
    const response = await page.goto("/admin/search/phase173/health?scenario=empty");
    if (!response?.ok()) throw new Error(`Search health empty fixture returned ${response?.status() ?? "no HTTP response"}.`);
    await waitForLiveConnected(page);
    locator = page.locator("main");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Search health renders the empty allowlist next step without a healthy verdict", text, (value) => String(value).includes("No search schemas configured") && String(value).includes("Configure the host application's schema allowlist to inspect search health") && !String(value).includes("Healthy")));
  } else if (element === "E4") {
    locator = page.locator("main");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Failed work names the actual empty history and where pending work is checked", text, (value) => String(value).includes("No failed or retrying sync work") && String(value).includes("Pending work and document freshness are checked on Sync and index")));
  } else if (element === "E5" || element === "E10") {
    locator = page.getByRole("dialog", { name: "Manage saved searches" });
    const rows = await page.locator(".ops-saved-search-row").count();
    assertions.push(await assertObserved("saved-search collection is actually empty", rows, (value) => value === 0));
    assertions.push(await assertObserved("saved-search empty state retains its real save or import next step", await locator.innerText(), (value) => String(value).includes("No saved searches yet") && String(value).includes("Save one from Search, or import a JSON file")));
  } else {
    const response = await page.goto("/admin/search/sync-and-index?schema=ScrypathEcommerce.Catalog.NotAllowlisted");
    if (!response?.ok()) throw new Error(`Sync settings unavailable-selection state returned ${response?.status() ?? "no HTTP response"}.`);
    await waitForLiveConnected(page);
    locator = page.getByRole("alert");
    const text = await locator.innerText();
    assertions.push(await assertObserved("sync settings explains the unavailable schema and the exact recovery action", text, (value) => String(value).includes("That schema is unavailable") && String(value).includes("Select an allowlisted schema to continue.")));
  }
  return locator;
}

async function assertPopulated(page: Page, element: ElementId, assertions: Assertion[]): Promise<Locator> {
  let locator: Locator;
  if (element === "E1") {
    await page.getByLabel("Search products").fill("quantum");
    await waitForLiveConnected(page);
    locator = page.locator("[data-testid='storefront-results']");
    const rows = await page.getByTestId("storefront-result").count();
    assertions.push(await assertObserved("storefront returns the seeded quantum products", rows, (value) => value >= 2));
  } else if (element === "E2") {
    locator = page.locator("[data-testid='control-room-verdict']");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Control Room presents a populated operational observation", text, (value) => String(value).includes("schemas") && String(value).includes("View search health")));
  } else if (element === "E3" || element === "E7") {
    locator = page.locator("[data-testid='posture-row']").first();
    const rows = await page.getByTestId("posture-row").count();
    assertions.push(await assertObserved("Search health displays real per-schema observations", rows, (value) => value > 0));
  } else if (element === "E4") {
    locator = page.getByTestId("failed-sync-row").first();
    const rows = await page.getByTestId("failed-sync-row").count();
    assertions.push(await assertObserved("failed work rows and retry eligibility are rendered from seeded jobs", rows, (value) => value > 0));
    assertions.push(await assertObserved("failed work exposes its actual retry control", await locator.getByTestId("failed-sync-retry").isVisible(), (value) => value === true));
  } else if (element === "E5" || element === "E10") {
    locator = page.getByRole("dialog", { name: "Manage saved searches" });
    const rows = await page.locator(".ops-saved-search-row").count();
    assertions.push(await assertObserved("saved-search records are loaded from the application database", rows, (value) => value > 0));
  } else if (element === "E6") {
    locator = page.locator("#index-settings-status");
    await expect(locator).toBeVisible({ timeout: 20_000 });
    const text = await locator.innerText();
    assertions.push(await assertObserved("sync settings show the completed matching backend comparison and its exact status copy", text, (value) => String(value).includes("Meilisearch settings match the schema.") && String(value).includes("Filters, sorting and facets work as declared.")));
  } else if (element === "E8") {
    locator = page.locator("#saved-searches");
    assertions.push(await assertObserved("Help content is present in its named topic", await locator.isVisible(), (value) => value === true));
  } else {
    locator = page.locator("#search-form");
    assertions.push(await assertObserved("shared Search controls retain their product form", await page.getByLabel("Search text").isVisible(), (value) => value === true));
  }
  return locator;
}

async function assertPartial(page: Page, element: ElementId, assertions: Assertion[]): Promise<Locator> {
  let locator: Locator;
  if (element === "E1") {
    await page.getByLabel("Search products").fill("quantum");
    await waitForLiveConnected(page);
    const category = page.getByRole("checkbox", { name: "Smartphones" });
    await category.check();
    await waitForLiveConnected(page);
    locator = page.locator("[data-testid='storefront-results']");
    assertions.push(await assertObserved("storefront selected-category scope stays in the route", page.url(), (value) => String(value).includes("category_id=")));
    assertions.push(await assertObserved("partial storefront results remain scoped to the selected category", await page.getByTestId("storefront-result").count(), (value) => value > 0));
  } else if (element === "E2") {
    locator = page.locator("[data-testid='control-room-affected-scope']");
    assertions.push(await assertObserved("Control Room identifies affected schema scope", await locator.isVisible(), (value) => value === true));
    const fullText = await page.locator("[data-testid='control-room-verdict']").innerText();
    assertions.push(await assertObserved("partial operational observation does not claim healthy completion", fullText, (value) => !String(value).includes("No sync failures found")));
  } else if (element === "E3" || element === "E7") {
    await page.goto("/admin/search/phase173/health?scenario=partial");
    await waitForLiveConnected(page);
    locator = page.getByTestId("posture-row").filter({ hasText: "Search health could not be checked" });
    assertions.push(await assertObserved("phase173 test source preserves both the available row and scoped failure row", await page.getByTestId("posture-row").count(), (value) => value === 2));
    assertions.push(await assertObserved("unknown backend observation stays explicitly unavailable", await locator.isVisible(), (value) => value === true));
  } else if (element === "E4") {
    locator = page.getByTestId("failed-sync-row").first();
    const baseline = await page.getByTestId("failed-sync-row").count();
    const causeFilters = page.locator("input[name='cause[]']");
    let selected = false;
    for (let index = 0; index < await causeFilters.count(); index += 1) {
      const option = causeFilters.nth(index);
      const count = Number((await option.locator("xpath=..").locator(".ops-filter-chip__count").innerText()).trim());
      if (count > 0 && count < baseline) {
        await option.check();
        selected = true;
        break;
      }
    }
    expect(selected, "an actual cause facet narrows the seeded failed-work list").toBe(true);
    await waitForLiveConnected(page);
    const narrowed = await page.getByTestId("failed-sync-row").count();
    assertions.push(await assertObserved("failed-work cause selection stays in the real filter route", page.url(), (value) => String(value).includes("cause=")));
    assertions.push(await assertObserved("filtered failed-work retains its explicit subset without broadening to all rows", `${narrowed}/${baseline}`, (value) => {
      const [visible, total] = String(value).split("/").map(Number);
      return visible > 0 && visible < total;
    }));
  } else if (element === "E5" || element === "E10") {
    locator = page.getByRole("dialog", { name: "Manage saved searches" });
    const rows = page.locator(".ops-saved-search-row");
    assertions.push(await assertObserved("saved-search list preserves a selected subset and exact names", await rows.count(), (value) => value > 0));
    assertions.push(await assertObserved("saved-search names remain visible", await rows.first().locator(".ops-saved-search-row__name").innerText(), (value) => String(value).startsWith("phase185-heldout-")));
  } else {
    locator = page.locator("#sync-schema-select");
    await expect(locator).toBeVisible();
    assertions.push(await assertObserved("settings preserves the actual selected-schema control", await locator.isVisible(), (value) => value === true));
    const choices = page.locator("#sync-schema-select input[type=radio]");
    assertions.push(await assertObserved("settings offers the configured schema allowlist as real radio choices", await choices.count(), (value) => value > 1));
    assertions.push(await assertObserved("settings has exactly one selected allowlisted schema", await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length), (value) => value === 1));
    if (element === "E6") {
      const status = page.locator("#index-settings-status");
      await expect(status).toBeVisible({ timeout: 20_000 });
      await expect(status).toContainText(/differ|mismatch|does not match|out of date/i, { timeout: 20_000 });
      const text = await status.innerText();
      assertions.push(await assertObserved("settings preserves the seeded drift comparison as an incomplete match", text, (value) => /differ|mismatch|does not match|out of date/i.test(String(value))));
    }
  }
  return locator;
}

async function assertZeroOneMany(page: Page, element: ElementId, assertions: Assertion[], request: Parameters<typeof seedScenario>[0], actions: string[], transport: Transport[]): Promise<Locator> {
  if (element === "E1") {
    const input = page.getByLabel("Search products");
    const counts: number[] = [];
    for (const query of ["phase185-no-matching-product", "Quantum CyberPhone X", "quantum"]) {
      await input.fill(query);
      await waitForLiveConnected(page);
      const count = await page.getByTestId("storefront-result").count();
      counts.push(count);
      transport.push({ operation: "storefront-live-search", outcome: `query=${query}; visible_results=${count}` });
    }
    actions.push("run three real storefront LiveView searches in order: zero-match, one-match, then multi-match");
    assertions.push(await assertObserved("storefront retains zero, one and many result states", counts.join(","), (value) => value === "0,1,2"));
    assertions.push(await assertObserved("storefront count copy matches the final result set", await page.locator("[data-testid='storefront-results']").innerText(), (value) => String(value).includes("2 visible hits")));
    return page.locator("[data-testid='storefront-results']");
  }
  if (element === "E2") {
    const observations: { scenario: string; text: string }[] = [];
    for (const scenario of ["all_green", "degraded", "incident"] as const) {
      await seedScenario(request, scenario);
      await page.reload();
      await waitForLiveConnected(page);
      const verdict = page.getByTestId("control-room-verdict");
      const text = (await verdict.innerText()).trim();
      observations.push({ scenario, text });
      transport.push({ operation: "control-room-operational-read", outcome: `seed=${scenario}; verdict=${text}` });
    }
    actions.push("seed and read actual Control Room outcomes in order: all_green, degraded, incident; leave incident visible");
    assertions.push(await assertObserved("Control Room distinguishes zero failures, drift-only source data, and the multiple failed-job count", observations.map(({ scenario, text }) => `${scenario}:${text}`).join("\n"), (value) => {
      const rows = String(value).split("\n");
      return rows.length === 3 && rows[0].includes("all_green:") && rows[0].includes("No sync failures found") && rows[1].includes("degraded:") && rows[2].includes("incident:") && /\b[2-9]\d* sync jobs failed\b/.test(rows[2]);
    }));
    assertions.push(await assertObserved("Control Room still exposes its health and settings entry actions", await page.getByTestId("control-room-secondary-intents").isVisible(), (value) => value === true));
    return page.locator("main");
  }
  if (element === "E3" || element === "E7") {
    const counts: number[] = [];
    for (const scenario of ["empty", "healthy", "partial"]) {
      await page.goto(`/admin/search/phase173/health?scenario=${scenario}`);
      await waitForLiveConnected(page);
      const count = await page.getByTestId("posture-row").count();
      counts.push(count);
      transport.push({ operation: "health-fixture-read", outcome: `scenario=${scenario}; schema_rows=${count}` });
    }
    actions.push("navigate the real Search health route through empty, healthy and partial source observations");
    assertions.push(await assertObserved("health collection preserves zero, one and multiple schema rows", counts.join(","), (value) => value === "0,1,2"));
    return page.locator("main");
  }
  if (element === "E4") {
    await seedScenario(request, "incident");
    await page.goto("/admin/search/failed-sync");
    await waitForLiveConnected(page);
    const many = await page.getByTestId("failed-sync-row").count();
    const oneCause = page.locator("input[name='cause[]']").first();
    await oneCause.check();
    await waitForLiveConnected(page);
    const one = await page.getByTestId("failed-sync-row").count();
    transport.push({ operation: "failed-work-filter", outcome: `incident_rows=${many}; checked_cause_rows=${one}` });
    await page.goto("/admin/search/failed-sync?schema=Elixir.NotAllowlisted");
    await waitForLiveConnected(page);
    const zero = await page.getByTestId("failed-sync-row").count();
    transport.push({ operation: "failed-work-unavailable-schema", outcome: `visible_rows=${zero}; route=${new URL(page.url()).pathname + new URL(page.url()).search}` });
    actions.push("render incident failed work, narrow by one real cause filter, then resolve an unavailable schema to zero visible rows");
    const countRecord = `${zero},${one},${many}`;
    assertions.push(await assertObserved("failed work retains exact zero, one-cause and multiple-row counts", countRecord, (value) => {
      const observed = String(value).split(",").map(Number);
      return observed.length === 3 && observed.every(Number.isFinite) && observed[0] === 0 && observed[1] === 1 && observed[2] > observed[1];
    }));
    return page.locator("main");
  }
  if (element === "E5" || element === "E10") {
    const name = `phase185-heldout-${element.toLowerCase()}-zero-one-many`;
    await deleteSavedSearches(request, { prefix: "phase185-heldout-" });
    const counts: number[] = [];
    for (const count of [0, 1, 3]) {
      await deleteSavedSearches(request, { prefix: "phase185-heldout-" });
      for (let index = 0; index < count; index += 1) await putSavedSearch(request, `${name}-${index + 1}`, { mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "quantum", opts: { page: { size: 10 } } });
      await page.goto("/admin/search/search?saved=manage");
      await waitForLiveConnected(page);
      const actualCount = await page.locator(".ops-saved-search-row").count();
      counts.push(actualCount);
      transport.push({ operation: "saved-search-list-read", outcome: `seeded_records=${count}; rendered_rows=${actualCount}` });
    }
    actions.push("seed and read actual saved-search collection sizes in order: zero, one, many");
    assertions.push(await assertObserved("saved-search management renders zero, one and many actual records", counts.join(","), (value) => value === "0,1,3"));
    return page.getByRole("dialog", { name: "Manage saved searches" });
  }
  if (element === "E6") {
    const selector = page.locator("#sync-schema-select");
    const radios = selector.locator("input[type=radio]");
    const zeroResponse = await page.goto("/admin/search/sync-and-index?schema=ScrypathEcommerce.Catalog.NotAllowlisted");
    if (!zeroResponse?.ok()) throw new Error(`Sync settings zero-selection state returned ${zeroResponse?.status() ?? "no HTTP response"}.`);
    await waitForLiveConnected(page);
    const zeroSelected = await radios.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length);
    const unavailable = (await page.getByRole("alert").innerText()).trim();
    const oneResponse = await page.goto("/admin/search/sync-and-index?schema=ScrypathEcommerce.Catalog.Product");
    if (!oneResponse?.ok()) throw new Error(`Sync settings one-selection state returned ${oneResponse?.status() ?? "no HTTP response"}.`);
    await waitForLiveConnected(page);
    const oneSelected = await radios.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length);
    const selectedValue = await radios.evaluateAll((nodes) => nodes.find((node) => (node as HTMLInputElement).checked)?.getAttribute("value") ?? "");
    const many = await radios.count();
    const allNames = await radios.evaluateAll((nodes) => nodes.map((node) => (node as HTMLInputElement).value));
    const observed = JSON.stringify({ zeroSelected, unavailable, oneSelected, selectedValue, many, allNames });
    assertions.push(await assertObserved("actual sync settings distinguishes zero selected, one selected and many allowlisted schemas with scoped recovery copy", observed, (value) => {
      const result = JSON.parse(String(value));
      return result.zeroSelected === 0 && result.unavailable.includes("That schema is unavailable") && result.unavailable.includes("Select an allowlisted schema to continue.") && result.oneSelected === 1 && result.selectedValue === "ScrypathEcommerce.Catalog.Product" && result.many > 1 && result.allNames.includes("ScrypathEcommerce.Catalog.Variant");
    }));
    transport.push({ operation: "sync-schema-selection", outcome: `zero_selected=${zeroSelected}; unavailable=${unavailable}; selected=${selectedValue}; allowlisted=${allNames.join(",")}` });
    actions.push("resolve an unavailable schema to zero selected, then select Product from the actual multi-schema allowlist");
    return selector;
  }
  return page.locator("main");
}

async function assertActionLoading(page: Page, element: ElementId): Promise<{ target: Locator; transport: Transport[] }> {
  const transport: Transport[] = [];
  const priorRoute = new URL(page.url()).pathname + new URL(page.url()).search;
  await page.evaluate(() => (window as Window & { liveSocket?: { enableLatencySim: (ms: number) => void } }).liveSocket?.enableLatencySim(1400));
  let target: Locator;
  if (element === "E8") {
    target = page.getByRole("link", { name: "Open Search", exact: true });
    await expect(target).toBeVisible();
    await target.click();
    await expect(target).toHaveClass(/phx-click-loading/, { timeout: 1_200 });
    transport.push({ operation: "liveview-navigation", outcome: `in-flight with configured transport latency; prior Help DOM retained; route=${priorRoute}` });
  } else if (element === "E9") {
    target = page.getByRole("button", { name: "Run search", exact: true });
    await page.getByLabel("Search text").fill("quantum");
    await expect(target).toBeEnabled();
    await target.click();
    await expect(target).toHaveClass(/phx-click-loading/, { timeout: 1_200 });
    transport.push({ operation: "search-submit", outcome: "liveview action issued; current form retained during request" });
  } else {
    const confirmation = page.locator("#saved-search-delete-input");
    const row = page.locator(".ops-saved-search-row").first();
    const name = (await row.locator(".ops-saved-search-row__name").innerText()).trim();
    await row.getByRole("button", { name: `Delete ${name}` }).click();
    await expect(page.getByRole("dialog", { name: "Delete saved search" })).toBeVisible();
    await confirmation.fill(name);
    target = page.locator("#saved-search-delete-form").getByRole("button", { name: "Delete", exact: true });
    await target.click();
    transport.push({ operation: "saved-search-delete", outcome: "actual delete action in-flight with configured transport latency" });
  }
  await page.waitForTimeout(80);
  const loadingClass = element === "E1" ? "phx-change-loading" : "phx-click-loading";
  if (element === "E10") await expect(page.locator("#saved-search-delete-form")).toHaveClass(/phx-submit-loading/, { timeout: 1_200 });
  else await expect(target).toHaveClass(new RegExp(loadingClass), { timeout: 1_200 });
  if (element !== "E10") await waitForLiveConnected(page);
  return { target, transport };
}

async function assertTransportError(page: Page, element: ElementId, assertions: Assertion[], transport: Transport[]): Promise<Locator> {
  if (element === "E10") {
    const row = page.locator(".ops-saved-search-row").first();
    const name = (await row.locator(".ops-saved-search-row__name").innerText()).trim();
    await row.getByRole("button", { name: `Delete ${name}` }).click();
    const dialog = page.getByRole("dialog", { name: "Delete saved search" });
    const input = page.locator("#saved-search-delete-input");
    await input.fill(name.toLowerCase() === name ? `${name}-wrong` : name.toLowerCase());
    await dialog.getByRole("button", { name: "Delete saved search", exact: true }).click();
    const alert = page.getByRole("alert");
    const text = (await alert.innerText()).trim();
    assertions.push(await assertObserved("protected deletion explains the exact-name requirement and keeps the dialog open", text, (value) => String(value).includes("Type the name exactly as shown to confirm.")));
    assertions.push(await assertObserved("protected deletion retains the saved row", await page.locator(".ops-saved-search-row").count(), (value) => value > 0));
    await expect(input).toBeFocused();
    transport.push({ operation: "protected-delete-validation", outcome: `server rejected mismatched name; role=alert text=${text}; row retained` });
    return dialog;
  }
  if (element === "E3") {
    await page.goto("/admin/search/phase173/health?scenario=refresh-failure");
    await waitForLiveConnected(page);
    await page.locator("#search-health-refresh").click();
    const alert = page.locator("[data-testid='posture-refresh-issue'], [role='alert'], [role='status']").filter({ hasText: /refresh|unavailable|could not/i }).first();
    await expect(alert).toBeVisible();
    const text = (await alert.innerText()).trim();
    assertions.push(await assertObserved("real health refresh failure retains its cause and retry route", text, (value) => String(value).length > 0));
    transport.push({ operation: "health-refresh", outcome: `server returned the configured test-adapter failure; ${text}` });
    return page.locator("main");
  }
  const main = page.locator("[data-phx-main]");
  const priorHeading = (await primaryHeading(page, element)).innerText();
  const priorText = await main.innerText();
  await page.evaluate(() => (window as Window & { liveSocket?: { disconnect: () => void } }).liveSocket?.disconnect());
  await expect(page.locator("#client-error")).toBeVisible({ timeout: 10_000 });
  const errorText = (await page.locator("#client-error").innerText()).trim();
  assertions.push(await assertObserved("LiveView transport failure gives its real reconnect cause", errorText, (value) => String(value).length > 0));
  assertions.push(await assertObserved("transport loss retains the existing product observation", await primaryHeading(page, element).then((heading) => heading.innerText()), (value) => value === priorHeading));
  assertions.push(await assertObserved("transport loss retains prior content", await main.innerText(), (value) => value === priorText));
  transport.push({ operation: "liveview-websocket", outcome: `actual disconnected state displayed: ${errorText}; product route and prior content retained for capture` });
  return main;
}

async function assertLongText(page: Page, element: ElementId, assertions: Assertion[], request: Parameters<typeof seedScenario>[0], actions: string[], transport: Transport[]): Promise<Locator> {
  const longName = `phase185-heldout-${element.toLowerCase()}-${"InternationalWarehouseRecovery".repeat(3)}`.slice(0, 120);
  let locator: Locator;
  if (element === "E3" || element === "E7") {
    await page.goto("/admin/search/phase173/health?scenario=long");
    await waitForLiveConnected(page);
    locator = page.getByTestId("posture-row");
    const text = await locator.allInnerTexts();
    assertions.push(await assertObserved("health keeps the actual long schema identifiers in the rendered rows", text.join("\n"), (value) => String(value).includes("IntentionallyLongName") || String(value).includes("IntentionallyLong")));
  } else if (element === "E2") {
    await seedScenario(request, "incident");
    await page.goto("/admin/search");
    await waitForLiveConnected(page);
    locator = page.getByTestId("control-room-verdict");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Control Room retains the exact schema identifier and failed-job count in its operational evidence", text, (value) => String(value).includes("ScrypathEcommerce.Catalog.Product") && String(value).includes("5 sync jobs failed")));
  } else if (element === "E4") {
    await seedScenario(request, "incident");
    await page.goto("/admin/search/failed-sync");
    await waitForLiveConnected(page);
    locator = page.getByTestId("failed-sync-reason");
    const reasons = await locator.allInnerTexts();
    assertions.push(await assertObserved("failed-work details keep an exact backend cause available", reasons.join("\n"), (value) => String(value).includes("invalid_state: index is processing a settings update and rejected the batch")));
  } else if (element === "E5" || element === "E10") {
    await deleteSavedSearches(request, { prefix: "phase185-heldout-" });
    await putSavedSearch(request, longName, { mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: "quantum", opts: { page: { size: 10 } } });
    await page.goto("/admin/search/search?saved=manage");
    await waitForLiveConnected(page);
    locator = page.locator(".ops-saved-search-row").first();
    assertions.push(await assertObserved("database-backed saved-search name stays exact", await locator.locator(".ops-saved-search-row__name").innerText(), (value) => value === longName));
  } else if (element === "E8") {
    locator = page.locator("#saved-searches");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Help preserves its exact saved-search instructions", text, (value) => String(value).length > 80 && String(value).includes("not the results")));
  } else if (element === "E6") {
    locator = page.locator("#sync-schema-select");
    const schemaChoice = page.getByRole("radio", { name: /ScrypathEcommerce\.Catalog\.Product/ });
    const alternateChoice = page.getByRole("radio", { name: /ScrypathEcommerce\.Catalog\.Variant/ });
    if (await alternateChoice.count() !== 1) throw new Error("The actual Sync and index route did not render its canonical Variant schema radio choice.");
    if (await schemaChoice.count() !== 1) throw new Error("The actual Sync and index route did not render its canonical Product schema radio choice.");
    await alternateChoice.check();
    await waitForLiveConnected(page);
    await schemaChoice.check();
    await waitForLiveConnected(page);
    actions.push("change the actual Sync and index schema radio from Variant to Product through its LiveView handler");
    transport.push({ operation: "sync-schema-selection", outcome: `Variant then Product; final_route=${new URL(page.url()).pathname + new URL(page.url()).search}` });
    const selectedSchemaText = await locator.innerText();
    assertions.push(await assertObserved("actual Sync and index route keeps the full canonical schema identifier visible and selectable at the narrow viewport", selectedSchemaText, (value) => String(value).includes("ScrypathEcommerce.Catalog.Product") && String(value).length >= 32));
  } else {
    const query = `${"phase185-long-query-".repeat(8)}🔬東京`;
    locator = element === "E1" ? page.getByLabel("Search products") : page.getByLabel("Search text");
    await locator.fill(query);
    assertions.push(await assertObserved("long exact query remains available in the actual search control", await locator.inputValue(), (value) => value === query));
  }
  if (element === "E10") {
    const name = (await page.locator(".ops-saved-search-row").first().locator(".ops-saved-search-row__name").innerText()).trim();
    await page.locator(".ops-saved-search-row").first().getByRole("button", { name: `Delete ${name}` }).click();
    locator = page.locator("#saved-search-delete-input");
    assertions.push(await assertObserved("confirmation control retains its contextual accessible name", await locator.getAttribute("aria-label") || await locator.getAttribute("name") || "", (value) => String(value).length > 0));
  }
  return locator;
}

async function captureActualState(page: Page, testInfo: TestInfo, element: ElementId, category: Category, dataIdentity: string,
  assertions: Assertion[], actions: string[], transport: Transport[], target: Locator, widths: number[], fontProfile: Record<string, unknown>,
  timerProof: { fired: boolean; elapsed_ms: number; observed_date: string }): Promise<void> {
  if (!artifactRoot || !evidencePath) throw new Error("The disposable full-run evidence directory and PHASE105_EVIDENCE_PATH are required for held-out receipts.");
  const runId = process.env.E2E_RUN_ID || "";
  if (!runId.startsWith("phase185-")) throw new Error("Held-out state cases require the phase185-gated disposable server Clock.");
  const sourceSha = process.env.E2E_PRODUCT_SOURCE_SHA || process.env.SCRYPATH_SOURCE_SHA || "";
  const buildSha = process.env.SCRYPATH_SOURCE_SHA || "";
  const productTreeSha = process.env.E2E_PRODUCT_TREE_SHA256 || "";
  const fixtureSha = process.env.E2E_FIXTURE_OVERLAY_SHA256 || "";
  const appId = process.env.E2E_APPLICATION_IMAGE_ID || "";
  const standaloneOpsId = process.env.E2E_STANDALONE_OPS_IMAGE_ID || "";
  const browserId = process.env.E2E_BROWSER_IMAGE_ID || "";
  const effectiveRuntime = process.env.E2E_EFFECTIVE_RUNTIME_SHA256 || "";
  if (!/^[a-f0-9]{40}$/.test(sourceSha) || !/^[a-f0-9]{40}$/.test(buildSha) || !/^sha256:[a-f0-9]{64}$/.test(productTreeSha) || !/^sha256:[a-f0-9]{64}$/.test(fixtureSha) || !/^sha256:[a-f0-9]{64}$/.test(appId) || !/^sha256:[a-f0-9]{64}$/.test(standaloneOpsId) || !/^sha256:[a-f0-9]{64}$/.test(browserId) || !/^sha256:[a-f0-9]{64}$/.test(effectiveRuntime)) {
    throw new Error("The host-verified source, tree, fixture, image and effective-runtime identities must be injected into the disposable browser.");
  }
  const clock = await fixedClock();
  const clockBytes = await readFile(fixturePath);
  const clockArtifact = "ui-review-artifacts/iteration3-journeys/phase185-held-out/phase185-clock.txt";
  const clockArtifactPath = path.join(artifactRoot, clockArtifact);
  await mkdir(path.dirname(clockArtifactPath), { recursive: true });
  try {
    await writeFile(clockArtifactPath, clockBytes, { flag: "wx" });
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    const existingClockBytes = await readFile(clockArtifactPath);
    if (!existingClockBytes.equals(clockBytes)) throw new Error("The held-out artifact bundle already contains a different fixed-clock byte sequence.");
  }
  const currentFocus = await page.evaluate(() => {
    const active = document.activeElement as HTMLElement | null;
    return active ? `${active.getAttribute("aria-label") || active.getAttribute("name") || active.id || active.innerText || active.tagName}` : "body";
  });
  const initialScroll = await page.evaluate(() => ({ x: scrollX, y: scrollY }));
  const geometry: Record<string, number | string>[] = [];
  const images: ImageReceipt[] = [];
  const copyNodes = ["main", "#client-error", "[data-testid='storefront-results']", "[data-testid='control-room-verdict']", "[data-testid='posture-row']", "[data-testid='failed-sync-row']", ".ops-saved-search-row", "#saved-searches", "#search-form", "#sync-pipeline-status", "#index-settings-status"];
  const visibleCopy: { text: string; sha256: string }[] = [];
  for (const selector of copyNodes) {
    const node = page.locator(selector).first();
    if (await node.count() && await node.isVisible().catch(() => false)) {
      const text = (await node.innerText().catch(() => "")).trim();
      if (text) visibleCopy.push({ text, sha256: digest(text) });
    }
  }
  for (const width of widths) {
    const height = width === 390 ? 844 : 900;
    await page.setViewportSize({ width, height });
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
    const observed = await page.evaluate(() => ({ width: innerWidth, height: innerHeight, dpr: devicePixelRatio, scrollX, scrollY, documentWidth: document.documentElement.scrollWidth, documentHeight: document.documentElement.scrollHeight }));
    assertions.push(await assertObserved(`document has no viewport-wide horizontal overflow at ${width}px`, observed.documentWidth, (value) => value <= width));
    const box = await target.boundingBox();
    if (box) geometry.push({ name: `case-target-${width}`, x: box.x, y: box.y, width: box.width, height: box.height, viewport_width: width });
    geometry.push({ name: `document-${width}`, x: 0, y: 0, width: observed.documentWidth, height: observed.documentHeight, viewport_width: width });
    const { captureStableImage } = await import("../ui-review.mjs");
    const stabilitySamples: { path: string; bytes: Buffer; state_path: string; state_bytes: Buffer }[] = [];
    let bytes: Buffer;
    try {
      const stable = await captureStableImage({
        page,
        id: `${safe(element)}-${safe(category)}-${width}`,
        kind: "held-out",
        captureImage: async ({ timeout }) => page.screenshot({ fullPage: true, animations: "disabled", timeout }),
        saveSample: async ({ path: samplePath, bytes: sampleBytes, state_path: statePath, state_bytes: stateBytes }) => {
          if (sampleBytes) stabilitySamples.push({ path: samplePath, bytes: sampleBytes, state_path: statePath, state_bytes: stateBytes });
        }
      });
      bytes = stable.image;
      assertions.push({ name: `held-out state and raw image are stationary at ${width}px`, status: "passed", actual: JSON.stringify({ method: stable.stability.method, samples: stable.stability.samples.length, selected: stable.stability.selected }) });
    } catch (error) {
      const failureRoot = path.join(artifactRoot, "test-results", "phase185-capture-failures", `${safe(element)}-${safe(category)}-${width}-attempt-${testInfo.retry}`);
      for (const sample of stabilitySamples) {
        const imagePath = path.join(failureRoot, sample.path);
        const statePath = path.join(failureRoot, sample.state_path);
        await mkdir(path.dirname(imagePath), { recursive: true });
        await writeFile(imagePath, sample.bytes, { flag: "wx" });
        await writeFile(statePath, sample.state_bytes, { flag: "wx" });
      }
      throw error;
    }
    const relative = `ui-review-artifacts/iteration3-journeys/phase185-held-out/${safe(element)}-${safe(category)}-${width}.png`;
    const absolute = path.join(artifactRoot, relative);
    await mkdir(path.dirname(absolute), { recursive: true });
    await writeFile(absolute, bytes, { flag: "wx" });
    images.push({ path: relative, sha256: digest(bytes), viewport: { width, height }, capture: "full-page-real-product-state" });
  }
  const browser = page.context().browser();
  if (!browser || browser.version().trim() === "") throw new Error("The actual Chromium version is unavailable from the launched browser.");
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(playwrightPackageVersion)) throw new Error(`Installed Playwright package version is not exact semver: ${playwrightPackageVersion}`);
  const observedProfile = await page.evaluate(() => ({
    language: navigator.language,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    device_scale_factor: devicePixelRatio,
    color_scheme: matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }));
  const normalizedFontProfile = {
    method: fontProfile.method,
    fixed_font_family: (fontProfile.font_families as Record<string, unknown>)?.fixed,
    applied: fontProfile.applied,
    lifetime: fontProfile.lifetime
  };
  if (JSON.stringify(normalizedFontProfile) !== JSON.stringify(fonts)) throw new Error("The active CDP font setup does not match the acknowledged retained fixed-font profile.");
  if (observedProfile.language !== "en-US" || observedProfile.timezone !== "UTC" || observedProfile.device_scale_factor !== 1) throw new Error(`Actual browser profile differs from the held-out capture recipe: ${JSON.stringify(observedProfile)}`);
  if (observedProfile.color_scheme !== (themeFor(element, category) === "light" ? "light" : "dark")) throw new Error(`Actual browser color scheme differs from the case theme: ${JSON.stringify(observedProfile)}`);
  const observedTheme = await page.locator("html").evaluate((node) => ({
    preference: (node as HTMLElement).dataset.themePreference,
    effective: (node as HTMLElement).dataset.themeEffective
  }));
  const expectedPreference = themeFor(element, category) === "system-dark" ? "system" : themeFor(element, category);
  const expectedEffective = themeFor(element, category) === "light" ? "light" : "dark";
  if (observedTheme.preference !== expectedPreference || observedTheme.effective !== expectedEffective) throw new Error(`Actual product theme differs from requested preference: ${JSON.stringify(observedTheme)}`);
  assertions.push({ name: "actual product theme preference and effective theme match the requested recipe", status: "passed", actual: JSON.stringify(observedTheme) });
  const profileRecipe = {
    browser: { engine: "chromium", version: browser.version(), package: "@playwright/test", package_version: playwrightPackageVersion },
    launch_args: ["--disable-partial-raster"], locale: observedProfile.language,
    timezone: observedProfile.timezone, device_scale_factor: observedProfile.device_scale_factor,
    font_profile: normalizedFontProfile,
    font_profile_setup: fontProfile
  };
  const profileSha = `sha256:${digest(JSON.stringify(canonicalize(profileRecipe)))}`;
  const dataRecipe = {
    protocol: "phase185-heldout-deterministic-data-v1",
    seed_endpoint: "/dev/e2e/seed",
    operational_scenarios: ["all_green", "degraded", "incident", "empty"],
    saved_search_prefix: "phase185-heldout-",
    clock_sha256: clock.sha256
  };
  const dataRecipeSha = `sha256:${digest(JSON.stringify(canonicalize(dataRecipe)))}`;
  if (process.env.E2E_BROWSER_PROFILE_SHA256 && process.env.E2E_BROWSER_PROFILE_SHA256 !== profileSha) throw new Error("The actual browser profile does not match the host-pinned common profile hash.");
  if (process.env.E2E_DATA_RECIPE_SHA256 && process.env.E2E_DATA_RECIPE_SHA256 !== dataRecipeSha) throw new Error("The test data recipe does not match the host-pinned common data recipe hash.");
  const clockRecipe = {
    ...profileRecipe,
    browser_date: { fixed: true, timers_running: timerProof.fired, timer_elapsed_ms: timerProof.elapsed_ms, observed: (await page.evaluate(() => new Date().toISOString())) },
    clock_sha256: clock.sha256,
    profile_sha256: profileSha,
    data_recipe_sha256: dataRecipeSha
  };
  if (clockRecipe.browser_date.observed !== clock.instant) throw new Error("The browser Date does not match the immutable mounted clock fixture.");
  const recipeSha = `sha256:${digest(JSON.stringify(canonicalize(clockRecipe)))}`;
  const receipt = {
    operation: "ui_preservation_case", case_id: `${element} ${category}`,
    test_identity: JSON.stringify([`examples/scrypath_ecommerce/${path.relative(process.cwd(), testInfo.file).split(path.sep).join("/")}`, "chromium", testInfo.titlePath, "shared"]),
    product_source_sha: sourceSha, build_source_sha: buildSha, product_tree_sha256: productTreeSha,
    fixture_overlay_sha256: fixtureSha, recipe_sha256: recipeSha, clock_recipe: clockRecipe,
    data_recipe: dataRecipe,
    runtime: { application_image_id: appId, standalone_ops_image_id: standaloneOpsId, browser_image_id: browserId, effective_runtime_sha256: effectiveRuntime, browser_source_layer_id: process.env.E2E_BROWSER_SOURCE_LAYER_ID || "", browser_base_layers_sha256: process.env.E2E_BROWSER_BASE_LAYERS_SHA256 || "" },
    state: {
      element, category, route: new URL(page.url()).pathname + new URL(page.url()).search,
      theme: themeFor(element, category), color_scheme: observedProfile.color_scheme,
      viewport: { width: widths[0], height: widths[0] === 390 ? 844 : 900 },
      scroll: initialScroll, focus: { name: currentFocus }, data_identity: dataIdentity,
      clock: { browser_iso: clockRecipe.browser_date.observed, server_iso: clock.instant, clock_sha256: clock.sha256 }
    },
    clock_artifact: { path: clockArtifact, sha256: digest(clockBytes) },
    actions, transport_sequence: transport, geometry, assertions, visible_copy: visibleCopy, images
  };
  await appendFile(evidencePath, `${JSON.stringify(receipt)}\n`, { flag: "a" });
}

export async function runPreservationCase(args: {
  browser: Browser; request: Parameters<typeof seedScenario>[0]; testInfo: TestInfo; element: ElementId; category: Category;
}): Promise<void> {
  const { browser, request, testInfo, element, category } = args;
  const host = new URL(targetUrl);
  if (host.protocol !== "http:" || host.hostname !== "web" || host.port !== "4002") throw new Error(`Held-out capture refuses non-disposable product target ${targetUrl}.`);
  const dataIdentity = await initializeData(element, category, request);
  const theme = themeFor(element, category);
  const widths = category === "overflow" ? [...REQUIRED_WIDTHS] : category === "long-text" && element === "E6" ? [390] : [1440];
  const context = await browser.newContext({ baseURL: targetUrl, viewport: { width: widths[0], height: widths[0] === 390 ? 844 : 900 }, locale: "en-US", timezoneId: "UTC", deviceScaleFactor: 1, colorScheme: theme === "light" ? "light" : "dark" });
  const page = await context.newPage();
  const assertions: Assertion[] = [];
  const actions: string[] = ["seed deterministic test data through the existing application API", "navigate to the actual product route", "observe the rendered product state"];
  const transport: Transport[] = [];
  let font: { profile: Record<string, unknown>; session: { detach: () => Promise<void> } } | null = null;
  let timerProof: { fired: boolean; elapsed_ms: number; observed_date: string };
  try {
    await setTheme(context, theme);
    const clock = await fixedClock();
    await page.clock.setFixedTime(new Date(clock.instant));
    timerProof = await verifyFixedDateLeavesTimersRunning(page, clock.instant);
    assertions.push(await assertObserved("browser Date is fixed while a real timer callback fires", `${timerProof.observed_date};${Math.round(timerProof.elapsed_ms)}ms`, (value) => String(value).startsWith(`${clock.instant};`) && Number(String(value).split(";")[1].replace("ms", "")) > 0));
    const { configureDisposableFontProfile } = await import("../ui-review.mjs");
    font = await configureDisposableFontProfile(context, page);
    await assertServerClock(page, clock.instant, assertions, transport);
    const heading = await enterPage(page, element, assertions, transport);
    await prepareSavedManager(page, element);
    let target: Locator = heading;
    if (category === "empty") target = await assertEmpty(page, element, assertions);
    else if (category === "populated") target = await assertPopulated(page, element, assertions);
    else if (category === "partial") target = await assertPartial(page, element, assertions);
    else if (category === "zero-one-many") target = await assertZeroOneMany(page, element, assertions, request, actions, transport);
    else if (category === "loading") {
      if (element === "E8" || element === "E9" || element === "E10") {
        const priorText = await page.locator("[data-phx-main]").innerText();
        const priorRoute = new URL(page.url()).pathname + new URL(page.url()).search;
        const pending = await assertActionLoading(page, element);
        target = pending.target;
        transport.push(...pending.transport);
        const pendingText = await page.locator("[data-phx-main]").innerText();
        const observed = JSON.stringify({ priorRoute, actualRoute: new URL(page.url()).pathname + new URL(page.url()).search, priorText, pendingText });
        assertions.push(await assertObserved(`${element} retains the exact route and visible product copy while a real LiveView action is pending`, observed, (value) => {
          const state = JSON.parse(String(value));
          return state.actualRoute === state.priorRoute && state.pendingText === state.priorText;
        }));
        actions.push("issue actual LiveView navigation or action with the bounded browser transport latency harness");
      } else {
        const priorText = await page.locator("[data-phx-main]").innerText();
        await page.evaluate(() => (window as Window & { liveSocket?: { enableLatencySim: (ms: number) => void } }).liveSocket?.enableLatencySim(1400));
        const action = element === "E1" ? page.getByLabel("Search products") : element === "E2" ? page.locator("#control-room-refresh") : element === "E3" ? page.locator("#search-health-refresh") : element === "E4" ? page.locator("#failed-sync-refresh") : element === "E5" ? page.getByRole("button", { name: /Load .+/ }).first() : page.locator("#sync-and-index-refresh");
        target = action;
        if (element === "E1") await action.fill("quantum"); else await action.click();
        const loadingClass = element === "E1" ? /phx-change-loading/ : /phx-click-loading/;
        await expect(action).toHaveClass(loadingClass, { timeout: 1_200 });
        await waitForLiveConnected(page);
        const pendingText = await page.locator("[data-phx-main]").innerText();
        assertions.push(await assertObserved(`${element} retains its prior product copy and a real busy action control during an outstanding LiveView request`, JSON.stringify({ priorText, pendingText, visible: await action.isVisible(), loading: await action.evaluate((node) => node.className) }), (value) => {
          const state = JSON.parse(String(value));
          return state.pendingText === state.priorText && state.visible === true && loadingClass.test(state.loading);
        }));
        transport.push({ operation: `${element.toLowerCase()}-liveview-action`, outcome: `pending during the real LiveView request; product copy retained; busy_class=${loadingClass}` });
        actions.push("issue the actual product LiveView read/action while transport response is pending");
      }
    } else if (category === "error") {
      target = await assertTransportError(page, element, assertions, transport);
      actions.push("cause a real rejected protected action or LiveView transport disconnect and verify the product error/recovery state");
    } else if (category === "long-text") {
      target = await assertLongText(page, element, assertions, request, actions, transport);
      actions.push("render and inspect the exact long product identifier, query, name or Help copy");
    }
    if (category === "overflow") {
      target = element === "E8" ? page.locator("#saved-searches") : element === "E10" ? page.locator(".ops-saved-search-row").first() : element === "E7" ? page.getByTestId("posture-row").last() : page.locator("main");
      if (element === "E10") {
        const row = page.locator(".ops-saved-search-row").first();
        const name = (await row.locator(".ops-saved-search-row__name").innerText()).trim();
        const deleteTrigger = row.getByRole("button", { name: `Delete ${name}` });
        await deleteTrigger.hover();
        await deleteTrigger.click();
        const confirmation = page.locator("#saved-search-delete-input");
        await expect(confirmation).toBeFocused();
        await confirmation.fill(name);
        assertions.push(await assertObserved("overflow case reaches the real exact-name deletion confirmation", await page.locator("#saved-search-delete-form").innerText(), (value) => String(value).includes("It can't be undone") && String(value).includes(name)));
        target = page.locator("#saved-search-delete-form");
      } else if (element === "E8") {
        const helpLink = page.getByRole("link", { name: "Open Search", exact: true });
        await helpLink.hover();
        assertions.push(await assertObserved("Help navigation link remains visible after pointer hover", await helpLink.isVisible(), (value) => value === true));
      } else {
        await target.hover();
      }
      actions.push("inspect existing product layout at the required 1440, 768 and 390 pixel viewports");
    }
    if (category === "long-text" && element === "E8") {
      await page.getByRole("link", { name: "Manage saved searches", exact: true }).focus();
      assertions.push(await assertObserved("Help navigation target has a real accessible name", await page.getByRole("link", { name: "Manage saved searches", exact: true }).getAttribute("aria-label") || "Manage saved searches", (value) => String(value).length > 0));
      actions.push("focus the existing Help navigation link and retain its accessible name");
    }
    const main = page.locator("[data-phx-main]");
    const text = await main.innerText();
    assertions.push(await assertObserved("actual product content remains rendered for evidence", text, (value) => String(value).trim().length > 0));
    const expectedViewportWidths = category === "overflow" ? [...REQUIRED_WIDTHS] : [widths[0]];
    await captureActualState(page, testInfo, element, category, dataIdentity, assertions, actions, transport, target, expectedViewportWidths, font.profile, timerProof);
    if (category === "error" && element !== "E3" && element !== "E10") {
      await page.evaluate(() => (window as Window & { liveSocket?: { connect: () => void } }).liveSocket?.connect());
      await waitForLiveConnected(page);
    }
    if (category === "loading") {
      await page.evaluate(() => (window as Window & { liveSocket?: { disableLatencySim?: () => void; enableLatencySim: (ms: number) => void } }).liveSocket?.disableLatencySim?.());
      await page.evaluate(() => (window as Window & { liveSocket?: { enableLatencySim: (ms: number) => void } }).liveSocket?.enableLatencySim(0));
      await waitForLiveConnected(page);
    }
  } finally {
    await context.close();
  }
}
