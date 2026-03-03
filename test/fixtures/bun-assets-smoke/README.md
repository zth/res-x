# bun-assets-smoke fixture

This fixture exists to verify the Bun-only asset pipeline plan end-to-end.

It is intentionally small and deterministic:
- fixed app port (`4460`)
- stable asset set (`assets/` + `public/`)
- generated files committed under `src/__generated__/`

Primary verification runner:
- `bun run scripts/verify.mjs`

This suite is expected to fail until the Bun migration implementation is complete.

Local smoke commands inside this repository:
- `bun res:build` (links local `rescript-x`/`rescript-bun` from repo root and compiles)
- `bun assets:dev`
- `bun dev`
