# Framework performance benchmarks

Run from the repository root with the project's locked dependencies installed:

```sh
npm ci
bun run res:build
bun run test
bun run bench
bun run bench -- --filter html/ --output /tmp/rendering.json
bun run bench:smoke
```

`bun run test` verifies every benchmark's exact expected output twice, exercises the runner and comparison statistics, and runs renderer/request-context regression tests. CI also executes the short benchmark smoke run. Timing thresholds are deliberately not part of correctness tests: shared CI scheduling and JIT behavior can easily produce false regressions.

## What is measured

The 28 workloads cover safe and escaped text, attributes/raw attributes, styles, raw HTML, a 100-row list, list construction plus rendering, UTF-8 encoding, function components, nested provider contexts, the async API on small and large synchronous trees, a single resolved promise, sparse/dense/nested async trees, streaming, AsyncLocalStorage run/read/await, request controller operations, minimal requests, full pages, request-context consumers, head/title/body injection, and route hits/misses with 1,000 registered routes.

Rendering-only cases reuse immutable trees; `create-and-render` includes tree creation. Async workloads create fresh promises each iteration. Request workloads create a fresh Request, execute `Handlers.handleRequest`, and consume `Response.text()`. They include context creation, routing, rendering, response construction and body consumption, but no sockets, TLS, database or external I/O. Route registration happens outside timing. They are **in-process request costs**, not HTTP server throughput.

The HTML benchmarks measure string construction; strings can remain ropes internally. The separate UTF-8 workload forces encoding, and complete-request benchmarks consume the response body. This distinguishes construction gains from savings that persist when producing bytes. The output sink uses lengths/numeric results; correctness assertions run outside timing.

AsyncLocalStorage-only cases are controls that isolate runtime costs. `request/context-components-100` exercises the actual framework context API. Runtime microbenchmarks can be heavily optimized by the JIT; interpret them alongside complete request results. No change to AsyncLocalStorage semantics is made.

## Compare checkouts reproducibly

Keep baseline and candidate source trees separate and install/build the same dependencies in both. Use the **candidate's harness for both versions**, so workloads cannot drift:

```sh
bun run bench:compare -- ../res-x . bench/results/comparison 3
```

The runner imports the framework from `BENCH_ROOT` (the current repository by default). You can also collect an individual baseline:

```sh
BENCH_ROOT=../res-x bun bench/runner.mjs --output /tmp/baseline.json
```

Each case receives at least 1,000 ms of warmup, adaptive batch calibration, then nine approximately 60 ms samples. Sync cases use a synchronous inner loop; async cases await each operation. The reported per-process result is the median time per operation. The comparison launches three fresh processes per version by default, alternates baseline/candidate order, and takes the median of the process medians. Raw samples and process-median ranges are retained. The speedup is baseline time divided by candidate time.

JSON records include Bun version, CPU/OS/architecture, git revision and tracked dirty state, source hashes, and the hash of the shared fixtures/runner. The comparison rejects differing runtime metadata, workload hashes, workload sets, smoke results, invalid timings, and source/revision changes within either version. Use an odd number of processes (at least three). The dirty flag does not include untracked files; source hashes identify the actual measured implementation.

Run comparisons on an otherwise idle machine using the deployment Bun version. Avoid overlapping benchmarks, test runs or builds. Shared-host load, CPU scaling, GC and JIT tiering still affect results; modest differences and overlapping ranges are not proof of an improvement. This suite is not a memory profiler, a cold-start benchmark, or a substitute for application load tests. In particular, the experimental streaming tests check ordering and final bytes, not backpressure or time to first byte.

## Implementation notes

The renderer accumulates static spans as strings, handles primitive children without recursive dispatch, and allocates pending work only for asynchronous subtrees. It updates provider context when invoking components rather than on every text/DOM node. Promise results fill their original positions, preserving document order.

The streaming callback receives the ready prefix before the first async subtree, then the ordered remainder after pending work completes. This fixes prior corruption with multiple async siblings/nested promises, but deliberately buffers content after the first async boundary. Error boundaries render their fallback without appending an internal array length. The legacy `h()` factory retains its behavior; compiled ReScript JSX now uses a dedicated factory that preserves numeric zero. Comparison fixtures use arrays for numeric children so old and new code render identical output.

Routes use dictionaries instead of persistent balanced trees: registration mutates internal tables, and request lookup performs direct property access. Route matching, method separation, first-registration-wins behavior and form-action precedence remain covered by tests. Response construction skips awaiting a default no-op callback when no after-render hook is supplied.

See [RESULTS.md](RESULTS.md) for the first pass, [ROUND2.md](ROUND2.md) for further gains against that PR, and [RENDERER-RESEARCH.md](RENDERER-RESEARCH.md) for techniques investigated in KitaJS, Hono and Preact.

For buffered-rendering comparisons without streaming, set `BENCH_EXCLUDE=stream`. This applies to individual runs and the comparison command.

## Isolated workload comparison

When earlier workloads change the renderer's JIT/type profile enough to destabilize later results, use a fresh process for each workload:

```sh
BENCH_EXCLUDE=stream bun bench/compare-isolated.mjs ../res-x-performance-round1 ../res-x-performance-round2 bench/results/round2 3
```

This runs each workload three times per version in neighboring, alternating baseline/candidate pairs. Each child still warms up for one second and records nine samples. Six aggregate JSON files retain the samples and per-workload timestamps, along with an `isolation: "workload"` marker. Source revisions and hashes must remain constant throughout. Use detached worktree snapshots as targets so publishing further commits does not invalidate in-progress measurements. This controls cross-workload JIT history; it does not eliminate GC or shared-host noise, nor measure cold startup.
