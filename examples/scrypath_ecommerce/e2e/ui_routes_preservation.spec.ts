import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { expect, test, type Browser, type Response } from "@playwright/test";
import { waitForLiveConnected } from "./helpers/e2e";
import { guardVerificationTarget } from "./helpers/verification-target.mjs";

const standaloneBaseUrl =
  process.env.PHASE173_STANDALONE_BASE_URL || "http://127.0.0.1:4014";

async function maintainedOpsRoutes(): Promise<{ mounted: string[]; standalone: string[] }> {
  const source = await readFile(join(process.cwd(), "e2e", "ui-review.mjs"), "utf8");
  const surfacesBlock = source.match(/export const surfaces = \[([\s\S]*?)\n\];/)?.[1];
  const standaloneBlock = source.match(/export const standaloneRoutes = \{([\s\S]*?)\n\};/)?.[1];

  if (!surfacesBlock || !standaloneBlock) {
    throw new Error("Could not read the maintained UI capture route inventory.");
  }

  const surfaces = [...surfacesBlock.matchAll(/\{ id: "([^"]+)", route: "([^"]+)"/g)].map(
    ([, id, route]) => ({ id, route })
  );
  const standalone = new Map(
    [...standaloneBlock.matchAll(/^\s*(?:"([^"]+)"|([\w-]+)):\s*"([^"]+)"/gm)].map(
      ([, quotedId, bareId, route]) => [quotedId || bareId, route]
    )
  );
  const ops = surfaces.filter(({ id }) => id !== "storefront");

  if (ops.length === 0 || ops.some(({ id }) => !standalone.has(id))) {
    throw new Error("The maintained UI capture inventory is missing an Ops route mapping.");
  }

  return {
    mounted: ops.map(({ route }) => route),
    standalone: ops.map(({ id }) => standalone.get(id) as string)
  };
}

async function expectBrowserLoadedAssets(
  browser: Browser,
  baseUrl: string,
  route: string,
  assets: Array<{ path: string; type: string; resourceType: string }>
): Promise<void> {
  const page = await browser.newPage();
  const origin = new URL(baseUrl).origin;
  const expectedPaths = new Set(assets.map(asset => asset.path));
  const responses = new Map<string, Response>();
  const recordResponse = (response: Response) => {
    const url = new URL(response.url());
    if (url.origin === origin && expectedPaths.has(url.pathname)) {
      responses.set(url.pathname, response);
    }
  };

  page.on("response", recordResponse);
  try {
    const navigation = await page.goto(new URL(route, baseUrl).toString());
    expect(navigation?.status(), `browser navigation ${route}`).toBe(200);

    for (const asset of assets) {
      const response = responses.get(asset.path);
      if (!response) throw new Error(`Browser navigation did not request linked asset ${asset.path}.`);
      expect(response.status(), asset.path).toBe(200);
      expect(response.request().resourceType(), asset.path).toBe(asset.resourceType);
      expect(response.headers()["content-type"], asset.path).toContain(asset.type);
      expect((await response.body()).byteLength, asset.path).toBeGreaterThan(0);
    }

    await waitForLiveConnected(page);
  } finally {
    await page.close();
  }
}

test.beforeEach(async ({ baseURL }) => {
  await guardVerificationTarget(baseURL, reason => test.skip(true, reason), async () => {});
});

test("standalone root redirects locally before the operator route is followed", async ({
  page,
  request
}) => {
  const rootResponse = await request.get(new URL("/", standaloneBaseUrl).toString(), {
    maxRedirects: 0
  });

  expect(rootResponse.status()).toBe(302);
  expect(rootResponse.headers().location).toBe("/ops");

  await page.goto(new URL("/ops/", standaloneBaseUrl).toString());
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room", exact: true })).toBeVisible();
});

test("mounted and standalone Ops route inventories remain reachable at their existing prefixes", async ({
  request,
  baseURL
}) => {
  const hostBaseUrl = baseURL || "http://127.0.0.1:4002";
  const routes = await maintainedOpsRoutes();

  for (const route of routes.mounted) {
    const response = await request.get(new URL(route, hostBaseUrl).toString(), {
      maxRedirects: 0
    });

    expect(response.status(), `mounted route ${route}`).toBe(200);
    expect(response.headers()["content-type"], `mounted route ${route} content type`).toContain(
      "text/html"
    );
    expect(new URL(response.url()).pathname, `mounted route ${route} stayed under its prefix`).toBe(
      new URL(route, hostBaseUrl).pathname
    );
    expect(await response.text(), `mounted route ${route} rendered a LiveView`).toContain(
      "data-phx-main"
    );
  }

  for (const route of routes.standalone) {
    const response = await request.get(new URL(route, standaloneBaseUrl).toString(), {
      maxRedirects: 0
    });

    expect(response.status(), `standalone route ${route}`).toBe(200);
    expect(response.headers()["content-type"], `standalone route ${route} content type`).toContain(
      "text/html"
    );
    expect(
      new URL(response.url()).pathname,
      `standalone route ${route} stayed under its prefix`
    ).toBe(new URL(route, standaloneBaseUrl).pathname);
    expect(await response.text(), `standalone route ${route} rendered a LiveView`).toContain(
      "data-phx-main"
    );
  }
});

test("host root remains the public storefront", async ({ page, request, baseURL }) => {
  const hostBaseUrl = baseURL || "http://127.0.0.1:4002";
  const rootResponse = await request.get(new URL("/", hostBaseUrl).toString(), {
    maxRedirects: 0
  });

  expect(rootResponse.status()).toBe(200);

  await page.goto("/");
  await waitForLiveConnected(page);

  await expect(page).toHaveURL(new URL("/", hostBaseUrl).toString());
  await expect(page.locator("body")).toHaveClass(/scrypath-demo/);
  await expect(
    page.getByRole("heading", { level: 1, name: "Tenant-scoped catalog search" })
  ).toBeVisible();
});

test("host, mounted Ops, and standalone Ops load their linked assets in the browser", async ({
  browser,
  request,
  baseURL
}) => {
  const hostBaseUrl = baseURL || "http://127.0.0.1:4002";
  const routes = await maintainedOpsRoutes();
  const hostAssets = [
    { path: "/assets/css/app.css", type: "text/css", resourceType: "stylesheet" },
    { path: "/assets/js/app.js", type: "javascript", resourceType: "script" }
  ];
  const mountedAssets = [
    ...hostAssets,
    {
      path: "/admin/search/assets/css/app.css",
      type: "text/css",
      resourceType: "stylesheet"
    }
  ];

  await expectBrowserLoadedAssets(browser, hostBaseUrl, "/", hostAssets);
  await expectBrowserLoadedAssets(browser, hostBaseUrl, routes.mounted[0], mountedAssets);
  await expectBrowserLoadedAssets(browser, standaloneBaseUrl, routes.standalone[0], hostAssets);

  // Both Ops routers keep cross-origin protection on their forwarded prefix
  // JavaScript routes; the actual layouts load their root-path assets above.
  for (const { baseUrl, path } of [
    { baseUrl: hostBaseUrl, path: "/admin/search/assets/js/app.js" },
    { baseUrl: standaloneBaseUrl, path: "/ops/assets/js/app.js" }
  ]) {
    const protectedScript = await request.get(new URL(path, baseUrl).toString(), {
      maxRedirects: 0
    });
    expect(protectedScript.status(), `${path} keeps direct-request JavaScript protection`).toBe(403);
  }
});
