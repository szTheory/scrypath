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
const PHASE185_RESET_TABLES = [
  "public.tenants",
  "public.categories",
  "public.products",
  "public.variants",
  "public.oban_jobs",
  "public.scrypath_ops_saved_searches"
] as const;

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

function scenarioFor(element: ElementId, category: Category): "all_green" | "degraded" | "incident" | "empty" | "e2e_search_catalog" | "phase185_partial_catalog" | "phase185_one_failed" | null {
  if (element === "E1") return category === "empty" ? "empty" : category === "partial" ? "phase185_partial_catalog" : "e2e_search_catalog";
  if (element === "E2") return category === "zero-one-many" ? null : category === "empty" ? "empty" : category === "partial" || category === "error" || category === "long-text" ? "incident" : "all_green";
  if (element === "E3" || element === "E7") return null;
  if (element === "E4") return category === "zero-one-many" ? null : category === "empty" ? "empty" : category === "populated" || category === "partial" || category === "error" || category === "long-text" ? "incident" : "all_green";
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
  const reset = await seedScenario(request, "phase185_case_reset");
  const actualResetTables = reset.reset_tables ?? [];
  const resetIdentities = reset.identity_state ?? {};
  if (reset.scenario !== "phase185_case_reset" || JSON.stringify(actualResetTables) !== JSON.stringify(PHASE185_RESET_TABLES)) {
    throw new Error(`Phase185 case reset did not confirm its exact owned table set: ${JSON.stringify({ scenario: reset.scenario, tables: actualResetTables })}`);
  }
  if (Object.keys(resetIdentities).sort().join(",") !== [...PHASE185_RESET_TABLES].sort().join(",") ||
      PHASE185_RESET_TABLES.some((table) => resetIdentities[table]?.next_id !== 1 || resetIdentities[table]?.is_called !== false)) {
    throw new Error(`Phase185 case reset did not confirm every identity sequence starts at next id 1: ${JSON.stringify(resetIdentities)}`);
  }
  const scenario = scenarioFor(element, category);
  let identity = `phase185:${element}:${category}:case-reset=phase185-case-reset-v1:tables=${PHASE185_RESET_TABLES.join(",")}:identity=next-id-1,is-called-false`;
  if (scenario) {
    const seed = await seedScenario(request, scenario);
    identity += `:${scenario}:${seed.tenant_id ?? "none"}:${Object.keys(seed.products).sort().join(",")}`;
    if (seed.missing_field_product_id && seed.missing_field_product_name) {
      identity += `:missing-field=description:${seed.missing_field_product_id}:${seed.missing_field_product_name}`;
    }
  }
  if (element === "E5" || element === "E10") {
    await deleteSavedSearches(request, { prefix: "phase185-heldout-" });
    const name = savedSearchName(element, category);
    const count = category === "empty" ? 0 : category === "zero-one-many" ? 3 : 1;
    for (let index = 0; index < count; index += 1) {
      await putSavedSearch(request, `${name}-${index + 1}`, { mode: "search", schema: "ScrypathEcommerce.Catalog.Product", q: index === 1 ? "quantum" : "scanner", opts: { page: { size: 10 } } });
    }
    identity += `:saved-searches:${count}:${name}`;
  }
  if (element === "E2" && category === "zero-one-many") identity += ":scenario-sequence=all_green,degraded,phase185_one_failed,incident;failed-counts=0,0,1,5;final=incident";
  if (element === "E3" && category === "zero-one-many") identity += ":scenario-sequence=empty,healthy,partial;final=partial";
  if (element === "E4" && category === "zero-one-many") identity += ":scenario-sequence=incident;filtered-cause;unavailable-schema;final=zero-rows";
  if (element === "E6" && category === "zero-one-many") identity += ":selection-sequence=zero-selected,Product-selected,two-allowlisted";
  return identity;
}

function savedSearchName(element: ElementId, category: Category): string {
  if (category === "long-text") return `phase185-heldout-${element.toLowerCase()}-${"InternationalWarehouseRecovery".repeat(3)}`.slice(0, 120);
  return `phase185-heldout-${element.toLowerCase()}-${category}`;
}

