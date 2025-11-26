import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import { make as CSRFToken } from "../src/CSRFToken.js";

test("CSRFToken renders hidden input", async () => {
  const html = await H.renderToString(
    <form>
      <CSRFToken />
    </form>
  );
  expect(html).toContain("name=\"resx_csrf_token\"");
  expect(html).toContain("type=\"hidden\"");
});

