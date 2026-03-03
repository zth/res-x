const path = require("path");
const fs = require("fs");

function requireResXModule(moduleName) {
  const requested = path.posix.join("src", moduleName);
  const envRoot = process.env.RESX_REPO_ROOT;

  if (typeof envRoot === "string" && envRoot.length > 0) {
    const fromEnv = path.join(envRoot, requested);
    if (fs.existsSync(fromEnv)) {
      return require(fromEnv);
    }
  }

  const fromRepoLayout = path.resolve(__dirname, "../../../../", requested);
  if (fs.existsSync(fromRepoLayout)) {
    return require(fromRepoLayout);
  }

  return require(`rescript-x/${requested}`);
}

const BunUtils = requireResXModule("BunUtils.js");

let AssetsApi = null;
try {
  AssetsApi = requireResXModule("Assets.js");
} catch {
  AssetsApi = null;
}

const port = Number.parseInt(process.env.PORT || "4460", 10);

function getGeneratedAssets() {
  const generatedPath = path.resolve(__dirname, "__generated__/res-x-assets.js");
  delete require.cache[generatedPath];

  try {
    return require(generatedPath).assets;
  } catch {
    return {
      styles_css: "/assets/styles.css",
      main_ts: "/assets/main.js",
      images__logo_png: "/assets/images/logo.png",
      misc__data_txt: "/assets/misc/data.txt",
      resXClient_js: "/assets/resx-client.js",
    };
  }
}

async function maybeStartDevAssets() {
  if (!BunUtils.isDev) return false;
  if (AssetsApi == null || typeof AssetsApi.startDev !== "function") return false;
  await AssetsApi.startDev();
  return true;
}

function htmlPage(assets) {
  const css = assets.styles_css || "/assets/styles.css";
  const js = assets.main_ts || "/assets/main.js";
  const client = assets.resXClient_js || "/assets/resx-client.js";

  return `<!DOCTYPE html><html><head><meta charset="utf-8"/><title>bun-assets-smoke</title><link rel="stylesheet" href="${css}"/></head><body><h1 class="fixture-banner">bun-assets-smoke</h1><p>fixture server is running</p><script type="module" src="${js}"></script><script async src="${client}"></script></body></html>`;
}

async function boot() {
  const startDevAvailable = await maybeStartDevAssets();

  const server = Bun.serve({
    port,
    development: BunUtils.isDev,
    fetch: async request => {
      const url = new URL(request.url);

      if (url.pathname === "/healthz") {
        return Response.json({
          ok: true,
          env: BunUtils.isDev ? "development" : "production",
          startDevAvailable,
        });
      }

      const staticResponse = await BunUtils.serveStaticFile(request);
      if (staticResponse != null) {
        return staticResponse;
      }

      return new Response(htmlPage(getGeneratedAssets()), {
        headers: {"Content-Type": "text/html; charset=utf-8"},
      });
    },
  });

  const actualPort = server.port;
  console.log(`[bun-assets-smoke] listening on http://localhost:${actualPort}`);
}

void boot();
