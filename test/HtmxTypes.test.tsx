import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import * as Htmx from "../src/Htmx.js";

test("Htmx helpers produce strings usable as attributes", async () => {
  const swap = Htmx.Swap.make("innerHTML", "Transition");
  const html = await H.renderToString(<div hx-swap={swap}>Hello</div>);
  expect(html).toContain("hx-swap=");
  expect(html).toContain("transition:true");
});

