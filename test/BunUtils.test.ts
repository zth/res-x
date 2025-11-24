import { test, expect } from "bun:test";
import * as BunUtils from "../src/BunUtils.js";

test("URLSearchParams.copy returns a new instance", () => {
  const s = new URLSearchParams([[
    "a",
    "1"
  ]]);
  const c = BunUtils.URLSearchParams.copy(s);
  expect(c.get("a")).toBe("1");
  c.set("a", "2");
  expect(s.get("a")).toBe("1");
});

test("serveStaticFile returns undefined for missing file", async () => {
  const req = new Request("http://localhost/nope");
  const res = await BunUtils.serveStaticFile(req);
  expect(res).toBeUndefined();
});

