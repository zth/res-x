#!/usr/bin/env bun

import {spawn, spawnSync} from "node:child_process";
import {createHash} from "node:crypto";
import {once} from "node:events";
import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {setTimeout as delay} from "node:timers/promises";
import {fileURLToPath, pathToFileURL} from "node:url";

const scriptFile = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(scriptFile);
const fixtureRoot = path.resolve(scriptDir, "..");
const repoRoot = path.resolve(fixtureRoot, "../../..");
const resxCmd = process.env.RESX_CMD || "bun run ./bin/resx";

let portCursor = 4460;

const options = {
  only: null,
  allowMissingCli: false,
  failFast: false,
  keepTemp: false,
  verbose: false,
};

for (let i = 2; i < process.argv.length; i++) {
  const arg = process.argv[i];
  if (arg === "--only") {
    options.only = (process.argv[i + 1] || "")
      .split(",")
      .map(v => v.trim())
      .filter(Boolean);
    i++;
  } else if (arg === "--allow-missing-cli") {
    options.allowMissingCli = true;
  } else if (arg === "--fail-fast") {
    options.failFast = true;
  } else if (arg === "--keep-temp") {
    options.keepTemp = true;
  } else if (arg === "--verbose") {
    options.verbose = true;
  } else if (arg === "--help" || arg === "-h") {
    printHelpAndExit(0);
  } else {
    console.error(`Unknown flag: ${arg}`);
    printHelpAndExit(2);
  }
}

function printHelpAndExit(code) {
  console.log(`Usage: bun run scripts/verify.mjs [flags]

Flags:
  --only <ids>             Comma separated list, for example: V3,V4,V5
  --allow-missing-cli      Skip checks requiring "resx" CLI when unavailable
  --fail-fast              Stop after first failing check
  --keep-temp              Keep temporary directories for debugging
  --verbose                Print command output for passing checks
  -h, --help               Show this help
`);
  process.exit(code);
}

function q(value) {
  return `'${String(value).replace(/'/g, `'\"'\"'`)}'`;
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function normalizeOutput(result) {
  const out = [result.stdout || "", result.stderr || ""].join("\n").trim();
  return out;
}

function runShell(command, {cwd = repoRoot, allowFailure = false, env = {}} = {}) {
  const result = spawnSync("bash", ["-lc", command], {
    cwd,
    env: {...process.env, ...env},
    encoding: "utf8",
  });

  if (!allowFailure && result.status !== 0) {
    const output = normalizeOutput(result);
    throw new Error(`Command failed (${result.status}): ${command}\n${output}`);
  }

  return result;
}

function buildCommand({root, dev = false, watch = false, clean = true}) {
  return `${resxCmd} assets build${dev ? " --dev" : ""}${watch ? " --watch" : ""} --root ${q(root)}${
    clean ? " --clean" : ""
  }`;
}

function runBuild({
  root,
  dev = false,
  watch = false,
  clean = true,
  allowFailure = false,
  env = {},
} = {}) {
  const command = buildCommand({root, dev, watch, clean});
  return runShell(command, {
    cwd: repoRoot,
    allowFailure,
    env,
  });
}

function sha256File(filePath) {
  const content = fs.readFileSync(filePath);
  return createHash("sha256").update(content).digest("hex");
}

async function readJson(filePath) {
  return JSON.parse(await fsp.readFile(filePath, "utf8"));
}

async function readText(filePath) {
  return await fsp.readFile(filePath, "utf8");
}

async function ensureSymlink({linkPath, targetPath}) {
  assert(exists(targetPath), `Missing target for symlink: ${targetPath}`);

  try {
    const stat = await fsp.lstat(linkPath);
    if (stat.isSymbolicLink()) {
      const current = await fsp.readlink(linkPath);
      const resolvedCurrent = path.resolve(path.dirname(linkPath), current);
      const resolvedTarget = path.resolve(targetPath);
      if (resolvedCurrent === resolvedTarget) return;
    }
    await fsp.rm(linkPath, {recursive: true, force: true});
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const type = process.platform === "win32" ? "junction" : "dir";
  await fsp.symlink(targetPath, linkPath, type);
}

async function prepareFixtureReScriptDeps(root) {
  const fixtureNodeModules = path.join(root, "node_modules");
  await fsp.mkdir(fixtureNodeModules, {recursive: true});

  await ensureSymlink({
    linkPath: path.join(fixtureNodeModules, "rescript-x"),
    targetPath: repoRoot,
  });

  await ensureSymlink({
    linkPath: path.join(fixtureNodeModules, "rescript-bun"),
    targetPath: path.join(repoRoot, "node_modules/rescript-bun"),
  });

  await ensureSymlink({
    linkPath: path.join(fixtureNodeModules, "@rescript"),
    targetPath: path.join(repoRoot, "node_modules/@rescript"),
  });

  await ensureSymlink({
    linkPath: path.join(fixtureNodeModules, "rescript"),
    targetPath: path.join(repoRoot, "node_modules/rescript"),
  });
}

function devManifestPath(root) {
  return path.join(root, ".resx/dev/resx-assets.json");
}

function prodManifestPath(root) {
  return path.join(root, "dist/resx-assets.json");
}

function generatedResFile(root) {
  return path.join(root, "src/__generated__/ResXAssets.res");
}

function generatedJsFile(root) {
  return path.join(root, "src/__generated__/res-x-assets.js");
}

function outputPathFromUrl(root, mode, urlPath) {
  assert(urlPath.startsWith("/"), `Expected URL path to start with '/': ${urlPath}`);
  const relative = urlPath.slice(1);
  const base = mode === "dev" ? path.join(root, ".resx/dev") : path.join(root, "dist");
  return path.join(base, relative);
}

function listFilesRecursive(rootDir) {
  if (!exists(rootDir)) return [];

  const output = [];
  const stack = [rootDir];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, {withFileTypes: true});
    for (const entry of entries) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(full);
      } else {
        output.push(full);
      }
    }
  }
  return output.sort();
}

