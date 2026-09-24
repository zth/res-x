import {test, expect} from 'bun:test';
import {createRequire} from 'node:module';
import {readFileSync, mkdtempSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve, join} from 'node:path';
import {createResxTransform} from './oxc-transform.mjs';
import {renderSync} from '../src/vendor/hyperons.js';
const filename = resolve('test/CompilerFixtures.js');
const header = '"use strict"; var H = require("../src/Hjsx.js");\n';
const jsx = 'H.Elements.jsx("div", {children: "<safe>"})';
function evaluate(code) {
  const module = {exports: {}};
  new Function('require', 'module', 'exports', code)(createRequire(filename), module, module.exports);
  return module.exports;
}
async function withTransform(run, options) {
  const transform = createResxTransform(options);
  try { await run(transform); } finally { transform.close(); }
}
test('ordinary stock output has identical exports and HTML, with native construction eliminated', () => withTransform(async t => {
  const code = readFileSync(filename, 'utf8');
  const result = await t.transform(code, filename);
  expect(result.templates).toBeGreaterThan(0);
  const before = evaluate(code), after = evaluate(result.code);
  expect(Object.keys(after)).toEqual(Object.keys(before));
  expect(renderSync(after.catalog(100))).toBe(renderSync(before.catalog(100)));
  const card = result.code.match(/function card\([\s\S]*?\n\}/)[0];
  expect(card).toContain('.template(');
  expect(card).not.toMatch(/\.jsxs?\(/);
  expect(JSON.parse(result.map).sourcesContent).toEqual([code]);
}));
test('scope resolution leaves shadowed factories alone', () => withTransform(async t => {
  const code = header + `exports.real = ${jsx}; exports.fake = function(H) {return ${jsx}};`;
  const result = await t.transform(code, filename);
  expect(result.templates).toBe(1);
  expect(evaluate(result.code).fake({Elements: {jsx: () => 'fake'}})).toBe('fake');
}));
for (const [name, code] of [
  ['unapproved module', 'var H = require("another-framework");'],
  ['shadowed require', 'function require(){}; var H = require("../src/Hjsx.js");'],
  ['binding write', header + 'H = other;'],
  ['factory write', header + 'H.Elements.jsx = custom;'],
  ['namespace escape', header + 'unknown(H);'],
  ['elements escape', header + 'unknown(H.Elements);'],
  ['direct eval', header + 'eval("H.Elements.jsx = custom");'],
]) test(name + ' disables the transform', () => withTransform(async t => {
  expect(await t.transform(code + `exports.tree = ${jsx};`, filename)).toBeNull();
}));
for (const props of ['{...props}', '{get children(){return "x"}}', '{[key]: "x"}', '{id: "a", id: "b"}', '{id: dynamic}', '{style: "color:red"}']) {
  test('unsupported props fall back: ' + props, () => withTransform(async t => {
    expect(await t.transform(header + `exports.tree = H.Elements.jsx("div", ${props});`, filename)).toBeNull();
  }));
}
test('captures evaluate once in order; sparse arrays, escaping and Unicode match', () => withTransform(async t => {
  const code = header + `const marker = "🦊"; let calls = []; function get(x) {calls.push(x);return x;}
exports.tree = H.Elements.jsxs("div", {title: "<&\\\"'", children: [get("first"), H.Elements.jsx("b", {children: get("second")}), [,"🦊", "\\ud800"]]}); exports.calls = calls;`;
  const result = await t.transform(code, filename);
  expect(result.templates).toBeGreaterThan(0);
  const before = evaluate(code), after = evaluate(result.code);
  expect(after.calls).toEqual(['first', 'second']);
  expect(renderSync(after.tree)).toBe(renderSync(before.tree));
  expect(result.code).toContain('const marker = "🦊"');
}));
test('ESM namespace imports and generated name collisions', () => withTransform(async t => {
  const code = 'import * as H from "../src/Hjsx.js"; const __resxWriter0 = 1; export const tree = ' + jsx + ';';
  const result = await t.transform(code, filename.replace('.js', '.mjs'));
  expect(result.templates).toBe(1);
  expect(result.code).toContain('function __resxWriter1(');
  expect(result.code).not.toContain('export function __resxWriter');
}));
test('invalid JavaScript reports an error and the worker remains usable', () => withTransform(async t => {
  await expect(t.transform(header + jsx + '; const =', filename)).rejects.toThrow('parse error');
  expect((await t.transform(header + jsx, filename)).templates).toBe(1);
}));
test('content cache reuses plans and invalidates changed source', async () => {
  const cacheDir = mkdtempSync(join(tmpdir(), 'resx-oxc-cache-'));
  try {
    const code = header + jsx;
    await withTransform(async t => {
      await t.transform(code, filename);
      await t.transform(code, filename);
      expect(t.stats.nativeRequests).toBe(1);
      expect(t.stats.cacheHits).toBe(1);
    }, {cacheDir});
    await withTransform(async t => {
      await t.transform(code, filename);
      expect(t.stats.nativeRequests).toBe(0);
      await t.transform(code.replace('<safe>', 'changed'), filename);
      expect(t.stats.nativeRequests).toBe(1);
    }, {cacheDir});
  } finally { rmSync(cacheDir, {recursive: true, force: true}); }
});

for (const alias of ['output', 'context', 'values']) {
  test('writer parameters do not shadow runtime import ' + alias, () => withTransform(async t => {
    const code = header.replace('var H =', `var ${alias} =`) + `exports.tree = ${jsx.replaceAll('H.Elements', alias + '.Elements')};`;
    const result = await t.transform(code, filename);
    expect(renderSync(evaluate(result.code).tree)).toBe(renderSync(evaluate(code).tree));
  }));
}
test('writer names respect decoded identifiers and unresolved references', () => withTransform(async t => {
  const code = header + 'const __resxWrit\\u0065r0 = 1; function nested(__resxWriter1) {return ' + jsx + ';} exports.tree = ' + jsx + '; exports.missing = typeof __resxWrit\\u0065r2;';
  const result = await t.transform(code, filename);
  expect(evaluate(result.code).missing).toBe('undefined');
  expect(renderSync(evaluate(result.code).tree)).toBe(renderSync(evaluate(code).tree));
}));

test('generated combinations match ordinary rendering and expression evaluation', () => withTransform(async t => {
  const attributes = ['', 'className: "",', 'title: "<&\\\"\'",', 'id: read("id"),', '...{className: "spread"},'];
  const children = ['"🦊<&>"', 'read(0)', 'read(null)', '[read("a"), , read("b")]', 'H.Elements.jsx("b", {children: read("nested")})', 'read(false)'];
  for (const tag of ['div', 'input']) for (const props of attributes) for (const child of children) {
    const code = header + `let calls = []; const read = value => (calls.push(value), value);
exports.tree = H.Elements.jsx(${JSON.stringify(tag)}, {${props} children: ${child}}); exports.calls = calls;`;
    const result = await t.transform(code, filename);
    const before = evaluate(code), after = evaluate(result?.code ?? code);
    expect(renderSync(after.tree)).toBe(renderSync(before.tree));
    expect(after.calls).toEqual(before.calls);
  }
}));

test('closed compiler cannot return stale cached output', async () => {
  const transform = createResxTransform();
  try { await transform.transform(header + jsx, filename); }
  finally { transform.close(); }
  await expect(transform.transform(header + jsx, filename)).rejects.toThrow('closed');
});
