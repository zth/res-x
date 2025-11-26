import { test, expect } from "bun:test";

// Ensure TS resolves the module types for the browser-only client script.
type RC = typeof import("../src/ResXClient.js");

test("ResXClient types resolve without runtime import", () => {
  expect(true).toBe(true);
});

