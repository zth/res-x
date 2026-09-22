import {execFileSync} from 'node:child_process';
import {writeFileSync, mkdirSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {createRequire} from 'node:module';
import {createResxBunPlugin} from './oxc-bun.mjs';

if (!globalThis.Bun) throw new Error('Run this build adapter with Bun');
const root = process.cwd();
const baseline = process.argv.includes('--baseline');
const entryIndex = process.argv.indexOf('--entry');
const entry = resolve(root, entryIndex < 0 ? 'src/Demo.js' : process.argv[entryIndex + 1]);
const require = createRequire(join(root, 'package.json'));
const cli = join(dirname(require.resolve('rescript/package.json')), 'cli/rescript.js');
const env = {...process.env, RAYON_NUM_THREADS: process.env.RAYON_NUM_THREADS || '2'};
delete env.RESCRIPT_BSC_EXE;
const start = performance.now();
execFileSync('node', [cli], {cwd: root, env, stdio: 'inherit'});
const stockCompileMs = performance.now() - start;
const instance = baseline ? null : createResxBunPlugin({cacheDir: join(root, '.resx/cache/oxc')});
const bundleStart = performance.now();
const outdir = join(root, baseline ? '.resx/baseline' : '.resx/optimized');
try {
  const result = await Bun.build({entrypoints: [entry], outdir, target: 'bun', format: 'esm',
    define: {'process.env.NODE_ENV': JSON.stringify('production')},
    naming: 'app.mjs', sourcemap: 'external', plugins: instance ? [instance.plugin] : []});
  if (!result.success) throw new AggregateError(result.logs, 'Application bundle failed');
  const report = {mode: baseline ? 'baseline' : 'oxc', entry, outdir, stockCompileMs,
    bundleMs: performance.now() - bundleStart, totalMs: performance.now() - start, ...instance?.transform.stats};
  mkdirSync(join(root, '.resx'), {recursive: true});
  writeFileSync(join(root, '.resx/build-report.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report));
} finally { instance?.transform.close(); }
