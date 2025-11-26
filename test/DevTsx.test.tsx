import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import { make as Dev } from "../src/Dev.js";

test("Dev component renders (may be empty in production)", async () => {
  const html = await H.renderToString(<Dev port={1234} />);
  expect(typeof html).toBe("string");
});

