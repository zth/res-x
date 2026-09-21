import {cpus, platform, arch} from 'node:os';
import {execFileSync} from 'node:child_process';
import {mkdirSync, writeFileSync, readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname, resolve} from 'node:path';
import {createCases, verifyCase} from './fixtures.mjs';

export function summarize(samples) {
  const sorted = [...samples].sort((a, b) => a - b);
  const median = sorted[Math.floor(sorted.length / 2)];
  return {medianNs: median, minNs: sorted[0], maxNs: sorted.at(-1), opsPerSecond: 1e9 / median};
}
let sink = 0;
function consume(value) { sink = (sink + (typeof value === 'string' ? value.length : value)) | 0; }
function syncBatch(run, count) {
  const start = performance.now();
  for (let i = 0; i < count; i++) consume(run());
  return performance.now() - start;
}
async function asyncBatch(run, count) {
  const start = performance.now();
  for (let i = 0; i < count; i++) consume(await run());
  return performance.now() - start;
}

export async function measure(benchmark, {samples = 9, targetMs = 60, warmupMs = 1000} = {}) {
  await verifyCase(benchmark);
  const batch = benchmark.async ? asyncBatch : syncBatch;
  let count = 1;
  let elapsed;
  const start = performance.now();
  do {
    elapsed = await batch(benchmark.run, count);
    if (elapsed < targetMs / 2) count = Math.min(count * 2, 1 << 20);
  } while (performance.now() - start < warmupMs || elapsed < targetMs / 2 && count < 1 << 20);
  count = Math.max(1, Math.min(1 << 20, Math.round(count * targetMs / Math.max(elapsed, 0.001))));
  const timings = [];
  for (let i = 0; i < samples; i++) timings.push(await batch(benchmark.run, count) * 1e6 / count);
  await verifyCase(benchmark);
  return {name: benchmark.name, iterationsPerSample: count, samplesNs: timings, ...summarize(timings)};
}

if (import.meta.main) {
  const smoke = process.argv.includes('--smoke');
  const outputIndex = process.argv.indexOf('--output');
  const filterIndex = process.argv.indexOf('--filter');
  const filter = filterIndex < 0 ? '' : process.argv[filterIndex + 1];
  const root = resolve(process.env.BENCH_ROOT || new URL('..', import.meta.url).pathname);
  const results = [];
  for (const benchmark of createCases().filter(c => c.name.includes(filter))) {
    const result = await measure(benchmark, smoke ? {samples: 3, targetMs: 2, warmupMs: 5} : {});
    results.push(result);
    console.log(`${result.name.padEnd(38)} ${(result.medianNs / 1000).toFixed(3).padStart(10)} us/op`);
  }
  if (!results.length) throw new Error('No benchmarks matched');
  const report = {
    schemaVersion: 1, timestamp: new Date().toISOString(), runtime: Bun.version,
    platform: platform(), arch: arch(), cpu: cpus()[0]?.model,
    revision: execFileSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).trim(),
    dirty: Boolean(execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], {cwd: root, encoding: 'utf8'}).trim()),
    workloadHash: createHash('sha256').update(readFileSync(new URL('./fixtures.mjs', import.meta.url))).update(readFileSync(import.meta.filename)).digest('hex'),
    sourceHashes: Object.fromEntries(['src/vendor/hyperons.js', 'src/Handlers.js', 'src/RequestController.js'].map(path => [path, createHash('sha256').update(readFileSync(resolve(root, path))).digest('hex')])),
    mode: smoke ? 'smoke' : 'measurement', results, sink,
  };
  if (outputIndex >= 0) {
    const file = process.argv[outputIndex + 1];
    mkdirSync(dirname(file), {recursive: true});
    writeFileSync(file, JSON.stringify(report, null, 2) + '\n');
  }
}
