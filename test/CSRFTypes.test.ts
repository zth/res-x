import { test, expect } from "bun:test";
import * as CSRF from "../src/CSRF.js";

test("CSRF token generation and verification", async () => {
  const token = CSRF.generateToken();
  expect(typeof token).toBe("string");

  const headers = new Headers({ "X-CSRF-Token": token });
  const req = new Request("http://localhost/", { method: "POST", headers });
  const ok = await CSRF.verifyRequest(req);
  expect(ok).toBe(true);
});

test("CSRF getTokenFromHeaders", () => {
  const h = new Headers({ "x-csrf-token": "abc" });
  expect(CSRF.getTokenFromHeaders(h)).toBe("abc");
});