function parseResFields(content) {
  const fields = [];
  const pattern = /^\s*([a-zA-Z_][a-zA-Z0-9_]*): string,/gm;
  let match = pattern.exec(content);
  while (match != null) {
    fields.push(match[1]);
    match = pattern.exec(content);
  }
  return fields.sort();
}

async function waitForCondition(predicate, timeoutMs = 10000, intervalMs = 100) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await predicate()) return;
    await delay(intervalMs);
  }
  throw new Error(`Condition not met within ${timeoutMs}ms`);
}

async function waitForFile(filePath, timeoutMs = 10000, intervalMs = 100) {
  await waitForCondition(() => exists(filePath), timeoutMs, intervalMs);
}

function nextPort() {
  portCursor += 1;
  return portCursor;
}

async function makeTempFixture({withSpaces = false} = {}) {
  const parent = await fsp.mkdtemp(path.join(os.tmpdir(), "resx-bun-assets-"));
  const root = withSpaces ? path.join(parent, "fixture with spaces") : path.join(parent, "fixture");
  const ignoredRoots = new Set(["dist", ".resx", "node_modules", "bun.lock", "package-lock.json", "lib"]);
  await fsp.mkdir(root, {recursive: true});
  await fsp.cp(fixtureRoot, root, {
    recursive: true,
    filter: source => {
      const name = path.basename(source);
      return !ignoredRoots.has(name);
    },
  });
  await fsp.rm(path.join(root, "dist"), {recursive: true, force: true});
  await fsp.rm(path.join(root, ".resx"), {recursive: true, force: true});
  return {
    root,
    parent,
    async cleanup() {
      if (!options.keepTemp) {
        await fsp.rm(parent, {recursive: true, force: true});
      }
    },
  };
}

async function withTempFixture(fn, opts = {}) {
  const fixture = await makeTempFixture(opts);
  try {
    return await fn(fixture.root);
  } finally {
    await fixture.cleanup();
  }
}

function spawnShell(command, {cwd, env = {}}) {
  const child = spawn("bash", ["-lc", command], {
    cwd,
    env: {...process.env, ...env},
    stdio: ["ignore", "pipe", "pipe"],
  });

  let logs = "";
  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");
  child.stdout.on("data", chunk => {
    logs += chunk;
  });
  child.stderr.on("data", chunk => {
    logs += chunk;
  });

  return {child, getLogs: () => logs};
}

async function stopProcess(child) {
  if (child.exitCode != null) return;
  child.kill("SIGTERM");
  await Promise.race([once(child, "exit"), delay(1500)]);
  if (child.exitCode == null) {
    child.kill("SIGKILL");
    await Promise.race([once(child, "exit"), delay(1500)]);
  }
}

async function startWatcher(root) {
  const command = buildCommand({root, dev: true, watch: true, clean: true});
  const spawned = spawnShell(command, {cwd: repoRoot});
  try {
    await waitForFile(devManifestPath(root), 20000, 200);
    return spawned;
  } catch (error) {
    await stopProcess(spawned.child);
    throw new Error(`watcher failed to boot\n${spawned.getLogs()}\n${error.message}`);
  }
}

async function withServer({root, mode, entry = "src/App.js"}, fn) {
  const port = nextPort();
  const env = {
    NODE_ENV: mode === "dev" ? "development" : "production",
    PORT: String(port),
    RESX_REPO_ROOT: repoRoot,
  };
  const command = `bun run ${q(entry)}`;
  const spawned = spawnShell(command, {cwd: root, env});
  try {
    await waitForCondition(
      async () => {
        try {
          const res = await fetch(`http://127.0.0.1:${port}/healthz`);
          return res.ok;
        } catch {
          return false;
        }
      },
      12000,
      150,
    );
    return await fn({port, logs: spawned.getLogs});
  } catch (error) {
    throw new Error(`server failed: ${error.message}\n${spawned.getLogs()}`);
  } finally {
    await stopProcess(spawned.child);
  }
}

async function fetchBytes(url) {
  const response = await fetch(url);
  const arrayBuffer = await response.arrayBuffer();
  return {
    response,
    body: Buffer.from(arrayBuffer),
  };
}

async function readAssetsMap(jsFilePath) {
  const href = `${pathToFileURL(jsFilePath).href}?cacheBust=${Date.now()}-${Math.random()}`;
  const mod = await import(href);
  return mod.assets;
}

const checks = [];

function addCheck({id, title, requiresCli = true, run}) {
  checks.push({id, title, requiresCli, run});
}

