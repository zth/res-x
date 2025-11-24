import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import { make as RenderInHead } from "../src/RenderInHead.js";
import { make as RenderBeforeBodyEnd } from "../src/RenderBeforeBodyEnd.js";
import { make as makeHandlers, handleRequest } from "../src/Handlers.js";

test("RenderInHead and RenderBeforeBodyEnd append content", async () => {
  const handlers = makeHandlers(async (_req) => ({}));
  const res = await handleRequest(handlers, {
    request: new Request("http://localhost/"),
    render: async ({ requestController }) => (
      <html>
        <head>
          <RenderInHead requestController={requestController}>
            <meta name="x" content="y" />
          </RenderInHead>
        </head>
        <body>
          <div>content</div>
          <RenderBeforeBodyEnd requestController={requestController}>
            <script src="/x.js"></script>
          </RenderBeforeBodyEnd>
        </body>
      </html>
    ),
  });

  const html = await res.text();
  expect(html).toContain("<meta name=\"x\" content=\"y\"/>");
  expect(html).toContain("<script src=\"/x.js\"></script>");
});