async function assertServerClock(page: Page, instant: string, assertions: Assertion[], transport: Transport[]): Promise<void> {
  await page.clock.setFixedTime(new Date(instant));
  const response = await page.goto("/admin/search/failed-sync");
  if (!response?.ok()) throw new Error(`Clock probe navigation failed with ${response?.status() ?? "no HTTP response"}.`);
  await waitForLiveConnected(page);
  const stamp = page.locator("[data-ops-timestamp-copy]").first();
  await expect(stamp).toBeVisible();
  const serverValue = await stamp.getAttribute("data-ops-timestamp-copy");
  if (!serverValue || new Date(serverValue).toISOString() !== instant) throw new Error(`Server Clock did not render the mounted fixed instant: expected ${instant}, got ${serverValue ?? "missing"}.`);
  assertions.push({ name: "actual failed-work LiveView Clock timestamp matches the immutable mounted fixture", status: "passed", actual: serverValue });
  transport.push({ operation: "server-clock-liveview-refresh", outcome: `connected on non-fixture /admin/search/failed-sync route; status=${response.status()}; timestamp=${serverValue}` });
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
  } else if (element === "E6") {
    await page.goto("/admin/search/search");
    await waitForLiveConnected(page);
    await page.getByLabel("Search text").fill("phase185-no-matching-document");
    await page.getByRole("button", { name: "Run search", exact: true }).click();
    await waitForLiveConnected(page);
    locator = page.locator("#search-results-heading");
    const text = await page.locator("main").innerText();
    assertions.push(await assertObserved("Search results have a real zero-result state with its task-specific recovery copy", text, (value) => String(value).includes("No matching documents") && String(value).includes("Try fewer words, check the spelling or leave the query blank to browse.") && !String(value).includes("Search could not run")));
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
    throw new Error(`No actual empty product state is defined for ${element}.`);
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
    const searchInput = page.getByLabel("Search products");
    const initialQuery = await searchInput.inputValue();
    const unfilteredCount = await page.getByTestId("storefront-result").count();
    const category = page.getByRole("checkbox", { name: "Smartphones" });
    await category.check();
    await waitForLiveConnected(page);
    locator = page.locator("[data-testid='storefront-results']");
    const filteredRoute = page.url();
    assertions.push(await assertObserved("storefront selected-category filter narrows the actual unqueried catalog and stays in the route", JSON.stringify({ initialQuery, unfilteredCount, filteredRoute }), (value) => {
      const result = JSON.parse(String(value));
      return result.initialQuery === "" && result.unfilteredCount === 3 && result.filteredRoute.includes("category_id=");
    }));
    const rows = page.getByTestId("storefront-result");
    const rowCount = await rows.count();
    const missingFieldProduct = rows.filter({ hasText: "Quantum CyberPhone X" });
    const missingFieldCardText = await missingFieldProduct.innerText();
    const descriptionCopy = await missingFieldProduct.locator(":scope > p").innerText();
    const completeFieldProduct = rows.filter({ hasText: "Quantum CyberPhone Pro" });
    const completeDescription = await completeFieldProduct.locator(":scope > p").innerText();
    assertions.push(await assertObserved("partial storefront result retains exact product identity and the available category field", missingFieldCardText, (value) => String(value).includes("Quantum CyberPhone X") && String(value).includes("Smartphones")));
    assertions.push(await assertObserved("known absent description stays absent on the narrowed actual result while other exact fields remain", JSON.stringify({ descriptionCopy, completeDescription, rowCount, unfilteredCount }), (value) => {
      const result = JSON.parse(String(value));
      return result.descriptionCopy === "" && result.completeDescription === "Pro version of the cyberphone." && result.rowCount === 2 && result.unfilteredCount === 3;
    }));
    assertions.push(await assertObserved("scoped storefront subset is available and is not mislabeled as unknown or unavailable", await locator.innerText(), (value) => String(value).includes("2 visible hits") && !String(value).includes("Search unavailable") && !String(value).includes("Unknown data")));
  } else if (element === "E2") {
    locator = page.locator("[data-testid='control-room-affected-scope']");
    assertions.push(await assertObserved("Control Room identifies affected schema scope", await locator.isVisible(), (value) => value === true));
    const fullText = await page.locator("[data-testid='control-room-verdict']").innerText();
    assertions.push(await assertObserved("Control Room keeps the exact failed-job and affected-schema evidence without a healthy verdict", `${fullText};${await locator.innerText()}`, (value) => String(value).includes("5 sync jobs failed") && String(value).includes("ScrypathEcommerce.Catalog.Product") && !String(value).includes("No sync failures found")));
  } else if (element === "E3" || element === "E7") {
    await page.goto("/admin/search/phase173/health?scenario=partial");
    await waitForLiveConnected(page);
    locator = page.getByTestId("posture-row").filter({ hasText: "Search health could not be checked" });
    const partialText = await page.locator("main").innerText();
    assertions.push(await assertObserved("phase173 test source preserves one available row and one explicitly unknown row", JSON.stringify({ rowCount: await page.getByTestId("posture-row").count(), partialText }), (value) => {
      const result = JSON.parse(String(value));
      return result.rowCount === 2 && result.partialText.includes("Phase173FixtureSchema") && result.partialText.includes("Phase173PartialSchema") && result.partialText.includes("phase173_backend_unavailable");
    }));
    assertions.push(await assertObserved("unknown backend observation stays scoped to its schema and does not erase the available row", await locator.innerText(), (value) => String(value).includes("Search health could not be checked") && String(value).includes("phase173_backend_unavailable")));
  } else if (element === "E4") {
    locator = page.getByTestId("failed-sync-row").first();
    const baseline = await page.getByTestId("failed-sync-row").count();
    const causeFilters = page.locator("input[name='cause[]']");
    const backendRejected = page.locator("input[name='cause[]'][value='backend_rejected']");
    await expect(backendRejected).toBeVisible();
    const facetCount = Number((await backendRejected.locator("xpath=..").locator(".ops-filter-chip__count").innerText()).trim());
    expect(facetCount, "the backend_rejected facet has exactly one known fixture row").toBe(1);
    await backendRejected.check();
    await waitForLiveConnected(page);
    const narrowed = await page.getByTestId("failed-sync-row").count();
    const selectedCause = await causeFilters.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).map((node) => (node as HTMLInputElement).value).join(","));
    const filteredText = await page.locator("main").innerText();
    const summary = page.getByTestId("failed-sync-summary");
    const summaryText = await summary.innerText();
    assertions.push(await assertObserved("failed-work cause selection stays in the real filter route", page.url(), (value) => String(value).includes("cause=")));
    assertions.push(await assertObserved("filtered failed-work retains the known exact cause and a narrower intentional subset", JSON.stringify({ narrowed, baseline, cause: selectedCause, filteredText, facetCount }), (value) => {
      const result = JSON.parse(String(value));
      return result.narrowed === 1 && result.baseline === 5 && result.cause === "backend_rejected" && result.facetCount === 1 && result.filteredText.includes("invalid_state: index is processing a settings update and rejected the batch") && !result.filteredText.includes("could not load") && !result.filteredText.includes("unknown scope");
    }));
    assertions.push(await assertObserved("the backend-rejected subset is explicitly filtered from a complete known source list, not an unknown or stale source", JSON.stringify({ baseline, selectedCause, summaryVisible: await summary.isVisible(), summaryText }), (value) => {
      const result = JSON.parse(String(value));
      return result.baseline === 5 && result.selectedCause === "backend_rejected" && result.summaryVisible === true && result.summaryText.includes("4 more hidden by filters.") && result.summaryText.includes("Clear filters");
    }));
    await page.goto("/admin/search/failed-sync");
    await waitForLiveConnected(page);
    const fullRows = await page.getByTestId("failed-sync-row").evaluateAll((nodes) => nodes.map((node) => {
      const row = node as HTMLElement;
      return {
        text: row.innerText,
        reason: row.querySelector("[data-testid='failed-sync-reason']")?.textContent?.trim() || "",
        guidance: row.querySelector(".ops-failed-row__guidance")?.innerText.trim() || "",
        retry: Boolean(row.querySelector("[data-testid='failed-sync-retry']")),
        ineligibleCopy: row.querySelector("[data-testid='failed-sync-eligibility']")?.textContent?.trim() || ""
      };
    }));
    const unknownRows = fullRows.filter((row) => row.reason.includes("unclassified delete failure from upstream"));
    const backendRows = fullRows.filter((row) => row.reason.includes("invalid_state: index is processing a settings update and rejected the batch"));
    const exhaustedRows = fullRows.filter((row) => row.guidance.includes("Retries used up"));
    assertions.push(await assertObserved("incident fixture keeps the unknown cause scoped beside known failures and exposes retry only for eligible rows", JSON.stringify({ total: fullRows.length, retryableRows: fullRows.filter((row) => row.retry).length, unknownRows, backendRows, exhaustedRows }), (value) => {
      const result = JSON.parse(String(value));
      const unknown = result.unknownRows[0];
      const exhausted = result.exhaustedRows[0];
      return result.total === 5 && result.retryableRows === 3 && result.unknownRows.length === 1 && unknown.text.includes("Unknown cause.") && unknown.guidance.includes("Unknown cause. Read the error, then retry.") && unknown.retry === true && result.backendRows.length === 1 && result.backendRows[0].retry === false && result.exhaustedRows.length === 1 && exhausted.retry === false && exhausted.ineligibleCopy.includes("can't be retried here");
    }));
    const unknownCause = page.locator("input[name='cause[]'][value='unknown']");
    await expect(unknownCause).toBeVisible();
    const unknownFacetCount = Number((await unknownCause.locator("xpath=..").locator(".ops-filter-chip__count").innerText()).trim());
    await unknownCause.check();
    await waitForLiveConnected(page);
    const unknownOnly = page.getByTestId("failed-sync-row");
    const unknownOnlyCount = await unknownOnly.count();
    const unknownOnlyText = await unknownOnly.first().innerText();
    const unknownSummary = await page.getByTestId("failed-sync-summary").innerText();
    const unknownRoute = new URL(page.url()).pathname + new URL(page.url()).search;
    assertions.push(await assertObserved("unknown cause filtering preserves its explicit route scope and recovery copy while other known rows stay outside that subset", JSON.stringify({ unknownFacetCount, unknownOnlyCount, unknownOnlyText, unknownSummary, unknownRoute }), (value) => {
      const result = JSON.parse(String(value));
      return result.unknownFacetCount === 1 && result.unknownOnlyCount === 1 && result.unknownOnlyText.includes("Unknown cause. Read the error, then retry.") && result.unknownOnlyText.includes("unclassified delete failure from upstream") && result.unknownOnlyText.includes("Retry") && result.unknownSummary.includes("4 more hidden by filters.") && result.unknownSummary.includes("Clear filters") && result.unknownRoute.includes("cause=unknown");
    }));
    transport.push({ operation: "failed-work-unknown-cause-filter", outcome: `incident_rows=${fullRows.length}; unknown_facet=${unknownFacetCount}; visible_unknown_rows=${unknownOnlyCount}; eligible_retry_rows=3; route=${unknownRoute}` });
    locator = unknownOnly.first();
  } else if (element === "E5") {
    await page.goto("/admin/search/ui-fixtures?scenario=partial");
    await waitForLiveConnected(page);
    locator = page.getByTestId("result-hit-fixture");
    await expect(locator).toHaveAttribute("data-fixture-state", "partial-component");
    const hit = locator.locator(".ops-search-hit");
    await expect(hit).toContainText("Partial result with unavailable description");
    await expect(hit).toContainText("Description");
    await expect(hit.locator(".ops-value-null")).toContainText("null");
    await hit.getByText("Raw hit payload", { exact: true }).click();
    const rawPayload = await hit.locator("pre").innerText();
    assertions.push(await assertObserved("the actual shared ResultUi component retains available hit fields and renders a null description explicitly", await hit.innerText(), (value) => String(value).includes("Partial result with unavailable description") && String(value).includes("partial-result-42") && String(value).includes("Description") && String(value).includes("null")));
    assertions.push(await assertObserved("component-boundary fixture source is identified and raw field provenance remains visible", `${await locator.getAttribute("data-fixture-state")};${rawPayload}`, (value) => String(value).startsWith("partial-component;") && String(value).includes('"description" => nil') && String(value).includes("supplier note remains available")));
    transport.push({ operation: "shared-result-component-fixture", outcome: "actual ScrypathOps ResultUi.result_hit rendered on the dev/test-only mounted LiveView route; partial field value is nil, not synthesized HTML" });
  } else if (element === "E10") {
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
      const differenceRows = page.locator(".ops-settings-diff tbody tr");
      const differences = await differenceRows.allInnerTexts();
      assertions.push(await assertObserved("settings preserves the exact seeded filterableAttributes drift and declared/live values", JSON.stringify({ text, differenceCount: differences.length, differences }), (value) => {
        const result = JSON.parse(String(value));
        return result.text.includes("Meilisearch settings differ from the schema") && result.text.includes("Nothing was changed") && result.text.includes("Apply the schema's settings") && result.differenceCount > 0 && result.differences.join("\n").includes("filterableAttributes") && result.differences.join("\n").includes("tenant_id");
      }));
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
    for (const scenario of ["all_green", "degraded", "phase185_one_failed", "incident"] as const) {
      await seedScenario(request, scenario);
      await page.reload();
      await waitForLiveConnected(page);
      const verdict = page.getByTestId("control-room-verdict");
      const text = (await verdict.innerText()).trim();
      observations.push({ scenario, text });
      transport.push({ operation: "control-room-operational-read", outcome: `seed=${scenario}; verdict=${text}` });
    }
    actions.push("seed and read actual Control Room outcomes in order: zero failures, drifted settings with no failed jobs, one failed job, five failed jobs; leave incident visible");
    assertions.push(await assertObserved("Control Room preserves exact zero, one and many failed-job counts while the drifted-settings seed remains a zero-failure observation", observations.map(({ scenario, text }) => `${scenario}:${text}`).join("\n"), (value) => {
      const rows = String(value).split("\n");
      const driftOnly = rows.find((row) => row.startsWith("degraded:")) || "";
      const oneFailed = rows.find((row) => row.startsWith("phase185_one_failed:")) || "";
      const manyFailed = rows.find((row) => row.startsWith("incident:")) || "";
      return rows.length === 4 && rows[0].includes("all_green:") && rows[0].includes("No sync failures found") && driftOnly.includes("No sync failures found") && !/\b\d+ sync jobs failed\b/.test(driftOnly) && /\b1 sync job failed\b/.test(oneFailed) && /\b5 sync jobs failed\b/.test(manyFailed);
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
    await page.goto("/admin/search/search?mode=multi&q=quantum");
    await waitForLiveConnected(page);
    const choices = page.locator("#ops-search-playground-form input[name='schemas[]']");
    const choiceCount = await choices.count();
    expect(choiceCount, "the actual Search route renders the configured Product and Variant schema controls").toBe(2);
    for (let index = 0; index < choiceCount; index += 1) await choices.nth(index).uncheck();
    await waitForLiveConnected(page);
    const submit = page.getByRole("button", { name: "Run search", exact: true });
    await submit.click();
    await waitForLiveConnected(page);
    const zeroSelected = await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length);
    const zeroCopy = (await page.getByRole("alert").innerText()).trim();
    assertions.push(await assertObserved("actual multi-schema Search route explains the zero-selected task-specific next step", `${zeroSelected};${zeroCopy}`, (value) => String(value) === "0;Select at least one schema."));

    const productChoice = page.locator("#ops-search-playground-form input[name='schemas[]'][value='ScrypathEcommerce.Catalog.Product']");
    const variantChoice = page.locator("#ops-search-playground-form input[name='schemas[]'][value='ScrypathEcommerce.Catalog.Variant']");
    await productChoice.check();
    await waitForLiveConnected(page);
    const oneSelected = await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length);
    const oneNames = await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).map((node) => (node as HTMLInputElement).value));
    await submit.click();
    await waitForLiveConnected(page);
    await expect(page.locator("#search-outcome")).toHaveText(/^\d+ results? shown$/, { timeout: 20_000 });
    const oneResultCount = await page.locator(".ops-search-hit").count();
    const oneSubmittedSchemas = JSON.parse((await page.locator("#search-run-attribution").getAttribute("data-schemas")) || "[]") as string[];
    await productChoice.check();
    await variantChoice.check();
    await waitForLiveConnected(page);
    const manySelected = await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).length);
    const manyNames = await choices.evaluateAll((nodes) => nodes.filter((node) => (node as HTMLInputElement).checked).map((node) => (node as HTMLInputElement).value));
    await submit.click();
    await waitForLiveConnected(page);
    await expect(page.locator("#search-outcome")).toHaveText(/^\d+ results? shown$/, { timeout: 20_000 });
    const manyResultCount = await page.locator(".ops-search-hit").count();
    const manySubmittedSchemas = JSON.parse((await page.locator("#search-run-attribution").getAttribute("data-schemas")) || "[]") as string[];
    const multiCopy = await page.locator("#ops-search-playground-form").innerText();
    const observed = JSON.stringify({ zeroSelected, zeroCopy, oneSelected, oneNames, oneSubmittedSchemas, oneResultCount, manySelected, manyNames, manySubmittedSchemas, manyResultCount, multiCopy });
    assertions.push(await assertObserved("actual multi-schema Search route traverses zero, one and many selections with exact selected schema identities and a real combined result list", observed, (value) => {
      const result = JSON.parse(String(value));
      return result.zeroSelected === 0 && result.zeroCopy === "Select at least one schema." && result.oneSelected === 1 && result.oneNames[0] === "ScrypathEcommerce.Catalog.Product" && result.oneSubmittedSchemas.length === 1 && result.oneSubmittedSchemas[0] === "ScrypathEcommerce.Catalog.Product" && result.oneResultCount > 0 && result.manySelected === 2 && result.manyNames.includes("ScrypathEcommerce.Catalog.Product") && result.manyNames.includes("ScrypathEcommerce.Catalog.Variant") && result.manySubmittedSchemas.length === 2 && result.manySubmittedSchemas.includes("ScrypathEcommerce.Catalog.Product") && result.manySubmittedSchemas.includes("ScrypathEcommerce.Catalog.Variant") && result.manyResultCount >= result.oneResultCount && result.multiCopy.includes("One combined result list.");
    }));
    transport.push({ operation: "search-multi-schema-selection", outcome: `selected_counts=0,${oneSelected},${manySelected}; one_results=${oneResultCount}; many_results=${manyResultCount}; schemas=${manyNames.join(",")}` });
    actions.push("use the actual Search multi-schema controls to run zero selected, Product only, then Product and Variant; verify the zero-selection recovery copy and combined result list");
    return page.locator("#ops-search-playground-form");
  }
  return page.locator("main");
}

