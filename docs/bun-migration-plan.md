# Bun-only Asset Pipeline Plan (v1 Usable Spec)

## Goals
- Remove Vite entirely (no Vite dev server, no Vite plugin, no Vite dependency).
- Replace the asset pipeline with Bun-only tooling.
- Keep `assets/` + `public/` conventions and keep `ResXAssets.assets.<field>` API.
- Transform assets automatically (CSS/JS via bundler; other files copied) and hash in prod.
- Support implicit JS entrypoints from `assets/`.
- Prebundle `ResXClient` and include it as `resXClient_js` in the asset map.
- Provide a CLI for builds and a runtime API to start dev processing inside the Bun app.

## Non-goals (v1)
- HMR (CSS or HTML morphing).
- CDN/publicPath/basePath configuration.
- Embedding assets into the Bun single-binary output (tracked for later).
- Advanced user configuration (keep zero-config first).

## Locked Decisions (Clarified)
- Dev pipeline starts explicitly in app code (no separate dev server process).
- Dev output goes to `.resx/dev/` with stable, unhashed URLs.
- Prod output goes to `dist/`, assets under `dist/assets/`.
- `public/` is copied as-is and is not part of `ResXAssets`.
- Implicit JS entrypoints: any `assets/**/*.{js,jsx,ts,tsx,mjs,cjs}`.
- CSS entrypoints: any `assets/**/*.css`.
- Single-file output per entry (no code splitting in v1).
- `ResX.Dev` becomes a no-op in v1.

## Root + Path Resolution
- Default project root is current working directory.
- CLI supports `--root <path>` override.
- Runtime API supports `~root` override.
- `assets/` and `public/` are optional; missing directories are treated as empty.
- Generated files location is fixed to `src/__generated__/` in v1.
- Symlink policy for discovery/copying: do not follow symlink targets that resolve outside project root.

## Artifact Contracts
### Asset key derivation
- Normalize discovered file paths to `/` separators before key generation.
- Keep current `toRescriptFieldName` behavior for compatibility.
- Process files in sorted order for deterministic collision resolution.
- Collision rule remains suffix `_` repeatedly until unique.

### Manifest schema
- Emit JSON manifest in both dev and prod:

```json
{
  "version": 1,
  "mode": "dev",
  "assets": {
    "styles_css": "/assets/styles.css",
    "resXClient_js": "/assets/resx-client.js"
  }
}
```

- `version` is required and starts at `1`.
- `mode` is `dev` or `prod`.
- `assets` keys match generated ReScript fields.

### Generated files
- Always generate `src/__generated__/ResXAssets.res`.
- Always generate `src/__generated__/res-x-assets.js`.
- Always include `resXClient_js` in both files.

### Hashing
- Prod hashes are content-based.
- Algorithm: `sha256`, truncated to 8 hex chars.
- Filename format: `<name>-<hash>.<ext>`.

## Runtime Contracts
### `ResX.Assets.startDev()`
- Async, idempotent API.
- First call builds assets into `.resx/dev/`, writes `.resx/dev/resx-assets.json`, regenerates `src/__generated__/ResXAssets.res` and `src/__generated__/res-x-assets.js`, and starts file watching.
- Subsequent calls in same process are no-ops.
- Uses write-if-changed for generated files to reduce rebuild churn.
- Watches at least: `assets/`, `public/`, `src/ResXClient.*`.

### `ResX.BunUtils.serveStaticFile`
- Dev behavior: serve `/assets/*` from `.resx/dev/assets/` and serve non-assets static files from `public/`.
- Prod behavior: serve `/assets/*` from `dist/assets/` and serve non-assets static files from `dist/`.
- `/assets/*` is reserved for managed pipeline assets; `public/assets/*` must not override it.
- Must reject traversal attempts (`..`) after URL decoding/normalization.

## CLI Contract (`resx`)
### v1 command
- `resx assets build`

