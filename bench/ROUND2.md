# Second-pass measured results

Baseline: first-pass PR commit `2b6dbd5`. Candidate: `5bbd562`. These are **additional** changes after the first optimization pass, measured using detached worktree snapshots. The implementation hashes match the current framework files.

Bun 1.3.14, Linux x64, AMD RYZEN AI MAX+ 395, shared development host. Each workload runs in a fresh process, with one second of warmup and nine approximately 60 ms samples. Three baseline/candidate pairs per workload alternate order. Reported values are medians of process medians. Streaming is excluded: 25 of the 28 correctness-checked workloads are measured here.

| Workload | Previous PR µs/op | New µs/op | Additional speedup | Baseline process range µs | New process range µs |
|---|---:|---:|---:|---:|---:|
| html/text-safe-4k | 0.204 | 0.201 | 1.01× | 0.198–0.212 | 0.193–0.201 |
| html/text-escaped | 1.668 | 1.743 | 0.96× | 1.641–1.805 | 1.672–1.795 |
| html/attributes | 0.525 | 0.497 | 1.06× | 0.523–0.536 | 0.496–0.529 |
| html/styles | 0.122 | 0.118 | 1.03× | 0.116–0.127 | 0.115–0.123 |
| html/list-100 | 24.792 | 27.850 | 0.89× | 23.629–24.936 | 24.446–29.624 |
| html/list-100-utf8 | 46.455 | 46.275 | 1.00× | 43.921–48.250 | 43.315–51.414 |
| html/create-and-render-100 | 51.363 | 42.205 | 1.22× | 48.201–62.207 | 41.220–42.967 |
| html/components-100 | 8.806 | 7.070 | 1.25× | 8.208–9.634 | 6.978–7.563 |
| html/context-depth-20 | 1.791 | 1.806 | 0.99× | 1.680–1.882 | 1.771–2.070 |
| html/raw-4k | 0.001 | 0.001 | 1.00× | 0.001–0.002 | 0.001–0.001 |
| html/small-sync-async-api | 0.154 | 0.096 | 1.60× | 0.150–0.170 | 0.095–0.097 |
| html/single-promise | 0.529 | 0.271 | 1.95× | 0.487–0.531 | 0.264–0.280 |
| html/async-api-sync-tree | 25.441 | 24.953 | 1.02× | 24.224–27.836 | 24.064–25.325 |
| html/async-sparse | 57.576 | 45.637 | 1.26× | 53.332–60.287 | 42.963–46.582 |
| html/async-dense-100 | 28.952 | 29.358 | 0.99× | 27.915–29.917 | 25.093–30.282 |
| html/async-nested | 39.836 | 27.710 | 1.44× | 38.425–43.768 | 27.429–31.206 |
| context/als-run | 0.009 | 0.009 | 0.95× | 0.008–0.010 | 0.008–0.010 |
| context/als-read-100 | 0.239 | 0.240 | 1.00× | 0.238–0.264 | 0.221–0.248 |
| context/als-await | 0.116 | 0.118 | 0.98× | 0.115–0.120 | 0.115–0.119 |
| request/controller | 0.111 | 0.086 | 1.29× | 0.098–0.119 | 0.083–0.090 |
| request/minimal | 5.184 | 5.075 | 1.02× | 4.926–5.593 | 4.699–5.743 |
| request/page-100 | 61.919 | 60.161 | 1.03× | 59.919–66.085 | 58.693–61.729 |
| request/context-components-100 | 10.396 | 9.557 | 1.09× | 9.776–11.170 | 9.277–9.721 |
| request/head-title-body | 7.170 | 7.082 | 1.01× | 6.850–8.361 | 6.936–8.061 |
| request/route-hit-1000 | 4.600 | 4.216 | 1.09× | 4.546–4.645 | 3.800–4.281 |
| request/route-miss-1000 | 3.698 | 3.676 | 1.01× | 3.545–3.797 | 3.644–4.255 |

## What changed

- Dedicated two-argument compiler JSX factory: avoids variadic/rest-array work and props mutation. Legacy `h()` remains available. Compiled numeric zero children now render correctly. Component execution stays deferred for context/provider correctness.
- Buffered async API returns immediately for a synchronous tree while retaining a promise-returning contract. A single async subtree skips `Promise.all` coordination.
- Request controllers allocate head, body-end and title collections only on first use; getters still return independent title copies. Default Headers are constructed from a record rather than an iterable of pairs, with a fresh Headers instance per request.

## Interpretation and limits

- Creation plus rendering improves 22% in throughput; component rendering improves 25%. Sparse async rendering improves 26%, nested async 44%, small synchronous trees through the async API 60%, and the isolated single-promise case 95%. The last two are sub-microsecond operations: their ratios do not predict equivalent application throughput improvements.
- Controller operations improve 29% in throughput. Complete page and minimal-request medians improve only about 3% and 2%; their ranges overlap. No substantial additional full-request gain is claimed.
- Prebuilt 100-row synchronous tree rendering has a 12% slower median (0.89×), while rendering plus UTF-8 encoding is essentially unchanged. The faster tree-construction path is therefore not a universal rendering improvement. All slower/control cases are retained in the table.
- Raw-HTML identity work and AsyncLocalStorage controls can be strongly optimized by the JIT; tiny ratios are not evidence of framework gains.
- These isolated-workload measurements use a different protocol from the first-pass suite-in-one-process results. Do not multiply their speedups or directly compare their absolute times across reports.

## Reproduce

```sh
BENCH_EXCLUDE=stream bun bench/compare-isolated.mjs ../res-x-performance-round1 ../res-x-performance-round2 bench/results/recheck-round2 3
```

The snapshot worktrees must contain the revisions listed above and the same dependencies. Use the current harness for both targets. All samples, source hashes and workload timestamps are committed under [results/round2](results/round2/). The comparison rejects mixed source revisions, workload hashes and isolation modes.

## Research and validation

See [RENDERER-RESEARCH.md](RENDERER-RESEARCH.md) for the inspected KitaJS, Hono and Preact implementations, adopted techniques, and rejected experiments. The generic variadic-factory rewrite was discarded; its exploratory pilot files are retained separately.

CI passed all 122 tests with 320 assertions on the pushed implementation and measurement workflow, including compiled JSX zero children, deferred components, promise behavior, header isolation and lazy-controller collection semantics. Existing streaming correctness tests remain; no further streaming optimization was undertaken.
