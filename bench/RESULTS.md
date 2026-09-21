# Measured results

Measured on 2026-09-21 against main commit `9dd19d2693e82d2f979c8d54fe682237d78b72ae`.

Environment: Bun 1.3.14, linux/x64, AMD RYZEN AI MAX+ 395 w/ Radeon 8060S. This is a shared development host, not a dedicated performance machine.

Each result below is the median of three independent process medians. Each process uses one second of warmup per workload and nine approximately 60 ms samples. Baseline/candidate order alternates. Both versions use the same workload and runner files, and identical installed dependencies. All three candidate source hashes match the files delivered in this worktree.

## Results

| Workload | Baseline µs/op | Optimized µs/op | Speedup | Baseline process range µs | Optimized process range µs |
|---|---:|---:|---:|---:|---:|
| html/text-safe-4k | 0.222 | 0.199 | 1.12× | 0.218–0.231 | 0.198–0.202 |
| html/text-escaped | 1.805 | 1.653 | 1.09× | 1.776–1.828 | 1.650–2.567 |
| html/attributes | 1.280 | 1.169 | 1.09× | 1.006–1.307 | 1.100–1.210 |
| html/styles | 0.415 | 0.151 | 2.75× | 0.399–0.430 | 0.142–0.157 |
| html/list-100 | 64.193 | 30.017 | 2.14× | 62.654–65.411 | 29.770–32.907 |
| html/list-100-utf8 | 75.697 | 52.514 | 1.44× | 64.244–76.452 | 48.747–62.834 |
| html/create-and-render-100 | 84.618 | 50.746 | 1.67× | 81.830–84.808 | 48.273–52.961 |
| html/components-100 | 22.981 | 12.665 | 1.81× | 21.377–28.471 | 10.734–13.918 |
| html/context-depth-20 | 5.201 | 3.337 | 1.56× | 4.406–6.162 | 3.235–4.354 |
| html/raw-4k | 0.048 | 0.035 | 1.37× | 0.046–0.050 | 0.033–0.039 |
| html/async-api-sync-tree | 67.221 | 37.527 | 1.79× | 65.640–69.779 | 29.205–46.624 |
| html/async-sparse | 154.399 | 64.929 | 2.38× | 142.150–181.408 | 62.766–66.082 |
| html/stream-async-tail | 84.344 | 67.945 | 1.24× | 83.514–94.283 | 67.545–69.498 |
| html/async-dense-100 | 55.886 | 37.234 | 1.50× | 52.195–56.026 | 33.723–60.436 |
| html/async-nested | 75.396 | 50.984 | 1.48× | 75.224–76.906 | 43.872–54.087 |
| html/stream-sync-tree | 74.261 | 32.750 | 2.27× | 70.217–77.985 | 30.521–42.070 |
| context/als-run | 0.012 | 0.013 | 0.94× | 0.012–0.014 | 0.012–0.013 |
| context/als-read-100 | 0.074 | 0.075 | 1.00× | 0.073–0.075 | 0.073–0.078 |
| context/als-await | 0.132 | 0.126 | 1.05× | 0.127–0.133 | 0.125–0.132 |
| request/controller | 0.178 | 0.178 | 1.00× | 0.165–0.180 | 0.168–0.189 |
| request/minimal | 5.272 | 5.714 | 0.92× | 5.263–5.470 | 5.116–6.642 |
| request/page-100 | 191.210 | 72.595 | 2.63× | 187.388–196.250 | 72.353–83.495 |
| request/context-components-100 | 20.846 | 14.649 | 1.42× | 15.563–22.548 | 14.576–16.554 |
| request/head-title-body | 10.015 | 10.484 | 0.96× | 8.376–10.596 | 8.031–11.493 |
| request/route-hit-1000 | 5.069 | 4.255 | 1.19× | 4.543–5.452 | 4.109–4.836 |
| request/route-miss-1000 | 3.925 | 3.607 | 1.09× | 3.754–4.162 | 3.344–3.613 |

## Interpretation

- The 100-row HTML render takes about 53% less time; the same render plus UTF-8 encoding takes about 31% less time. The encoding result demonstrates that gains persist when materializing bytes.
- Sparse async rendering takes about 58% less time. Static content no longer requires a promise per HTML chunk.
- The complete 100-row page request takes about 62% less time. This includes Request creation, framework processing, Response construction and response-body consumption, but excludes network I/O. It is not a claim of 2.63× higher HTTP throughput.
- The 1,000-route hit workload improves about 19% in throughput. Route registration is outside the timed region; this result also includes the rest of the request pipeline, so it does not isolate the dictionary change.
- AsyncLocalStorage controls and request-controller creation are effectively unchanged. No AsyncLocalStorage optimization is claimed.
- Minimal requests have an approximately 8% slower median and head/title/body injection an approximately 5% slower median in this run. Their process ranges overlap the baseline. This shared-host experiment does not establish a reliable gain or regression for those small workloads; they remain visible as targets for dedicated-host follow-up.

## Warmup sensitivity

The initial 150 ms warmup comparison produced apparent regressions in nested async rendering and synchronous streaming. Raw samples showed large timing shifts within/between processes consistent with JIT tiering effects. Increasing warmup to one second removed those apparent regressions in this run. This is evidence of warmup sensitivity, not proof that all application workloads will improve. Both sets of measurements are retained:

- [Final comparison](results/final/comparison.json), with six adjacent raw result files containing every timed sample, source hashes and environment metadata.
- [Short-warmup comparison](results/short-warmup/comparison.json), with its six raw result files.
- Initial single-process exploratory results are retained directly under `results/`; those used earlier implementations and/or workload sets and are not the final comparison.

## Reproduce

```sh
bun run bench:compare -- ../res-x . bench/results/recheck 3
```

See [README.md](README.md) for setup, workload scope and measurement limitations. Avoid overlapping benchmark runs with builds or tests. Use the deployment Bun version on a quiet host before setting performance budgets.

## Correctness coverage

The normal test suite includes exact-output checks for all 26 benchmark workloads, runner/comparison tests, renderer fast-path tests, async ordering/rejection/context tests, streaming order tests, 32 concurrent request isolation checks, route-table tests, and the existing security/routing/rendering integration tests. Test servers now request OS-assigned ports to avoid the random-port collisions observed during baseline validation.

Validation completed: ReScript build passed; `bun run test` passed all 113 tests (286 assertions); `bun run bench:smoke` and `git diff --check` passed.