addCheck({
  id: "V1",
  title: "No Vite runtime references remain",
  requiresCli: false,
  run: async () => {
    const command =
      'rg -n "vite|@vite/client|res-x-vite-plugin" -S src README.md package.json demo/package.json';
    const result = runShell(command, {cwd: repoRoot, allowFailure: true});
    if (result.status === 0) {
      throw new Error(`Found Vite references:\n${result.stdout}`);
    }
    if (result.status > 1) {
      throw new Error(`Search command failed (${result.status}): ${normalizeOutput(result)}`);
    }
  },
});

addCheck({
  id: "V2",
  title: "CLI command exists and exposes help",
  run: async () => {
    const base = runShell(`${resxCmd} --help`, {cwd: repoRoot});
    const sub = runShell(`${resxCmd} assets build --help`, {cwd: repoRoot});
    const text = `${base.stdout}\n${base.stderr}\n${sub.stdout}\n${sub.stderr}`;
    assert(/assets\s+build/.test(text), "Help output does not include `assets build`");
    assert(text.includes("--dev"), "Help output does not include `--dev`");
    assert(text.includes("--watch"), "Help output does not include `--watch`");
    assert(text.includes("--root"), "Help output does not include `--root`");
    assert(text.includes("--clean"), "Help output does not include `--clean`");
  },
});

addCheck({
  id: "V3",
  title: "Fixture is present and complete",
  requiresCli: false,
  run: async () => {
    const required = [
      "assets/styles.css",
      "assets/main.ts",
      "assets/images/logo.png",
      "assets/misc/data.txt",
      "public/robots.txt",
      "public/favicon.ico",
      "src/App.js",
      "src/AppView.res",
      "src/__generated__/ResXAssets.res",
      "src/__generated__/res-x-assets.js",
      "scripts/setup-local-rescript-deps.mjs",
      "postcss.config.js",
      "tailwind.config.js",
      "rescript.json",
      "package.json",
    ];

    for (const rel of required) {
      const target = path.join(fixtureRoot, rel);
      assert(exists(target), `Missing fixture file: ${rel}`);
    }
  },
});

addCheck({
  id: "V4",
  title: "Dev build emits expected roots",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      assert(exists(path.join(root, ".resx/dev/assets")), "Missing .resx/dev/assets");
      assert(exists(devManifestPath(root)), "Missing .resx/dev/resx-assets.json");
    }),
});

addCheck({
  id: "V5",
  title: "Dev generated files are emitted",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      assert(exists(generatedResFile(root)), "Missing generated ResXAssets.res");
      assert(exists(generatedJsFile(root)), "Missing generated res-x-assets.js");
    }),
});

addCheck({
  id: "V6",
  title: "Dev URLs are stable and unhashed",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      const manifest = await readJson(devManifestPath(root));
      const urls = Object.values(manifest.assets || {});
      const hashed = urls.filter(url => /\/assets\/.*-[0-9a-f]{8}\./.test(String(url)));
      assert(hashed.length === 0, `Found hashed URL(s) in dev manifest: ${hashed.join(", ")}`);
    }),
});

addCheck({
  id: "V7",
  title: "`resXClient_js` is present in manifest and generated type",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      const manifest = await readJson(devManifestPath(root));
      assert(manifest.assets != null, "Manifest missing `assets` field");
      assert(manifest.assets.resXClient_js != null, "Manifest missing `resXClient_js` key");
      const resType = await readText(generatedResFile(root));
      assert(resType.includes("resXClient_js"), "Generated ResXAssets.res missing `resXClient_js`");
    }),
});

addCheck({
  id: "V8",
  title: "Watch mode updates changed files",
  run: async () =>
    withTempFixture(async root => {
      const watcher = await startWatcher(root);
      try {
        const manifest = await readJson(devManifestPath(root));
        const styleUrl = manifest.assets?.styles_css;
        assert(styleUrl != null, "Manifest missing styles_css");
        const outputCss = outputPathFromUrl(root, "dev", styleUrl);
        await waitForFile(outputCss, 10000, 200);
        const before = sha256File(outputCss);

        const marker = `.v8-marker-${Date.now()} { color: #123456; }\n`;
        await fsp.appendFile(path.join(root, "assets/styles.css"), marker);

        await waitForCondition(() => exists(outputCss) && sha256File(outputCss) !== before, 12000, 200);
      } finally {
        await stopProcess(watcher.child);
      }
    }),
});

addCheck({
  id: "V9",
  title: "Deletion or rename does not leave stale files",
  run: async () =>
    withTempFixture(async root => {
      const tempAsset = path.join(root, "assets/temp-delete.txt");
      const tempOutput = path.join(root, ".resx/dev/assets/temp-delete.txt");
      await fsp.writeFile(tempAsset, "delete-me\n", "utf8");
      runBuild({root, dev: true, clean: true});
      assert(exists(tempOutput), "Expected temp asset output to exist after first build");

      await fsp.rm(tempAsset, {force: true});
      runBuild({root, dev: true, clean: true});
      assert(!exists(tempOutput), "Stale output exists after asset deletion");
    }),
});

addCheck({
  id: "V10",
  title: "Prod build emits hashed asset filenames",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: false, clean: true});
      const files = listFilesRecursive(path.join(root, "dist/assets"));
      const hashed = files.some(file => /-[0-9a-f]{8}\.[^/]+$/.test(file));
      assert(hashed, "No hashed asset filename found in dist/assets");
    }),
});