### v1 flags
- `--dev` builds to `.resx/dev/` instead of `dist/`.
- `--watch` watches for changes (dev mode only).
- `--root <path>` overrides project root.
- `--clean` removes output directory before build (enabled by default).

### Exit codes
- `0`: success
- `1`: runtime/build failure
- `2`: invalid CLI usage

## Agent Handoff (Start Here)
### Current status snapshot
- Date: February 13, 2026.
- Planning/spec and verification design are in place.
- Verification fixture exists at `test/fixtures/bun-assets-smoke/`.
- Automated verification runner exists at `test/fixtures/bun-assets-smoke/scripts/verify.mjs`.
- Root convenience script exists: `bun run verify:bun-assets-plan`.
- Bun migration implementation is not complete yet; many checks are expected to fail until steps 2-10 are implemented.

### First commands for a new agent
- `bun run verify:bun-assets-plan -- --only V3`
- `bun run verify:bun-assets-plan -- --only V2 --allow-missing-cli`
- `bun run verify:bun-assets-plan -- --only V1`

### Recommended execution loop
1. Pick the next incomplete step in `Step-by-step Plan`.
2. Implement only that step and keep scope tight.
3. Run the step-relevant `V*` checks from this doc.
4. Fix regressions before starting the next step.
5. Re-run broader checks periodically (`V1-V20`) to catch cross-step breakage.
6. Run the full verification suite before final handoff.

### Step to verification mapping (minimum)
- Step 2: run `V4`, `V5`, `V13`, `V18`.
- Step 3: run `V4`, `V8`, `V20`, `V26`.
- Step 4: run `V4`, `V6`, `V8`, `V31`.
- Step 5: run `V4`, `V9`, `V24`, `V27`.
- Step 6: run `V10`, `V11`, `V12`, `V16`, `V18`.
- Step 7: run `V7`, `V14`, `V25`.
- Step 8: run `V17`, `V29`, `V30`.
- Step 9: run `V2`, `V19`, `V34`.
- Step 10: run `V1`, `V32`, `V33`.

### Final handoff checklist
- `bun run verify:bun-assets-plan` passes for all agent-verifiable checks (`V1-V34`).
- `U1` and `U2` are explicitly called out for user-assisted follow-up.
- `rg -n "vite|@vite/client|res-x-vite-plugin" -S . --glob '!CHANGELOG.md'` has no runtime/doc hits.
- Plan doc is updated if any contract changed during implementation.

## Test Project for Verification
Create and keep a dedicated fixture project in this repo:
- Path: `test/fixtures/bun-assets-smoke/`
- Purpose: stable end-to-end target for agent-run verification of dev/prod build behavior.

### Fixture contents (minimum)
- `assets/`
- `styles.css` (Tailwind directives)
- `main.ts` (JS entrypoint)
- `images/logo.png` (copied asset)
- `misc/data.txt` (copied asset)
- `public/`
- `robots.txt`
- `favicon.ico` (or another static file)
- `src/`
- minimal Bun server app using `ResX.BunUtils.serveStaticFile`
- app startup calls `await ResX.Assets.startDev()` in dev
- sample view uses `ResXAssets.assets.styles_css` and `ResXAssets.assets.resXClient_js`
- `postcss.config.js` + `tailwind.config.js`
- `rescript.json` and `package.json` scripts for `dev`, `build`, and `start`

### Fixture conventions
- Use fixed port for test server (for example `4460`) to make scripted checks deterministic.
- Keep fixture minimal and deterministic; do not add unrelated app logic.
- Keep fixture committed so agent can run checks without setup prompts.

## Target Developer Flow
### Dev
1. Run `rescript build -w`.
2. Run app with Bun (`bun --watch run src/App.js`).
3. In app startup, call `await ResX.Assets.startDev()`.
4. Use `ResXAssets.assets.*` in views and refresh browser manually.

