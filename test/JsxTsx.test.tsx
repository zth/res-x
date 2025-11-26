import { test, expect } from "bun:test";
import * as H from "../src/H.js";

function Hello({ name }: { name: string }) {
  return <div class="greet">Hello {name}</div>;
}

test("TSX JSX renders string", async () => {
  const html = await H.renderToString(<Hello name="TS" />);
  expect(typeof html).toBe("string");
  expect(html).toContain("Hello TS");
});

test("children typing works", async () => {
  const html = await H.renderToString(
    <div>
      <span>Child</span>
    </div>
  );
  expect(html).toContain("Child");
});