addCheck({
  id: "V11",
  title: "Public files are copied unchanged",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: false, clean: true});
      const src = path.join(root, "public/robots.txt");
      const dst = path.join(root, "dist/robots.txt");
      assert(exists(dst), "dist/robots.txt missing");
      assert(sha256File(src) === sha256File(dst), "public/robots.txt hash mismatch after copy");
    }),
});

addCheck({
  id: "V12",
  title: "Prod manifest schema is correct",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: false, clean: true});
      const manifest = await readJson(prodManifestPath(root));
      assert(manifest.version === 1, "Manifest version must be 1");
      assert(manifest.mode === "prod", "Manifest mode must be `prod`");
      assert(manifest.assets != null && typeof manifest.assets === "object", "Manifest `assets` must be object");
    }),
});

addCheck({
  id: "V13",
  title: "Generated ReScript fields match manifest keys",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: false, clean: true});
      const manifest = await readJson(prodManifestPath(root));
      const keys = Object.keys(manifest.assets || {}).sort();
      const typeFields = parseResFields(await readText(generatedResFile(root)));
      assert(keys.length === typeFields.length, `Key/field count mismatch: ${keys.length} vs ${typeFields.length}`);
      assert(JSON.stringify(keys) === JSON.stringify(typeFields), "Manifest keys and generated type fields differ");
    }),
});

addCheck({
  id: "V14",
  title: "Dev server serves assets from .resx/dev",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      const manifest = await readJson(devManifestPath(root));
      const urlPath = manifest.assets?.styles_css || Object.values(manifest.assets || {})[0];
      assert(typeof urlPath === "string", "No asset URL found in dev manifest");

      await withServer({root, mode: "dev"}, async ({port}) => {
        const {response, body} = await fetchBytes(`http://127.0.0.1:${port}${urlPath}`);
        assert(response.status === 200, `Expected 200 for ${urlPath}, got ${response.status}`);
        const expected = await fsp.readFile(outputPathFromUrl(root, "dev", urlPath));
        assert(Buffer.compare(body, expected) === 0, "Served bytes do not match .resx/dev output");
      });
    }),
});

addCheck({
  id: "V15",
  title: "Dev server serves public files from top-level URLs",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      await withServer({root, mode: "dev"}, async ({port}) => {
        const {response, body} = await fetchBytes(`http://127.0.0.1:${port}/robots.txt`);
        assert(response.status === 200, `Expected 200 for /robots.txt, got ${response.status}`);
        const expected = await fsp.readFile(path.join(root, "public/robots.txt"));
        assert(Buffer.compare(body, expected) === 0, "Served robots.txt does not match public file");
      });
    }),
});

addCheck({
  id: "V16",
  title: "Prod server serves from dist",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: false, clean: true});
      const manifest = await readJson(prodManifestPath(root));
      const urlPath = Object.values(manifest.assets || {})[0];
      assert(typeof urlPath === "string", "No asset URL found in prod manifest");

      await withServer({root, mode: "prod"}, async ({port}) => {
        const {response, body} = await fetchBytes(`http://127.0.0.1:${port}${urlPath}`);
        assert(response.status === 200, `Expected 200 for ${urlPath}, got ${response.status}`);
        const expected = await fsp.readFile(outputPathFromUrl(root, "prod", urlPath));
        assert(Buffer.compare(body, expected) === 0, "Served bytes do not match dist output");
      });
    }),
});

addCheck({
  id: "V17",
  title: "Basic path traversal attempts are blocked",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      await withServer({root, mode: "dev"}, async ({port}) => {
        const urls = [
          "/assets/../src/App.js",
          "/%2e%2e/%2e%2e/etc/passwd",
        ];
        for (const url of urls) {
          const res = await fetch(`http://127.0.0.1:${port}${url}`);
          assert([403, 404].includes(res.status), `Expected 403/404 for ${url}, got ${res.status}`);
          const text = await res.text();
          assert(!text.includes("bun-assets-smoke"), `Traversal response leaked app content for ${url}`);
        }
      });
    }),
});

addCheck({
  id: "V18",
  title: "Manifest and generated outputs are deterministic",
  run: async () =>
    withTempFixture(async root => {
      const trackedFiles = [prodManifestPath(root), generatedResFile(root), generatedJsFile(root)];
      runBuild({root, dev: false, clean: true});
      const first = Object.fromEntries(trackedFiles.map(file => [file, sha256File(file)]));

      runBuild({root, dev: false, clean: true});
      const second = Object.fromEntries(trackedFiles.map(file => [file, sha256File(file)]));

      assert(JSON.stringify(first) === JSON.stringify(second), "Build artifacts changed across identical runs");
    }),
});

addCheck({
  id: "V19",
  title: "Invalid CLI usage returns exit code 2",
  run: async () =>
    withTempFixture(async root => {
      const result = runBuild({
        root,
        dev: false,
        watch: true,
        clean: true,
        allowFailure: true,
      });
      assert(result.status === 2, `Expected exit code 2, got ${result.status}`);
    }),
});

addCheck({
  id: "V20",
  title: "Build failures return exit code 1",
  run: async () =>
    withTempFixture(async root => {
      const entry = path.join(root, "assets/main.ts");
      const original = await readText(entry);
      try {
        await fsp.writeFile(entry, `${original}\nconst broken = ;\n`, "utf8");
        const result = runBuild({
          root,
          dev: true,
          clean: true,
          allowFailure: true,
        });
        const output = normalizeOutput(result);
        assert(result.status === 1, `Expected exit code 1, got ${result.status}`);
        assert(output.includes("main.ts"), "Failure output should mention failing file");
      } finally {
        await fsp.writeFile(entry, original, "utf8");
      }
    }),
});

