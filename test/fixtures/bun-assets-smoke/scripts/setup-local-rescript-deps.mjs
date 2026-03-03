#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import {fileURLToPath} from "node:url";

const scriptFile = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(scriptFile);
const fixtureRoot = path.resolve(scriptDir, "..");
const repoRoot = path.resolve(fixtureRoot, "../../..");

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function exists(target) {
  try {
    await fs.access(target);
    return true;
  } catch {
    return false;
  }
}

async function ensureSymlink({linkPath, targetPath}) {
  assert(await exists(targetPath), `Missing target: ${targetPath}`);

  try {
    const stat = await fs.lstat(linkPath);
    if (stat.isSymbolicLink()) {
      const current = await fs.readlink(linkPath);
      const resolvedCurrent = path.resolve(path.dirname(linkPath), current);
      const resolvedTarget = path.resolve(targetPath);
      if (resolvedCurrent === resolvedTarget) return;
    }
    await fs.rm(linkPath, {recursive: true, force: true});
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const type = process.platform === "win32" ? "junction" : "dir";
  await fs.symlink(targetPath, linkPath, type);
}

async function main() {
  const nodeModules = path.join(fixtureRoot, "node_modules");
  await fs.mkdir(nodeModules, {recursive: true});

  await ensureSymlink({
    linkPath: path.join(nodeModules, "rescript-x"),
    targetPath: repoRoot,
  });

  await ensureSymlink({
    linkPath: path.join(nodeModules, "rescript-bun"),
    targetPath: path.join(repoRoot, "node_modules/rescript-bun"),
  });

  await ensureSymlink({
    linkPath: path.join(nodeModules, "rescript"),
    targetPath: path.join(repoRoot, "node_modules/rescript"),
  });

  await ensureSymlink({
    linkPath: path.join(nodeModules, "@rescript"),
    targetPath: path.join(repoRoot, "node_modules/@rescript"),
  });
}

main().catch(error => {
  console.error(error.message || String(error));
  process.exit(1);
});
