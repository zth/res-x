const fs = require("fs");
const os = require("os");
const path = require("path");
const { pathToFileURL } = require("url");
const { describe, expect, test } = require("bun:test");
const TestUtils = require("./TestUtils.js");

async function getPluginTestHelpers() {
  return (await import("../res-x-vite-plugin.mjs")).__test;
}

async function withTempDir(run) {
  const tempDir = fs.mkdtempSync(
    path.join(os.tmpdir(), "resx-static-asset-routes-")
  );

  try {
    return await run(tempDir);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

async function importGeneratedModule(modulePath) {
  return import(`${pathToFileURL(modulePath).href}?t=${Date.now()}`);
}

async function withStaticAssetServer(routes, run) {
  const [port, releasePort] = TestUtils.getPort();
  const server = Bun.serve({
    development: true,
    port,
    routes,
    fetch: async request =>
      new Response(`app:${new URL(request.url).pathname}`, {
        status: 200,
      }),
  });

  try {
    return await run({
      baseUrl: `http://localhost:${port}`,
    });
  } finally {
    server.stop(true);
    releasePort();
  }
}

describe("static asset routes", () => {
  test("matches static asset route patterns", async () => {
    const { matchesStaticAssetRoutePattern } = await getPluginTestHelpers();

    expect(matchesStaticAssetRoutePattern("/assets/**", "/assets/app.css")).toBe(
      true
    );
    expect(
      matchesStaticAssetRoutePattern(
        "/assets/**",
        "/assets/images/icons/logo.svg"
      )
    ).toBe(true);
    expect(
      matchesStaticAssetRoutePattern("/assets/*", "/assets/app.css")
    ).toBe(true);
    expect(
      matchesStaticAssetRoutePattern(
        "/assets/*",
        "/assets/images/icons/logo.svg"
      )
    ).toBe(false);
    expect(matchesStaticAssetRoutePattern("/robots.txt", "/robots.txt")).toBe(
      true
    );
    expect(matchesStaticAssetRoutePattern("/robots.txt", "/favicon.ico")).toBe(
      false
    );
  });

  test("uses the last matching headers rule without merging", async () => {
    const { getStaticAssetRouteHeaders } = await getPluginTestHelpers();

    const headers = getStaticAssetRouteHeaders(
      {
        "/assets/**": {
          "Cache-Control": "public, max-age=31536000, immutable",
          "X-Base": "1",
        },
        "/assets/app.css": {
          "Cache-Control": "public, max-age=60",
        },
      },
      "/assets/app.css"
    );

    expect(headers).toEqual({
      "Cache-Control": "public, max-age=60",
    });
  });

  test("always emits exact routes for managed assets", async () => {
    const { buildStaticAssetRouteEntries, createStaticAssetRoutesConfig } =
      await getPluginTestHelpers();

    const exactEntries = buildStaticAssetRouteEntries({
      publicEntries: [
        {
          routePath: "/robots.txt",
          filePath: "./public/robots.txt",
        },
      ],
      assetEntries: [
        {
          routePath: "/assets/a.css",
          filePath: "./dist/assets/a.css",
        },
        {
          routePath: "/assets/b.css",
          filePath: "./dist/assets/b.css",
        },
      ],
      headers: createStaticAssetRoutesConfig().headers,
    });

    expect(exactEntries).toEqual([
      {
        routePath: "/robots.txt",
        filePath: "./public/robots.txt",
        headers: null,
      },
      {
        routePath: "/assets/a.css",
        filePath: "./dist/assets/a.css",
        headers: null,
      },
      {
        routePath: "/assets/b.css",
        filePath: "./dist/assets/b.css",
        headers: null,
      },
    ]);
  });

  test("rejects the removed assets config", async () => {
    const { createStaticAssetRoutesConfig } = await getPluginTestHelpers();

    expect(() =>
      createStaticAssetRoutesConfig({
        assets: {
          strategy: "exact",
        },
      })
    ).toThrow(
      "`staticAssetRoutes.assets` is no longer supported. ResX now always generates exact static asset routes. If you need a different asset loading strategy, implement your own asset pipeline."
    );
  });

  test("includes public assets under /assets routes", async () => {
    const { getDummyStaticAssetRoutesFile, createStaticAssetRoutesConfig } =
      await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const assetDir = path.join(tempDir, "assets");
      const publicDir = path.join(tempDir, "public");
      const resXClientPath = path.join(tempDir, "ResXClient.js");
      const modulePath = path.join(tempDir, "routes.mjs");

      fs.mkdirSync(assetDir, { recursive: true });
      fs.mkdirSync(path.join(publicDir, "assets"), { recursive: true });
      fs.writeFileSync(
        path.join(publicDir, "assets", "from-public.txt"),
        "public asset"
      );
      fs.writeFileSync(resXClientPath, "export {};\n");
      fs.writeFileSync(
        modulePath,
        getDummyStaticAssetRoutesFile(
          assetDir,
          publicDir,
          resXClientPath,
          createStaticAssetRoutesConfig()
        )
      );

      const { staticAssetRoutes } = await importGeneratedModule(modulePath);
      const response = staticAssetRoutes["/assets/from-public.txt"].GET;

      expect(await response.text()).toBe("public asset");
    });
  });

  test("generated exact routes serve correctly through Bun.serve", async () => {
    const { getDummyStaticAssetRoutesFile, createStaticAssetRoutesConfig } =
      await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const assetDir = path.join(tempDir, "assets");
      const publicDir = path.join(tempDir, "public");
      const resXClientPath = path.join(tempDir, "ResXClient.js");
      const modulePath = path.join(tempDir, "routes.mjs");

      fs.mkdirSync(assetDir, { recursive: true });
      fs.mkdirSync(path.join(publicDir, "assets"), { recursive: true });
      fs.writeFileSync(path.join(assetDir, "app.css"), "body { color: red; }");
      fs.writeFileSync(path.join(publicDir, "robots.txt"), "User-agent: *");
      fs.writeFileSync(
        path.join(publicDir, "assets", "from-public.txt"),
        "public asset"
      );
      fs.writeFileSync(resXClientPath, "export {};\n");
      fs.writeFileSync(
        modulePath,
        getDummyStaticAssetRoutesFile(
          assetDir,
          publicDir,
          resXClientPath,
          createStaticAssetRoutesConfig({
            headers: {
              "/assets/**": {
                "Cache-Control": "public, max-age=31536000, immutable",
              },
              "/robots.txt": {
                "Cache-Control": "public, max-age=300",
              },
            },
          })
        )
      );

      const { staticAssetRoutes } = await importGeneratedModule(modulePath);
      const routes = Object.assign(
        {
          "/health": {
            GET: new Response("ok"),
          },
        },
        staticAssetRoutes
      );

      await withStaticAssetServer(routes, async ({ baseUrl }) => {
        const robotsResponse = await fetch(`${baseUrl}/robots.txt`);
        expect(robotsResponse.status).toBe(200);
        expect(robotsResponse.headers.get("cache-control")).toBe(
          "public, max-age=300"
        );
        expect(await robotsResponse.text()).toBe("User-agent: *");

        const assetResponse = await fetch(`${baseUrl}/assets/app.css`);
        expect(assetResponse.status).toBe(200);
        expect(assetResponse.headers.get("cache-control")).toBe(
          "public, max-age=31536000, immutable"
        );
        expect(await assetResponse.text()).toBe("body { color: red; }");

        const publicAssetResponse = await fetch(
          `${baseUrl}/assets/from-public.txt`
        );
        expect(publicAssetResponse.status).toBe(200);
        expect(await publicAssetResponse.text()).toBe("public asset");

        const healthResponse = await fetch(`${baseUrl}/health`);
        expect(healthResponse.status).toBe(200);
        expect(await healthResponse.text()).toBe("ok");

        const appResponse = await fetch(`${baseUrl}/app`);
        expect(appResponse.status).toBe(200);
        expect(await appResponse.text()).toBe("app:/app");
      });
    });
  });

  test("generated exact routes apply configured headers", async () => {
    const { getStaticAssetRoutesFileContent } = await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const robotsPath = path.join(tempDir, "robots.txt");
      const modulePath = path.join(tempDir, "routes.mjs");

      fs.writeFileSync(robotsPath, "/\nDisallow: *");
      fs.writeFileSync(
        modulePath,
        getStaticAssetRoutesFileContent({
          exactEntries: [
            {
              routePath: "/robots.txt",
              filePath: robotsPath,
              headers: {
                "Cache-Control": "public, max-age=300",
              },
            },
          ],
        })
      );

      const { staticAssetRoutes } = await importGeneratedModule(modulePath);
      const response = staticAssetRoutes["/robots.txt"].GET;

      expect(response.headers.get("cache-control")).toBe("public, max-age=300");
      expect(await response.text()).toBe("/\nDisallow: *");
    });
  });

  test("generated exact routes serve zero-byte files", async () => {
    const { getStaticAssetRoutesFileContent } = await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const emptyPath = path.join(tempDir, "empty.txt");
      const modulePath = path.join(tempDir, "routes.mjs");

      fs.writeFileSync(emptyPath, "");
      fs.writeFileSync(
        modulePath,
        getStaticAssetRoutesFileContent({
          exactEntries: [
            {
              routePath: "/empty.txt",
              filePath: emptyPath,
              headers: null,
            },
          ],
        })
      );

      const { staticAssetRoutes } = await importGeneratedModule(modulePath);
      const response = staticAssetRoutes["/empty.txt"].GET;

      expect(response.status).toBe(200);
      expect(await response.text()).toBe("");
    });
  });

  test("generated exact routes resolve headers at build time", async () => {
    const { getStaticAssetRoutesFileContent } = await getPluginTestHelpers();

    const content = getStaticAssetRoutesFileContent({
      exactEntries: [
        {
          routePath: "/robots.txt",
          filePath: "./dist/robots.txt",
          headers: {
            "Cache-Control": "public, max-age=300",
          },
        },
      ],
    });

    expect(content.includes("matchStaticAssetRouteSegments")).toBe(false);
    expect(content.includes("getStaticAssetRouteHeaders(")).toBe(false);
    expect(content.includes("decodeWildcardStaticAssetPath")).toBe(false);
    expect(content.includes("const staticAssetHeaders0 =")).toBe(true);
    expect(
      content.includes(
        'new Response(Bun.file("./dist/robots.txt"), { headers: staticAssetHeaders0 })'
      )
    ).toBe(true);
  });
});
