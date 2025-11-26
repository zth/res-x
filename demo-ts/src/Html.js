import { jsx as _jsx, jsxs as _jsxs } from "rescript-x/jsx-runtime";
// This file renders the outer HTML shell for every page.
// Vite plugin generates __generated__/res-x-assets.js during dev/build.
// We use that for including the ResX client in dev.
// If not present (e.g., first run before vite started), we fall back to node_modules path.
let clientSrc = "/node_modules/rescript-x/src/ResXClient.js";
try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const g = await import("../__generated__/res-x-assets.js");
    if (g && typeof g.assets?.resXClient_js === "string") {
        clientSrc = g.assets.resXClient_js;
    }
}
catch { }
export function Html({ children }) {
    return (_jsxs("html", { children: [_jsx("head", { children: _jsx("link", { rel: "stylesheet", type: "text/css", href: "/assets/styles.css" }) }), _jsxs("body", { class: "wrap", children: [children, _jsx("script", { src: "https://unpkg.com/htmx.org@1.9.10" }), _jsx("script", { src: clientSrc, async: true })] })] }));
}
