import { test, expect } from "bun:test";
import * as Security from "../src/Security.js";
import * as StaticExporter from "../src/StaticExporter.js";

test("escapeHTML escapes characters", () => {
  expect(Security.escapeHTML("<div>"))
    .toBe("&lt;div&gt;");
});

test("StaticExporter debug/log callable", () => {
  StaticExporter.debug("hello");
  StaticExporter.log("hello");
  expect(true).toBe(true);
});