addCheck({
  id: "V21",
  title: "Empty-project build succeeds",
  run: async () =>
    withTempFixture(async root => {
      await fsp.rm(path.join(root, "assets"), {recursive: true, force: true});
      await fsp.rm(path.join(root, "public"), {recursive: true, force: true});
      runBuild({root, dev: true, clean: true});
      assert(exists(devManifestPath(root)), "Missing dev manifest in empty project");
      assert(exists(generatedResFile(root)), "Missing generated ResXAssets.res in empty project");
      const manifest = await readJson(devManifestPath(root));
      assert(manifest.assets?.resXClient_js != null, "Expected resXClient_js in empty project manifest");
    }),
});

addCheck({
  id: "V22",
  title: "Missing-directory matrix succeeds",
  run: async () => {
    const cases = [
      {name: "assets-only", removeAssets: false, removePublic: true},
      {name: "public-only", removeAssets: true, removePublic: false},
      {name: "none", removeAssets: true, removePublic: true},
    ];

    for (const current of cases) {
      await withTempFixture(async root => {
        if (current.removeAssets) await fsp.rm(path.join(root, "assets"), {recursive: true, force: true});
        if (current.removePublic) await fsp.rm(path.join(root, "public"), {recursive: true, force: true});
        runBuild({root, dev: true, clean: true});
        assert(exists(devManifestPath(root)), `Missing manifest for case: ${current.name}`);
      });
    }
  },
});

addCheck({
  id: "V23",
  title: "Field-name collision handling is deterministic",
  run: async () =>
    withTempFixture(async root => {
      await fsp.writeFile(path.join(root, "assets/a-b.css"), "body { color: red; }\n", "utf8");
      await fsp.writeFile(path.join(root, "assets/a_b.css"), "body { color: blue; }\n", "utf8");

      runBuild({root, dev: true, clean: true});
      const firstMap = await readAssetsMap(generatedJsFile(root));

      runBuild({root, dev: true, clean: true});
      const secondMap = await readAssetsMap(generatedJsFile(root));

      assert(JSON.stringify(firstMap) === JSON.stringify(secondMap), "Collision mapping changed between runs");
      const collisionKeys = Object.keys(firstMap).filter(key => key.startsWith("a_b_css"));
      assert(collisionKeys.length >= 2, "Expected collision-resolved keys for a-b.css and a_b.css");
    }),
});

addCheck({
  id: "V24",
  title: "/assets conflict policy is enforced",
  run: async () =>
    withTempFixture(async root => {
      await fsp.mkdir(path.join(root, "public/assets"), {recursive: true});
      await fsp.writeFile(path.join(root, "public/assets/conflict.txt"), "public-conflict\n", "utf8");
      await fsp.writeFile(path.join(root, "assets/conflict.txt"), "asset-conflict\n", "utf8");

      runBuild({root, dev: true, clean: true});
      const manifest = await readJson(devManifestPath(root));
      const urlPath = manifest.assets?.conflict_txt || "/assets/conflict.txt";
      const expectedPath = outputPathFromUrl(root, "dev", urlPath);
      const expected = await readText(expectedPath);

      await withServer({root, mode: "dev"}, async ({port}) => {
        const response = await fetch(`http://127.0.0.1:${port}/assets/conflict.txt`);
        const text = await response.text();
        assert(response.status === 200, `Expected 200 for /assets/conflict.txt, got ${response.status}`);
        assert(text === expected, "public/assets override detected for managed /assets path");
      });
    }),
});

addCheck({
  id: "V25",
  title: "startDev idempotency (no duplicate rebuild cycles)",
  run: async () =>
    withTempFixture(async root => {
      await withServer({root, mode: "dev", entry: "src/App.start-dev-twice.js"}, async ({port}) => {
        const health = await fetch(`http://127.0.0.1:${port}/healthz`).then(r => r.json());
        assert(health.startDevAvailable === true, "startDev API unavailable for idempotency check");

        const manifestFile = devManifestPath(root);
        await waitForFile(manifestFile, 12000, 200);
        let previousHash = sha256File(manifestFile);

        const marker = `.v25-marker-${Date.now()} { color: #654321; }\n`;
        await fsp.appendFile(path.join(root, "assets/styles.css"), marker);

        const changed = [];
        const stopAt = Date.now() + 9000;
        while (Date.now() < stopAt) {
          if (exists(manifestFile)) {
            const current = sha256File(manifestFile);
            if (current !== previousHash) {
              changed.push(current);
              previousHash = current;
            }
          }
          await delay(200);
        }

        assert(changed.length >= 1, "No rebuild observed after editing watched asset");
        assert(changed.length === 1, `Expected exactly one rebuild write, observed ${changed.length}`);
      });
    }),
});

