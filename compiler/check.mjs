import assert from 'node:assert/strict';
import {execFileSync, spawnSync} from 'node:child_process';
import {readFileSync, writeFileSync, rmSync, existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

process.chdir(fileURLToPath(new URL('..', import.meta.url)));
const build = (...args) => execFileSync(process.execPath, ['compiler/build.mjs', ...args], {stdio: 'inherit'});
const snapshot = () => execFileSync('bun', ['-e', `const f = require('./test/CompilerFixtures.js'); const {renderSync} = require('./src/vendor/hyperons.js'); console.log(renderSync(f.catalog(100)));`], {encoding: 'utf8'});
build('--baseline');
execFileSync('bun', ['run', 'test'], {stdio: 'inherit'});
const expected = snapshot();
assert(!readFileSync('test/CompilerFixtures.js', 'utf8').includes('function resxTemplate'));
build();
execFileSync('bun', ['run', 'test'], {stdio: 'inherit'});
assert.equal(snapshot(), expected, 'compiled catalog must match baseline byte for byte');
const generated = readFileSync('test/CompilerFixtures.js', 'utf8');
assert.match(generated, /function resxTemplate\d+\(output/);
const card = generated.match(/function card\([\s\S]*?\n\}/)?.[0];
assert(card?.includes('.template('), 'ordinary JSX must become a template');
assert(!card.includes('.jsx(') && !card.includes('.jsxs('), 'card must eliminate native element construction');
const invalid = 'test/CompilerInvalid.res';
if (existsSync(invalid)) throw new Error(`Refusing to overwrite ${invalid}`);
try {
  writeFileSync(invalid, '@@jsxConfig({module_: "Hjsx"})\nlet invalid = <div title=123 />\n');
  const result = spawnSync(process.execPath, ['compiler/build.mjs'], {encoding: 'utf8'});
  assert.notEqual(result.status, 0, 'original JSX must still be type checked');
  assert.match(result.stdout + result.stderr, /int[\s\S]*string/, 'must fail for the invalid prop type');
} finally {
  rmSync(invalid);
  rmSync('test/CompilerInvalid.js', {force: true});
  build();
}
console.log('Baseline/template parity, emitted specialization, and JSX type checking passed.');