### Production
1. Run `resx assets build`.
2. Run Bun server with `NODE_ENV=production`.
3. `ResX.BunUtils.serveStaticFile` serves from `dist/`.

## Architecture
### Asset discovery
- Scan `assets/**/*` and `public/**/*` using `Bun.Glob` or `fast-glob`.
- Partition rules:
- JS entrypoints are `.js/.jsx/.ts/.tsx/.mjs/.cjs`.
- CSS entrypoints are `.css`.
- Other assets (images/fonts/wasm/txt/etc) are copied.

### Build pipeline (shared core for dev/prod)
- JS entrypoints: `bun build` with no code splitting.
- CSS entrypoints use `bun build` when sufficient; otherwise fallback to PostCSS via local `postcss.config.js`.
- Other assets: copy to output; hash names in prod.
- Add prebundled `resx-client.js` as additional asset entry (copied/mapped).
- Emit manifest (`.resx/dev/resx-assets.json` in dev, `dist/resx-assets.json` in prod).
- Regenerate `src/__generated__/ResXAssets.res` + `src/__generated__/res-x-assets.js`.

### Cleanup behavior
- Dev builds clean `.resx/dev/` before writing outputs.
- Prod builds clean `dist/` before writing outputs.
- This guarantees deleted or renamed assets do not leave stale artifacts.

## Step-by-step Plan (Each Step Independently Verifiable)
### Step 0: Build verification fixture project
- Add `test/fixtures/bun-assets-smoke/` with files listed above.
- Add scripts intended for agent-run local verification.

### Step 1: Capability validation
- Verify Bun JS/CSS build behavior against fixture assets.
- Verify PostCSS fallback path works with fixture Tailwind setup.
- Verify no-code-splitting output for multi-entry JS.

### Step 2: Core asset discovery + manifest/codegen (no bundling yet)
- Implement discovery for `assets/` + `public/`.
- Generate manifest object and both generated files using dev-style URLs.
- Ensure deterministic ordering and collision handling.

### Step 3: JS bundling (dev output)
- Build JS entries into `.resx/dev/assets/`.
- Wire output URLs into manifest and generated files.

### Step 4: CSS pipeline (dev output)
- Add CSS entry handling into `.resx/dev/assets/`.
- Use Bun path first, PostCSS fallback second.

### Step 5: Copy non-entry assets (dev output)
- Copy non-entry files into `.resx/dev/assets/` with stable names.

### Step 6: Production output + hashing
- Build prod outputs in `dist/assets/` with hashed names.
- Copy `public/` into `dist/`.
- Emit `dist/resx-assets.json`.

### Step 7: Prebundle `ResXClient`
- Build and include `resXClient_js` in both dev/prod manifests and generated files.

### Step 8: Runtime integration
- Implement `ResX.Assets.startDev()` (build + watch + regenerate).
- Make `ResX.Dev` a no-op.
- Update `ResX.BunUtils.serveStaticFile` for new roots.

### Step 9: CLI integration
- Add `resx assets build` and flags listed above.
- Provide help output and stable exit codes.

### Step 10: Migration cleanup
- Remove `res-x-vite-plugin.mjs`.
- Drop `vite` peer/deps and Vite scripts.
- Remove Vite references from README/demo code/docs.

## Verification Plan
All checks below are designed to be executable by the agent with shell tools and local process control.

### Automation-first policy
- Prefer executable tests/scripts over manual spot checks for every `V*` item.
- If a check can be automated, it should be implemented as:
- a Bun test in `test/`, or
- a deterministic verification script under `test/fixtures/bun-assets-smoke/scripts/`.
- Manual verification should only be used when there is no reliable automation path.
- CI should run the automated verification suite for regression prevention.

### A. Environment and migration checks
#### V1: No Vite runtime references remain
- Command:
- `rg -n "vite|@vite/client|res-x-vite-plugin" -S . --glob '!CHANGELOG.md'`
- Pass:
- No runtime docs/code references remain (historical changelog entries allowed).
- Verifiable by agent: Yes

