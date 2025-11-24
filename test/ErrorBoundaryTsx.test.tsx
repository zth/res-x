import { test, expect } from "bun:test";
import * as H from "../src/H.js";
import { make as ErrorBoundary } from "../src/ErrorBoundary.js";

function Boom() {
  throw new Error("boom");
}

test("ErrorBoundary catches errors and renders fallback", async () => {
  const html = await H.renderToString(
    <ErrorBoundary renderError={() => <div>fallback</div>}>
      <Boom />
    </ErrorBoundary>
  );
  expect(html).toContain("fallback");
});