async function assertActionLoading(page: Page, element: ElementId): Promise<{ target: Locator; transport: Transport[]; priorRoute: string; priorText: string }> {
  const transport: Transport[] = [];
  const priorRoute = new URL(page.url()).pathname + new URL(page.url()).search;
  let priorText = await page.locator("[data-phx-main]").innerText();
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
    priorText = await page.locator("[data-phx-main]").innerText();
    target = page.locator("#saved-search-delete-form").getByRole("button", { name: "Delete", exact: true });
    await target.click();
    transport.push({ operation: "saved-search-delete", outcome: "actual delete action in-flight with configured transport latency" });
  }
  await page.waitForTimeout(80);
  const loadingClass = element === "E1" ? "phx-change-loading" : "phx-click-loading";
  if (element === "E10") await expect(page.locator("#saved-search-delete-form")).toHaveClass(/phx-submit-loading/, { timeout: 1_200 });
  else await expect(target).toHaveClass(new RegExp(loadingClass), { timeout: 1_200 });
  return { target, transport, priorRoute, priorText };
}

async function assertPendingState(page: Page, element: ElementId, target: Locator, priorRoute: string, priorText: string): Promise<string> {
  const route = new URL(page.url()).pathname + new URL(page.url()).search;
  const currentText = await page.locator("[data-phx-main]").innerText();
  const busyLocator = element === "E10" ? page.locator("#saved-search-delete-form") : target;
  const busyClass = await busyLocator.getAttribute("class") || "";
  const expectedClass = element === "E1" ? "phx-change-loading" : element === "E10" ? "phx-submit-loading" : "phx-click-loading";
  if (route !== priorRoute || currentText !== priorText || !busyClass.split(/\s+/).includes(expectedClass)) {
    throw new Error(`${element} left its actual in-flight state before the screenshot: ${JSON.stringify({ route, priorRoute, currentText, priorText, busyClass, expectedClass })}`);
  }
  return JSON.stringify({ route, prior_route: priorRoute, current_text: currentText, prior_text: priorText, busy_class: expectedClass, class_list: busyClass });
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
    assertions.push(await assertObserved("protected deletion names the exact validation cause and the recovery action", text, (value) => String(value).includes("Type the name exactly as shown to confirm.") && String(value).includes(name)));
    assertions.push(await assertObserved("protected deletion retains the saved row", await page.locator(".ops-saved-search-row").count(), (value) => value > 0));
    await expect(input).toBeFocused();
    assertions.push(await assertObserved("protected deletion keeps the real recovery dialog open with the confirmation input focused", JSON.stringify({ dialogVisible: await dialog.isVisible(), focused: await input.evaluate((node) => document.activeElement === node), exactName: name }), (value) => {
      const result = JSON.parse(String(value));
      return result.dialogVisible === true && result.focused === true && result.exactName === name;
    }));
    transport.push({ operation: "protected-delete-validation", outcome: `server rejected mismatched name; role=alert text=${text}; row retained` });
    return input;
  }
  if (element === "E3") {
    await page.goto("/admin/search/phase173/health?scenario=refresh-failure");
    await waitForLiveConnected(page);
    await page.locator("#search-health-refresh").click();
    const alert = page.getByTestId("posture-row").filter({ hasText: "Phase173FixtureSchema" }).first();
    await expect(alert).toBeVisible();
    const text = (await alert.innerText()).trim();
    const recovery = page.getByRole("button", { name: "Refresh search health", exact: true });
    assertions.push(await assertObserved("real health refresh failure names the backend error and keeps the explicit retry action", JSON.stringify({ text, recoveryVisible: await recovery.isVisible(), recoveryEnabled: await recovery.isEnabled() }), (value) => {
      const result = JSON.parse(String(value));
      return result.text.includes("phase173_backend_unavailable") && result.text.includes("Search health could not be checked") && result.recoveryVisible && result.recoveryEnabled;
    }));
    transport.push({ operation: "health-refresh", outcome: `actual Phase173FixtureSource task-history error phase173_backend_unavailable; enabled recovery action Refresh search health; row=${text}` });
    return recovery;
  }
  const main = page.locator("[data-phx-main]");
  const priorHeading = (await primaryHeading(page, element)).innerText();
  const priorHeadingText = (await priorHeading).trim();
  const priorText = await main.innerText();
  await page.evaluate(() => (window as Window & { liveSocket?: { disconnect: () => void } }).liveSocket?.disconnect());
  await expect(page.locator("#client-error")).toBeVisible({ timeout: 10_000 });
  const errorText = (await page.locator("#client-error").innerText()).trim();
  assertions.push(await assertObserved("LiveView transport failure names the actual connectivity cause and recovery state", errorText, (value) => String(value).includes("We can't find the internet") && String(value).includes("Attempting to reconnect")));
  assertions.push(await assertObserved("transport loss retains the existing product observation", await primaryHeading(page, element).then((heading) => heading.innerText()), (value) => String(value).trim() === priorHeadingText));
  assertions.push(await assertObserved("transport loss retains prior content", await main.innerText(), (value) => value === priorText));
  transport.push({ operation: "liveview-websocket", outcome: `actual disconnected state displayed: ${errorText}; product route and prior content retained for capture` });
  return main;
}

