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
    return {styles_css: "/assets/styles.css", resXClient_js: "/assets/resx-client.js"};
  }
}

async function maybeStartDevAssetsTwice() {
  if (!BunUtils.isDev) return false;
  if (AssetsApi == null || typeof AssetsApi.startDev !== "function") return false;
  await Promise.all([AssetsApi.startDev(), AssetsApi.startDev()]);
  return true;
}

async function boot() {
  const startDevAvailable = await maybeStartDevAssetsTwice();

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
      if (staticResponse != null) return staticResponse;

      const assets = getGeneratedAssets();
      const css = assets.styles_css || "/assets/styles.css";
      return new Response(
        `<!DOCTYPE html><html><head><link rel="stylesheet" href="${css}"/></head><body>start-dev-twice</body></html>`,
        {
          headers: {"Content-Type": "text/html; charset=utf-8"},
        },
      );
    },
  });

  console.log(`[bun-assets-smoke] start-dev-twice on http://localhost:${server.port}`);
}

void boot();
