# Renderer implementation research

Inspected on 2026-09-21 to guide the second optimization pass. This is a source comparison, not a cross-framework speed ranking. Output semantics, escaping and context behavior differ, so published benchmark claims are not treated as measurements of ResX.

## KitaJS HTML

Inspected commit `97b89a9fd3cb2a8ee5b87858b60472ba229548cc`: [automatic JSX runtime](https://github.com/kitajs/html/blob/97b89a9fd3cb2a8ee5b87858b60472ba229548cc/packages/html/src/jsx-runtime.ts) and [string/attribute helpers](https://github.com/kitajs/html/blob/97b89a9fd3cb2a8ee5b87858b60472ba229548cc/packages/html/src/index.ts).

KitaJS has dedicated `jsx` and `jsxs` entry points rather than forcing compiler-generated calls through its legacy variadic factory. It produces strings directly and only uses promises when content is asynchronous. Its scalar-child and collection-child paths are separate.

Applied to ResX: a dedicated two-argument `jsx(type, props)` entry point, wired to the ReScript JSX bindings. It does not allocate a rest-argument array, synthesize an empty children array, or rewrite props. The legacy `h()` factory retains its variadic behavior. This also fixes numeric zero children in compiled JSX.

Not transplanted: eager component execution, in-place child-array flattening, and optional child escaping. ResX must preserve deferred provider/context behavior, reusable child arrays, and automatic text escaping. A raw-string result cannot stand in for an ordinary ResX text child without explicit escaping metadata.

## Hono JSX

Inspected commit `28e8572cd265b4da1160ce6cd51919bb70516e2c`: [node renderer](https://github.com/honojs/hono/blob/28e8572cd265b4da1160ce6cd51919bb70516e2c/src/jsx/base.ts), [buffer helpers](https://github.com/honojs/hono/blob/28e8572cd265b4da1160ce6cd51919bb70516e2c/src/utils/html.ts), and [precompiled JSX entry points](https://github.com/honojs/hono/blob/28e8572cd265b4da1160ce6cd51919bb70516e2c/src/jsx/jsx-runtime.ts).

Hono accumulates synchronous content into a string span, introduces separate promise positions on suspension, and returns the string directly when no asynchronous work exists. Its compiler-oriented runtime also exposes template and attribute helpers. These support two directions: keep synchronous work synchronous, and avoid reconstructing known template structure at runtime.

Applied to ResX: return the synchronous result directly from the promise-returning buffered API instead of always crossing an internal await; special-case a single pending subtree instead of coordinating it through `Promise.all`. The public API still returns a promise and exceptions still reject it.

Potential next step: a ReScript compiler transform emitting static HTML spans plus escaped dynamic holes. This could eliminate intrinsic-element objects entirely, but requires compiler integration and explicit rules for dynamic props, providers and error boundaries. The current runtime patch does not claim those compilation gains.

## Preact render-to-string

Inspected the [server string renderer](https://github.com/preactjs/preact-render-to-string/blob/main/src/index.js). It uses shared empty values, synchronous string results for ordinary trees, and promotes rendering to arrays/promises only when required. Its component hooks and suspension handling also demonstrate why avoiding allocations must not change context/effect lifetimes.

Applied principle: pay for optional state only when used. ResX request-controller head/body/title collections now allocate on first append. Returned title arrays remain independent copies, and collections stay isolated per request. Preact's own hook/context machinery is not copied: ResX has different semantics.

## Profile and rejected experiment

A Bun CPU sample of the first-pass `request/` workloads showed native Response, URL, Headers and Request construction among the largest costs. Element creation and request-controller creation were also visible. This motivated the dedicated JSX factory, lazy collections, and constructing default Headers from a record instead of an iterable of pairs. No Request, Response, Headers or user context object is shared between requests.

An initial rewrite of the legacy variadic `h()` function using `arguments` produced inconsistent rendering timings and a slower create-and-render pilot. It was reverted. The dedicated compiler entry point avoids that variadic adaptation entirely while retaining the old API. The pilot results are retained as `results/round2-pilot-*.json`; they are not the results of the final implementation.

All retained changes are evaluated against the first-pass PR commit with identical workloads. Streaming is excluded from the second-pass performance comparison at the user's request; existing correctness coverage is retained.
