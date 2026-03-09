import fs from "fs";
import path from "path";

const demoDir = path.resolve(import.meta.dirname, "..");
const nodeModulesDir = path.join(demoDir, "node_modules");
const linkPath = path.join(nodeModulesDir, "rescript-x");
const targetPath = path.relative(nodeModulesDir, path.resolve(demoDir, "..")) || "..";

fs.mkdirSync(nodeModulesDir, {recursive: true});

try {
  const existing = fs.lstatSync(linkPath);

  if (existing.isSymbolicLink() && fs.readlinkSync(linkPath) === targetPath) {
    process.exit(0);
  }

  const oldPath = path.join(
    nodeModulesDir,
    `.rescript-x-old-${process.pid}-${Date.now()}`,
  );

  fs.renameSync(linkPath, oldPath);

  try {
    fs.rmSync(oldPath, {recursive: true, force: true});
  } catch {
    // The old recursive directory can exceed path limits. It's already moved out
    // of the way, so leave cleanup to a later install if needed.
  }
} catch {
  // Nothing to replace.
}

fs.symlinkSync(targetPath, linkPath, "dir");