#### V2: CLI command exists
- Command:
- `bun x resx --help`
- `bun x resx assets build --help`
- Pass:
- Help output includes `assets build` and expected flags.
- Verifiable by agent: Yes

### B. Fixture bootstrap checks
#### V3: Fixture is present and complete
- Commands:
- `test -d test/fixtures/bun-assets-smoke`
- `test -f test/fixtures/bun-assets-smoke/assets/styles.css`
- `test -f test/fixtures/bun-assets-smoke/public/robots.txt`
- `test -f test/fixtures/bun-assets-smoke/src/AppView.res`
- Pass:
- All required fixture files exist.
- Verifiable by agent: Yes

### C. Dev build checks
#### V4: Dev build emits expected roots
- Command:
- `bun x resx assets build --dev --root test/fixtures/bun-assets-smoke --clean`
- Pass:
- `.resx/dev/assets/` and `.resx/dev/resx-assets.json` exist under fixture root.
- Verifiable by agent: Yes

#### V5: Dev generated files are emitted
- Commands:
- `test -f test/fixtures/bun-assets-smoke/src/__generated__/ResXAssets.res`
- `test -f test/fixtures/bun-assets-smoke/src/__generated__/res-x-assets.js`
- Pass:
- Both generated files exist.
- Verifiable by agent: Yes

#### V6: Dev URLs are stable/unhashed
- Command:
- `rg -n "\"/assets/.*-[0-9a-f]{8}\\." test/fixtures/bun-assets-smoke/.resx/dev/resx-assets.json`
- Pass:
- No hashed asset URLs in dev manifest.
- Verifiable by agent: Yes

#### V7: `resXClient_js` is always present
- Commands:
- `rg -n "\"resXClient_js\"" test/fixtures/bun-assets-smoke/.resx/dev/resx-assets.json`
- `rg -n "resXClient_js" test/fixtures/bun-assets-smoke/src/__generated__/ResXAssets.res`
- Pass:
- `resXClient_js` exists in manifest and ReScript type.
- Verifiable by agent: Yes

#### V8: Watch mode updates changed files
- Script-style commands:
- Start watcher in background:
- `bun x resx assets build --dev --watch --root test/fixtures/bun-assets-smoke > /tmp/resx-watch.log 2>&1 &`
- Modify `assets/styles.css`.
- Wait briefly and assert `.resx/dev/assets/styles.css` changed.
- Kill watcher process.
- Pass:
- Updated source is reflected in dev output.
- Verifiable by agent: Yes

#### V9: Deletion/rename does not leave stale files
- Script-style commands:
- Add temporary asset, run dev build, assert output exists.
- Remove/rename temporary asset, run dev build, assert old output is removed.
- Pass:
- No stale files from deleted/renamed assets.
- Verifiable by agent: Yes

### D. Production build checks
#### V10: Prod build emits hashed assets
- Command:
- `bun x resx assets build --root test/fixtures/bun-assets-smoke --clean`
- Pass:
- `dist/assets/*` includes `-<8hex>` hashed filenames.
- Verifiable by agent: Yes

#### V11: Public files copied unchanged
- Commands:
- `test -f test/fixtures/bun-assets-smoke/dist/robots.txt`
- Compare source and output hashes for a public file.
- Pass:
- Public files exist in `dist/` and bytes match source.
- Verifiable by agent: Yes

#### V12: Prod manifest schema is correct
- Commands:
- Parse `dist/resx-assets.json` and assert:
- `version === 1`
- `mode === "prod"`
- `assets` is an object
- Pass:
- Manifest fields and types match contract.
- Verifiable by agent: Yes

#### V13: Generated ReScript fields match manifest keys
- Commands:
- Extract manifest keys.
- Extract field names from `ResXAssets.res`.
- Compare sets.
- Pass:
- No missing or extra keys (except type-level ordering differences).
- Verifiable by agent: Yes

