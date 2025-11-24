import { test, expect } from "bun:test";
import { CacheControl } from "../src/Utils.js";

test("CacheControl.make builds header string", () => {
  const header = CacheControl.make(
    false,
    "public",
    [{ kind: "max-age", _0: { TAG: "Seconds", _0: 10 } }],
    undefined,
    ["immutable"],
    undefined,
  );
  expect(header).toContain("public");
  expect(header).toContain("max-age=10");
  expect(header).toContain("immutable");
});

