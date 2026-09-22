# Framework performance benchmarks

Install the locked dependencies and build the framework before running:

```sh
npm ci
bun run res:build
bun run test
bun run bench
bun run bench -- --filter html/ --output /tmp/rendering.json
bun run bench:smoke
```

The workloads cover escaping, attributes, styles, JSX construction, synchronous and asynchronous rendering, UTF-8 encoding, provider contexts, AsyncLocalStorage, request controllers, complete in-process requests, and routing with 1,000 registered routes.

Correctness tests verify each fixture's expected output twice and exercise the runner's statistics and output validation. CI runs a short smoke benchmark without timing thresholds, since shared CI scheduling and JIT behavior make them unreliable.

## Measurement method

Each workload receives at least one second of warmup, adaptive batch calibration, and nine approximately 60 ms samples. The runner reports the median time per operation. Synchronous workloads use a synchronous inner loop; asynchronous workloads await each operation. Expected output is checked before and after timing.

Rendering-only workloads reuse trees; `create-and-render` includes tree construction. The UTF-8 workload forces byte encoding because HTML strings may remain ropes internally. Request workloads create a fresh Request, call the framework handler, and consume Response.text(); they include no sockets, TLS, database, or external I/O. These measure in-process costs, not HTTP throughput. AsyncLocalStorage workloads are runtime controls and may be heavily optimized by the JIT.

## Comparing changes

Run the same harness against separately built checkouts with identical dependencies. `BENCH_ROOT` selects the framework checkout; `BENCH_CASE` selects one exact workload, avoiding preceding workloads affecting its JIT profile:

```sh
BENCH_ROOT=../baseline BENCH_CASE=html/list-100 bun bench/runner.mjs --output /tmp/baseline.json
BENCH_ROOT=../candidate BENCH_CASE=html/list-100 bun bench/runner.mjs --output /tmp/candidate.json
```

Repeat each version in fresh processes at least three times, alternating order, and compare the medians of process medians. Speedup is baseline time divided by candidate time. Use fixed source revisions and an otherwise idle machine; do not run benchmarks concurrently. Small differences and overlapping ranges are not evidence of improvement. Measurements do not cover cold startup or memory usage.

Optional JSON output includes raw samples, runtime/CPU information, source revision and hashes, and the shared workload hash. Keep results outside the repository and summarize relevant measurements in the PR description. `BENCH_EXCLUDE=stream` excludes streaming cases; their output correctness remains covered by tests.