### E. Runtime serving checks
#### V14: Dev server serves assets from `.resx/dev`
- Commands:
- Start fixture app with `NODE_ENV=development`.
- `curl` `http://localhost:4460/assets/<known-file>`.
- Pass:
- Response is `200` and bytes match `.resx/dev/assets` output.
- Verifiable by agent: Yes

#### V15: Dev server serves `public/` from top-level URLs
- Command:
- `curl -i http://localhost:4460/robots.txt`
- Pass:
- `200` with expected content from fixture `public/robots.txt`.
- Verifiable by agent: Yes

#### V16: Prod server serves from `dist/`
- Commands:
- Run prod build.
- Start fixture app with `NODE_ENV=production`.
- Read one hashed URL from `dist/resx-assets.json`.
- `curl` that URL from server.
- Pass:
- `200` and content matches file in `dist/assets`.
- Verifiable by agent: Yes

#### V17: Path traversal is blocked
- Commands:
- `curl -i "http://localhost:4460/assets/../src/App.js"`
- `curl -i "http://localhost:4460/%2e%2e/%2e%2e/etc/passwd"`
- Pass:
- Requests are denied (`404` or `403`) and do not return file contents.
- Verifiable by agent: Yes

### F. Determinism and failure checks
#### V18: Deterministic manifest and generated outputs
- Commands:
- Run same build twice without source changes.
- Compare checksums of:
- `resx-assets.json`
- `ResXAssets.res`
- `res-x-assets.js`
- Pass:
- Checksums are identical between runs.
- Verifiable by agent: Yes

#### V19: Invalid CLI usage returns code 2
- Command:
- `bun x resx assets build --watch` (without `--dev`) or another invalid combination.
- Pass:
- Command fails with exit code `2` and actionable error message.
- Verifiable by agent: Yes

#### V20: Build failures return code 1
- Commands:
- Introduce a temporary syntax error in fixture asset entry.
- Run build command.
- Pass:
- Command exits with code `1` and reports the failing file.
- Verifiable by agent: Yes

### G. Additional agent-verifiable checks
#### V21: Empty-project build succeeds
- Script-style commands:
- Copy fixture to a temp directory.
- Remove both `assets/` and `public/`.
- Run `bun x resx assets build --dev --root <tmp> --clean`.
- Pass:
- Build succeeds and still emits manifest + generated files (with at least `resXClient_js`).
- Verifiable by agent: Yes

#### V22: Missing-directory matrix succeeds
- Script-style commands:
- Case 1: `assets/` present, `public/` missing.
- Case 2: `public/` present, `assets/` missing.
- Case 3: both missing.
- Run build for each case.
- Pass:
- All cases succeed and outputs/manifest reflect only available inputs.
- Verifiable by agent: Yes

#### V23: Field-name collision handling is deterministic
- Script-style commands:
- Add files that normalize to same field name (for example `a-b.css` and `a_b.css`).
- Build twice from clean state.
- Compare generated key mapping across runs.
- Pass:
- Collision suffixing is stable and identical across runs.
- Verifiable by agent: Yes

#### V24: `/assets/*` conflict policy is enforced
- Script-style commands:
- Add `public/assets/conflict.txt` and `assets/conflict.txt`.
- Build and run server.
- Request `/assets/conflict.txt`.
- Pass:
- Response matches managed asset output, not `public/` override.
- Verifiable by agent: Yes

#### V25: `startDev()` idempotency
- Script-style commands:
- Run fixture app variant that calls `ResX.Assets.startDev()` twice.
- Modify one watched asset once.
- Assert only one rebuild cycle occurs for that change (via deterministic counter/log assertion in test harness).
- Pass:
- Multiple `startDev()` calls do not create duplicate watchers/rebuilds.
- Verifiable by agent: Yes