addCheck({
  id: "V26",
  title: "Watch burst stability reaches final source state",
  run: async () =>
    withTempFixture(async root => {
      const watcher = await startWatcher(root);
      try {
        const cssMarker = `v26-final-${Date.now()}`;
        const jsMarker = `V26_JS_FINAL_${Date.now()}`;
        const stylesPath = path.join(root, "assets/styles.css");
        const mainPath = path.join(root, "assets/main.ts");

        await fsp.appendFile(stylesPath, `\n.v26-mid-${Date.now()} { color: #111111; }\n`);
        await fsp.appendFile(stylesPath, `\n.${cssMarker} { color: #abcdef; }\n`);
        await fsp.appendFile(mainPath, `\nconsole.log("V26_JS_MID_${Date.now()}");\n`);
        await fsp.appendFile(mainPath, `\nconsole.log("${jsMarker}");\n`);

        await waitForCondition(async () => {
          const manifest = await readJson(devManifestPath(root));
          const cssUrl = manifest.assets?.styles_css;
          const jsUrl = manifest.assets?.main_ts || manifest.assets?.main_js;
          if (typeof cssUrl !== "string" || typeof jsUrl !== "string") return false;
          const cssOut = outputPathFromUrl(root, "dev", cssUrl);
          const jsOut = outputPathFromUrl(root, "dev", jsUrl);
          if (!exists(cssOut) || !exists(jsOut)) return false;
          const cssText = await readText(cssOut);
          const jsText = await readText(jsOut);
          return cssText.includes(cssMarker) && jsText.includes(jsMarker);
        }, 15000, 250);
      } finally {
        await stopProcess(watcher.child);
      }
    }),
});

addCheck({
  id: "V27",
  title: "--clean only deletes inside output directories",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      const outside = path.join(root, "sentinel-outside.txt");
      const insideDev = path.join(root, ".resx/dev/sentinel-inside.txt");
      await fsp.writeFile(outside, "outside", "utf8");
      await fsp.writeFile(insideDev, "inside-dev", "utf8");

      runBuild({root, dev: true, clean: true});
      assert(exists(outside), "Outside sentinel was deleted by --clean");
      assert(!exists(insideDev), "Inside dev sentinel survived --clean");

      runBuild({root, dev: false, clean: true});
      const insideDist = path.join(root, "dist/sentinel-inside.txt");
      await fsp.writeFile(insideDist, "inside-dist", "utf8");
      runBuild({root, dev: false, clean: true});
      assert(exists(outside), "Outside sentinel was deleted by prod --clean");
      assert(!exists(insideDist), "Inside dist sentinel survived --clean");
    }),
});

addCheck({
  id: "V28",
  title: "--root edge cases work (relative, spaces, symlink)",
  run: async () => {
    const rootsToCleanup = [];
    try {
      const fixtureA = await makeTempFixture();
      rootsToCleanup.push(fixtureA);
      const relativeRoot = path.relative(repoRoot, fixtureA.root);
      runBuild({root: relativeRoot, dev: true, clean: true});
      assert(exists(devManifestPath(fixtureA.root)), "Relative root build did not emit manifest");

      const fixtureSpace = await makeTempFixture({withSpaces: true});
      rootsToCleanup.push(fixtureSpace);
      runBuild({root: fixtureSpace.root, dev: true, clean: true});
      assert(exists(devManifestPath(fixtureSpace.root)), "Space-containing root build failed");

      const fixtureB = await makeTempFixture();
      rootsToCleanup.push(fixtureB);
      const linkParent = await fsp.mkdtemp(path.join(os.tmpdir(), "resx-root-link-"));
      const linkPath = path.join(linkParent, "fixture-link");
      await fsp.symlink(fixtureB.root, linkPath);
      runBuild({root: linkPath, dev: true, clean: true});
      assert(exists(devManifestPath(fixtureB.root)), "Symlink root build failed");
      if (!options.keepTemp) {
        await fsp.rm(linkParent, {recursive: true, force: true});
      }
    } finally {
      for (const fixture of rootsToCleanup) {
        await fixture.cleanup();
      }
    }
  },
});

addCheck({
  id: "V29",
  title: "Traversal hardening handles encoded and separator variants",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      await withServer({root, mode: "dev"}, async ({port}) => {
        const urls = [
          "/%252e%252e/%252e%252e/etc/passwd",
          "/assets/..%2f..%2fsrc%2fApp.js",
          "/assets/..\\\\..\\\\src\\\\App.js",
        ];
        for (const url of urls) {
          const res = await fetch(`http://127.0.0.1:${port}${url}`);
          assert([403, 404].includes(res.status), `Expected 403/404 for ${url}, got ${res.status}`);
        }
      });
    }),
});

addCheck({
  id: "V30",
  title: "Symlink escape policy prevents serving/copying outside-root targets",
  run: async () =>
    withTempFixture(async root => {
      const externalParent = await fsp.mkdtemp(path.join(os.tmpdir(), "resx-outside-"));
      const secret = path.join(externalParent, "secret.txt");
      await fsp.writeFile(secret, "outside-secret\n", "utf8");
      const link = path.join(root, "assets/outside-link.txt");
      await fsp.symlink(secret, link);

      const result = runBuild({root, dev: true, clean: true, allowFailure: true});
      const copied = path.join(root, ".resx/dev/assets/outside-link.txt");
      if (result.status === 0) {
        assert(!exists(copied), "Outside symlink target was copied into managed assets");
      }
      if (!options.keepTemp) {
        await fsp.rm(externalParent, {recursive: true, force: true});
      }
    }),
});

