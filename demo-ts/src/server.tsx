import * as H from "rescript-x/src/H";
import { make as makeHandlers, handleRequest, hxGet, hxGetRef, hxGetDefine } from "rescript-x/src/Handlers";
import { make as RenderInHead } from "rescript-x/src/RenderInHead";
import { make as RenderBeforeBodyEnd } from "rescript-x/src/RenderBeforeBodyEnd";
import { allow } from "rescript-x/src/SecurityPolicy";
import * as BunUtils from "rescript-x/src/BunUtils";
import { Html } from "./Html.js";
import { Home } from "./pages/Home.js";

type Ctx = { };

const handlers = makeHandlers<Ctx>(async (_req) => ({}));

// Simple HTMX handler: GET /_api/hello
const helloUrl = hxGet(handlers, "/hello", allow, async () => {
  return <div id="htmx-target">Hello from HTMX!</div>;
});

// Define a ref-first handler for current time
const timeRef = hxGetRef(handlers, "/time");
hxGetDefine(handlers, timeRef, allow, async () => {
  return <div id="htmx-target">Time: {new Date().toLocaleTimeString()}</div>;
});

const port = 4444;

const server = Bun.serve({
  development: BunUtils.isDev,
  port,
  fetch: async (request) => {
    return handleRequest(handlers, {
      request,
      render: async ({ requestController }) => (
        <Html>
          <RenderInHead requestController={requestController}>
            <meta name="demo" content="ts-only" />
          </RenderInHead>
          <div>
            <Home helloUrl={helloUrl} timeUrl={timeRef} />
          </div>
          <RenderBeforeBodyEnd requestController={requestController}>
            <script>console.log("ResX TS demo loaded")</script>
          </RenderBeforeBodyEnd>
        </Html>
      ),
    });
  },
});

console.log(`Listening on http://localhost:${server.port}`);

// Optional: Start a lightweight dev websocket helper
if (BunUtils.isDev) BunUtils.runDevServer(port);