#### V26: Watch burst stability
- Script-style commands:
- Start dev watch.
- Perform rapid consecutive edits to one CSS and one JS entry.
- Wait for quiescence and inspect outputs + manifest.
- Pass:
- Final outputs and manifest reflect the final source state, with no corruption.
- Verifiable by agent: Yes

#### V27: `--clean` safety boundaries
- Script-style commands:
- Create sentinel files outside output dirs and inside output dirs.
- Run builds with `--clean`.
- Pass:
- Only `.resx/dev/` or `dist/` contents are removed; external sentinels remain untouched.
- Verifiable by agent: Yes

#### V28: `--root` path edge cases
- Script-style commands:
- Run builds with:
- relative root path,
- absolute root path with spaces,
- symlinked root path.
- Pass:
- Outputs are written under resolved root correctly in all cases.
- Verifiable by agent: Yes

#### V29: Traversal hardening for encoded and separator variants
- Commands:
- `curl -i "http://localhost:4460/%252e%252e/%252e%252e/etc/passwd"`
- `curl -i "http://localhost:4460/assets/..%2f..%2fsrc%2fApp.js"`
- `curl -i "http://localhost:4460/assets/..\\..\\src\\App.js"`
- Pass:
- Requests are denied and no sensitive file contents are returned.
- Verifiable by agent: Yes

#### V30: Symlink escape policy is enforced
- Script-style commands:
- Add symlink under `assets/` or `public/` that points outside root.
- Build and run server.
- Pass:
- External target is not copied/served; warning or error is emitted consistently.
- Verifiable by agent: Yes

#### V31: Content-Type headers are correct in dev and prod
- Commands:
- `curl -I` for one CSS, one JS, one image, one text file in dev and prod.
- Pass:
- Responses include expected MIME types for each file kind.
- Verifiable by agent: Yes

#### V32: Package contents are correct
- Commands:
- Run `npm pack --json`.
- Inspect tarball file list.
- Pass:
- Includes new CLI/runtime files; excludes removed Vite/plugin artifacts.
- Verifiable by agent: Yes

#### V33: Fresh-install smoke test from packed tarball
- Script-style commands:
- Create temp project.
- Install packed tarball.
- Run `resx assets build` against minimal fixture-like project.
- Pass:
- Command runs successfully in clean install context.
- Verifiable by agent: Yes

#### V34: Error message ergonomics
- Script-style commands:
- Trigger representative failure modes (invalid CLI args, missing root, syntax error).
- Capture stderr.
- Pass:
- Messages include actionable reason and relevant file/path.
- Verifiable by agent: Yes

### H. User-assisted checks (only where agent verification is limited)
#### U1: Browser-level manual refresh behavior in dev
- Why user help may be needed:
- Agent can validate file/build/HTTP behavior, but not subjective browser UX quality.
- Expected:
- Editing an asset and refreshing the browser loads updated content with no HMR dependency.

#### U2: Cross-platform behavior outside current environment (if needed)
- Why user help may be needed:
- Agent verifies in current environment; Windows-specific path semantics may still need separate run.
- Expected:
- Same verification suite passes on target deployment OSes.

## Risks and mitigations
- Bun CSS entrypoint support unclear: keep PostCSS fallback path in v1.
- Hash naming support unclear: perform explicit post-build content hashing.
- Asset map generation timing vs ReScript compile: provide explicit bootstrap command (`resx assets build --dev`).
- Watch-mode churn risk: use write-if-changed and idempotent watcher startup.

## Acceptance criteria
- No Vite dependency or Vite-specific docs/code in runtime path.
- `resx assets build` produces `dist/` with hashed assets and a correct `ResXAssets` map.
- `ResX.Assets.startDev()` works inside app runtime and keeps assets current in dev.
- Verification fixture project exists and the verification suite above passes.
- Demo runs with Bun-only tooling.