async function assertLongText(page: Page, element: ElementId, assertions: Assertion[], actions: string[], transport: Transport[]): Promise<Locator> {
  const longName = savedSearchName(element, "long-text");
  let locator: Locator;
  if (element === "E3" || element === "E7") {
    await page.goto("/admin/search/phase173/health?scenario=long");
    await waitForLiveConnected(page);
    locator = page.getByTestId("posture-row");
    const text = await locator.allInnerTexts();
    assertions.push(await assertObserved("health keeps the actual long schema identifiers in the rendered rows", text.join("\n"), (value) => String(value).includes("IntentionallyLongName") || String(value).includes("IntentionallyLong")));
  } else if (element === "E2") {
    await page.goto("/admin/search");
    await waitForLiveConnected(page);
    locator = page.getByTestId("control-room-verdict");
    const text = await locator.innerText();
    assertions.push(await assertObserved("Control Room retains the exact schema identifier and failed-job count in its operational evidence", text, (value) => String(value).includes("ScrypathEcommerce.Catalog.Product") && String(value).includes("5 sync jobs failed")));
  } else if (element === "E4") {
    await page.goto("/admin/search/failed-sync");
    await waitForLiveConnected(page);
    locator = page.getByTestId("failed-sync-reason");
    const reasons = await locator.allInnerTexts();
    assertions.push(await assertObserved("failed-work details keep an exact backend cause available", reasons.join("\n"), (value) => String(value).includes("invalid_state: index is processing a settings update and rejected the batch")));
  } else if (element === "E5" || element === "E10") {
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
    await expect(schemaChoice).toBeChecked();
    await expect(alternateChoice).not.toBeChecked();
    actions.push("change the actual Sync and index schema radio from Variant to Product through its LiveView handler");
    transport.push({ operation: "sync-schema-selection", outcome: `Variant then Product; final_route=${new URL(page.url()).pathname + new URL(page.url()).search}` });
    const selectedSchemaState = JSON.stringify({ text: await locator.innerText(), product_selected: await schemaChoice.isChecked(), variant_selected: await alternateChoice.isChecked() });
    assertions.push(await assertObserved("actual Sync and index route keeps the full canonical schema identifier visible and selected at the narrow viewport", selectedSchemaState, (value) => {
      const result = JSON.parse(String(value));
      return result.text.includes("ScrypathEcommerce.Catalog.Product") && result.product_selected === true && result.variant_selected === false;
    }));
  } else {
    const query = `${"phase185-long-query-".repeat(8)}🔬東京`;
    locator = element === "E1" ? page.getByLabel("Search products") : page.getByLabel("Search text");
    await locator.fill(query);
    await expect(locator).not.toHaveClass(/phx-change-loading/, { timeout: 20_000 });
    await waitForLiveConnected(page);
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
  assertions: Assertion[], transport: Transport[], target: Locator, theme: typeof THEMES[number], widths: number[], fontProfile: Record<string, unknown>,
  timerProof: { fired: boolean; elapsed_ms: number; observed_date: string }, pendingCheck?: () => Promise<void>, preferredInteractionTarget?: Locator): Promise<{ common: Record<string, unknown>; observations: Record<string, unknown>[] }> {
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
  const browserSourceLayer = process.env.E2E_BROWSER_SOURCE_LAYER_ID || "";
  const browserBaseLayers = process.env.E2E_BROWSER_BASE_LAYERS_SHA256 || "";
  if (!/^[a-f0-9]{40}$/.test(sourceSha) || !/^[a-f0-9]{40}$/.test(buildSha) || !/^sha256:[a-f0-9]{64}$/.test(productTreeSha) || !/^sha256:[a-f0-9]{64}$/.test(fixtureSha) || !/^sha256:[a-f0-9]{64}$/.test(appId) || !/^sha256:[a-f0-9]{64}$/.test(standaloneOpsId) || !/^sha256:[a-f0-9]{64}$/.test(browserId) || !/^sha256:[a-f0-9]{64}$/.test(effectiveRuntime) || !/^sha256:[a-f0-9]{64}$/.test(browserSourceLayer) || !/^sha256:[a-f0-9]{64}$/.test(browserBaseLayers)) {
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
  if (observedProfile.color_scheme !== (theme === "light" ? "light" : "dark")) throw new Error(`Actual browser color scheme differs from the case theme: ${JSON.stringify(observedProfile)}`);
  const observedTheme = await page.locator("html").evaluate((node) => ({
    preference: (node as HTMLElement).dataset.themePreference,
    effective: (node as HTMLElement).dataset.themeEffective
  }));
  const expectedPreference = theme === "system-dark" ? "system" : theme;
  const expectedEffective = theme === "light" ? "light" : "dark";
  if (observedTheme.preference !== expectedPreference || observedTheme.effective !== expectedEffective) throw new Error(`Actual product theme differs from requested preference: ${JSON.stringify(observedTheme)}`);
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
    operational_scenarios: ["all_green", "degraded", "incident", "empty", "phase185_partial_catalog", "phase185_one_failed"],
    saved_search_prefix: "phase185-heldout-",
    case_reset: {
      protocol: "phase185-case-reset-v1",
      scenario: "phase185_case_reset",
      tables: [...PHASE185_RESET_TABLES],
      identities: { next_id: 1, is_called: false }
    },
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
  if (clockRecipe.browser_date.observed !== clock.instant || timerProof.observed_date !== clock.instant) throw new Error("The browser Date does not match the immutable mounted clock fixture.");
  const sharedRecipe = {
    ...clockRecipe,
    browser_date: { fixed: true, timers_running: timerProof.fired, observed: clockRecipe.browser_date.observed }
  };
  const recipeSha = `sha256:${digest(JSON.stringify(canonicalize(sharedRecipe)))}`;
  const runtime = { application_image_id: appId, standalone_ops_image_id: standaloneOpsId, browser_image_id: browserId, effective_runtime_sha256: effectiveRuntime, browser_source_layer_id: browserSourceLayer, browser_base_layers_sha256: browserBaseLayers };
  const common = {
    product_source_sha: sourceSha,
    build_source_sha: buildSha,
    product_tree_sha256: productTreeSha,
    fixture_overlay_sha256: fixtureSha,
    recipe_sha256: recipeSha,
    clock_recipe: clockRecipe,
    data_recipe: dataRecipe,
    runtime,
    clock_artifact: { path: clockArtifact, sha256: digest(clockBytes) }
  };
  const { captureStableImage, captureUiStateInPage } = await import("../ui-review.mjs");
  const copyNodes = ["main", "#client-error", "[data-testid='storefront-results']", "[data-testid='control-room-verdict']", "[data-testid='posture-row']", "[data-testid='failed-sync-row']", ".ops-saved-search-row", "#saved-searches", "#search-form", "#sync-pipeline-status", "#index-settings-status"];
  const observations: Record<string, unknown>[] = [];
  for (const width of widths) {
    const height = width === 390 ? 844 : 900;
    await page.setViewportSize({ width, height });
    await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
    const observed = await page.evaluate(() => ({ width: innerWidth, height: innerHeight, dpr: devicePixelRatio, scrollX, scrollY, documentWidth: document.documentElement.scrollWidth, documentHeight: document.documentElement.scrollHeight }));
    const observationAssertions: Assertion[] = [];
    observationAssertions.push(await assertObserved(`document has no viewport-wide horizontal overflow at ${width}px`, observed.documentWidth, (value) => value <= width));

    const candidates = [
      ...(preferredInteractionTarget ? [preferredInteractionTarget] : []),
      target,
      page.locator("main a[href]:visible, main button:not([disabled]):visible, a[href]:visible, button:not([disabled]):visible").first(),
      page.locator("main input:not([disabled]):visible, main select:not([disabled]):visible, main textarea:not([disabled]):visible").first()
    ];
    let interaction: Locator | null = null;
    let interactionIdentity: { tag: string; role: string | null; name: string | null; href: string | null } | null = null;
    for (const candidate of candidates) {
      if (await candidate.count() === 0) continue;
      if (!(await candidate.isVisible().catch(() => false)) || !(await candidate.isEnabled().catch(() => false))) continue;
      const identity = await candidate.evaluate(captureUiStateInPage) as typeof interactionIdentity;
      if (identity && ["a", "button", "input", "select", "textarea"].includes(identity.tag) && typeof identity.name === "string" && identity.name.trim()) {
        interaction = candidate;
        interactionIdentity = identity;
        break;
      }
    }
    if (!interaction || !interactionIdentity) throw new Error(`${element} ${category} has no visible, named real product control for keyboard and hover evidence.`);
    await interaction.hover();
    await interaction.focus();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");
    await expect(interaction).toBeFocused();
    const domState = await page.evaluate(captureUiStateInPage) as Record<string, any>;
    const focus = domState.focus;
    if (JSON.stringify(focus.element) !== JSON.stringify(interactionIdentity) || focus.focus_visible !== true || domState.document_has_focus !== true || !domState.hover.some((entry: any) => JSON.stringify(entry.element) === JSON.stringify(interactionIdentity))) {
      throw new Error(`${element} ${category} lacks actual keyboard focus-visible and hover state for its named control: ${JSON.stringify({ focus, hover: domState.hover, interactionIdentity })}`);
    }
    const focusRect = focus.rect;
    if (!focusRect || focusRect.width <= 0 || focusRect.height <= 0) throw new Error(`${element} ${category} focus target has no positive visible rectangle.`);
    observationAssertions.push(await assertObserved("actual named product control has keyboard focus-visible and pointer-hover state", JSON.stringify({ interactionIdentity, focus, document_has_focus: domState.document_has_focus, hover: domState.hover }), (value) => {
      const result = JSON.parse(String(value));
      return result.focus.element.name === result.interactionIdentity.name && result.focus.focus_visible && result.document_has_focus && result.hover.some((entry: any) => entry.element.name === result.interactionIdentity.name);
    }));

    const geometry: Record<string, number | string>[] = [];
    const box = await target.boundingBox();
    if (box) geometry.push({ name: `case-target-${width}`, x: box.x, y: box.y, width: box.width, height: box.height, viewport_width: width });
    const interactionBox = await interaction.boundingBox();
    if (interactionBox) geometry.push({ name: `interaction-target-${width}`, x: interactionBox.x, y: interactionBox.y, width: interactionBox.width, height: interactionBox.height, viewport_width: width });
    for (const [name, selector] of [["shell", ".ops-shell-frame"], ["shell-content", ".ops-shell-content"], ["header", ".ops-header"], ["main", "main"]] as const) {
      const anchor = page.locator(selector).first();
      const anchorBox = await anchor.count() ? await anchor.boundingBox().catch(() => null) : null;
      if (anchorBox) geometry.push({ name: `${name}-${width}`, x: anchorBox.x, y: anchorBox.y, width: anchorBox.width, height: anchorBox.height, viewport_width: width });
    }
    geometry.push({ name: `document-${width}`, x: 0, y: 0, width: observed.documentWidth, height: observed.documentHeight, viewport_width: width });
    const visibleCopy: { text: string; sha256: string }[] = [];
    for (const selector of copyNodes) {
      const node = page.locator(selector).first();
      if (await node.count() && await node.isVisible().catch(() => false)) {
        const text = (await node.innerText().catch(() => "")).trim();
        if (text) visibleCopy.push({ text, sha256: digest(text) });
      }
    }
    if (visibleCopy.length === 0) throw new Error(`${element} ${category} has no actual visible product copy for ${theme} at ${width}px.`);
    const focusName = focus.element?.name || "";
    const route = new URL(page.url()).pathname + new URL(page.url()).search;
    const observationState = {
      element, category, route, theme, color_scheme: observedProfile.color_scheme,
      viewport: { width: observed.width, height: observed.height },
      scroll: { x: observed.scrollX, y: observed.scrollY },
      focus: { name: focusName, role: focus.element?.role ?? null, tag: focus.element?.tag ?? null, focus_visible: focus.focus_visible, outline: focus.outline, opacity: focus.opacity, document_has_focus: domState.document_has_focus },
      interaction_target: interactionIdentity,
      data_identity: dataIdentity,
      clock: { browser_iso: clockRecipe.browser_date.observed, server_iso: clock.instant, clock_sha256: clock.sha256 },
      dom_state_sha256: digest(JSON.stringify(canonicalize(domState)))
    };
    if (!focusName.trim()) throw new Error(`${element} ${category} focus evidence has no actual accessible name.`);

    const stabilitySamples: { path: string; bytes: Buffer; state_path: string; state_bytes: Buffer }[] = [];
    let captureSampling: Record<string, any> | undefined;
    let bytes: Buffer;
    const captureId = `${safe(element)}-${safe(category)}-${safe(theme)}-${width}`;
    try {
      const stable = await captureStableImage({
        page,
        id: captureId,
        kind: "held-out",
        captureImage: async ({ timeout }) => {
          await pendingCheck?.();
          const image = await page.screenshot({ fullPage: true, animations: "disabled", timeout });
          await pendingCheck?.();
          return image;
        },
        saveSample: async ({ path: samplePath, bytes: sampleBytes, state_path: statePath, state_bytes: stateBytes }) => {
          if (sampleBytes) stabilitySamples.push({ path: samplePath, bytes: sampleBytes, state_path: statePath, state_bytes: stateBytes });
        }
      });
      bytes = stable.image;
      captureSampling = stable.stability;
      const stabilityVerified = stable.stability.method === "consecutive-exact-v1" &&
        stable.stability.max_samples === 6 && stable.stability.max_elapsed_ms === 10_000 &&
        stable.stability.samples.length >= 2 && stable.stability.samples.length <= 6 &&
        stable.stability.selected === stable.stability.samples.length - 1;
      if (!stabilityVerified) throw new Error(`${element} ${category} capture returned proof outside the strict stationary image contract: ${JSON.stringify(stable.stability)}`);
      assertions.push({ name: `held-out state and raw image are stationary at ${width}px`, status: "passed", actual: JSON.stringify({ method: "consecutive-exact-v1", max_samples: 6, max_elapsed_ms: 10_000, verified: true }) });
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
    const afterCapture = await page.evaluate(captureUiStateInPage) as Record<string, any>;
    if (JSON.stringify(canonicalize(domState)) !== JSON.stringify(canonicalize(afterCapture))) throw new Error(`${element} ${category} DOM state changed after the stationary raw screenshot capture.`);
    if (!captureSampling) throw new Error(`${element} ${category} stationary raw screenshot is missing its per-run sample proof.`);
    const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
    if (bytes.length < 24 || !bytes.subarray(0, 8).equals(pngSignature)) throw new Error(`${element} ${category} capture is not a raw PNG with a complete IHDR.`);
    const fullPageRaster = { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
    if (fullPageRaster.width !== width || fullPageRaster.height !== observed.documentHeight) throw new Error(`${element} ${category} raw full-page PNG dimensions differ from measured viewport/document geometry: ${JSON.stringify({ fullPageRaster, observed })}`);
    const relative = `ui-review-artifacts/iteration3-journeys/phase185-held-out/${captureId}.png`;
    const absolute = path.join(artifactRoot, "phase185-raw-staging", relative);
    await mkdir(path.dirname(absolute), { recursive: true });
    await writeFile(absolute, bytes, { flag: "wx" });
    const image = { path: relative, sha256: digest(bytes), viewport: { width, height }, full_page_raster: fullPageRaster, capture: "full-page-real-product-state" };
    const receiptAssertions = [...observationAssertions,
      await assertObserved("raw full-page PNG raster exactly matches actual viewport and measured document dimensions", JSON.stringify({ fullPageRaster, document: { width: observed.documentWidth, height: observed.documentHeight }, viewport: { width, height } }), (value) => {
        const result = JSON.parse(String(value));
        return result.fullPageRaster.width === result.viewport.width && result.fullPageRaster.height === result.document.height;
      }),
      { name: "actual product theme preference and effective theme match the requested recipe", status: "passed", actual: JSON.stringify({ theme, ...observedTheme, color_scheme: observedProfile.color_scheme }) }
    ];
    observations.push({ theme, viewport: { width, height }, state: observationState, geometry, assertions: receiptAssertions, visible_copy: visibleCopy, transport_sequence: transport.map((step) => ({ ...step })), capture_sampling: captureSampling, image, images: [image] });
  }
  return { common, observations };
}

export async function runPreservationCase(args: {
  browser: Browser; request: Parameters<typeof seedScenario>[0]; testInfo: TestInfo; element: ElementId; category: Category;
}): Promise<void> {
  const { browser, request, testInfo, element, category } = args;
  const host = new URL(targetUrl);
  if (host.protocol !== "http:" || host.hostname !== "web" || host.port !== "4002") throw new Error(`Held-out capture refuses non-disposable product target ${targetUrl}.`);
  if (!artifactRoot || !evidencePath || !(process.env.E2E_RUN_ID || "").startsWith("phase185-")) {
    throw new Error("Held-out state seeding requires the phase185-gated disposable server, clock fixture and evidence directory.");
  }
  await fixedClock();
  const dataIdentity = await initializeData(element, category, request);
  const isGridCase = category === "overflow" || category === "long-text";
  const captureThemes = isGridCase ? [...THEMES] : [themeFor(element, category)];
  const widths = isGridCase ? [...REQUIRED_WIDTHS] : [1440];
  const observations: Record<string, any>[] = [];
  const allAssertions: Assertion[] = [];
  let common: Record<string, any> | null = null;
  const actions = ["seed deterministic test data once through the existing dev/test application API", "navigate to the actual product route or declared shared component boundary", "exercise the real interaction/state and inspect actual rendered output"];
  const transports: Transport[] = [];
  for (const theme of captureThemes) {
    const context = await browser.newContext({ baseURL: targetUrl, viewport: { width: widths[0], height: 900 }, locale: "en-US", timezoneId: "UTC", deviceScaleFactor: 1, colorScheme: theme === "light" ? "light" : "dark" });
    const page = await context.newPage();
    const assertions: Assertion[] = [];
    const transport: Transport[] = [];
    let font: { profile: Record<string, unknown>; session: { detach: () => Promise<void> } } | null = null;
    let pendingCheck: (() => Promise<void>) | undefined;
    let preferredInteractionTarget: Locator | undefined;
    try {
      await setTheme(context, theme);
      const clock = await fixedClock();
      await page.clock.setFixedTime(new Date(clock.instant));
      const timerProof = await verifyFixedDateLeavesTimersRunning(page, clock.instant);
      assertions.push(await assertObserved("browser Date is fixed while a real timer callback fires", JSON.stringify({ fixed_date: timerProof.observed_date, timer_fired: timerProof.fired, minimum_elapsed_threshold_met: timerProof.elapsed_ms >= 20 }), (value) => {
        const result = JSON.parse(String(value));
        return result.fixed_date === clock.instant && result.timer_fired === true && result.minimum_elapsed_threshold_met === true;
      }));
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
          const pending = await assertActionLoading(page, element);
          target = pending.target;
          transport.push(...pending.transport);
          pendingCheck = () => assertPendingState(page, element, target, pending.priorRoute, pending.priorText).then(() => undefined);
          const pendingObservation = await assertPendingState(page, element, target, pending.priorRoute, pending.priorText);
          assertions.push(await assertObserved(`${element} retains its exact route and prior visible content while the actual busy marker is active`, pendingObservation, (value) => {
            const state = JSON.parse(String(value));
            return state.route === state.prior_route && state.current_text === state.prior_text && state.busy_class.includes("phx-");
          }));
          actions.push("issue actual LiveView navigation or action with the bounded browser transport latency harness");
        } else {
          const priorRoute = new URL(page.url()).pathname + new URL(page.url()).search;
          const priorText = await page.locator("[data-phx-main]").innerText();
          await page.evaluate(() => (window as Window & { liveSocket?: { enableLatencySim: (ms: number) => void } }).liveSocket?.enableLatencySim(1400));
          const action = element === "E1" ? page.getByLabel("Search products") : element === "E2" ? page.locator("#control-room-refresh") : element === "E3" ? page.locator("#search-health-refresh") : element === "E4" ? page.locator("#failed-sync-refresh") : element === "E5" ? page.getByRole("button", { name: /Load .+/ }).first() : page.locator("#sync-and-index-refresh");
          target = action;
          if (element === "E1") await action.fill("quantum"); else await action.click();
          const loadingClass = element === "E1" ? /phx-change-loading/ : /phx-click-loading/;
          await expect(action).toHaveClass(loadingClass, { timeout: 1_200 });
          pendingCheck = () => assertPendingState(page, element, action, priorRoute, priorText).then(() => undefined);
          const pendingObservation = await assertPendingState(page, element, action, priorRoute, priorText);
          assertions.push(await assertObserved(`${element} retains prior product copy and the actual busy marker during an outstanding LiveView request`, JSON.stringify({ pendingObservation, visible: await action.isVisible(), disabled: await action.isDisabled() }), (value) => {
            const state = JSON.parse(String(value));
            const observation = JSON.parse(state.pendingObservation);
            return observation.route === observation.prior_route && observation.current_text === observation.prior_text && observation.busy_class.includes("phx-") && state.visible === true;
          }));
          transport.push({ operation: `${element.toLowerCase()}-liveview-action`, outcome: `still pending before each image sample; prior content retained; busy class=${loadingClass}` });
          actions.push("issue the actual product LiveView read/action and retain its pending transport state through every image sample");
        }
      } else if (category === "error") {
        target = await assertTransportError(page, element, assertions, transport);
        if (element === "E3") preferredInteractionTarget = target;
        if (element === "E10") preferredInteractionTarget = target;
        actions.push("cause an actual backend failure, protected validation rejection, or LiveView disconnect and verify its specific cause and recovery state");
      } else if (category === "long-text") {
        target = await assertLongText(page, element, assertions, actions, transport);
        actions.push("render and inspect the exact long product identifier, query, saved name, failure detail or Help copy");
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
          preferredInteractionTarget = confirmation;
          assertions.push(await assertObserved("overflow case reaches the real exact-name deletion confirmation", await page.locator("#saved-search-delete-form").innerText(), (value) => String(value).includes("It can't be undone") && String(value).includes(name)));
          target = page.locator("#saved-search-delete-form");
        } else if (element === "E8") {
          const helpLink = page.getByRole("link", { name: "Open Search", exact: true });
          await helpLink.hover();
          preferredInteractionTarget = helpLink;
          assertions.push(await assertObserved("Help navigation link remains visible after pointer hover", await helpLink.isVisible(), (value) => value === true));
        } else {
          await target.hover();
        }
        actions.push("observe this actual product state at 1440, 768 and 390 pixels in light, dark and system-dark themes");
      }
      if (category === "long-text" && element === "E8") {
        const helpLink = page.getByRole("link", { name: "Manage saved searches", exact: true });
        await helpLink.focus();
        preferredInteractionTarget = helpLink;
        assertions.push(await assertObserved("Help navigation target retains its exact accessible name", await helpLink.getAttribute("aria-label") || "Manage saved searches", (value) => String(value).trim() === "Manage saved searches"));
        actions.push("focus the existing Help topic link and retain its accessible name");
      }
      if (category === "long-text" && element === "E6") preferredInteractionTarget = page.getByRole("radio", { name: /ScrypathEcommerce\.Catalog\.Product/ });
      const mainText = await page.locator("[data-phx-main]").innerText();
      assertions.push(await assertObserved("actual product/component content remains rendered for evidence", mainText, (value) => String(value).trim().length > 0));
      const capture = await captureActualState(page, testInfo, element, category, dataIdentity, assertions, transport, target, theme, widths, font.profile, timerProof, pendingCheck, preferredInteractionTarget);
      const comparableCommon = (value: Record<string, any>) => {
        const recipe = value.clock_recipe;
        const { timer_elapsed_ms: _elapsed, ...browserDate } = recipe.browser_date;
        return canonicalize({ ...value, clock_recipe: { ...recipe, browser_date: browserDate } });
      };
      if (common && JSON.stringify(comparableCommon(common)) !== JSON.stringify(comparableCommon(capture.common))) throw new Error("Theme-specific captures changed the common source, runtime, clock, or data recipe beyond the independently measured timer elapsed time.");
      common = capture.common;
      observations.push(...capture.observations);
      allAssertions.push(...assertions);
      transports.push(...transport);
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
  if (!common || observations.length !== (isGridCase ? 9 : 1)) throw new Error(`${element} ${category} produced ${observations.length} observations; expected ${isGridCase ? 9 : 1}.`);
  const aggregateAssertions = observations.flatMap((observation) => observation.assertions as Assertion[]);
  const aggregateGeometry = observations.flatMap((observation) => observation.geometry as Record<string, number | string>[]);
  const aggregateCopy = observations.flatMap((observation) => observation.visible_copy as { text: string; sha256: string }[]);
  const aggregateImages = observations.map((observation) => observation.image);
  const firstState = observations[0].state;
  const receipt = {
    operation: "ui_preservation_case",
    case_id: `${element} ${category}`,
    test_identity: JSON.stringify([`examples/scrypath_ecommerce/${path.relative(process.cwd(), testInfo.file).split(path.sep).join("/")}`, "chromium", testInfo.titlePath, "shared"]),
    ...common,
    state: firstState,
    actions: [...new Set(actions)],
    transport_sequence: transports,
    geometry: aggregateGeometry,
    assertions: [...allAssertions, ...aggregateAssertions],
    visible_copy: aggregateCopy,
    images: aggregateImages,
    observations
  };
  await appendFile(evidencePath, `${JSON.stringify(receipt)}\n`, { flag: "a" });
}
