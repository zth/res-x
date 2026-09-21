import {describe, test, expect} from 'bun:test';
import {createCases, verifyCase} from '../bench/fixtures.mjs';
import {measure, summarize} from '../bench/runner.mjs';

describe('benchmark workloads', () => {
  for (const benchmark of createCases()) {
    test(benchmark.name, async () => {
      await verifyCase(benchmark);
      await verifyCase(benchmark); // Catch consumed promises, request bodies, and mutable fixtures.
    });
  }
  test('names are unique', () => {
    const names = createCases().map(c => c.name);
    expect(new Set(names).size).toBe(names.length);
  });
  test('statistics use sorted copies and nanosecond units', () => {
    const samples = [300, 100, 200];
    expect(summarize(samples)).toEqual({medianNs: 200, minNs: 100, maxNs: 300, opsPerSecond: 5e6});
    expect(samples).toEqual([300, 100, 200]);
  });
  test('runner measures both sync and async work and rejects incorrect output', async () => {
    for (const isAsync of [false, true]) {
      const c = {name: 'test', async: isAsync, run: isAsync ? async () => 'ok' : () => 'ok', expected: 'ok'};
      const result = await measure(c, {samples: 3, targetMs: 1, warmupMs: 1});
      expect(result.samplesNs).toHaveLength(3);
      expect(result.medianNs).toBeGreaterThan(0);
      expect(result.iterationsPerSample).toBeGreaterThan(0);
      await expect(measure({...c, expected: 'wrong'})).rejects.toThrow();
    }
  });
});

import {compareReports} from '../bench/compare.mjs';
test('comparison reports measured speedups and rejects incomparable runs', () => {
  const report = {schemaVersion: 1, runtime: 'test', platform: 'linux', arch: 'x64', cpu: 'test', mode: 'measurement', workloadHash: 'same', results: [{name: 'test', medianNs: 100}]};
  const candidate = {...report, results: [{name: 'test', medianNs: 50}]};
  expect(compareReports([report], [candidate])[0]).toMatchObject({speedup: 2, reductionPercent: 50});
  for (const difference of [{runtime: 'other'}, {mode: 'smoke'}, {workloadHash: 'different'}, {results: [{name: 'other', medianNs: 50}]}]) {
    expect(() => compareReports([report], [{...candidate, ...difference}])).toThrow();
  }
});