addCheck({
  id: "V31",
  title: "Content-Type headers are correct in dev and prod",
  run: async () =>
    withTempFixture(async root => {
      runBuild({root, dev: true, clean: true});
      const devManifest = await readJson(devManifestPath(root));

      await withServer({root, mode: "dev"}, async ({port}) => {
        const cssUrl = devManifest.assets?.styles_css;
        const jsUrl = devManifest.assets?.main_ts || devManifest.assets?.main_js;
        const imageUrl =
          devManifest.assets?.images__logo_png ||
          Object.values(devManifest.assets || {}).find(v => String(v).endsWith(".png"));

        assert(typeof cssUrl === "string", "Missing CSS URL for MIME test");
        assert(typeof jsUrl === "string", "Missing JS URL for MIME test");
        assert(typeof imageUrl === "string", "Missing image URL for MIME test");

        const css = await fetch(`http://127.0.0.1:${port}${cssUrl}`);
        const js = await fetch(`http://127.0.0.1:${port}${jsUrl}`);
        const img = await fetch(`http://127.0.0.1:${port}${imageUrl}`);
        const txt = await fetch(`http://127.0.0.1:${port}/robots.txt`);

        assert((css.headers.get("content-type") || "").includes("text/css"), "Unexpected CSS content-type in dev");
        assert(
          (js.headers.get("content-type") || "").includes("javascript"),
          `Unexpected JS content-type in dev: ${js.headers.get("content-type")}`,
        );
        assert(
          (img.headers.get("content-type") || "").startsWith("image/"),
          `Unexpected image content-type in dev: ${img.headers.get("content-type")}`,
        );
        assert(
          (txt.headers.get("content-type") || "").includes("text/plain"),
          `Unexpected text content-type in dev: ${txt.headers.get("content-type")}`,
        );
      });

      runBuild({root, dev: false, clean: true});
      const prodManifest = await readJson(prodManifestPath(root));
      await withServer({root, mode: "prod"}, async ({port}) => {
        const cssUrl = prodManifest.assets?.styles_css;
        const jsUrl = prodManifest.assets?.main_ts || prodManifest.assets?.main_js;
        const imageUrl =
          prodManifest.assets?.images__logo_png ||
          Object.values(prodManifest.assets || {}).find(v => String(v).includes(".png"));

        assert(typeof cssUrl === "string", "Missing CSS URL for MIME prod test");
        assert(typeof jsUrl === "string", "Missing JS URL for MIME prod test");
        assert(typeof imageUrl === "string", "Missing image URL for MIME prod test");

        const css = await fetch(`http://127.0.0.1:${port}${cssUrl}`);
        const js = await fetch(`http://127.0.0.1:${port}${jsUrl}`);
        const img = await fetch(`http://127.0.0.1:${port}${imageUrl}`);
        const txt = await fetch(`http://127.0.0.1:${port}/robots.txt`);

        assert((css.headers.get("content-type") || "").includes("text/css"), "Unexpected CSS content-type in prod");
        assert(
          (js.headers.get("content-type") || "").includes("javascript"),
          `Unexpected JS content-type in prod: ${js.headers.get("content-type")}`,
        );
        assert(
          (img.headers.get("content-type") || "").startsWith("image/"),
          `Unexpected image content-type in prod: ${img.headers.get("content-type")}`,
        );
        assert(
          (txt.headers.get("content-type") || "").includes("text/plain"),
          `Unexpected text content-type in prod: ${txt.headers.get("content-type")}`,
        );
      });
    }),
});

addCheck({
  id: "V32",
  title: "npm pack contains expected migration artifacts and no Vite plugin",
  run: async () => {
    const pack = runShell("npm pack --json", {cwd: repoRoot});
    const parsed = JSON.parse(pack.stdout);
    const entry = parsed[0];
    assert(entry != null && Array.isArray(entry.files), "Unexpected npm pack --json output");
    const paths = entry.files.map(file => file.path);
    assert(!paths.includes("res-x-vite-plugin.mjs"), "Packed tarball still contains res-x-vite-plugin.mjs");
    assert(paths.some(file => file === "src/Assets.js" || file === "src/Assets.res"), "Packed tarball missing Assets module");
    assert(paths.some(file => file.startsWith("bin/") && file.includes("resx")), "Packed tarball missing CLI binary");
  },
});

addCheck({
  id: "V33",
  title: "Fresh install smoke test from packed tarball",
  run: async () => {
    const pack = runShell("npm pack --json", {cwd: repoRoot});
    const parsed = JSON.parse(pack.stdout);
    const entry = parsed[0];
    const tarballPath = path.join(repoRoot, entry.filename);
    assert(exists(tarballPath), `Missing packed tarball: ${tarballPath}`);

    const temp = await fsp.mkdtemp(path.join(os.tmpdir(), "resx-pack-smoke-"));
    try {
      runShell("npm init -y >/dev/null 2>&1", {cwd: temp});
      runShell(`npm install ${q(tarballPath)} >/dev/null 2>&1`, {cwd: temp});

      const projectRoot = path.join(temp, "project");
      await fsp.mkdir(path.join(projectRoot, "assets"), {recursive: true});
      await fsp.mkdir(path.join(projectRoot, "public"), {recursive: true});
      await fsp.mkdir(path.join(projectRoot, "src"), {recursive: true});
      await fsp.writeFile(path.join(projectRoot, "assets/main.ts"), 'console.log("pack-smoke");\n', "utf8");
      await fsp.writeFile(path.join(projectRoot, "assets/styles.css"), "body { color: black; }\n", "utf8");
      await fsp.writeFile(path.join(projectRoot, "public/robots.txt"), "User-agent: *\nAllow: /\n", "utf8");
      await fsp.writeFile(path.join(projectRoot, "src/App.js"), 'console.log("fixture");\n', "utf8");

      const cli = path.join(temp, "node_modules/.bin/resx");
      assert(exists(cli), "Installed package does not provide `resx` binary");
      const command = `${q(cli)} assets build --dev --root ${q(projectRoot)} --clean`;
      runShell(command, {cwd: temp});

      assert(exists(path.join(projectRoot, ".resx/dev/resx-assets.json")), "Pack smoke build did not emit dev manifest");
    } finally {
      if (!options.keepTemp) {
        await fsp.rm(temp, {recursive: true, force: true});
      }
      if (!options.keepTemp) {
        await fsp.rm(tarballPath, {force: true});
      }
    }
  },
});

