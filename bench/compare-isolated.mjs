import {readFileSync, writeFileSync, mkdirSync, mkdtempSync, rmSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {tmpdir} from 'node:os';
import assert from 'node:assert/strict';
import {createCases} from './fixtures.mjs';
import {compareReports} from './compare.mjs';

const [baselineRoot, candidateRoot, outputDir = 'bench/results/isolated', repeatsArg = '3'] = process.argv.slice(2);
if (!baselineRoot || !candidateRoot) throw new Error('Usage: bun bench/compare-isolated.mjs BASELINE CANDIDATE [OUTPUT_DIR] [REPEATS]');
const repeats = Number(repeatsArg);
assert(Number.isInteger(repeats) && repeats >= 3 && repeats % 2 === 1, 'Use an odd number of runs, at least three');
const directory = resolve(outputDir);
mkdirSync(directory, {recursive: true});
const scratch = mkdtempSync(join(tmpdir(), 'resx-bench-'));
const reports = {baseline: [], candidate: []};
const cases = createCases().filter(c => !process.env.BENCH_EXCLUDE || !c.name.includes(process.env.BENCH_EXCLUDE));
try {
  for (const benchmark of cases) {
    for (let i = 0; i < repeats; i++) {
      // Neighboring runs measure the same workload on both versions; no earlier
      // workload can leave the renderer in a different JIT tier or type profile.
      for (const label of i % 2 ? ['candidate', 'baseline'] : ['baseline', 'candidate']) {
        const file = join(scratch, 'result.json');
        const child = Bun.spawn([process.execPath, resolve(import.meta.dir, 'runner.mjs'), '--output', file], {
          env: {...process.env, BENCH_CASE: benchmark.name, BENCH_ROOT: resolve(label === 'baseline' ? baselineRoot : candidateRoot)},
          stdout: 'ignore', stderr: 'inherit',
        });
        assert.equal(await child.exited, 0, `${label} ${benchmark.name} failed`);
        const report = JSON.parse(readFileSync(file, 'utf8'));
        assert.deepEqual(report.results.map(r => r.name), [benchmark.name]);
        const existing = reports[label][i];
        if (existing) {
          for (const key of ['revision', 'sourceHashes', 'runtime', 'workloadHash', 'cpu', 'isolation']) {
            assert.deepEqual(report[key], existing[key], `${key} changed during measurement`);
          }
          existing.results.push({...report.results[0], timestamp: report.timestamp});
        } else {
          reports[label][i] = {...report, results: [{...report.results[0], timestamp: report.timestamp}]};
        }
        writeFileSync(join(directory, `${label}-${i + 1}.json`), JSON.stringify(reports[label][i], null, 2) + '\n');
      }
    }
    const result = compareReports(reports.baseline, reports.candidate).at(-1);
    console.log(`${result.name.padEnd(38)} ${(result.baselineNs / 1000).toFixed(3)} -> ${(result.candidateNs / 1000).toFixed(3)} us/op (${result.speedup.toFixed(2)}x)`);
  }
  const comparison = compareReports(reports.baseline, reports.candidate);
  writeFileSync(join(directory, 'comparison.json'), JSON.stringify(comparison, null, 2) + '\n');
  const table = ['| Workload | Previous PR µs/op | New µs/op | Additional speedup |', '|---|---:|---:|---:|',
    ...comparison.map(r => `| ${r.name} | ${(r.baselineNs / 1000).toFixed(3)} | ${(r.candidateNs / 1000).toFixed(3)} | ${r.speedup.toFixed(2)}× |`)];
  writeFileSync(join(directory, 'comparison.md'), table.join('\n') + '\n');
} finally {
  rmSync(scratch, {recursive: true, force: true});
}
