import { test, expect } from "bun:test";
import { make, hxGetRef, hxGetDefine, handleRequest } from "../src/Handlers.js";
import { allow } from "../src/SecurityPolicy.js";

type Ctx = { userId?: string };

const handlers = make<Ctx>(async (_req) => ({}));

test("handlers TSX types and basic path work", async () => {
  const ref = hxGetRef(handlers, "/ts-ping");
  hxGetDefine(
    handlers,
    ref,
    allow,
    async (_ctx) => {
      return <div>ok</div>;
    }
  );

  const res = await handleRequest(handlers, {
    request: new Request("http://localhost/_api/ts-ping", { method: "GET" }),
    render: async () => <div>fallback</div>,
  });
  expect(res.status).toBe(200);
});
