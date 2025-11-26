import type { ResxElement } from "rescript-x/H";
// This file renders the outer HTML shell for every page.
// Vite plugin generates __generated__/res-x-assets.js during dev/build.
// We use that for including the ResX client in dev.
// If not present (e.g., first run before vite started), we fall back to node_modules path.

let clientSrc = "/node_modules/rescript-x/src/ResXClient.js";
try {
  const modPath = new URL("../__generated__/res-x-assets.js", import.meta.url).href;
  const g: any = await import(/* @vite-ignore */ modPath);
  if (g && typeof g.assets?.resXClient_js === "string") {
    clientSrc = g.assets.resXClient_js as string;
  }
} catch {}

export function Html({ children }: { children?: ResxElement | ResxElement[] }) {
  return (
    <html>
      <head>
        <link rel="stylesheet" type="text/css" href="/assets/styles.css" />
      </head>
      <body class="wrap">
        {children}
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
        <script src={clientSrc} async></script>
      </body>
    </html>
  );
}
