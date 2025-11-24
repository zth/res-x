import { test, expect } from "bun:test";
import * as F from "../src/FormDataHelpers.js";

test("FormDataHelpers basic getters", () => {
  const fd = new FormData();
  fd.append("name", "Alice");
  fd.append("age", "42");
  fd.append("pi", "3.14");
  fd.append("flag", "true");

  expect(F.getString(fd, "name")).toBe("Alice");
  expect(F.getInt(fd, "age")).toBe(42);
  expect(F.getFloat(fd, "pi")).toBeCloseTo(3.14);
  expect(F.getBool(fd, "flag")).toBe(true);
});

test("FormDataHelpers arrays + empty handling", () => {
  const fd = new FormData();
  fd.append("tags", "a");
  fd.append("tags", "b");
  fd.append("nums", "1");
  fd.append("nums", "2");
  fd.append("bools", "true");
  fd.append("bools", "false");

  expect(F.getStringArray(fd, "tags")).toEqual(["a", "b"]);
  expect(F.getIntArray(fd, "nums")).toEqual([1, 2]);
  expect(F.getBoolArray(fd, "bools")).toEqual([true, false]);

  const fd2 = new FormData();
  fd2.append("empty", "");
  expect(F.getString(fd2, "empty")).toBe("");
  expect(F.getString(fd2, "empty", true)).toBe("");
});

test("FormDataHelpers expect helpers + custom decoders", () => {
  const fd = new FormData();
  fd.append("name", "Bob");
  fd.append("check", "on");
  fd.append("date", "2020-01-02");

  expect(F.expectString(fd, "name")).toBe("Bob");
  expect(F.expectCheckbox(fd, "check")).toBe(true);
  const d = F.expectDate(fd, "date");
  expect(d instanceof Date).toBe(true);

  // custom ok
  const ok = F.expectCustom(fd, "name", (v) => ({ TAG: "Ok", _0: String(v) }));
  expect(ok).toBe("Bob");

  // getCustom passthrough
  const raw = F.getCustom(fd, "name", (v) => v);
  expect(raw).toBe("Bob");
});
