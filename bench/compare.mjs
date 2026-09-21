import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {resolve, join} from 'node:path';
import assert from 'node:assert/strict';
import {summarize} from './runner.mjs';

export function compareReports(baseline, candidate) {
  assert(baseline.length && baseline.length === candidate.length, 'Use equally many baseline and candidate runs');
  assert(baseline.length % 2 === 1, 'Use an odd number of runs for an unambiguous middle sample');
  for (const group of [baseline, candidate]) {
    assert(group[0].sourceHashes && Object.keys(group[0].sourceHashes).length, 'Missing source hashes');
    for (const report of group) {
      assert.equal(report.revision, group[0].revision, 'Revision changed within a version');
      assert.deepEqual(report.sourceHashes, group[0].sourceHashes, 'Sources changed within a version');
    }
  }
  const first = baseline[0];
  assert.equal(first.schemaVersion, 1, 'Unsupported report schema');
  const names = first.results.map(r => r.name);
  assert(names.length && new Set(names).size === names.length, 'Expected unique, nonempty workloads');
  for (const report of [...baseline, ...candidate]) {
    for (const key of ['schemaVersion', 'runtime', 'platform', 'arch', 'cpu', 'mode', 'workloadHash']) {
      assert.equal(report[key], first[key], `Incompatible ${key}`);
    }
    assert(report.results.every(r => Number.isFinite(r.medianNs) && r.medianNs > 0), 'Expected finite, positive timings');
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
  assert(Number.isInteger(repeats) && repeats >= 3 && repeats % 2 === 1, 'Use an odd number of independent processes per version (at least three)');
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
