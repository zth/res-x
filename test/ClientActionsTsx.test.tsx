import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import { Actions, ValidityMessage } from "../src/Client.js";

test("Client.Actions serializes and renders as attribute", async () => {
  const actions = Actions.make([
    { kind: "AddClass", target: { kind: "This" }, className: "active" },
    {
      kind: "SwapClass",
      target: { kind: "CssSelector", selector: "#target" },
      fromClassName: "a",
      toClassName: "b",
    },
  ]);

  const html = await H.renderToString(
    <button resx-onclick={actions}>Click</button>
  );

  expect(html).toContain("resx-onclick=");
  expect(html).toContain("AddClass");
  expect(html).toContain("SwapClass");
});

test("Client.ValidityMessage serializes and renders as attribute", async () => {
  const validity = ValidityMessage.make({ valueMissing: "Required field" });
  const html = await H.renderToString(
    <input name="x" required resx-validity-message={validity} />
  );

  expect(html).toContain("resx-validity-message=");
  expect(html).toContain("Required field");
});

