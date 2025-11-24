# ResX TypeScript Demo

A minimal, TypeScript-only example showing how to build a ResX app with TSX.

## Scripts

- `bun install` — install dependencies
- `bun run dev:server` — start Bun server on http://localhost:4444
- `bun run dev:vite` — start Vite dev server on http://localhost:9000

Open http://localhost:9000 in your browser. The Vite plugin proxies dynamic routes to the Bun server and serves assets from `assets/`.

## Files

- `tsconfig.json` — configured for TSX via `jsxImportSource: "rescript-x"`
- `vite.config.ts` — uses the ResX Vite plugin
- `assets/styles.css` — sample CSS
- `src/Html.tsx` — outer HTML shell, includes HTMX + ResX client scripts
- `src/pages/Home.tsx` — page component using HTMX + Client actions
- `src/server.ts` — Bun server + ResX handlers

## Notes

- The Vite plugin generates `src/__generated__/res-x-assets.js` in dev; `Html.tsx` imports it when available to reference the ResX client bundle path. If it's not yet generated, it falls back to `/node_modules/rescript-x/src/ResXClient.js` in dev.
- For production builds, run `bun run build` to build the asset bundle; serve `dist/` with your preferred static file server alongside your Bun server.