addCheck({
  id: "V34",
  title: "Failure messages are actionable",
  run: async () => {
    const invalid = runShell(`${resxCmd} assets build --watch`, {cwd: repoRoot, allowFailure: true});
    const invalidText = normalizeOutput(invalid);
    assert(invalid.status !== 0, "Invalid CLI usage unexpectedly succeeded");
    assert(
      invalidText.toLowerCase().includes("watch") || invalidText.toLowerCase().includes("invalid"),
      "Invalid usage output is not actionable",
    );

    const missingRoot = path.join(os.tmpdir(), `resx-missing-${Date.now()}`);
    const missing = runBuild({
      root: missingRoot,
      dev: true,
      clean: true,
      allowFailure: true,
    });
    const missingText = normalizeOutput(missing);
    assert(missing.status !== 0, "Missing-root build unexpectedly succeeded");
    assert(
      missingText.includes(missingRoot) || missingText.toLowerCase().includes("not found"),
      "Missing-root error does not mention path or reason",
    );

    await withTempFixture(async root => {
      const entry = path.join(root, "assets/main.ts");
      const original = await readText(entry);
      try {
        await fsp.writeFile(entry, `${original}\nconst broken = ;\n`, "utf8");
        const result = runBuild({
          root,
          dev: true,
          clean: true,
          allowFailure: true,
        });
        const text = normalizeOutput(result);
        assert(result.status !== 0, "Syntax-error build unexpectedly succeeded");
        assert(text.includes("main.ts"), "Syntax-error output does not mention failing file");
      } finally {
        await fsp.writeFile(entry, original, "utf8");
      }
    });
  },
});

addCheck({
  id: "V35",
  title: "Fixture ReScript build compiles with local package deps",
  requiresCli: false,
  run: async () =>
    withTempFixture(async root => {
      const compiler = path.join(repoRoot, "node_modules/.bin/rescript");
      assert(exists(compiler), "Missing compiler binary at node_modules/.bin/rescript. Run `bun install` in repo root.");
      await prepareFixtureReScriptDeps(root);
      runShell(q(compiler), {cwd: root});
    }),
});

function buildSelectedChecks() {
  if (!options.only || options.only.length === 0) return checks;
  const wanted = new Set(options.only);
  const selected = checks.filter(check => wanted.has(check.id));
  const missing = options.only.filter(id => !checks.some(check => check.id === id));
  if (missing.length > 0) {
    throw new Error(`Unknown check id(s): ${missing.join(", ")}`);
  }
  return selected;
}

const cliProbe = runShell(`${resxCmd} --help`, {cwd: repoRoot, allowFailure: true});
const cliAvailable = cliProbe.status === 0;

if (!cliAvailable && options.verbose) {
  console.log(`CLI probe failed for "${resxCmd} --help"`);
  console.log(normalizeOutput(cliProbe));
}

const selectedChecks = buildSelectedChecks();
const results = [];

console.log(`Running ${selectedChecks.length} verification check(s) from ${fixtureRoot}`);
console.log(`resx command: ${resxCmd}`);

for (const check of selectedChecks) {
  const start = Date.now();
  const prefix = `[${check.id}]`;

  if (check.requiresCli && !cliAvailable && options.allowMissingCli) {
    const duration = Date.now() - start;
    results.push({id: check.id, status: "skipped", duration, message: "CLI unavailable"});
    console.log(`${prefix} SKIP (${duration}ms) - CLI unavailable`);
    continue;
  }

  try {
    await check.run();
    const duration = Date.now() - start;
    results.push({id: check.id, status: "passed", duration});
    console.log(`${prefix} PASS (${duration}ms) - ${check.title}`);
  } catch (error) {
    const duration = Date.now() - start;
    results.push({id: check.id, status: "failed", duration, message: error.message});
    console.log(`${prefix} FAIL (${duration}ms) - ${check.title}`);
    console.log(error.message.trimEnd());
    if (options.failFast) break;
  }
}

const passed = results.filter(r => r.status === "passed").length;
const failed = results.filter(r => r.status === "failed").length;
const skipped = results.filter(r => r.status === "skipped").length;

console.log("");
console.log(`Summary: ${passed} passed, ${failed} failed, ${skipped} skipped`);

if (options.verbose) {
  for (const result of results) {
    if (result.status !== "failed") continue;
    console.log(`- ${result.id}: ${result.message}`);
  }
}

process.exit(failed > 0 ? 1 : 0);
