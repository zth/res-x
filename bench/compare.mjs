import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {resolve, join} from 'node:path';
import assert from 'node:assert/strict';
import {summarize} from './runner.mjs';

export function compareReports(baseline, candidate) {
  assert(baseline.length && baseline.length === candidate.length, 'Use equally many baseline and candidate runs');
  const first = baseline[0];
  const names = first.results.map(r => r.name);
  for (const report of [...baseline, ...candidate]) {
    for (const key of ['schemaVersion', 'runtime', 'platform', 'arch', 'cpu', 'mode', 'workloadHash']) {
      assert.equal(report[key], first[key], `Incompatible ${key}`);
    }
    assert.equal(report.mode, 'measurement', 'Smoke runs are not performance evidence');
    assert.deepEqual(report.results.map(r => r.name), names, 'Workload sets differ');
  }
  return names.map((name, i) => {
    const before = baseline.map(r => r.results[i].medianNs);
    const after = candidate.map(r => r.results[i].medianNs);
    const b = summarize(before), a = summarize(after);
    return {name, baselineNs: b.medianNs, candidateNs: a.medianNs,
      speedup: b.medianNs / a.medianNs, reductionPercent: (1 - a.medianNs / b.medianNs) * 100,
      baselineRangeNs: [b.minNs, b.maxNs], candidateRangeNs: [a.minNs, a.maxNs]};
  });
}

if (import.meta.main) {
  const [baselineRoot, candidateRoot, outputDir = 'bench/results/comparison', repeatsArg = '3'] = process.argv.slice(2);
  if (!baselineRoot || !candidateRoot) throw new Error('Usage: bun bench/compare.mjs BASELINE_ROOT CANDIDATE_ROOT [OUTPUT_DIR] [REPEATS]');
  const repeats = Number(repeatsArg);
  assert(Number.isInteger(repeats) && repeats >= 3, 'Use at least three independent processes per version');
  const directory = resolve(outputDir);
  mkdirSync(directory, {recursive: true});
  const reports = {baseline: [], candidate: []};
  for (let i = 0; i < repeats; i++) {
    // Alternate the order to reduce systematic effects from machine drift.
    for (const label of i % 2 ? ['candidate', 'baseline'] : ['baseline', 'candidate']) {
      const file = join(directory, `${label}-${i + 1}.json`);
      console.log(`\n${label} ${i + 1}/${repeats}`);
      const child = Bun.spawn([process.execPath, resolve(import.meta.dir, 'runner.mjs'), '--output', file], {
        env: {...process.env, BENCH_ROOT: resolve(label === 'baseline' ? baselineRoot : candidateRoot)},
        stdout: 'inherit', stderr: 'inherit',
      });
      assert.equal(await child.exited, 0, `${label} benchmark failed`);
      reports[label].push(JSON.parse(readFileSync(file, 'utf8')));
    }
  }
  const comparison = compareReports(reports.baseline, reports.candidate);
  writeFileSync(join(directory, 'comparison.json'), JSON.stringify(comparison, null, 2) + '\n');
  const table = ['| Workload | Baseline µs/op | Candidate µs/op | Speedup |', '|---|---:|---:|---:|',
    ...comparison.map(r => `| ${r.name} | ${(r.baselineNs / 1000).toFixed(3)} | ${(r.candidateNs / 1000).toFixed(3)} | ${r.speedup.toFixed(2)}× |`)];
  writeFileSync(join(directory, 'comparison.md'), table.join('\n') + '\n');
  console.log('\n' + table.join('\n'));
}
