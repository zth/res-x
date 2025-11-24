import { jsx as _jsx, jsxs as _jsxs } from "rescript-x/jsx-runtime";
import { make as makeHandlers, handleRequest, hxGet, hxGetRef, hxGetDefine } from "rescript-x/src/Handlers.js";
import { make as RenderInHead } from "rescript-x/src/RenderInHead.js";
import { make as RenderBeforeBodyEnd } from "rescript-x/src/RenderBeforeBodyEnd.js";
import { allow } from "rescript-x/src/SecurityPolicy.js";
import * as BunUtils from "rescript-x/src/BunUtils.js";
import { Html } from "./Html.js";
import { Home } from "./pages/Home.js";
const handlers = makeHandlers(async (_req) => ({}));
// Simple HTMX handler: GET /_api/hello
const helloUrl = hxGet(handlers, "/hello", allow, async () => {
    return _jsx("div", { id: "htmx-target", children: "Hello from HTMX!" });
});
// Define a ref-first handler for current time
const timeRef = hxGetRef(handlers, "/time");
hxGetDefine(handlers, timeRef, allow, async () => {
    return _jsxs("div", { id: "htmx-target", children: ["Time: ", new Date().toLocaleTimeString()] });
});
const port = 4444;
const server = Bun.serve({
    development: BunUtils.isDev,
    port,
    fetch: async (request) => {
        return handleRequest(handlers, {
            request,
            render: async ({ requestController }) => (_jsxs(Html, { children: [_jsx(RenderInHead, { requestController: requestController, children: _jsx("meta", { name: "demo", content: "ts-only" }) }), _jsx("div", { children: _jsx(Home, { helloUrl: helloUrl, timeUrl: timeRef }) }), _jsx(RenderBeforeBodyEnd, { requestController: requestController, children: _jsx("script", { children: "console.log(\"ResX TS demo loaded\")" }) })] })),
        });
    },
});
console.log(`Listening on http://localhost:${server.port}`);
// Optional: Start a lightweight dev websocket helper
if (BunUtils.isDev)
    BunUtils.runDevServer(port);
