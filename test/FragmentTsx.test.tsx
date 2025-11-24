import { test, expect } from "bun:test";
import * as H from "../src/H.js";

function Frag() {
  return (
    <>
      <span>a</span>
      <span>b</span>
    </>
  );
}

test("Fragment renders adjacent children", async () => {
  const html = await H.renderToString(<Frag />);
  expect(html).toContain("<span>a</span><span>b</span>");
});

