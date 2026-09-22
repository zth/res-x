import assert from 'node:assert/strict';
import {execFileSync, spawnSync} from 'node:child_process';
import {readFileSync, writeFileSync, rmSync, existsSync, mkdtempSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
process.chdir(root);
const output = join(root, '.resx/build');
const build = (...args) => execFileSync(process.execPath, ['compiler/build.mjs', ...args], {stdio: 'inherit'});
const snapshot = cwd => execFileSync('bun', ['-e', `const f = require('./test/CompilerFixtures.js'); const {renderSync} = require('./src/vendor/hyperons.js'); console.log(JSON.stringify({exports: Object.keys(f).sort(), html: renderSync(f.catalog(100))}));`], {cwd, encoding: 'utf8'});
build('--baseline');
execFileSync('bun', ['run', 'test'], {stdio: 'inherit'});
const expected = snapshot(root);
const originalJS = readFileSync('test/CompilerFixtures.js', 'utf8');
const originalSource = readFileSync('test/CompilerFixtures.res', 'utf8');
build();
execFileSync('bun', ['run', 'test'], {cwd: output, stdio: 'inherit'});
assert.equal(snapshot(output), expected, 'HTML and public exports must match baseline');
assert.equal(readFileSync('test/CompilerFixtures.js', 'utf8'), originalJS, 'stock JS must remain untouched');
assert.equal(readFileSync('test/CompilerFixtures.res', 'utf8'), originalSource, 'source must remain untouched');
const originalCompiler = JSON.parse(readFileSync('lib/bs/compiler-info.json', 'utf8'));
const generatedCompiler = JSON.parse(readFileSync(join(output, 'lib/bs/compiler-info.json'), 'utf8'));
assert.match(originalCompiler.bsc_path, /node_modules\/@rescript\//, 'first stage must use npm stock compiler');
assert.equal(generatedCompiler.bsc_path, originalCompiler.bsc_path);
assert.equal(generatedCompiler.bsc_hash, originalCompiler.bsc_hash);
const generated = readFileSync(join(output, 'test/CompilerFixtures.js'), 'utf8');
assert.match(generated, /function resxHtml\w+Writer\d+\(output/);
assert(!/exports\.resxHtml/.test(generated), 'writers must remain private');
const card = generated.match(/function card\([\s\S]*?\n\}/)?.[0];
assert(card?.includes('.template('), 'ordinary JSX must become a template');
assert(!card.includes('.jsx(') && !card.includes('.jsxs('), 'card must eliminate native element construction');
const temporary = mkdtempSync(join(tmpdir(), 'resx-cmt-check-'));
try {
  const source = join(temporary, 'stale.res');
  writeFileSync(source, originalSource + '\n// changed after compilation\n');
  const analyzer = process.env.RESX_ANALYZER || readFileSync('compiler/.toolchain/analyzer', 'utf8').trim();
  const result = spawnSync(analyzer, ['lib/ocaml/CompilerFixtures-ResX.cmt', source, join(temporary, 'output.res')], {encoding: 'utf8'});
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Stale compiler artifact/);
  assert(!existsSync(join(temporary, 'output.res')));
} finally { rmSync(temporary, {recursive: true, force: true}); }
const invalid = 'test/CompilerInvalid.res';
if (existsSync(invalid)) throw new Error(`Refusing to overwrite ${invalid}`);
try {
  writeFileSync(invalid, '@@jsxConfig({module_: "Hjsx"})\nlet invalid = <div title=123 />\n');
  const result = spawnSync(process.execPath, ['compiler/build.mjs'], {encoding: 'utf8'});
  assert.notEqual(result.status, 0, 'stock compiler must still reject invalid JSX');
  assert.match(result.stdout + result.stderr, /int[\s\S]*string/);
} finally {
  rmSync(invalid);
  rmSync('test/CompilerInvalid.js', {force: true});
  build();
}
console.log('Stock compiler identity, source isolation, CMT freshness, generated code, and HTML parity passed.');
