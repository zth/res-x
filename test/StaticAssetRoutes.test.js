const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");
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

async function waitForUrl(url, options = {}) {
  const { timeoutMs = 15000 } = options;
  const start = Date.now();
  let lastError = null;

  while (Date.now() - start < timeoutMs) {
    try {
      const response = await fetch(url);
      if (response.status > 0) {
        return response;
      }
    } catch (error) {
      lastError = error;
    }

    await Bun.sleep(100);
  }

  throw lastError ?? new Error(`Timed out waiting for ${url}`);
}

async function waitForChildExit(child) {
  if (child.exitCode != null || child.signalCode != null) {
    return;
  }

  await new Promise(resolve => child.once("exit", resolve));
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
          sourcePath: "public/robots.txt",
        },
      ],
      assetEntries: [
        {
          routePath: "/assets/a.css",
          sourcePath: "dist/assets/a.css",
        },
        {
          routePath: "/assets/b.css",
          sourcePath: "dist/assets/b.css",
        },
      ],
      headers: createStaticAssetRoutesConfig().headers,
    });

    expect(exactEntries).toEqual([
      {
        routePath: "/robots.txt",
        sourcePath: "public/robots.txt",
        headers: null,
      },
      {
        routePath: "/assets/a.css",
        sourcePath: "dist/assets/a.css",
        headers: null,
      },
      {
        routePath: "/assets/b.css",
        sourcePath: "dist/assets/b.css",
        headers: null,
      },
    ]);
  });

  test("defaults static asset route mode to filesystem", async () => {
    const { createStaticAssetRoutesConfig } = await getPluginTestHelpers();

    expect(createStaticAssetRoutesConfig()).toEqual({
      mode: "filesystem",
      headers: {},
    });
    expect(
      createStaticAssetRoutesConfig({
        mode: "embedded",
      })
    ).toEqual({
      mode: "embedded",
      headers: {},
    });
  });

  test("rejects invalid static asset route modes", async () => {
    const { createStaticAssetRoutesConfig } = await getPluginTestHelpers();

    expect(() =>
      createStaticAssetRoutesConfig({
        mode: "zipfile",
      })
    ).toThrow(
      "`staticAssetRoutes.mode` must be either \"filesystem\" or \"embedded\"."
    );
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
              sourcePath: robotsPath,
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
              sourcePath: emptyPath,
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
          sourcePath: "dist/robots.txt",
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

  test("embedded routes import files instead of using filesystem-relative Bun.file paths", async () => {
    const { getStaticAssetRoutesFileContent } = await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const generatedDir = path.join(tempDir, "src", "__generated__");
      const assetPath = path.join(tempDir, "dist", "assets", "app.css");
      const modulePath = path.join(generatedDir, "res-x-static-routes.js");

      fs.mkdirSync(path.dirname(assetPath), { recursive: true });
      fs.mkdirSync(generatedDir, { recursive: true });
      fs.writeFileSync(assetPath, "body { color: red; }");

      const content = getStaticAssetRoutesFileContent({
        exactEntries: [
          {
            routePath: "/assets/app.css",
            sourcePath: assetPath,
            headers: {
              "Cache-Control": "public, max-age=31536000, immutable",
            },
          },
        ],
        generatedFilePath: modulePath,
        mode: "embedded",
        projectRoot: tempDir,
      });

      expect(content.includes('with { type: "file" }')).toBe(true);
      expect(content.includes('"../../dist/assets/app.css"')).toBe(true);
      expect(content.includes('Bun.file("./dist/assets/app.css")')).toBe(false);

      fs.writeFileSync(modulePath, content);
      const { staticAssetRoutes } = await importGeneratedModule(modulePath);
      const response = staticAssetRoutes["/assets/app.css"].GET;

      expect(response.headers.get("cache-control")).toBe(
        "public, max-age=31536000, immutable"
      );
      expect(await response.text()).toBe("body { color: red; }");
    });
  });

  test("build manifest keeps browser-facing asset urls normalized", async () => {
    const { createStaticAssetRoutesConfig, getGeneratedBuildManifest } =
      await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const outDir = path.join(tempDir, "dist");
      const publicDir = path.join(tempDir, "public");
      const assetsDir = path.join(outDir, "assets");

      fs.mkdirSync(assetsDir, { recursive: true });
      fs.mkdirSync(publicDir, { recursive: true });
      fs.writeFileSync(path.join(publicDir, "robots.txt"), "User-agent: *");
      fs.writeFileSync(path.join(outDir, "robots.txt"), "User-agent: *");
      fs.writeFileSync(
        path.join(assetsDir, "styles_css-123.css"),
        "body { color: red; }"
      );
      fs.writeFileSync(
        path.join(assetsDir, "resXClient_js_loader-123.js"),
        'console.log("loader");'
      );
      fs.writeFileSync(
        path.join(assetsDir, "resXClient_js-456.js"),
        'console.log("inner");'
      );

      const generatedBuildManifest = getGeneratedBuildManifest({
        assetFileNameByBuildId: new Map([
          ["@res-x-asset-entry:styles_css", "assets/styles_css-123.css"],
        ]),
        bundleFileNames: [
          "assets/styles_css-123.css",
          "assets/resXClient_js_loader-123.js",
          "assets/resXClient_js-456.js",
        ],
        clientFileNameByFieldName: new Map([
          ["resXClient_js", "assets/resXClient_js_loader-123.js"],
        ]),
        manifest: [
          {
            buildId: "@res-x-asset-entry:styles_css",
            fieldName: "styles_css",
            kind: "asset",
          },
          {
            fieldName: "resXClient_js",
            kind: "client",
          },
        ],
        outDir,
        publicDir,
        staticAssetRoutes: createStaticAssetRoutesConfig({
          headers: {
            "/assets/**": {
              "Cache-Control": "public, max-age=31536000, immutable",
            },
          },
        }),
      });

      expect(generatedBuildManifest.assets).toEqual({
        styles_css: "/assets/styles_css-123.css",
        resXClient_js: "/assets/resXClient_js_loader-123.js",
      });
      expect(
        generatedBuildManifest.serverAssetEntries.some(
          entry =>
            entry.routePath === "/assets/resXClient_js-456.js" &&
            entry.kind === "bundle"
        )
      ).toBe(true);
      expect(
        generatedBuildManifest.serverAssetEntries.find(
          entry => entry.fieldName === "resXClient_js"
        )
      ).toMatchObject({
        routePath: "/assets/resXClient_js_loader-123.js",
        kind: "client",
      });
      expect(
        generatedBuildManifest.serverAssetEntries.find(
          entry => entry.routePath === "/robots.txt"
        )
      ).toMatchObject({
        kind: "public",
        sourcePath: path.join(outDir, "robots.txt"),
      });
    });
  });

  test("embedded build routes serve from a standalone Bun executable", async () => {
    const {
      createStaticAssetRoutesConfig,
      getBuildStaticAssetRoutesFile,
      getGeneratedBuildManifest,
    } = await getPluginTestHelpers();

    await withTempDir(async tempDir => {
      const outDir = path.join(tempDir, "dist");
      const publicDir = path.join(tempDir, "public");
      const assetsDir = path.join(outDir, "assets");
      const generatedDir = path.join(tempDir, "src", "__generated__");
      const modulePath = path.join(generatedDir, "res-x-static-routes.js");
      const serverPath = path.join(tempDir, "server.js");
      const buildBinaryPath = path.join(tempDir, "resx-static-server");
      const runtimeDir = fs.mkdtempSync(
        path.join(os.tmpdir(), "resx-embedded-runtime-")
      );
      const runtimeBinaryPath = path.join(runtimeDir, "resx-static-server");
      const staticAssetRoutes = createStaticAssetRoutesConfig({
        mode: "embedded",
        headers: {
          "/assets/**": {
            "Cache-Control": "public, max-age=31536000, immutable",
          },
        },
      });
      const [port, releasePort] = TestUtils.getPort();

      fs.mkdirSync(assetsDir, { recursive: true });
      fs.mkdirSync(publicDir, { recursive: true });
      fs.mkdirSync(generatedDir, { recursive: true });

      fs.writeFileSync(path.join(publicDir, "robots.txt"), "User-agent: *");
      fs.writeFileSync(path.join(outDir, "robots.txt"), "User-agent: *");
      fs.writeFileSync(
        path.join(assetsDir, "styles_css-123.css"),
        "body { color: red; }"
      );
      fs.writeFileSync(
        path.join(assetsDir, "resXClient_js_loader-123.js"),
        'console.log("loader");'
      );
      fs.writeFileSync(
        path.join(assetsDir, "resXClient_js-456.js"),
        'console.log("inner");'
      );

      const generatedBuildManifest = getGeneratedBuildManifest({
        assetFileNameByBuildId: new Map([
          ["@res-x-asset-entry:styles_css", "assets/styles_css-123.css"],
        ]),
        bundleFileNames: [
          "assets/styles_css-123.css",
          "assets/resXClient_js_loader-123.js",
          "assets/resXClient_js-456.js",
        ],
        clientFileNameByFieldName: new Map([
          ["resXClient_js", "assets/resXClient_js_loader-123.js"],
        ]),
        manifest: [
          {
            buildId: "@res-x-asset-entry:styles_css",
            fieldName: "styles_css",
            kind: "asset",
          },
          {
            fieldName: "resXClient_js",
            kind: "client",
          },
        ],
        outDir,
        publicDir,
        staticAssetRoutes,
      });

      fs.writeFileSync(
        modulePath,
        getBuildStaticAssetRoutesFile({
          generatedFilePath: modulePath,
          projectRoot: tempDir,
          serverAssetEntries: generatedBuildManifest.serverAssetEntries,
          staticAssetRoutes,
        })
      );
      fs.writeFileSync(
        serverPath,
        `import { staticAssetRoutes } from "./src/__generated__/res-x-static-routes.js";

const server = Bun.serve({
  port: Number(process.env.PORT),
  routes: staticAssetRoutes,
  fetch: request => new Response("app:" + new URL(request.url).pathname),
});

console.log(server.port);
`
      );

      try {
        const buildResult = Bun.spawnSync([
          "bun",
          "build",
          serverPath,
          "--compile",
          "--outfile",
          buildBinaryPath,
        ], {
          cwd: tempDir,
          stderr: "pipe",
          stdout: "pipe",
        });
        if (buildResult.exitCode !== 0) {
          throw new Error(
            Buffer.from(buildResult.stderr || []).toString() ||
              "bun build --compile failed"
          );
        }

        fs.copyFileSync(buildBinaryPath, runtimeBinaryPath);
        fs.chmodSync(runtimeBinaryPath, 0o755);
        fs.rmSync(outDir, { recursive: true, force: true });
        fs.rmSync(publicDir, { recursive: true, force: true });
        fs.rmSync(path.join(tempDir, "src"), { recursive: true, force: true });

        const child = spawn(runtimeBinaryPath, [], {
          cwd: runtimeDir,
          env: {
            ...process.env,
            PORT: String(port),
          },
          stdio: ["ignore", "pipe", "pipe"],
        });

        let stderr = "";
        child.stderr.on("data", chunk => {
          stderr += chunk.toString();
        });

        try {
          await waitForUrl(`http://127.0.0.1:${port}/robots.txt`);

          const robotsResponse = await fetch(`http://127.0.0.1:${port}/robots.txt`);
          expect(robotsResponse.status).toBe(200);
          expect(await robotsResponse.text()).toBe("User-agent: *");

          const styleResponse = await fetch(
            `http://127.0.0.1:${port}/assets/styles_css-123.css`
          );
          expect(styleResponse.status).toBe(200);
          expect(styleResponse.headers.get("cache-control")).toBe(
            "public, max-age=31536000, immutable"
          );
          expect(await styleResponse.text()).toBe("body { color: red; }");

          const clientResponse = await fetch(
            `http://127.0.0.1:${port}/assets/resXClient_js_loader-123.js`
          );
          expect(clientResponse.status).toBe(200);
          expect(await clientResponse.text()).toBe('console.log("loader");');
        } finally {
          child.kill("SIGKILL");
          await waitForChildExit(child);
        }

        expect(stderr).toBe("");
      } finally {
        releasePort();
        fs.rmSync(runtimeDir, { recursive: true, force: true });
      }
    });
  });
});
