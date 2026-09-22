# Final merge-level measurements

Direct comparison of main `9dd19d2693e82d2f979c8d54fe682237d78b72ae` against final implementation snapshot `5bbd562a235c59a75c726030c74835d8c74bc681`. SHA-256 hashes of all four measured framework files match the delivered PR implementation. Later commits contain measurement tooling, results, documentation and tests.

Measured on Bun 1.3.14, Linux x64, AMD RYZEN AI MAX+ 395, shared development host. Each workload/version runs in a fresh process: one second warmup, nine approximately 60 ms samples, three alternating baseline/candidate pairs. Values are medians of process medians; ranges below are the minimum and maximum process medians, not confidence intervals. All 25 non-streaming workloads verify their expected output before and after timing.

These direct measurements supersede the earlier two rounds for assessing this merge. In particular, the complete page request is **1.42× faster (29.5% less time)**, not the earlier suite-level 2.63× estimate. The isolated protocol avoids preceding workloads changing the JIT/type profile; shared-host noise remains. Do not multiply earlier rounds' ratios.

| Workload | Main µs/op | Final PR µs/op | Speedup | Main process range µs | Final process range µs |
|---|---:|---:|---:|---:|---:|
| html/text-safe-4k | 0.224 | 0.196 | 1.15× | 0.221–0.237 | 0.192–0.203 |
| html/text-escaped | 1.900 | 1.855 | 1.02× | 1.789–1.964 | 1.743–1.910 |
| html/attributes | 0.549 | 0.546 | 1.01× | 0.528–0.550 | 0.506–0.560 |
| html/styles | 0.358 | 0.119 | 3.01× | 0.335–0.369 | 0.117–0.121 |
| html/list-100 | 52.883 | 25.828 | 2.05× | 51.379–55.351 | 23.281–25.924 |
| html/list-100-utf8 | 51.578 | 44.355 | 1.16× | 51.162–55.252 | 43.895–46.522 |
| html/create-and-render-100 | 69.073 | 41.940 | 1.65× | 68.798–74.832 | 39.933–43.780 |
| html/components-100 | 15.205 | 7.775 | 1.96× | 14.911–15.211 | 7.152–8.621 |
| html/context-depth-20 | 2.078 | 1.894 | 1.10× | 2.038–2.375 | 1.879–1.900 |
| html/raw-4k | 0.020 | 0.001 | 14.21× | 0.020–0.022 | 0.001–0.002 |
| html/small-sync-async-api | 0.287 | 0.098 | 2.92× | 0.282–0.356 | 0.098–0.105 |
| html/single-promise | 0.520 | 0.277 | 1.88× | 0.515–0.530 | 0.266–0.300 |
| html/async-api-sync-tree | 54.583 | 26.852 | 2.03× | 53.350–58.849 | 26.100–27.432 |
| html/async-sparse | 140.428 | 43.865 | 3.20× | 130.479–142.627 | 42.237–46.022 |
| html/async-dense-100 | 41.748 | 26.078 | 1.60× | 39.914–45.170 | 25.671–28.904 |
| html/async-nested | 56.136 | 25.653 | 2.19× | 54.828–63.379 | 25.260–26.179 |
| context/als-run | 0.009 | 0.010 | 0.88× | 0.009–0.009 | 0.008–0.012 |
| context/als-read-100 | 0.230 | 0.251 | 0.92× | 0.220–0.237 | 0.245–0.277 |
| context/als-await | 0.121 | 0.126 | 0.96× | 0.121–0.122 | 0.119–0.134 |
| request/controller | 0.099 | 0.086 | 1.14× | 0.096–0.101 | 0.082–0.087 |
| request/minimal | 5.062 | 4.770 | 1.06× | 4.898–5.322 | 4.693–4.963 |
| request/page-100 | 82.424 | 58.079 | 1.42× | 82.403–83.742 | 56.369–61.685 |
| request/context-components-100 | 11.188 | 10.192 | 1.10× | 10.851–11.941 | 9.508–10.980 |
| request/head-title-body | 8.179 | 6.834 | 1.20× | 8.065–8.346 | 6.542–7.065 |
| request/route-hit-1000 | 4.084 | 3.539 | 1.15× | 4.055–4.263 | 3.509–3.682 |
| request/route-miss-1000 | 3.561 | 3.240 | 1.10× | 3.375–3.591 | 2.867–3.491 |

## What helped

- String accumulation, primitive-child fast paths, fewer context updates, and pending work only for actual async subtrees reduce renderer overhead. The 100-row render is 2.05× faster; sparse async rendering is 3.20× faster.
- A dedicated compiler JSX entry point avoids variadic allocation and props mutation. Creating and rendering 100 rows is 1.65× faster overall; 100 components render 1.96× faster. Components remain deferred and text remains escaped.
- Synchronous results and a single-promise fast path avoid unnecessary async coordination. Small synchronous trees through the async API improve 2.92×, but save only about 0.19 µs per call.
- Lazy controller collections, dictionary route lookup, fresh record-based Headers, and skipping the absent after-render hook reduce request overhead. Full page requests improve 1.42×; route hits improve 1.15×. These are combined-change measurements, not isolated attribution to individual edits.
- KitaJS, Hono and Preact informed the compiler entry point and synchronous-path approach; see [research](RENDERER-RESEARCH.md).

## What did not help, and limits

- Escaping-heavy text (1.02×) and attribute-heavy rendering (1.01×) are essentially unchanged. The existing native escaping implementation was already efficient.
- AsyncLocalStorage was not changed. Controls have slower medians (0.88–0.96×); no ALS improvement is claimed. Minimal requests improve only 1.06×, with overlapping process ranges.
- A generic variadic `h()` rewrite was rejected after pilot regressions. The second pass also had a slower prebuilt-list median than the first pass; final versus main still improves 2.05×.
- The raw-HTML identity case's 14.21× ratio measures about 19 ns saved and is susceptible to JIT elimination. It is not a useful application speedup claim.
- UTF-8 materialization reduces the renderer gain to 1.16×. These separate JIT-compiled workloads must not be subtracted to estimate encoding cost.
- Request cases include fresh Request construction, framework handling and Response.text(), but no network, TLS or database. Native Request/Response/Headers/URL costs limit further gains. This is not a claim of equivalent production HTTP throughput or latency improvements.
- Streaming performance is excluded. Existing correctness coverage remains.

## Reproduce

```sh
BENCH_EXCLUDE=stream bun bench/compare-isolated.mjs ../res-x ../res-x-performance-round2 bench/results/recheck-merge 3
```

Use the baseline and candidate revisions above with identical dependencies. [Raw samples and comparison](results/merge/) include source hashes, timestamps and all slower/control cases. A test recomputes this comparison from the committed samples. See [README](README.md) for harness details and the earlier [first](RESULTS.md) and [second](ROUND2.md) passes for historical experiments.
