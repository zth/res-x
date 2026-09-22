import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync, readdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {resxBunPlugin} from './oxc-bun.mjs';
execFileSync('bun', ['run', 'res:build'], {stdio: 'inherit', env: {...process.env, RAYON_NUM_THREADS: '2'}});
const original = readFileSync('test/CompilerFixtures.js', 'utf8');
const entrypoints = readdirSync('test').filter(name => /\.test\.(mjs|js)$/.test(name)).map(name => resolve('test', name));
for (const mode of ['baseline', 'optimized']) {
  const plugin = resxBunPlugin();
  const build = await Bun.build({entrypoints, outdir: `.resx/tests/${mode}`, naming: '[name].js', target: 'bun', format: 'esm', plugins: mode === 'optimized' ? [plugin] : []});
  assert(build.success, String(build.logs));
  execFileSync('bun', ['test', ...build.outputs.filter(out => out.path.endsWith('.js')).map(out => out.path)], {stdio: 'inherit', env: {...process.env, BENCH_ROOT: process.cwd()}});
  if (mode === 'optimized') assert(plugin.stats.templates > 0);
}
assert.equal(readFileSync('test/CompilerFixtures.js', 'utf8'), original);
console.log('Baseline and transformed application bundles pass the same tests; stock output is untouched.');
