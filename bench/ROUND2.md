# Second optimization pass

Baseline: the first-pass PR at `2b6dbd5`. The new implementation adds a dedicated compiler JSX factory, a synchronous fast path in the async rendering API, a single-promise fast path, lazy request-controller collections, and record-based default Headers construction.

The [source research](RENDERER-RESEARCH.md) explains the techniques investigated in KitaJS, Hono and Preact. Streaming is excluded from this pass's performance comparison.

Repeated measurements are in progress. The earlier `round2-pilot-*.json` files describe a rejected intermediate variadic-factory experiment, not the current implementation. No additional speedup is claimed until the controlled comparison completes.
